//
//  StockDetailViewModel.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import Foundation

@MainActor
class StockDetailViewModel: ObservableObject {
    @Published var isLoadingChartData = true
    @Published var stockHistory = [StockHistoryDataItem]()
    @Published var xTicks = [Date]()
    @Published var yAxisLow: Int = 0
    @Published var yAxisHigh: Int = 1000
    @Published var maximumRequestsExceeded: Bool = false
    
    let symbol: String
    let name: String
    
    private let dataService: DataService
    
    init(symbol: String,
         name: String,
         dataService: DataService) {
        self.symbol = symbol
        self.name = name
        self.dataService = dataService
    }
    
    func loadStockHistory() {
        isLoadingChartData = true
        
        Task {
            do {
                stockHistory = try await dataService.stockHistory(for: symbol)
                xTicks = calculateXTicks()
                yAxisLow = Int(stockHistory.map { $0.price }.min() ?? 0) - 5
                yAxisHigh = Int(stockHistory.map { $0.price }.max() ?? 0) + 5
                maximumRequestsExceeded = false
            } catch {
                if let fetchError = error as? DataServiceError {
                    switch fetchError {
                    case .maximumRequestsExceeded:
                        maximumRequestsExceeded = true
                    default:
                        break
                    }
                }
                print("loadStockHistory error: \(error)")
            }
            isLoadingChartData = false
        }
    }
    
    // Function to calculate 4 X-axis ticks: start, two middle, and end
    func calculateXTicks() -> [Date] {
        guard let firstDate = stockHistory.first?.date, let lastDate = stockHistory.last?.date else {
            return []
        }
        
        let middleDate1 = firstDate.addingTimeInterval(lastDate.timeIntervalSince(firstDate) / 3)
        let middleDate2 = firstDate.addingTimeInterval(2 * lastDate.timeIntervalSince(firstDate) / 3)
        
        return [firstDate, middleDate1, middleDate2, lastDate]
    }
}
