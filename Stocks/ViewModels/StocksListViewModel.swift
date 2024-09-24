//
//  StocksListViewModel.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import Combine
import Foundation

@MainActor
class StocksListViewModel: ObservableObject {
    private let dataService: DataService
    
    @Published var stockList = [StockListItem]()
    
    @Published var isSearchInProgress = false
    @Published var searchResults = [StockListItem]()
    
    var maximumRequestsExceeded: Bool = false
    
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(dataService: DataService) {
        self.dataService = dataService
        setupStockListSubscription()
        setupSearchResultsSubscription()
        setupErrorSubscription()
    }
    
    func search(for searchTerm: String) {
        guard !searchTerm.isEmpty else { return }
        isSearchInProgress = true
        errorMessage = nil
        dataService.searchSubject.send(searchTerm)
    }
    
    func addStock(_ symbol: String, _ name: String) {
        do {
            try dataService.addStock(symbol, name)
        } catch {
            print("addStock error: \(error)")
        }
    }
    
    func deleteStock(at index: Int) {
        dataService.deleteStock(at: index)
    }
    
    func refreshData() {
        dataService.loadListOfStocks()
    }
    
    func setupStockListSubscription() {
        dataService.$stockList
            .receive(on: RunLoop.main)
            .assign(to: &$stockList)
    }
    
    func setupSearchResultsSubscription() {
        dataService.$searchResults
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] results in
                guard let self else { return }
                self.searchResults = results
                self.isSearchInProgress = false
            }
            .store(in: &cancellables)
    }
    
    func setupErrorSubscription() {
        dataService.$maximumRequestsExceeded
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] bool in
                guard let self else { return }
                self.maximumRequestsExceeded = bool
                setErrorMessage()
            }
            .store(in: &cancellables)
    }
    
    private func setErrorMessage() {
        if maximumRequestsExceeded {
            errorMessage = "You've exceeded the maximum requests per minute, please wait or upgrade your subscription to continue."
        } else {
            errorMessage = nil
        }
    }
}
