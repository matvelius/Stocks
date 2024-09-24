//
//  StockDetailView.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import Foundation
import SwiftUI

struct StockDetailView: View {
    @StateObject var viewModel: StockDetailViewModel
    
    @State private var toast: Toast? = nil
    
    var body: some View {
        VStack {
            Text(viewModel.symbol)
                .font(.title)
            Text(viewModel.name)
            
            if viewModel.isLoadingChartData {
                Text("Loading chart data, please wait...")
            } else if viewModel.stockHistory.isEmpty {
                Text("Unable to display chart")
            } else {
                LineGraphView(with: viewModel.stockHistory,
                              xTicks: viewModel.xTicks,
                              yAxisLow: viewModel.yAxisLow,
                              yAxisHigh: viewModel.yAxisHigh)
                Text("Showing last 3 months of data.")
            }
            
            Spacer()
        }
        .onAppear {
            viewModel.loadStockHistory()
        }
        .toastView(toast: $toast)
        .onChange(of: viewModel.maximumRequestsExceeded) { _, newValue in
            if newValue {
                toast = Toast(style: .error, message: "You've exceeded the maximum requests per minute, please wait or upgrade your subscription to continue.")
            }
        }
    }
    
    init(_ viewModel: StockDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}
