using MicrosipAPI.Dtos;

namespace MicrosipAPI.Services
{
    public interface ICarritoCheckoutPagosService
    {
        Task<MpCreatePreferenceResponse> CrearPreferenceAsync(MpCreatePreferenceRequest request, CancellationToken ct);
        Task ProcesarWebhookAsync(string? topic, string? id, string rawBody, CancellationToken ct);
        Task<MpPagoDiagnosticoResponse> DiagnosticarPagoAsync(int cotizacionId, CancellationToken ct);
        Task<MpPagoSimuladoResponse> ObtenerResultadoAsync(int cotizacionId, CancellationToken ct);
        Task<MpPreferenceDebugResponse> ObtenerPreferenceDebugAsync(string preferenceId, CancellationToken ct);
        Task<MpMeDebugResponse> ObtenerMeDebugAsync(CancellationToken ct);
        Task<MpPagoSimuladoResponse> PagarSimuladoAsync(MpPagoSimuladoRequest request, CancellationToken ct);
    }
}
