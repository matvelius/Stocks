//
//  StocksOverviewViewModel.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import Foundation
import os.signpost

@MainActor
class StocksOverviewViewModel: ObservableObject {
    private(set) var dataService: DataService?
    
    private let keychainHelper: KeychainHelper
    
    @Published var isLoading = true
    
    @Published var apiKeyExists: Bool = false
    @Published var maximumRequestsExceeded: Bool = false
    
    @Published var stocks = [Stock]()
    
    @Published var log: OSLog?
    
    private(set) var signpostID: OSSignpostID?
    
    init(keychainHelper: KeychainHelper = KeychainHelper()) {
        self.keychainHelper = keychainHelper
        self.apiKeyExists = keychainHelper.getAPIKeyFromKeychain() != nil
        launchSignpost()
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
            endSignpost()
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
    
    func launchSignpost() {
        let log = OSLog(
            subsystem: "com.matveycodes.Stocks",
            category: "initialLoad"
        )
        self.log = log
        let signpostID = OSSignpostID(log: log)
        self.signpostID = signpostID
        
        os_signpost(.begin, log: log, name: "Initial Load", signpostID: signpostID)
    }
    
    func endSignpost() {
        guard let log, let signpostID else { return }
        os_signpost(.end, log: log, name: "Initial Load", signpostID: signpostID)
    }
}

enum StocksOverviewViewModelError: Error {
    case missingDependency
}
