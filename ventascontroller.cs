using System.Data;
using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MicrosipAPI.Data;
using MicrosipAPI.Dtos.AdminPanel;
using System.IO;
using System.Linq;

namespace MicrosipAPI.Controllers.AdminPanel
{
    [ApiController]
    [Route("api/AdminPanel/[controller]")]
    [Authorize(Roles = "Admin")]
    public class VentasController : ControllerBase
    {
        private readonly IDbConnectionFactory _factory;
        public VentasController(IDbConnectionFactory factory) => _factory = factory;

        // ------------------------------------------------------------
        // ?? UTILIDAD: genera folio consecutivo m�ximo 9 caracteres
        // ------------------------------------------------------------
        private async Task<string> GenerarFolioAsync(
            IDbConnection conn,
            IDbTransaction tx,
            string sistema,
            string tipoDocto,
            int sucursalId)
        {
            // Microsip maneja consecutivos por (SISTEMA, TIPO_DOCTO, SUCURSAL_ID, SERIE[, MODALIDAD_FACTURACION])
            // Tomamos el registro correspondiente y reservamos el siguiente consecutivo de forma at�mica.
            var folioVentas = await conn.QueryFirstOrDefaultAsync<(int FolioVentasId, int Consecutivo)>(@"
SELECT FIRST 1
  FOLIO_VENTAS_ID AS FolioVentasId,
  CONSECUTIVO     AS Consecutivo
FROM FOLIOS_VENTAS
WHERE SISTEMA = @sistema
  AND TIPO_DOCTO = @tipoDocto
  AND SUCURSAL_ID = @sucursalId
ORDER BY
  CASE WHEN MODALIDAD_FACTURACION = 'CFDI' THEN 0 ELSE 1 END,
  FOLIO_VENTAS_ID",
                new { sistema, tipoDocto, sucursalId }, tx);

            if (folioVentas.FolioVentasId == 0)
                throw new Exception($"No existe configuraci�n de folios en FOLIOS_VENTAS para SISTEMA={sistema}, TIPO_DOCTO={tipoDocto}, SUCURSAL_ID={sucursalId}.");

            var nuevoConsecutivo = await conn.ExecuteScalarAsync<int>(@"
UPDATE FOLIOS_VENTAS
SET CONSECUTIVO = CONSECUTIVO + 1
WHERE FOLIO_VENTAS_ID = @id
RETURNING CONSECUTIVO",
                new { id = folioVentas.FolioVentasId }, tx);

            // Formato t�pico observado en tu BD: 'R002909' (TIPO_DOCTO + 6 d�gitos)
            var folio = $"{tipoDocto}{nuevoConsecutivo:D6}";
            return folio.Length > 9 ? folio[..9] : folio;
        }



        // ------------------------------------------------------------
        // GET /api/AdminPanel/Ventas
        // lista paginada
        // ------------------------------------------------------------
        [HttpGet]
        public async Task<ActionResult<object>> GetAll(
            [FromQuery] DateTime? desde,
            [FromQuery] DateTime? hasta,
            [FromQuery] int? clienteId,
            [FromQuery] string? estatus,
            [FromQuery] string? tipo,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            using var conn = _factory.CreateConnection();
            conn.Open();

            var cond = new List<string> { "1=1" };
            if (desde.HasValue) cond.Add("CAST(VE.FECHA AS DATE) >= @desde");
            if (hasta.HasValue) cond.Add("CAST(VE.FECHA AS DATE) <= @hasta");
            if (clienteId.HasValue) cond.Add("VE.CLIENTE_ID = @clienteId");
            if (!string.IsNullOrWhiteSpace(estatus)) cond.Add("VE.ESTATUS = @estatus");
            if (!string.IsNullOrWhiteSpace(tipo)) cond.Add("VE.TIPO_DOCTO = @tipo");

            var where = "WHERE " + string.Join(" AND ", cond);

            // paginaci�n ROWS x TO y (Firebird)
            var skip = ((page <= 0 ? 1 : page) - 1) * (pageSize <= 0 ? 20 : pageSize) + 1;
            var take = skip + (pageSize <= 0 ? 20 : pageSize) - 1;

            var sqlItems = $@"
                SELECT
                    VE.DOCTO_VE_ID AS DoctoVeId,
                    VE.TIPO_DOCTO  AS TipoDocto,
                    VE.FOLIO       AS Folio,
                    VE.FECHA       AS Fecha,

                    VE.CLIENTE_ID  AS ClienteId,
                    C.NOMBRE       AS ClienteNombre,

                    VE.SUCURSAL_ID AS SucursalId,
                    S.NOMBRE       AS SucursalNombre,

                    VE.IMPORTE_NETO       AS Subtotal,
                    VE.TOTAL_IMPUESTOS    AS Impuestos,
                    (VE.IMPORTE_NETO + VE.TOTAL_IMPUESTOS) AS Total,

                    VE.ESTATUS     AS Estatus
                FROM DOCTOS_VE VE
                LEFT JOIN CLIENTES   C ON C.CLIENTE_ID   = VE.CLIENTE_ID
                LEFT JOIN SUCURSALES S ON S.SUCURSAL_ID  = VE.SUCURSAL_ID
                {where}
                ORDER BY VE.FECHA DESC, VE.DOCTO_VE_ID DESC
                ROWS @skip TO @take";

            var sqlCount = $"SELECT COUNT(*) FROM DOCTOS_VE VE {where};";

            var items = await conn.QueryAsync<AdminVentaListDto>(sqlItems,
                new { desde, hasta, clienteId, estatus, tipo, skip, take });

            var total = await conn.ExecuteScalarAsync<int>(sqlCount,
                new { desde, hasta, clienteId, estatus, tipo });

            return Ok(new { total, page, pageSize, items });
        }

        // ------------------------------------------------------------
        // GET /api/AdminPanel/Ventas/{id}
        // detalle con partidas e impuestos
        // ------------------------------------------------------------
        [HttpGet("{id:int}")]
        public async Task<ActionResult<AdminVentaDetailDto>> GetById(int id)
        {
            using var conn = _factory.CreateConnection();
            conn.Open();

            // Encabezado
            var sqlHdr = @"
                SELECT
                    VE.DOCTO_VE_ID AS DoctoVeId,
                    VE.TIPO_DOCTO  AS TipoDocto,
                    VE.FOLIO       AS Folio,
                    VE.FECHA       AS Fecha,

                    VE.CLIENTE_ID  AS ClienteId,
                    C.NOMBRE       AS ClienteNombre,

                    VE.SUCURSAL_ID AS SucursalId,
                    S.NOMBRE       AS SucursalNombre,

                    VE.IMPORTE_NETO       AS Subtotal,
                    VE.TOTAL_IMPUESTOS    AS Impuestos,
                    (VE.IMPORTE_NETO + VE.TOTAL_IMPUESTOS) AS Total,

                    VE.ESTATUS     AS Estatus,
                    VE.DESCRIPCION AS Notas
                FROM DOCTOS_VE VE
                LEFT JOIN CLIENTES   C ON C.CLIENTE_ID   = VE.CLIENTE_ID
                LEFT JOIN SUCURSALES S ON S.SUCURSAL_ID  = VE.SUCURSAL_ID
                WHERE VE.DOCTO_VE_ID = @id";

            var venta = await conn.QueryFirstOrDefaultAsync<AdminVentaDetailDto>(sqlHdr, new { id });
            if (venta == null) return NotFound();

            // Partidas
            var sqlDet = @"
                SELECT
                    DET.DOCTO_VE_DET_ID     AS DoctoVeDetId,
                    DET.DOCTO_VE_ID         AS DoctoVeId,
                    DET.ARTICULO_ID         AS ArticuloId,
                    A.NOMBRE                AS ArticuloNombre,
                    DET.UNIDADES            AS Unidades,
                    DET.PRECIO_UNITARIO     AS PrecioUnitario,
                    DET.PCTJE_DSCTO         AS DescuentoPct,
                    DET.PRECIO_TOTAL_NETO   AS Importe
                FROM DOCTOS_VE_DET DET
                LEFT JOIN ARTICULOS A ON A.ARTICULO_ID = DET.ARTICULO_ID
                WHERE DET.DOCTO_VE_ID = @id
                ORDER BY DET.DOCTO_VE_DET_ID";

            venta.Detalle = (await conn.QueryAsync<AdminVentaDetDto>(sqlDet, new { id })).ToList();

            // Impuestos
            var sqlImp = @"
                SELECT
                    IVE.IMPUESTO_ID       AS ImpuestoId,
                    IVE.VENTA_NETA        AS VentaNeta,
                    IVE.VENTA_BRUTA       AS VentaBruta,
                    IVE.PCTJE_IMPUESTO    AS PctjeImpuesto,
                    IVE.IMPORTE_IMPUESTO  AS ImporteImpuesto
                FROM IMPUESTOS_DOCTOS_VE IVE
                WHERE IVE.DOCTO_VE_ID = @id";

            venta.ImpuestosDetalle = (await conn.QueryAsync<AdminVentaImpuestoDto>(sqlImp, new { id })).ToList();

            return Ok(venta);
        }

        // ------------------------------------------------------------
        // POST /api/AdminPanel/Ventas
        // crear venta FAC/REM/COT con detalle e impuestos
        // ------------------------------------------------------------
        [HttpPost]
        public async Task<ActionResult<object>> Create([FromBody] AdminVentaCreateDto dto)
        {
            if (dto.Detalle == null || dto.Detalle.Count == 0)
                return BadRequest(new { message = "Debes incluir al menos una partida (Detalle)." });

            using var conn = _factory.CreateConnection();
            conn.Open();
            using var tx = conn.BeginTransaction();

            try
            {
                // ============================
                // Normaliza tipo (F / R / C)
                // ============================
                var tipo = (dto.Tipo ?? "FAC").ToUpper();
                string tipoChar = tipo switch
                {
                    "FAC" => "F",
                    "REM" => "R",
                    "COT" => "C",
                    _ => throw new Exception("Tipo inv�lido. Usa FAC | REM | COT.")
                };

                // ============================
                // Validaciones de datos base
                // ============================
                var existeCli = await conn.ExecuteScalarAsync<int>(
                    "SELECT COUNT(*) FROM CLIENTES WHERE CLIENTE_ID=@id",
                    new { id = dto.ClienteId }, tx);
                if (existeCli == 0)
                    return BadRequest(new { message = "CLIENTE_ID no existe." });

                var existeSuc = await conn.ExecuteScalarAsync<int>(
                    "SELECT COUNT(*) FROM SUCURSALES WHERE SUCURSAL_ID=@id",
                    new { id = dto.SucursalId }, tx);
                if (existeSuc == 0)
                    return BadRequest(new { message = "SUCURSAL_ID no existe." });

                if (dto.AlmacenId.HasValue)
                {
                    var existeAlm = await conn.ExecuteScalarAsync<int>(
                        "SELECT COUNT(*) FROM ALMACENES WHERE ALMACEN_ID=@id",
                        new { id = dto.AlmacenId }, tx);
                    if (existeAlm == 0)
                        return BadRequest(new { message = "ALMACEN_ID no existe." });
                }

                foreach (var r in dto.Detalle)
                {
                    var exArt = await conn.ExecuteScalarAsync<int>(
                        "SELECT COUNT(*) FROM ARTICULOS WHERE ARTICULO_ID=@id",
                        new { id = r.ArticuloId }, tx);
                    if (exArt == 0)
                        return BadRequest(new { message = $"ARTICULO_ID {r.ArticuloId} no existe." });
                }

                // ============================
                // Direcciones del cliente (Microsip cl�sico)
                // ============================
                var dirCliId = await conn.ExecuteScalarAsync<int?>(
                    "SELECT FIRST 1 DIR_CLI_ID FROM DIRS_CLIENTES WHERE CLIENTE_ID=@id ORDER BY DIR_CLI_ID",
                    new { id = dto.ClienteId }, tx);

                // Si el cliente no tiene direcci�n, asigna un valor gen�rico o lanza error controlado
                if (dirCliId == null)
                {
                    // Puedes crear una direcci�n gen�rica o simplemente detener la operaci�n:
                    throw new Exception($"El cliente {dto.ClienteId} no tiene direcci�n registrada en DIRS_CLIENTES.");
                }

                // Usa la misma direcci�n para env�o y facturaci�n
                var dirConsigId = dirCliId;


                // ============================
                // Generar folio consecutivo
                // ============================
                var folio = await GenerarFolioAsync(conn, tx, "VE", tipoChar, dto.SucursalId);

                // ============================
                // C�lculos de totales
                // ============================
                decimal subtotal = 0m;
                foreach (var r in dto.Detalle)
                {
                    var descPct = r.DescuentoPct ?? 0m;
                    subtotal += r.PrecioUnitario * r.Unidades * (1 - (descPct / 100m));
                }

                var ivaPct = dto.IvaPct ?? 16m;
                var iva = Math.Round(subtotal * (ivaPct / 100m), 2);
                var total = subtotal + iva;

                // ============================
                // INSERT: Encabezado DOCTOS_VE
                // ============================
                var sqlHdr = @"
INSERT INTO DOCTOS_VE (
    DOCTO_VE_ID,
    TIPO_DOCTO,
    SUBTIPO_DOCTO,
    SUCURSAL_ID,
    FOLIO,
    FECHA,
    HORA,
    CLIENTE_ID,
    DIR_CLI_ID,
    DIR_CONSIG_ID,
    ALMACEN_ID,
    MONEDA_ID,
    TIPO_CAMBIO,
    COND_PAGO_ID,
    IMPORTE_NETO,
    TOTAL_IMPUESTOS,
    DESCRIPCION,
    ESTATUS,
    APLICADO,
    SISTEMA_ORIGEN
) VALUES (
    -1,
    @TipoDocto,
    'N',
    @SucursalId,
    @Folio,
    @Fecha,
    @Hora,
    @ClienteId,
    @DirCliId,
    @DirConsigId,
    @AlmacenId,
    1,             -- MONEDA_ID (Pesos)
    1.000000,      -- TIPO_CAMBIO
    778,           -- COND_PAGO_ID (contado)
    @ImporteNeto,
    @TotalImpuestos,
    @Notas,
    'N',           -- ESTATUS
    'N',           -- APLICADO
    'VE'
)
RETURNING DOCTO_VE_ID";

                var doctoVeId = await conn.ExecuteScalarAsync<int>(sqlHdr, new
                {
                    TipoDocto = tipoChar,
                    SucursalId = dto.SucursalId,
                    Folio = folio,
                    Fecha = (dto.Fecha ?? DateTime.Now).Date,
                    Hora = DateTime.Now.ToString("HH:mm"),
                    ClienteId = dto.ClienteId,
                    DirCliId = dirCliId,
                    DirConsigId = dirConsigId,
                    AlmacenId = dto.AlmacenId,
                    ImporteNeto = subtotal,
                    TotalImpuestos = iva,
                    Notas = (dto.Notas ?? "").Length > 200 ? dto.Notas[..200] : dto.Notas
                }, tx);

                // ============================
                // INSERT: Detalle DOCTOS_VE_DET
                // ============================
                var sqlDet = @"
INSERT INTO DOCTOS_VE_DET (
    DOCTO_VE_DET_ID,
    DOCTO_VE_ID,
    ARTICULO_ID,
    UNIDADES,
    PRECIO_UNITARIO,
    PCTJE_DSCTO,
    PRECIO_TOTAL_NETO
) VALUES (
    -1,
    @DoctoVeId,
    @ArticuloId,
    @Unidades,
    @PrecioUnitario,
    @DescuentoPct,
    @Importe
)";

                foreach (var r in dto.Detalle)
                {
                    decimal descPct = r.DescuentoPct ?? 0m;
                    decimal importeLinea = r.PrecioUnitario * r.Unidades * (1 - (descPct / 100m));

                    await conn.ExecuteAsync(sqlDet, new
                    {
                        DoctoVeId = doctoVeId,
                        ArticuloId = r.ArticuloId,
                        Unidades = r.Unidades,
                        PrecioUnitario = r.PrecioUnitario,
                        DescuentoPct = descPct,
                        Importe = importeLinea
                    }, tx);
                }

                // ============================
                // INSERT: Impuestos IMPUESTOS_DOCTOS_VE
                // ============================
                var sqlImp = @"
INSERT INTO IMPUESTOS_DOCTOS_VE (
    DOCTO_VE_ID,
    IMPUESTO_ID,
    VENTA_NETA,
    VENTA_BRUTA,
    PCTJE_IMPUESTO,
    IMPORTE_IMPUESTO
) VALUES (
    @DoctoVeId,
    @ImpuestoId,
    @VentaNeta,
    @VentaBruta,
    @PctjeImpuesto,
    @ImporteImpuesto
)";

                await conn.ExecuteAsync(sqlImp, new
                {
                    DoctoVeId = doctoVeId,
                    ImpuestoId = 783,
                    VentaNeta = subtotal,
                    VentaBruta = total,
                    PctjeImpuesto = ivaPct,
                    ImporteImpuesto = iva
                }, tx);

                // ================================================
                // ?? Aplicar documento en MicroSIP (afectar inventario autom�ticamente)
                // ================================================
                try
                {
                    await conn.ExecuteAsync("EXECUTE PROCEDURE APLICA_DOCTO_VE(@id)", new { id = doctoVeId }, tx);
                }
                catch (Exception applyEx)
                {
                    Console.WriteLine($"[WARN] No se pudo aplicar inventario autom�ticamente: {applyEx.Message}");
                    // No detiene el flujo si MicroSIP tiene bloqueos o validaciones internas
                }



                tx.Commit();

                return CreatedAtAction(nameof(GetById),
                    new { id = doctoVeId },
                    new { id = doctoVeId, folio, total });
            }
            catch (Exception ex)
            {
                tx.Rollback();

                string logPath = @"C:\inetpub\MicrosipAPI\logs\ventas-errors.txt";
                string dtoJson = System.Text.Json.JsonSerializer.Serialize(dto, new System.Text.Json.JsonSerializerOptions
                {
                    WriteIndented = true
                });

                string errorMsg = $@"
======================================================
[ERROR VENTAS] {DateTime.Now:yyyy-MM-dd HH:mm:ss}
Mensaje: {ex.Message}
StackTrace: {ex.StackTrace}
InnerException: {ex.InnerException?.Message}
DTO RECIBIDO:
{dtoJson}
======================================================
";

                try
                {
                    Directory.CreateDirectory(Path.GetDirectoryName(logPath)!);
                    System.IO.File.AppendAllText(logPath, errorMsg);
                }
                catch { }

                Console.WriteLine(errorMsg);

                return BadRequest(new { message = ex.Message });
            }
        }



        // ------------------------------------------------------------
        // PUT /api/AdminPanel/Ventas/{id}
        // actualizar cabecera (ejemplo: Fecha, Notas)
        // ------------------------------------------------------------
        [HttpPut("{id:int}")]
        public async Task<ActionResult> UpdateHeader(int id, [FromBody] AdminVentaUpdateDto dto)
        {
            using var conn = _factory.CreateConnection();
            conn.Open();

            var rows = await conn.ExecuteAsync(@"
                UPDATE DOCTOS_VE
                SET
                    FECHA = COALESCE(@Fecha, FECHA),
                    DESCRIPCION = COALESCE(@Notas, DESCRIPCION)
                WHERE DOCTO_VE_ID = @id",
                new
                {
                    id,
                    dto.Fecha,
                    dto.Notas
                });

            return rows == 0 ? NotFound() : NoContent();
        }

        // ------------------------------------------------------------
        // PUT /api/AdminPanel/Ventas/{id}/estatus?estatus=C
        // cancelar / reactivar
        // ------------------------------------------------------------
        [HttpPut("{id:int}/estatus")]
        public async Task<ActionResult> UpdateEstatus(int id, [FromQuery] string estatus = "N")
        {
            using var conn = _factory.CreateConnection();
            conn.Open();

            var e = (estatus ?? "N").ToUpper();
            if (e != "N" && e != "C")
                return BadRequest(new { message = "Estatus inv�lido. Usa N o C." });

            var rows = await conn.ExecuteAsync(
                "UPDATE DOCTOS_VE SET ESTATUS=@e WHERE DOCTO_VE_ID=@id",
                new { id, e });

            return rows == 0 ? NotFound() : NoContent();
        }

        // ------------------------------------------------------------
        // DELETE /api/AdminPanel/Ventas/{id}
        // baja l�gica -> estatus 'C'
        // ------------------------------------------------------------
        [HttpDelete("{id:int}")]
        public async Task<ActionResult> DeleteLogical(int id)
        {
            using var conn = _factory.CreateConnection();
            conn.Open();

            var rows = await conn.ExecuteAsync(
                "UPDATE DOCTOS_VE SET ESTATUS='C' WHERE DOCTO_VE_ID=@id",
                new { id });

            return rows == 0 ? NotFound() : NoContent();
        }

        // ------------------------------------------------------------
        // GET /api/AdminPanel/Ventas/Reportes/Periodo?desde=...&hasta=...
        // totales por d�a
        // ------------------------------------------------------------
        [HttpGet("Reportes/Periodo")]
        public async Task<ActionResult<IEnumerable<AdminVentaReportePeriodoDto>>> ReportePeriodo(
            [FromQuery] DateTime? desde,
            [FromQuery] DateTime? hasta)
        {
            using var conn = _factory.CreateConnection();
            conn.Open();

            var fIni = (desde ?? DateTime.Now.AddDays(-30)).Date;
            var fFin = (hasta ?? DateTime.Now).Date;

            var sql = @"
                SELECT
                    CAST(VE.FECHA AS DATE)            AS Fecha,
                    COUNT(*)                          AS NumDocs,
                    SUM(VE.IMPORTE_NETO)              AS Subtotal,
                    SUM(VE.TOTAL_IMPUESTOS)           AS Impuestos,
                    SUM(VE.IMPORTE_NETO+VE.TOTAL_IMPUESTOS) AS Total
                FROM DOCTOS_VE VE
                WHERE CAST(VE.FECHA AS DATE) BETWEEN @fIni AND @fFin
                GROUP BY CAST(VE.FECHA AS DATE)
                ORDER BY Fecha DESC";

            var data = await conn.QueryAsync<AdminVentaReportePeriodoDto>(sql, new { fIni, fFin });
            return Ok(data);
        }

        // ------------------------------------------------------------
        // GET /api/AdminPanel/Ventas/Reportes/PorCliente?clienteId=10&desde=...&hasta=...
        // totales por cliente
        // ------------------------------------------------------------
        [HttpGet("Reportes/PorCliente")]
        public async Task<ActionResult<IEnumerable<AdminVentaReporteClienteDto>>> ReportePorCliente(
            [FromQuery] int? clienteId,
            [FromQuery] DateTime? desde,
            [FromQuery] DateTime? hasta)
        {
            using var conn = _factory.CreateConnection();
            conn.Open();

            var fIni = (desde ?? DateTime.Now.AddMonths(-1)).Date;
            var fFin = (hasta ?? DateTime.Now).Date;

            var filtroCliente = clienteId.HasValue ? "AND VE.CLIENTE_ID = @clienteId" : "";

            var sql = $@"
                SELECT
                    VE.CLIENTE_ID           AS ClienteId,
                    C.NOMBRE                AS ClienteNombre,
                    COUNT(*)                AS NumDocs,
                    SUM(VE.IMPORTE_NETO)    AS Subtotal,
                    SUM(VE.TOTAL_IMPUESTOS) AS Impuestos,
                    SUM(VE.IMPORTE_NETO+VE.TOTAL_IMPUESTOS) AS Total
                FROM DOCTOS_VE VE
                LEFT JOIN CLIENTES C ON C.CLIENTE_ID = VE.CLIENTE_ID
                WHERE CAST(VE.FECHA AS DATE) BETWEEN @fIni AND @fFin
                {filtroCliente}
                GROUP BY VE.CLIENTE_ID, C.NOMBRE
                ORDER BY Total DESC";

            var data = await conn.QueryAsync<AdminVentaReporteClienteDto>(sql,
                new { clienteId, fIni, fFin });

            return Ok(data);
        }

        // ------------------------------------------------------------
        // POST /api/AdminPanel/Ventas/{id}/Convertir?tipoDestino=REM
        // Convierte una venta (Cotizaci�n o Remisi�n) a otro tipo de documento
        // ------------------------------------------------------------
        [HttpPost("{id:int}/Convertir")]
        public async Task<ActionResult<object>> ConvertirVenta(
            int id,
            [FromQuery] string tipoDestino = "REM")
        {
            using var conn = _factory.CreateConnection();
            conn.Open();
            using var tx = conn.BeginTransaction();

            try
            {
                // ================================================
                // 1?? Normalizar tipo destino
                // ================================================
                tipoDestino = tipoDestino.ToUpperInvariant();
                if (tipoDestino is not ("COT" or "REM" or "FAC" or "CFDI2025"))
                    return BadRequest(new { message = "Tipo destino inv�lido. Usa COT | REM | FAC | CFDI2025." });

                // Mapear a valores de MicroSIP
                string tipoMicrosip = tipoDestino switch
                {
                    "COT" => "C",
                    "REM" => "R",
                    "FAC" => "F",
                    "CFDI2025" => "F",
                    _ => "C"
                };

                // ================================================
                // 2?? Traer encabezado original
                // ================================================
                var original = await conn.QueryFirstOrDefaultAsync<AdminVentaDetailDto>(@"
SELECT 
    DOCTO_VE_ID AS DoctoVeId,
    TIPO_DOCTO AS TipoDocto,
    CLIENTE_ID AS ClienteId,
    SUCURSAL_ID AS SucursalId,
    ALMACEN_ID AS AlmacenId,
    FECHA,
    IMPORTE_NETO AS Subtotal,
    TOTAL_IMPUESTOS AS Impuestos,
    (IMPORTE_NETO + TOTAL_IMPUESTOS) AS Total,
    DESCRIPCION AS Notas
FROM DOCTOS_VE
WHERE DOCTO_VE_ID = @id",
                    new { id }, tx);

                if (original is null)
                    return NotFound(new { message = "Documento no encontrado." });

                if (original.TipoDocto == tipoMicrosip)
                    return BadRequest(new { message = $"El documento ya es de tipo {tipoDestino}." });

                // ================================================
                // 3?? Obtener detalle original (asegurar valores correctos)
                // ================================================
                var detalle = (await conn.QueryAsync<AdminVentaDetDto>(@"
SELECT 
    CAST(ARTICULO_ID AS INTEGER) AS ArticuloId,
    COALESCE(UNIDADES, 0) AS Unidades,
    COALESCE(PRECIO_UNITARIO, PRECIO_TOTAL_NETO, 0) AS PrecioUnitario,
    COALESCE(PCTJE_DSCTO, 0) AS DescuentoPct
FROM DOCTOS_VE_DET 
WHERE DOCTO_VE_ID = @id
  AND ARTICULO_ID IS NOT NULL
  AND ARTICULO_ID > 0",
                    new { id }, tx)).ToList();

                if (detalle.Count == 0)
                    return BadRequest(new { message = "El documento original no tiene partidas v�lidas (ARTICULO_ID)." });

                // ================================================
                // 4?? Direcciones del cliente
                // ================================================
                var dirCliId = await conn.ExecuteScalarAsync<int?>(@"
SELECT FIRST 1 DIR_CLI_ID 
FROM DIRS_CLIENTES 
WHERE CLIENTE_ID = @clienteId AND USAR_PARA_FACTURAR = 'S'
ORDER BY DIR_CLI_ID",
                    new { clienteId = original.ClienteId }, tx);

                if (dirCliId is null)
                    return BadRequest(new { message = $"El cliente {original.ClienteId} no tiene direcci�n fiscal registrada (DIR_CLI_ID)." });

                var dirConsigId = await conn.ExecuteScalarAsync<int?>(@"
SELECT FIRST 1 DIR_CLI_ID 
FROM DIRS_CLIENTES 
WHERE CLIENTE_ID = @clienteId AND USAR_PARA_ENVIOS = 'S'
ORDER BY DIR_CLI_ID",
                    new { clienteId = original.ClienteId }, tx);

                if (dirConsigId is null)
                    dirConsigId = dirCliId;

                // ================================================
                // 5?? Calcular totales nuevos
                // ================================================
                decimal subtotal = 0m;
                foreach (var r in detalle)
                {
                    var unidades = r.Unidades > 0 ? r.Unidades : 0m;
                    var precio = r.PrecioUnitario > 0 ? r.PrecioUnitario : 0m;
                    var descuento = (r.DescuentoPct ?? 0m) / 100m;
                    subtotal += precio * unidades * (1 - descuento);
                }

                var ivaPct = 16m;
                var impuestos = Math.Round(subtotal * (ivaPct / 100m), 2);
                var total = subtotal + impuestos;

                // ================================================
                // 6?? Generar nuevo folio
                // ================================================
                var folio = await GenerarFolioAsync(conn, tx, "VE", tipoMicrosip, original.SucursalId);

                // ================================================
                // 7?? Insertar encabezado
                // ================================================
                var notas = $"Convertido desde {original.TipoDocto} #{original.DoctoVeId}. {original.Notas}";
                if (notas.Length > 60) notas = notas.Substring(0, 60);

                var sqlInsertHdr = @"
INSERT INTO DOCTOS_VE (
    DOCTO_VE_ID, TIPO_DOCTO, SUBTIPO_DOCTO, SUCURSAL_ID, FOLIO, FECHA, HORA,
    CLIENTE_ID, DIR_CLI_ID, DIR_CONSIG_ID, ALMACEN_ID, MONEDA_ID, TIPO_CAMBIO,
    COND_PAGO_ID, IMPORTE_NETO, TOTAL_IMPUESTOS, DESCRIPCION, ESTATUS,
    APLICADO, SISTEMA_ORIGEN
) VALUES (
    -1, @TipoDocto, 'N', @SucursalId, @Folio, @Fecha, @Hora,
    @ClienteId, @DirCliId, @DirConsigId, @AlmacenId, 1, 1.000000,
    778, @ImporteNeto, @TotalImpuestos, @Notas, 'N', 'N', 'VE'
)
RETURNING DOCTO_VE_ID;";

                var nuevoId = await conn.ExecuteScalarAsync<int>(sqlInsertHdr, new
                {
                    TipoDocto = tipoMicrosip,
                    SucursalId = original.SucursalId,
                    Folio = folio,
                    Fecha = DateTime.Now.Date,
                    Hora = DateTime.Now.ToString("HH:mm"),
                    ClienteId = original.ClienteId,
                    DirCliId = dirCliId,
                    DirConsigId = dirConsigId,
                    AlmacenId = original.AlmacenId,
                    ImporteNeto = subtotal,
                    TotalImpuestos = impuestos,
                    Notas = notas
                }, tx);

                // ================================================
                // 8?? Insertar detalle clonado
                // ================================================
                var sqlInsertDet = @"
INSERT INTO DOCTOS_VE_DET (
    DOCTO_VE_DET_ID, DOCTO_VE_ID, ARTICULO_ID, UNIDADES,
    PRECIO_UNITARIO, PCTJE_DSCTO, PRECIO_TOTAL_NETO
) VALUES (
    -1, @DoctoVeId, @ArticuloId, @Unidades,
    @PrecioUnitario, @DescuentoPct, @Importe
);";

                foreach (var r in detalle)
                {
                    var importe = r.PrecioUnitario * r.Unidades * (1 - (r.DescuentoPct ?? 0m) / 100m);
                    await conn.ExecuteAsync(sqlInsertDet, new
                    {
                        DoctoVeId = nuevoId,
                        ArticuloId = r.ArticuloId,
                        r.Unidades,
                        r.PrecioUnitario,
                        r.DescuentoPct,
                        Importe = importe
                    }, tx);
                }

                // ================================================
                // 9?? Insertar impuestos
                // ================================================
                var sqlInsertImp = @"
INSERT INTO IMPUESTOS_DOCTOS_VE (
    DOCTO_VE_ID, IMPUESTO_ID, VENTA_NETA, VENTA_BRUTA,
    PCTJE_IMPUESTO, IMPORTE_IMPUESTO
) VALUES (
    @DoctoVeId, 783, @VentaNeta, @VentaBruta, @PctjeImpuesto, @ImporteImpuesto
);";

                await conn.ExecuteAsync(sqlInsertImp, new
                {
                    DoctoVeId = nuevoId,
                    VentaNeta = subtotal,
                    VentaBruta = total,
                    PctjeImpuesto = ivaPct,
                    ImporteImpuesto = impuestos
                }, tx);

                // ================================================
                // ?? Aplicar documento convertido (afectar inventario)
                // ================================================
                try
                {
                    await conn.ExecuteAsync("EXECUTE PROCEDURE APLICA_DOCTO_VE(@id)", new { id = nuevoId }, tx);
                }
                catch (Exception applyEx)
                {
                    Console.WriteLine($"[WARN] No se pudo aplicar inventario autom�ticamente: {applyEx.Message}");
                }

                // ================================================
                // 10) Marcar documento original como ya convertido
                //      (cambiar estatus para que no se vuelva a convertir)
                // ================================================
                await conn.ExecuteAsync(@"UPDATE DOCTOS_VE SET ESTATUS = 'C' WHERE DOCTO_VE_ID = @id", new { id }, tx);

                // ================================================
                // ?? Confirmar y devolver resultado
                // ================================================
                tx.Commit();

                return Ok(new
                {
                    message = $"Documento convertido correctamente de {original.TipoDocto} ? {tipoDestino}",
                    nuevoId,
                    folio,
                    total
                });
            }
            catch (Exception ex)
            {
                tx.Rollback();
                return BadRequest(new { message = ex.Message });
            }
        }




        // ------------------------------------------------------------
        // GET /api/AdminPanel/Ventas/Reportes/PorTipo?desde=...&hasta=...
        // totales por tipo de documento (FAC/REM/COT)
        // ------------------------------------------------------------
        [HttpGet("Reportes/PorTipo")]
        public async Task<ActionResult<IEnumerable<AdminVentaReporteTipoDto>>> ReportePorTipo(
            [FromQuery] DateTime? desde,
            [FromQuery] DateTime? hasta)
        {
            using var conn = _factory.CreateConnection();
            conn.Open();

            var fIni = (desde ?? DateTime.Now.AddMonths(-1)).Date;
            var fFin = (hasta ?? DateTime.Now).Date;

            var sql = @"
                SELECT
                    VE.TIPO_DOCTO           AS TipoDocto,
                    COUNT(*)                AS NumDocs,
                    SUM(VE.IMPORTE_NETO)    AS Subtotal,
                    SUM(VE.TOTAL_IMPUESTOS) AS Impuestos,
                    SUM(VE.IMPORTE_NETO+VE.TOTAL_IMPUESTOS) AS Total
                FROM DOCTOS_VE VE
                WHERE CAST(VE.FECHA AS DATE) BETWEEN @fIni AND @fFin
                GROUP BY VE.TIPO_DOCTO
                ORDER BY Total DESC";

            var data = await conn.QueryAsync<AdminVentaReporteTipoDto>(sql, new { fIni, fFin });
            return Ok(data);
        }
    }
}