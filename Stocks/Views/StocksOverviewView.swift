//
//  StocksView.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import SwiftData
import SwiftUI

struct StocksOverviewView: View {
    @Environment(\.modelContext) var modelContext
        
    @StateObject var viewModel: StocksOverviewViewModel
    
    @State private var showingAlert = false
    @State private var apiKey = ""
    
    @State private var toast: Toast? = nil
    @State private var animationAmount = 1.0
    
    var body: some View {
        NavigationView {
            VStack {
                header()
                
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        Text("Loading, please wait...")
                        Spacer()
                    }
                } else if viewModel.maximumRequestsExceeded {
                    VStack {
                        Spacer()
                        Button {
                            fetchStocks()
                        } label: {
                            Text("Refresh")
                        }
                        Spacer()
                    }
                } else if viewModel.stocks.isEmpty {
                    emptyState()
                } else {
                    stockOverviewList()
                }
                
                Spacer()
            }
            .refreshable {
                fetchStocks()
            }
        }
        .onAppear {
            guard viewModel.apiKeyExists else {
                showingAlert = true
                return
            }
            initializeDataServiceAndViewModel()
        }
        .toastView(toast: $toast)
        .onChange(of: viewModel.apiKeyExists) { _, newValue in
            if !newValue {
                toast = Toast(style: .error, message: "Unknown API key or some other authorization error, please re-enter your API key.")
                showingAlert = true
            }
        }
        .onChange(of: viewModel.maximumRequestsExceeded) { _, newValue in
            if newValue {
                toast = Toast(style: .error, message: "You've exceeded the maximum requests per minute, please wait or upgrade your subscription to continue.")
            }
        }
        .alert("The polygon.io API requires a valid API key", isPresented: $showingAlert) {
            TextField("Please enter your API key", text: $apiKey)
            Button {
                viewModel.storeAPIKey(apiKey)
                initializeDataServiceAndViewModel()
            } label: {
                Text("Submit")
            }
            .disabled(apiKey.isEmpty)
        }
    }
    
    @ViewBuilder
    func stockOverviewList() -> some View {
        VStack {
            List {
                ForEach(viewModel.stocks) { stock in
                    if let dataService = viewModel.dataService {
                        let stockDetailViewModel = StockDetailViewModel(symbol: stock.symbol,
                                                                        name: stock.name,
                                                                        dataService: dataService)
                        NavigationLink(destination: StockDetailView(stockDetailViewModel)) {
                            HStack(spacing: 8) {
                                Text(stock.symbol)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                Text("$" + String(format:"%.2f", stock.currentPrice))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                Text((stock.dailyChange > 0 ? "+" : "") + String(format:"%.2f", stock.dailyChange))
                                    .foregroundStyle(stock.dailyChange > 0 ? Color.green : Color.red)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func header() -> some View {
        HStack {
            Text("Stocks Overview")
                .font(.headline)
            
            Spacer()
            
            if let dataService = viewModel.dataService {
                let stocksListViewModel = StocksListViewModel(dataService: dataService)
                NavigationLink(destination: StocksListView(stocksListViewModel)) {
                    Text("List of Stocks")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func emptyState() -> some View {
        VStack {
            Spacer()
            Text("There are no stocks on your list. Please use the \"List of Stocks\" button above to navigate to the list view and add one or more stocks using the \"Add Stock\" button.")
            Spacer()
        }
        .padding()
    }
    
    init(_ viewModel: StocksOverviewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private func initializeDataServiceAndViewModel() {
        let dataService = DataService(modelContext: modelContext)
        viewModel.addDataService(dataService: dataService)
        fetchStocks()
    }
    
    private func fetchStocks() {
        do {
            try viewModel.fetchStocks()
        } catch {
            toast = Toast(style: .error, message: "Error fetching stocks: \(error)")
        }
    }
}
