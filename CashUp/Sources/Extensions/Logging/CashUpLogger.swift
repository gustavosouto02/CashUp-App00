import Foundation
import os

/// Loggers do app. Nunca registrar `amount` ou `expenseDescription`.
enum CashUpLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "br.com.gustavosouto.cashup"

    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
