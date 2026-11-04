import SwiftData

/// Seed e deduplicação de cada abertura do app, antes de a Home ler os dados.
enum PreparacaoDeDadosIniciais {
    /// No fallback em memória o store real não abriu: o store vazio não recebe seed nem deduplicação, e a versão do seed
    /// (`seedVersaoAplicada`) não é gravada. Senão a abertura seguinte trataria o store real como já atualizado
    /// e quem vem de uma versão anterior nunca receberia as categorias novas do catálogo.
    @MainActor
    static func executar(em context: ModelContext, settings: AppSettingsProtocol, usandoFallbackEmMemoria: Bool) {
        guard !usandoFallbackEmMemoria else {
            CashUpLogger.persistence.error("Fallback em memória: seed e deduplicação não executados")
            return
        }
        do {
            try SeedService(settings: settings).aplicar(em: context)
        } catch {
            context.rollback()
            CashUpLogger.persistence.error("Seed: \(error.localizedDescription, privacy: .public)")
        }
        do {
            try DeduplicacaoService().deduplicar(em: context)
        } catch {
            context.rollback()
            CashUpLogger.persistence.error("Deduplicação: \(error.localizedDescription, privacy: .public)")
        }
    }
}
