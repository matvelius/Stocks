//
//  LineGraphView.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/21/24.
//

import Charts
import Foundation
import SwiftUI

struct LineGraphView: View {
    @State var chartData: [StockHistoryDataItem]
    @State var xTicks: [Date]
    @State var yAxisLow: Int
    @State var yAxisHigh: Int
    
    init(with chartData: [StockHistoryDataItem],
         xTicks: [Date],
         yAxisLow: Int,
         yAxisHigh: Int) {
        self.chartData = chartData
        self.xTicks = xTicks
        self.yAxisLow = yAxisLow
        self.yAxisHigh = yAxisHigh
    }
    
    var body: some View {
        Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Price", dataPoint.price)
            )
            PointMark(
                x: .value("Date", dataPoint.date),
                y: .value("Price", dataPoint.price)
            )
            .symbolSize(9)
        }
        .chartXAxis {
            AxisMarks(values: xTicks) { value in
                AxisValueLabel(format: .dateTime.month().day())  // Custom date format "MM/dd"
                AxisGridLine()
                AxisTick(centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text(currencyFormatter.string(from: NSNumber(value: price)) ?? "")
                    }
                }
                AxisGridLine()
                AxisTick(centered: true)
            }
        }
        .chartYScale(domain: [yAxisLow, yAxisHigh])
        .frame(height: 300)
        .padding()
    }
    
    // Number formatter for currency
    var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }
}
