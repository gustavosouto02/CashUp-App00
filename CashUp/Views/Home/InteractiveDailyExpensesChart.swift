//
//  InteractiveDailyExpensesChart.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 27/05/25.
//

import SwiftUI
import Charts

struct IdentifiableDate: Identifiable {
    let id: UUID
    let date: Date

    init(date: Date) {
        self.id = UUID()
        self.date = date
    }
}

struct InteractiveDailyExpensesChart: View {
    let dailyData: [DailyExpenseItem]
    let expensesViewModel: ExpensesViewModel
    
    @State private var selectedDate: Date? = nil
    @State private var deselectionTask: Task<Void, Never>? = nil
    @State private var dateItemForSheet: IdentifiableDate? = nil

    let selectedBarBlue = Color(red: 0.1, green: 0.45, blue: 1.0)

    private var maxYValue: Double {
        (dailyData.map { $0.totalExpenses }.max() ?? 0) * 1.1 + (dailyData.isEmpty || dailyData.allSatisfy { $0.totalExpenses == 0 } ? 100 : 0)
    }
    
    private var selectedDailyItem: DailyExpenseItem? {
        guard let selectedDate = selectedDate else { return nil }
        return dailyData.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack(spacing: 10) {
            Chart {
                ForEach(dailyData) { item in
                    BarMark(
                        x: .value("Dia", item.date, unit: .day),
                        y: .value("Gasto", item.totalExpenses),
                        width: .automatic
                    )
                    .foregroundStyle(barColor(for: item))
                    .cornerRadius(4)

                    if let currentSelectedDate = selectedDate, Calendar.current.isDate(item.date, inSameDayAs: currentSelectedDate) {
                        RuleMark(x: .value("Selected Day", currentSelectedDate))
                            .foregroundStyle(Color.gray.opacity(0.5))
                            .zIndex(-1)
                            .annotation(position: .top, alignment: .center, spacing: 0) {
                                if item.totalExpenses > 0 || (Calendar.current.isDate(item.date, inSameDayAs: Date()) && item.totalExpenses == 0) {
                                    valueAnnotation(for: item)
                                }
                            }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: calculateXAxisStride())) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day(.defaultDigits), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(preset: .automatic, values: .automatic(desiredCount: 4)) { value in
                     AxisGridLine()
                     AxisValueLabel()
                 }
            }
            .chartYScale(domain: 0...max(10, maxYValue))
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    deselectionTask?.cancel()
                                    guard let plotFrame = proxy.plotFrame else {
                                        self.selectedDate = nil
                                        return
                                    }
                                    let origin = geometry[plotFrame].origin
                                    let location = CGPoint(
                                        x: value.location.x - origin.x,
                                        y: value.location.y - origin.y
                                    )

                                    if let interpolatedDate: Date = proxy.value(atX: location.x, as: Date.self) {
                                        let calendar = Calendar.current
                                        if let nearestDataPoint = dailyData.min(by: { abs($0.date.timeIntervalSince(interpolatedDate)) < abs($1.date.timeIntervalSince(interpolatedDate)) }) {
                                            if calendar.isDate(nearestDataPoint.date, inSameDayAs: interpolatedDate) || dailyData.count == 1 {
                                                self.selectedDate = nearestDataPoint.date
                                            } else {
                                                if let closestDateOnSameDay = dailyData.first(where: {calendar.isDate($0.date, inSameDayAs: interpolatedDate)})?.date {
                                                    self.selectedDate = closestDateOnSameDay
                                                } else {
                                                    if abs(nearestDataPoint.date.timeIntervalSince(interpolatedDate)) < (12 * 60 * 60) {
                                                        self.selectedDate = nearestDataPoint.date
                                                    } else {
                                                        self.selectedDate = nil
                                                    }
                                                }
                                            }
                                        } else {
                                            self.selectedDate = nil
                                        }
                                    } else {
                                        self.selectedDate = nil
                                    }
                                }
                                .onEnded { _ in
                                    if self.selectedDate != nil {
                                        deselectionTask?.cancel()
                                        deselectionTask = Task {
                                            try? await Task.sleep(for: .seconds(3))
                                            if !Task.isCancelled {
                                                self.selectedDate = nil
                                            }
                                        }
                                    }
                                }
                        )
                }
            }
            
            if let item = selectedDailyItem, item.totalExpenses > 0 {
                Button {
                    self.dateItemForSheet = IdentifiableDate(date: item.date)
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.below.rectangle")
                        Text("Ver gastos de \(item.date, style: .date)")
                    }
                    .font(.callout)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
        }
        .animation(.snappy, value: selectedDate)
        .sheet(item: $dateItemForSheet) { identifiableDateItem in
            DailyExpensesDetailView(selectedDate: identifiableDateItem.date, expensesViewModel: expensesViewModel)
        }
    }

    private func barColor(for item: DailyExpenseItem) -> Color {
        if let currentSelectedDate = selectedDate, Calendar.current.isDate(item.date, inSameDayAs: currentSelectedDate) {
            return selectedBarBlue
        }
        return item.isToday ? Color.accentColor.opacity(0.9) : Color.accentColor.opacity(0.7)
    }

    @ViewBuilder
    private func valueAnnotation(for item: DailyExpenseItem) -> some View {
        VStack(spacing: 2) {
            Text(item.totalExpenses, format: .currency(code: "BRL").precision(.fractionLength(item.totalExpenses == 0 ? 0 : 2)))
                .font(.caption.weight(.bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial, in: Capsule())
        .shadow(radius: 1)
        .offset(y: item.totalExpenses > 0 ? -5 : -20)
    }
    
    private func calculateXAxisStride() -> Int {
        let count = dailyData.count
        if count == 0 { return 1}
        if count <= 7 {
            return 1
        } else if count <= 10 {
            return 2
        } else if count <= 20 {
            return 3
        }
        return 7 
    }
}
