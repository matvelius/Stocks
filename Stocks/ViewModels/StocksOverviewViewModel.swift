//
//  StocksOverviewViewModel.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import Foundation

@MainActor
class StocksOverviewViewModel: ObservableObject {
    private(set) var dataService: DataService?
    
    private let keychainHelper: KeychainHelper
    
    @Published var isLoading = true
    
    @Published var apiKeyExists: Bool = false
    @Published var maximumRequestsExceeded: Bool = false
    
    @Published var stocks = [Stock]()
    
    init(keychainHelper: KeychainHelper = KeychainHelper()) {
        self.keychainHelper = keychainHelper
        self.apiKeyExists = keychainHelper.getAPIKeyFromKeychain() != nil
    }
    
    func addDataService(dataService: DataService) {
        self.dataService = dataService
        setupStocksSubscription()
    }
    
    func fetchStocks() throws {
        guard let dataService else {
            throw StocksOverviewViewModelError.missingDependency
        }
        
        isLoading = true
        
        Task {
            do {
                try await dataService.loadStocksOverviewData()
                maximumRequestsExceeded = false
                isLoading = false
            } catch {
                if let fetchError = error as? DataServiceError {
                    switch fetchError {
                    case .maximumRequestsExceeded:
                        maximumRequestsExceeded = true
                    case .unknownAPIKey:
                        keychainHelper.deleteAPIKeyFromKeychain()
                        apiKeyExists = false
                    default:
                        break
                    }
                }
                print("fetchStocks error: \(error)")
                isLoading = false
            }
        }
    }
    
    func storeAPIKey(_ apiKey: String) {
        apiKeyExists = keychainHelper.saveAPIKeyToKeychain(apiKey: apiKey)
    }
    
    func setupStocksSubscription() {
        guard let dataService else { return }
        dataService.$stocks
            .receive(on: RunLoop.main)
            .assign(to: &$stocks)
    }
}

enum StocksOverviewViewModelError: Error {
    case missingDependency
}
