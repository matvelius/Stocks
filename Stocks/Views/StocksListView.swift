//
//  StocksListView.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import SwiftData
import SwiftUI

struct StocksListView: View {
    @Query(sort: \StockListItem.symbol) var stockList: [StockListItem]
    
    @Environment(\.isPresented) var isPresented
    @Environment(\.modelContext) var modelContext
    @StateObject var viewModel: StocksListViewModel
    
    @State private var firstLoad = true
    @State private var showAddStockBottomSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.stockList, id: \.self.symbol) { stock in
                    HStack {
                        Text(stock.name)
                        Spacer()
                        Text(stock.symbol)
                    }
                    .lineLimit(1)
                }
                .onDelete(perform: deleteStockFromList)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddStockBottomSheet = true
                } label: {
                    Text("Add Stock")
                }
            }
        }
        .sheet(isPresented: $showAddStockBottomSheet) {
            addStockSheet()
        }
        .onChange(of: isPresented) {
            if !isPresented {
                viewModel.refreshData()
            }
        }
    }
    
    @ViewBuilder
    func addStockSheet() -> some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                Button {
                    showAddStockBottomSheet = false
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .controlSize(.large)
                .padding(7)
            }
            HStack {
                Image(systemName: "magnifyingglass")
                
                TextField("Search for a stock name or symbol", text: $searchText, onEditingChanged: { isEditing in
                    viewModel.search(for: searchText)
                }, onCommit: {
                    viewModel.search(for: searchText)
                })
                .foregroundColor(.primary)
                .onChange(of: searchText) {
                    firstLoad = false
                    if !searchText.isAlpha {
                        searchText.removeAll(where: { !$0.isLetter })
                    }
                    viewModel.search(for: searchText)
                }
                
                Button(action: {
                    self.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill").opacity(searchText == "" ? 0 : 1)
                }
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .foregroundColor(.secondary)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10.0)
            .padding()
            
            if let errorMessage = viewModel.errorMessage, !firstLoad {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
            
            if firstLoad {
                Text("Please type in a stock name or symbol to search.")
                    .padding(11)
            } else if viewModel.maximumRequestsExceeded {
                EmptyView()
            } else if viewModel.isSearchInProgress {
                Text("Searching, please wait...")
            } else if !viewModel.maximumRequestsExceeded && (viewModel.searchResults.isEmpty || searchText.isEmpty) {
                Text("No results found.")
            } else {
                List {
                    ForEach(viewModel.searchResults) { result in
                        HStack {
                            Text(result.name)
                            Spacer()
                                .frame(minWidth: 5)
                            HStack {
                                Text(result.symbol)
                                Button {
                                    if !stockList.contains(where: { $0.symbol == result.symbol }) {
                                        viewModel.addStock(result.symbol, result.name)
                                    }
                                } label: {
                                    if stockList.contains(where: { $0.symbol == result.symbol }) {
                                        Image(systemName: "checkmark.rectangle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "plus.rectangle.fill")
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                        .lineLimit(1)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
                .padding(0)
            }
            
            Spacer()
        }
        .presentationDetents([.medium, .large])
    }
    
    init(_ viewModel: StocksListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    func deleteStockFromList(at offsets: IndexSet) {
        guard let index = offsets.first else {
            return
        }
        viewModel.deleteStock(at: index)
    }
}
