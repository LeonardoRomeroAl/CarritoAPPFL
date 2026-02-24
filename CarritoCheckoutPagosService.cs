using System;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Web;
using Dapper;
using MicrosipAPI.Data;
using MicrosipAPI.Dtos;

namespace MicrosipAPI.Services
{
    public class CarritoCheckoutPagosService : ICarritoCheckoutPagosService
    {
        private readonly IDbConnectionFactory _db;
        private readonly HttpClient _http;
        private readonly IConfiguration _cfg;
        private readonly ICarritoCheckoutService _checkout;

        public CarritoCheckoutPagosService(IDbConnectionFactory db, HttpClient http, IConfiguration cfg, ICarritoCheckoutService checkout)
        {
            _db = db;
            _http = http;
            _cfg = cfg;
            _checkout = checkout;
        }

        public async Task<MpCreatePreferenceResponse> CrearPreferenceAsync(MpCreatePreferenceRequest request, CancellationToken ct)
        {
            if (request.CotizacionId <= 0) throw new ArgumentException("CotizacionId inválido");
            var destino = (request.Destino ?? string.Empty).Trim().ToUpperInvariant();
            if (destino != "R" && destino != "F") throw new ArgumentException("Destino debe ser 'R' o 'F'");

            var accessToken = _cfg["MercadoPago:AccessToken"];
            if (string.IsNullOrWhiteSpace(accessToken)) throw new InvalidOperationException("MercadoPago:AccessToken no está configurado.");

            using var conn = _db.CreateConnection();
            conn.Open();
            using var tx = conn.BeginTransaction();

            var cot = await conn.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT DOCTO_VE_ID, TIPO_DOCTO, CLIENTE_ID FROM DOCTOS_VE WHERE DOCTO_VE_ID=@id",
                new { id = request.CotizacionId },
                tx);

            if (cot == null)
            {
                tx.Rollback();
                throw new InvalidOperationException("Cotización no encontrada");
            }
            if (((string)cot.TIPO_DOCTO).Trim() != "C")
            {
                tx.Rollback();
                throw new InvalidOperationException("El documento no es una cotización");
            }

            var dets = (await conn.QueryAsync<dynamic>(
                "SELECT ARTICULO_ID, UNIDADES, PRECIO_UNITARIO FROM DOCTOS_VE_DET WHERE DOCTO_VE_ID=@id",
                new { id = request.CotizacionId },
                tx)).ToList();

            if (dets.Count == 0)
            {
                tx.Rollback();
                throw new InvalidOperationException("Cotización sin partidas");
            }

            var payerEmail = (_cfg["MercadoPago:PayerEmail"] ?? string.Empty).Trim();

            var items = new List<object>();
            foreach (var d in dets)
            {
                var articuloId = (int)d.ARTICULO_ID;
                var unidades = Convert.ToDecimal(d.UNIDADES);
                var precioUnit = Convert.ToDecimal(d.PRECIO_UNITARIO);

                if (precioUnit <= 0)
                {
                    tx.Rollback();
                    throw new InvalidOperationException($"MercadoPago requiere unit_price > 0. ArticuloId={articuloId}, PrecioUnitario={precioUnit}. Crea la cotización con precioUnitario válido.");
                }

                if (unidades != Math.Floor(unidades) || unidades <= 0)
                {
                    tx.Rollback();
                    throw new InvalidOperationException($"MercadoPago requiere quantity entero > 0. ArticuloId={articuloId}, Unidades={unidades}.");
                }

                items.Add(new
                {
                    title = $"Articulo {articuloId}",
                    quantity = (int)unidades,
                    unit_price = Math.Round(precioUnit, 2),
                    currency_id = "MXN"
                });
            }

            var notificationUrl = (_cfg["MercadoPago:WebhookUrl"] ?? string.Empty).Trim();

            var body = new Dictionary<string, object?>
            {
                ["items"] = items,
                ["notification_url"] = string.IsNullOrWhiteSpace(notificationUrl) ? null : notificationUrl,
                ["external_reference"] = request.CotizacionId.ToString(),
                ["metadata"] = new
                {
                    cotizacion_id = request.CotizacionId,
                    destino = destino
                }
            };

            if (!string.IsNullOrWhiteSpace(payerEmail))
            {
                body["payer"] = new
                {
                    email = payerEmail
                };
            }

            using var httpReq = new HttpRequestMessage(HttpMethod.Post, "https://api.mercadopago.com/checkout/preferences");
            httpReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            httpReq.Content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json");

            using var httpResp = await _http.SendAsync(httpReq, ct);
            var raw = await httpResp.Content.ReadAsStringAsync(ct);
            if (!httpResp.IsSuccessStatusCode)
            {
                tx.Rollback();
                throw new InvalidOperationException($"MercadoPago error: {(int)httpResp.StatusCode} {raw}");
            }

            using var doc = JsonDocument.Parse(raw);
            var prefId = doc.RootElement.GetProperty("id").GetString() ?? string.Empty;
            var initPoint = doc.RootElement.TryGetProperty("init_point", out var ip) ? ip.GetString() ?? string.Empty : string.Empty;
            var sandboxInitPoint = doc.RootElement.TryGetProperty("sandbox_init_point", out var sip) ? sip.GetString() ?? string.Empty : string.Empty;
            if (!string.IsNullOrWhiteSpace(sandboxInitPoint))
            {
                initPoint = sandboxInitPoint;
            }

            await conn.ExecuteAsync(@"
                INSERT INTO API_PAGOS_MP (COTIZACION_ID, DESTINO, PREFERENCE_ID, STATUS, EXTERNAL_REFERENCE, RAW_PAYMENT_JSON, CREATED_AT, UPDATED_AT, PROCESSED)
                VALUES (@CotizacionId, @Destino, @PreferenceId, @Status, @ExternalReference, @Raw, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'N')",
                new
                {
                    CotizacionId = request.CotizacionId,
                    Destino = destino,
                    PreferenceId = prefId,
                    Status = "created",
                    ExternalReference = request.CotizacionId.ToString(),
                    Raw = raw
                },
                tx);

            tx.Commit();

            return new MpCreatePreferenceResponse
            {
                CotizacionId = request.CotizacionId,
                Destino = destino,
                PreferenceId = prefId,
                InitPoint = initPoint
            };
        }

        public async Task ProcesarWebhookAsync(string? topic, string? id, string rawBody, CancellationToken ct)
        {
            var accessToken = _cfg["MercadoPago:AccessToken"];
            if (string.IsNullOrWhiteSpace(accessToken)) throw new InvalidOperationException("MercadoPago:AccessToken no está configurado.");

            var topicNorm = (topic ?? string.Empty).Trim().ToLowerInvariant();
            var idNorm = (id ?? string.Empty).Trim();

            if ((string.IsNullOrWhiteSpace(topicNorm) || string.IsNullOrWhiteSpace(idNorm)) && !string.IsNullOrWhiteSpace(rawBody))
            {
                try
                {
                    using var bodyDoc = JsonDocument.Parse(rawBody);
                    if (string.IsNullOrWhiteSpace(topicNorm))
                    {
                        if (bodyDoc.RootElement.TryGetProperty("type", out var typeEl)) topicNorm = (typeEl.GetString() ?? string.Empty).Trim().ToLowerInvariant();
                        else if (bodyDoc.RootElement.TryGetProperty("topic", out var topEl)) topicNorm = (topEl.GetString() ?? string.Empty).Trim().ToLowerInvariant();
                    }

                    if (string.IsNullOrWhiteSpace(idNorm))
                    {
                        if (bodyDoc.RootElement.TryGetProperty("data", out var dataEl) && dataEl.ValueKind == JsonValueKind.Object)
                        {
                            if (dataEl.TryGetProperty("id", out var dataIdEl)) idNorm = dataIdEl.GetRawText().Trim('"');
                        }
                        if (string.IsNullOrWhiteSpace(idNorm) && bodyDoc.RootElement.TryGetProperty("id", out var idEl))
                        {
                            idNorm = idEl.GetRawText().Trim('"');
                        }
                    }
                }
                catch
                {
                    // ignore parse errors
                }
            }

            if (string.IsNullOrWhiteSpace(idNorm)) return;

            using var conn = _db.CreateConnection();
            conn.Open();
            using var tx = conn.BeginTransaction();

            var eventPreferenceId = $"EVT-{Guid.NewGuid():N}";

            await conn.ExecuteAsync(@"
                INSERT INTO API_PAGOS_MP (COTIZACION_ID, DESTINO, PREFERENCE_ID, PAYMENT_ID, STATUS, RAW_EVENT_JSON, CREATED_AT, UPDATED_AT, PROCESSED)
                VALUES (0, 'R', @PreferenceId, @PaymentId, @Status, @Raw, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'N')",
                new { PreferenceId = eventPreferenceId, PaymentId = idNorm, Status = $"webhook:{topicNorm}", Raw = rawBody ?? string.Empty },
                tx);

            tx.Commit();

            if (topicNorm != "payment" && topicNorm != "merchant_order") return;

            var resolvedPaymentId = idNorm;
            if (topicNorm == "merchant_order")
            {
                using var moReq = new HttpRequestMessage(HttpMethod.Get, $"https://api.mercadopago.com/merchant_orders/{idNorm}");
                moReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                using var moResp = await _http.SendAsync(moReq, ct);
                var moRaw = await moResp.Content.ReadAsStringAsync(ct);
                if (!moResp.IsSuccessStatusCode)
                {
                    return;
                }

                using var moDoc = JsonDocument.Parse(moRaw);
                if (moDoc.RootElement.TryGetProperty("payments", out var paysEl)
                    && paysEl.ValueKind == JsonValueKind.Array
                    && paysEl.GetArrayLength() > 0)
                {
                    var last = paysEl[paysEl.GetArrayLength() - 1];
                    if (last.TryGetProperty("id", out var pidEl))
                    {
                        resolvedPaymentId = pidEl.GetRawText().Trim('"');
                    }
                }
                else
                {
                    return;
                }
            }

            using var getReq = new HttpRequestMessage(HttpMethod.Get, $"https://api.mercadopago.com/v1/payments/{resolvedPaymentId}");
            getReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            using var getResp = await _http.SendAsync(getReq, ct);
            var payRaw = await getResp.Content.ReadAsStringAsync(ct);
            if (!getResp.IsSuccessStatusCode)
            {
                return;
            }

            using var payDoc = JsonDocument.Parse(payRaw);
            var status = payDoc.RootElement.TryGetProperty("status", out var st) ? (st.GetString() ?? string.Empty) : string.Empty;
            var statusDetail = payDoc.RootElement.TryGetProperty("status_detail", out var sd) ? (sd.GetString() ?? string.Empty) : string.Empty;
            var extRef = payDoc.RootElement.TryGetProperty("external_reference", out var er) ? (er.GetString() ?? string.Empty) : string.Empty;

            if (!int.TryParse(extRef, out var cotizacionId) || cotizacionId <= 0)
            {
                return;
            }

            using var conn2 = _db.CreateConnection();
            conn2.Open();
            using var tx2 = conn2.BeginTransaction();

            var pago = await conn2.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT FIRST 1 API_PAGO_MP_ID, DESTINO, PROCESSED FROM API_PAGOS_MP WHERE COTIZACION_ID=@c ORDER BY API_PAGO_MP_ID DESC",
                new { c = cotizacionId },
                tx2);

            if (pago == null)
            {
                tx2.Rollback();
                return;
            }

            var destino = ((string)pago.DESTINO).Trim().ToUpperInvariant();
            var processed = ((string)pago.PROCESSED).Trim().ToUpperInvariant();

            await conn2.ExecuteAsync(
                "UPDATE API_PAGOS_MP SET PAYMENT_ID=@PaymentId, STATUS=@Status, STATUS_DETAIL=@Detail, RAW_PAYMENT_JSON=@Raw, UPDATED_AT=CURRENT_TIMESTAMP WHERE API_PAGO_MP_ID=@Id",
                new { PaymentId = resolvedPaymentId, Status = status, Detail = statusDetail, Raw = payRaw, Id = (int)pago.API_PAGO_MP_ID },
                tx2);

            if (processed == "S")
            {
                tx2.Commit();
                return;
            }

            if (!string.Equals(status, "approved", StringComparison.OrdinalIgnoreCase))
            {
                tx2.Commit();
                return;
            }

            tx2.Commit();

            await _checkout.ConvertirCotizacionAsync(cotizacionId, new CarritoCheckoutConvertirRequest
            {
                Destino = destino,
                IntegrarInventario = "S",
                TipoSurtido = "D"
            }, ct);

            using var conn3 = _db.CreateConnection();
            conn3.Open();
            await conn3.ExecuteAsync(
                "UPDATE API_PAGOS_MP SET PROCESSED='S', UPDATED_AT=CURRENT_TIMESTAMP WHERE COTIZACION_ID=@c",
                new { c = cotizacionId });
        }

        public async Task<MpPagoDiagnosticoResponse> DiagnosticarPagoAsync(int cotizacionId, CancellationToken ct)
        {
            if (cotizacionId <= 0) throw new ArgumentException("CotizacionId inválido");

            var accessToken = _cfg["MercadoPago:AccessToken"];
            if (string.IsNullOrWhiteSpace(accessToken)) throw new InvalidOperationException("MercadoPago:AccessToken no está configurado.");

            string raw;
            JsonElement p;

            var extRef = cotizacionId.ToString();
            var url = $"https://api.mercadopago.com/v1/payments/search?external_reference={HttpUtility.UrlEncode(extRef)}&sort=date_created&criteria=desc&limit=1";

            using (var req = new HttpRequestMessage(HttpMethod.Get, url))
            {
                req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                using var resp = await _http.SendAsync(req, ct);
                raw = await resp.Content.ReadAsStringAsync(ct);
                if (!resp.IsSuccessStatusCode)
                {
                    throw new InvalidOperationException($"MercadoPago error: {(int)resp.StatusCode} {raw}");
                }
            }

            using var doc = JsonDocument.Parse(raw);
            if (!doc.RootElement.TryGetProperty("results", out var results) || results.ValueKind != JsonValueKind.Array || results.GetArrayLength() == 0)
            {
                using var conn = _db.CreateConnection();
                conn.Open();
                var prefId = await conn.QueryFirstOrDefaultAsync<string?>(
                    "SELECT FIRST 1 PREFERENCE_ID FROM API_PAGOS_MP WHERE COTIZACION_ID=@c ORDER BY API_PAGO_MP_ID DESC",
                    new { c = cotizacionId });

                prefId = (prefId ?? string.Empty).Trim();
                if (!string.IsNullOrWhiteSpace(prefId) && !prefId.StartsWith("EVT-", StringComparison.OrdinalIgnoreCase))
                {
                    var moUrl = $"https://api.mercadopago.com/merchant_orders/search?preference_id={HttpUtility.UrlEncode(prefId)}&limit=1&offset=0";
                    using var moReq = new HttpRequestMessage(HttpMethod.Get, moUrl);
                    moReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

                    using var moResp = await _http.SendAsync(moReq, ct);
                    var moRaw = await moResp.Content.ReadAsStringAsync(ct);
                    if (!moResp.IsSuccessStatusCode)
                    {
                        throw new InvalidOperationException($"MercadoPago error: {(int)moResp.StatusCode} {moRaw}");
                    }

                    using var moDoc = JsonDocument.Parse(moRaw);
                    if (moDoc.RootElement.TryGetProperty("elements", out var els) && els.ValueKind == JsonValueKind.Array && els.GetArrayLength() > 0)
                    {
                        var mo = els[0];
                        if (mo.TryGetProperty("payments", out var pays) && pays.ValueKind == JsonValueKind.Array && pays.GetArrayLength() > 0)
                        {
                            var last = pays[pays.GetArrayLength() - 1];
                            if (last.TryGetProperty("id", out var pidEl))
                            {
                                var paymentId2 = pidEl.GetRawText().Trim('"');
                                if (!string.IsNullOrWhiteSpace(paymentId2))
                                {
                                    using var payReq = new HttpRequestMessage(HttpMethod.Get, $"https://api.mercadopago.com/v1/payments/{paymentId2}");
                                    payReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

                                    using var payResp = await _http.SendAsync(payReq, ct);
                                    var payRaw = await payResp.Content.ReadAsStringAsync(ct);
                                    if (!payResp.IsSuccessStatusCode)
                                    {
                                        throw new InvalidOperationException($"MercadoPago error: {(int)payResp.StatusCode} {payRaw}");
                                    }

                                    using var payDoc = JsonDocument.Parse(payRaw);
                                    raw = payRaw;
                                    p = payDoc.RootElement;
                                    goto BuildResponse;
                                }
                            }
                        }

                        raw = moRaw;
                    }
                }

                return new MpPagoDiagnosticoResponse
                {
                    CotizacionId = cotizacionId,
                    Found = false,
                    Raw = raw
                };
            }

            p = results[0];

        BuildResponse:
            var paymentId = p.TryGetProperty("id", out var idEl) ? idEl.GetRawText().Trim('"') : string.Empty;
            var status = p.TryGetProperty("status", out var stEl) ? (stEl.GetString() ?? string.Empty) : string.Empty;
            var statusDetail = p.TryGetProperty("status_detail", out var sdEl) ? (sdEl.GetString() ?? string.Empty) : string.Empty;

            return new MpPagoDiagnosticoResponse
            {
                CotizacionId = cotizacionId,
                Found = true,
                PaymentId = paymentId,
                Status = status,
                StatusDetail = statusDetail,
                Raw = raw
            };
        }

        public async Task<MpPagoSimuladoResponse> ObtenerResultadoAsync(int cotizacionId, CancellationToken ct)
        {
            if (cotizacionId <= 0) throw new ArgumentException("CotizacionId inválido");

            using var conn = _db.CreateConnection();
            conn.Open();

            var pago = await conn.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT FIRST 1 DESTINO, PAYMENT_ID, STATUS, PROCESSED FROM API_PAGOS_MP WHERE COTIZACION_ID=@c ORDER BY API_PAGO_MP_ID DESC",
                new { c = cotizacionId });

            if (pago == null)
            {
                throw new InvalidOperationException("No existe información de pago para esta cotización");
            }

            var destino = ((string?)pago.DESTINO ?? string.Empty).Trim().ToUpperInvariant();
            var paymentId = ((string?)pago.PAYMENT_ID ?? string.Empty).Trim();
            var status = ((string?)pago.STATUS ?? string.Empty).Trim();
            var processed = ((string?)pago.PROCESSED ?? string.Empty).Trim().ToUpperInvariant();

            CarritoCheckoutConvertirResponse? conversion = null;

            if (processed == "S")
            {
                var doc = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "SELECT FIRST 1 DOCTO_VE_ID, FOLIO, TIPO_DOCTO FROM DOCTOS_VE WHERE DESCRIPCION LIKE @pat ORDER BY DOCTO_VE_ID DESC",
                    new { pat = $"Convertido desde C #{cotizacionId}.%" });

                if (doc != null)
                {
                    var docId = (int)doc.DOCTO_VE_ID;
                    var folio = ((string?)doc.FOLIO ?? string.Empty).Trim();
                    var tipo = ((string?)doc.TIPO_DOCTO ?? string.Empty).Trim().ToUpperInvariant();

                    conversion = new CarritoCheckoutConvertirResponse
                    {
                        CotizacionId = cotizacionId,
                        PedidoId = 0,
                        PedidoFolio = string.Empty,
                        DocumentoGeneradoId = docId,
                        DocumentoGeneradoFolio = folio,
                        TipoDocumentoGenerado = tipo
                    };
                }

                if (string.IsNullOrWhiteSpace(status)) status = "approved";
            }

            if (string.IsNullOrWhiteSpace(status))
            {
                status = processed == "S" ? "approved" : "pending";
            }

            if (string.IsNullOrWhiteSpace(destino)) destino = "R";

            return new MpPagoSimuladoResponse
            {
                CotizacionId = cotizacionId,
                Destino = destino,
                PaymentId = paymentId,
                Status = status,
                Conversion = conversion
            };
        }

        public async Task<MpPreferenceDebugResponse> ObtenerPreferenceDebugAsync(string preferenceId, CancellationToken ct)
        {
            preferenceId = (preferenceId ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(preferenceId)) throw new ArgumentException("PreferenceId inválido");

            var accessToken = _cfg["MercadoPago:AccessToken"];
            if (string.IsNullOrWhiteSpace(accessToken)) throw new InvalidOperationException("MercadoPago:AccessToken no está configurado.");

            using var req = new HttpRequestMessage(HttpMethod.Get, $"https://api.mercadopago.com/checkout/preferences/{HttpUtility.UrlEncode(preferenceId)}");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            using var resp = await _http.SendAsync(req, ct);
            var raw = await resp.Content.ReadAsStringAsync(ct);
            if (!resp.IsSuccessStatusCode)
            {
                throw new InvalidOperationException($"MercadoPago error: {(int)resp.StatusCode} {raw}");
            }

            bool? liveMode = null;
            var currencyIds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var excludedPaymentTypes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var excludedPaymentMethods = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            using var doc = JsonDocument.Parse(raw);
            var root = doc.RootElement;

            if (root.TryGetProperty("live_mode", out var lmEl) && (lmEl.ValueKind == JsonValueKind.True || lmEl.ValueKind == JsonValueKind.False))
            {
                liveMode = lmEl.GetBoolean();
            }

            if (root.TryGetProperty("items", out var itemsEl) && itemsEl.ValueKind == JsonValueKind.Array)
            {
                foreach (var it in itemsEl.EnumerateArray())
                {
                    if (it.ValueKind != JsonValueKind.Object) continue;
                    if (it.TryGetProperty("currency_id", out var curEl))
                    {
                        var cur = (curEl.GetString() ?? string.Empty).Trim();
                        if (!string.IsNullOrWhiteSpace(cur)) currencyIds.Add(cur);
                    }
                }
            }

            if (root.TryGetProperty("payment_methods", out var pmEl) && pmEl.ValueKind == JsonValueKind.Object)
            {
                if (pmEl.TryGetProperty("excluded_payment_types", out var eptEl) && eptEl.ValueKind == JsonValueKind.Array)
                {
                    foreach (var x in eptEl.EnumerateArray())
                    {
                        if (x.ValueKind != JsonValueKind.Object) continue;
                        if (x.TryGetProperty("id", out var idEl))
                        {
                            var idVal = (idEl.GetString() ?? string.Empty).Trim();
                            if (!string.IsNullOrWhiteSpace(idVal)) excludedPaymentTypes.Add(idVal);
                        }
                    }
                }

                if (pmEl.TryGetProperty("excluded_payment_methods", out var epmEl) && epmEl.ValueKind == JsonValueKind.Array)
                {
                    foreach (var x in epmEl.EnumerateArray())
                    {
                        if (x.ValueKind != JsonValueKind.Object) continue;
                        if (x.TryGetProperty("id", out var idEl))
                        {
                            var idVal = (idEl.GetString() ?? string.Empty).Trim();
                            if (!string.IsNullOrWhiteSpace(idVal)) excludedPaymentMethods.Add(idVal);
                        }
                    }
                }
            }

            return new MpPreferenceDebugResponse
            {
                PreferenceId = preferenceId,
                LiveMode = liveMode,
                CurrencyIds = currencyIds.ToList(),
                ExcludedPaymentTypes = excludedPaymentTypes.ToList(),
                ExcludedPaymentMethods = excludedPaymentMethods.ToList(),
                Raw = raw
            };
        }

        public async Task<MpMeDebugResponse> ObtenerMeDebugAsync(CancellationToken ct)
        {
            var accessToken = _cfg["MercadoPago:AccessToken"];
            if (string.IsNullOrWhiteSpace(accessToken)) throw new InvalidOperationException("MercadoPago:AccessToken no está configurado.");

            using var req = new HttpRequestMessage(HttpMethod.Get, "https://api.mercadopago.com/users/me");
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            using var resp = await _http.SendAsync(req, ct);
            var raw = await resp.Content.ReadAsStringAsync(ct);
            if (!resp.IsSuccessStatusCode)
            {
                throw new InvalidOperationException($"MercadoPago error: {(int)resp.StatusCode} {raw}");
            }

            long? userId = null;
            var siteId = string.Empty;
            bool? liveMode = null;
            var email = string.Empty;

            using var doc = JsonDocument.Parse(raw);
            var root = doc.RootElement;

            if (root.TryGetProperty("id", out var idEl) && idEl.ValueKind == JsonValueKind.Number)
            {
                if (idEl.TryGetInt64(out var idVal)) userId = idVal;
            }
            if (root.TryGetProperty("site_id", out var siteEl)) siteId = (siteEl.GetString() ?? string.Empty).Trim();
            if (root.TryGetProperty("live_mode", out var lmEl) && (lmEl.ValueKind == JsonValueKind.True || lmEl.ValueKind == JsonValueKind.False))
            {
                liveMode = lmEl.GetBoolean();
            }
            if (root.TryGetProperty("email", out var emEl)) email = (emEl.GetString() ?? string.Empty).Trim();

            return new MpMeDebugResponse
            {
                UserId = userId,
                SiteId = siteId,
                LiveMode = liveMode,
                Email = email,
                Raw = raw
            };
        }

        public async Task<MpPagoSimuladoResponse> PagarSimuladoAsync(MpPagoSimuladoRequest request, CancellationToken ct)
        {
            if (request.CotizacionId <= 0) throw new ArgumentException("CotizacionId inválido");
            var destino = (request.Destino ?? string.Empty).Trim().ToUpperInvariant();
            if (destino != "R" && destino != "F") throw new ArgumentException("Destino debe ser 'R' o 'F'");

            var modoPagos = (_cfg["Pagos:Modo"] ?? string.Empty).Trim();
            if (!string.Equals(modoPagos, "Simulado", StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("El modo de pagos no está configurado como 'Simulado'.");
            }

            using var conn = _db.CreateConnection();
            conn.Open();
            using var tx = conn.BeginTransaction();

            var cot = await conn.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT DOCTO_VE_ID, TIPO_DOCTO FROM DOCTOS_VE WHERE DOCTO_VE_ID=@id",
                new { id = request.CotizacionId },
                tx);

            if (cot == null)
            {
                tx.Rollback();
                throw new InvalidOperationException("Cotización no encontrada");
            }

            if (((string)cot.TIPO_DOCTO).Trim() != "C")
            {
                tx.Rollback();
                throw new InvalidOperationException("El documento no es una cotización");
            }

            var fakePaymentId = $"FAKE-{Guid.NewGuid():N}";

            await conn.ExecuteAsync(@"
                INSERT INTO API_PAGOS_MP (COTIZACION_ID, DESTINO, PREFERENCE_ID, PAYMENT_ID, STATUS, STATUS_DETAIL, EXTERNAL_REFERENCE, RAW_PAYMENT_JSON, CREATED_AT, UPDATED_AT, PROCESSED)
                VALUES (@CotizacionId, @Destino, @PreferenceId, @PaymentId, @Status, @StatusDetail, @ExternalReference, @Raw, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'N')",
                new
                {
                    CotizacionId = request.CotizacionId,
                    Destino = destino,
                    PreferenceId = fakePaymentId,
                    PaymentId = fakePaymentId,
                    Status = "approved",
                    StatusDetail = "simulated_approved",
                    ExternalReference = request.CotizacionId.ToString(),
                    Raw = "{}"
                },
                tx);

            tx.Commit();

            var conversion = await _checkout.ConvertirCotizacionAsync(request.CotizacionId, new CarritoCheckoutConvertirRequest
            {
                Destino = destino,
                IntegrarInventario = "S",
                TipoSurtido = "D"
            }, ct);

            using var conn2 = _db.CreateConnection();
            conn2.Open();
            await conn2.ExecuteAsync(
                "UPDATE API_PAGOS_MP SET PROCESSED='S', UPDATED_AT=CURRENT_TIMESTAMP WHERE COTIZACION_ID=@c",
                new { c = request.CotizacionId });

            return new MpPagoSimuladoResponse
            {
                CotizacionId = request.CotizacionId,
                Destino = destino,
                PaymentId = fakePaymentId,
                Status = "approved",
                Conversion = conversion
            };
        }
    }
}
