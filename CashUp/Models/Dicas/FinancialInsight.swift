import Foundation

struct FinancialInsight: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let message: String
    let severity: InsightSeverity
    let triggerType: InsightTriggerType
    let priorityScore: Int
    let metricLabel: String?
    let actionLabel: String?

    init(id: UUID = UUID(),
         title: String,
         message: String,
         severity: InsightSeverity,
         triggerType: InsightTriggerType,
         priorityScore: Int,
         metricLabel: String? = nil,
         actionLabel: String? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.triggerType = triggerType
        self.priorityScore = priorityScore
        self.metricLabel = metricLabel
        self.actionLabel = actionLabel
    }
}
