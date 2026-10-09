import Foundation

extension DateInterval {
    /// `DateInterval.contains` inclui `end`; intervalos de mês do `Calendar` são semiabertos `[start, end)`.
    func containsExcludingEnd(_ date: Date) -> Bool {
        date >= start && date < end
    }
}
