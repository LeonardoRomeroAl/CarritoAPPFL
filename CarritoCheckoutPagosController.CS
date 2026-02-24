using System.Text;
using Microsoft.AspNetCore.Mvc;
using MicrosipAPI.Dtos;
using MicrosipAPI.Services;

namespace MicrosipAPI.Controllers
{
    [ApiController]
    [Route("api/carrito-checkout/pagos")] 
    public class CarritoCheckoutPagosController : ControllerBase
    {
        private readonly ICarritoCheckoutPagosService _service;

        public CarritoCheckoutPagosController(ICarritoCheckoutPagosService service)
        {
            _service = service;
        }

        [HttpPost("mercadopago/preference")]
        public async Task<ActionResult<MpCreatePreferenceResponse>> CreatePreference([FromBody] MpCreatePreferenceRequest request, CancellationToken ct)
        {
            try
            {
                var resp = await _service.CrearPreferenceAsync(request, ct);
                return Ok(resp);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { error = ex.Message });
            }
        }

        [HttpPost("mercadopago/webhook")]
        public async Task<ActionResult<MpWebhookAckResponse>> Webhook([FromQuery] string? topic, [FromQuery] string? id, CancellationToken ct)
        {
            topic ??= Request.Query["type"].FirstOrDefault();
            id ??= Request.Query["data.id"].FirstOrDefault();

            using var reader = new StreamReader(Request.Body, Encoding.UTF8);
            var raw = await reader.ReadToEndAsync(ct);

            await _service.ProcesarWebhookAsync(topic, id, raw, ct);
            return Ok(new MpWebhookAckResponse());
        }

        [HttpGet("mercadopago/diagnostico/{cotizacionId:int}")]
        public async Task<ActionResult<MpPagoDiagnosticoResponse>> Diagnostico([FromRoute] int cotizacionId, CancellationToken ct)
        {
            try
            {
                var resp = await _service.DiagnosticarPagoAsync(cotizacionId, ct);
                return Ok(resp);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { error = ex.Message });
            }
        }

        [HttpGet("mercadopago/preference/{preferenceId}")]
        public async Task<ActionResult<MpPreferenceDebugResponse>> Preference([FromRoute] string preferenceId, CancellationToken ct)
        {
            try
            {
                var resp = await _service.ObtenerPreferenceDebugAsync(preferenceId, ct);
                return Ok(resp);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { error = ex.Message });
            }
        }

        [HttpGet("mercadopago/me")]
        public async Task<ActionResult<MpMeDebugResponse>> Me(CancellationToken ct)
        {
            try
            {
                var resp = await _service.ObtenerMeDebugAsync(ct);
                return Ok(resp);
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { error = ex.Message });
            }
        }

        [HttpGet("mercadopago/resultado/{cotizacionId:int}")]
        public async Task<ActionResult<MpPagoSimuladoResponse>> Resultado([FromRoute] int cotizacionId, CancellationToken ct)
        {
            try
            {
                var resp = await _service.ObtenerResultadoAsync(cotizacionId, ct);
                return Ok(resp);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { error = ex.Message });
            }
        }

        [HttpPost("simulado")]
        public async Task<ActionResult<MpPagoSimuladoResponse>> PagarSimulado([FromBody] MpPagoSimuladoRequest request, CancellationToken ct)
        {
            try
            {
                var resp = await _service.PagarSimuladoAsync(request, ct);
                return Ok(resp);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { error = ex.Message });
            }
        }
    }
}
