//
//  DataService.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import Combine
import Foundation
import SwiftData

public final class DataService: ObservableObject {
    private let keychainHelper: KeychainHelper
    private let networkService: NetworkServiceProtocol
    
    private var modelContext: ModelContext
    
    // array for locally stored stocks
    @Published var stockList = [StockListItem]()
    // dictionary for efficient look-up of locally stored stocks
    // key: stock symbol, value: stock name
    var stockDictionary = [String: String]()
    
    // array for storing stocks loaded from the API
    @Published var stocks = [Stock]()
    
    let searchSubject = PassthroughSubject<String, Never>()
    @Published var searchResults = [StockListItem]()
    @Published var maximumRequestsExceeded = false
    @Published var apiKeyExists = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext,
         keychainHelper: KeychainHelper = KeychainHelper(),
         networkService: NetworkServiceProtocol = NetworkService()) {
        self.modelContext = modelContext
        self.keychainHelper = keychainHelper
        self.networkService = networkService
        
        self.loadListOfStocks()
        self.setupSearchSubjectSubscription()
    }
    
    func loadListOfStocks() {
        do {
            let descriptor = FetchDescriptor<StockListItem>(sortBy: [SortDescriptor(\.symbol)])
            stockList = try modelContext.fetch(descriptor)
            if stockList.isEmpty {
                loadDefaultListOfStocks()
            }
        } catch {
            loadDefaultListOfStocks()
        }
        stockDictionary = [String: String]()
        stockList.forEach { stockListItem in
            stockDictionary[stockListItem.symbol] = stockListItem.name
        }
        stocks.sort(by: { $0.symbol < $1.symbol })
        stocks.removeAll(where: { stockDictionary[$0.symbol] == nil })
        stockList.sort(by: { $0.symbol < $1.symbol })
        Task {
            try await loadStocksOverviewData()
        }
    }
    
    func addStock(_ symbol: String, _ name: String) throws {
        guard stockDictionary[symbol] == nil else {
            throw DataServiceError.stockAlreadyInTheList
        }
        let stockListItem = StockListItem(symbol: symbol, name: name)
        modelContext.insert(stockListItem)
        stockList.append(stockListItem)
        stockDictionary[symbol] = name
        self.loadListOfStocks()
        Task {
            try await loadStocksOverviewData()
        }
    }
    
    func deleteStock(at index: Int) {
        let stockListItem = stockList[index]
        modelContext.delete(stockListItem)
        stockList.remove(at: index)
        stockDictionary[stockListItem.symbol] = nil
        self.loadListOfStocks()
        Task {
            try await loadStocksOverviewData()
        }
    }
    
    func stockHistory(for symbol: String) async throws -> [StockHistoryDataItem] {
        let stockHistoryURLString = try stockHistoryUrlString(for: symbol)
        
        guard let stockHistoryURL = URL(string: stockHistoryURLString) else {
            throw DataServiceError.unableToCreateURLs
        }
        
        let data = try await networkService.getData(for: stockHistoryURL)
        
        let decoder = JSONDecoder()
        let stockHistoryResponse = try decoder.decode(StockHistoryResponse.self, from: data)
        
        return stockHistoryResponse.results.map { StockHistoryDataItem(price: $0.c, date: Date(timeIntervalSince1970: TimeInterval($0.t))) }
    }
    
    func loadStocksOverviewData() async throws {
        // retrieve last market closing date and the day before that
        guard let lastMarketClosingDate = lastValidMarketClosingDate(from: Date().localDate()),
              let dayBeforeLastMarketClosingDate = lastValidMarketClosingDate(from: lastMarketClosingDate) else {
            throw DataServiceError.unableToRetrieveDates
        }
        
        // create URL strings
        let aggregateUrlStringForLastMarketClosingDate = try aggregateUrlString(using: formatDate(lastMarketClosingDate))
        let aggregateUrlStringForDayBeforeLastMarketClosingDate = try aggregateUrlString(using: formatDate(dayBeforeLastMarketClosingDate))
        
        // create URLs
        guard let lastMarketClosingDateURL = URL(string: aggregateUrlStringForLastMarketClosingDate),
              let dayBeforeLastMarketClosingDateURL = URL(string: aggregateUrlStringForDayBeforeLastMarketClosingDate) else {
            throw DataServiceError.unableToCreateURLs
        }
            
        // get aggregate response for last market closing date
        async let fetchedDataForLastMarketClosingDate = try await networkService.getData(for: lastMarketClosingDateURL)
        
        // get aggregate response for the day before the last market closing date
        async let fetchedDataForDayBeforeLastMarketClosingDate = try await networkService.getData(for: dayBeforeLastMarketClosingDateURL)
        
        // make the two API calls simultaneously
        let (dataForLastMarketClosingDate, dataForDayBeforeLastMarketClosingDate) = try await (fetchedDataForLastMarketClosingDate, fetchedDataForDayBeforeLastMarketClosingDate)
        
        // decode the JSON
        let decoder = JSONDecoder()
        let lastMarketClosingDateAggregateResponse = try decoder.decode(AggregateResponse.self, from: dataForLastMarketClosingDate)
        let dayBeforeLastMarketClosingDateAggregateResponse = try decoder.decode(AggregateResponse.self, from: dataForDayBeforeLastMarketClosingDate)
        
        guard let resultsForLastMarketClosingDate = lastMarketClosingDateAggregateResponse.results,
              let resultsForDayBeforeLastMarketClosingDate = dayBeforeLastMarketClosingDateAggregateResponse.results else {
            throw DataServiceError.unableToRetrieveOverviewResults
        }
                
        // extract and process stock info
        let lastMarketClosingDateStocks = resultsForLastMarketClosingDate.filter { stock in
            stockDictionary[stock.T] != nil
        }
        
        let dayBeforeLastMarketClosingDateStocks = resultsForDayBeforeLastMarketClosingDate.filter { stock in
            stockDictionary[stock.T] != nil
        }
        
        self.stocks = stocks(from: lastMarketClosingDateStocks, and: dayBeforeLastMarketClosingDateStocks)
        self.stocks.sort(by: { $0.symbol < $1.symbol })
    }
    
    private func stocks(from lastMarketClosingDateStocks: [StockInfo], and dayBeforeLastMarketClosingDateStocks: [StockInfo]) -> [Stock] {
        // key: stock symbol, value: closing price
        var dayBeforeLastMarketClosingDateStocksDictionary = [String: Float]()
        for stockInfo in dayBeforeLastMarketClosingDateStocks {
            dayBeforeLastMarketClosingDateStocksDictionary[stockInfo.T] = stockInfo.c
        }
        
        return lastMarketClosingDateStocks.map { stockInfo in
            Stock(symbol: stockInfo.T,
                  name: stockDictionary[stockInfo.T] ?? "n/a",
                  currentPrice: stockInfo.c,
                  dailyChange: (stockInfo.c - (dayBeforeLastMarketClosingDateStocksDictionary[stockInfo.T] ?? 0)))
        }
    }
    
    private func setupSearchSubjectSubscription() {
        searchSubject
            .debounce(for: 0.25, scheduler: DispatchQueue.global())
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self, !searchTerm.isEmpty else { return }
                try? self.performSearch(with: searchTerm)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(with searchTerm: String) throws {
        guard let searchURLString = try? self.searchUrlString(for: searchTerm),
              let searchURL = URL(string: searchURLString) else {
            throw DataServiceError.unableToCreateURLs
        }
        Task {
            do {
                let searchResultsData = try await self.networkService.getData(for: searchURL)
                let searchResults = try JSONDecoder().decode(TickerSearchResponse.self, from: searchResultsData)
                self.searchResults = searchResults.results.filter { $0.name != nil }
                    .map { StockListItem(symbol: $0.ticker, name: $0.name ?? "n/a") }
                self.maximumRequestsExceeded = false
            } catch {
                guard let knownError = error as? NetworkServiceError else {
                    return
                }
                switch knownError {
                case .maximumRequestsExceeded:
                    self.maximumRequestsExceeded = true
                default:
                    break
                }
            }
        }
    }
                                     
    func aggregateUrlString(using date: String) throws -> String {
        guard let apiKey = keychainHelper.getAPIKeyFromKeychain() else {
            throw DataServiceError.unableToRetrieveAPIKey
        }
        return Constants.apiUrl +  "v2/aggs/grouped/locale/us/market/stocks/\(date)?adjusted=true&include_otc=false&apiKey=\(apiKey)"
    }
        
    func searchUrlString(for searchTerm: String) throws -> String {
        guard let apiKey = keychainHelper.getAPIKeyFromKeychain() else {
            throw DataServiceError.unableToRetrieveAPIKey
        }
        return Constants.apiUrl + "v3/reference/tickers?search=\(searchTerm)&active=true&limit=10&apiKey=\(apiKey)"
    }
    
    func stockHistoryUrlString(for symbol: String) throws -> String {
        guard let apiKey = keychainHelper.getAPIKeyFromKeychain() else {
            throw DataServiceError.unableToRetrieveAPIKey
        }
        
        // retrieve last market closing date and a date three months prior
        guard let lastMarketClosingDate = lastValidMarketClosingDate(from: Date().localDate()),
              let threeMonthsBeforeLastMarketClosingDate = Calendar.current.date(byAdding: .month, value: -3, to: lastMarketClosingDate) else {
            throw DataServiceError.unableToRetrieveDates
        }

        return Constants.apiUrl
                + "v2/aggs/ticker/"
                + symbol
                + "/range/1/day/"
                + formatDate(threeMonthsBeforeLastMarketClosingDate)
                + "/"
                + formatDate(lastMarketClosingDate)
                + "?adjusted=true&sort=asc&limit=100&apiKey="
                + apiKey
    }
    
    private func loadDefaultListOfStocks() {
        let defaultListOfStocks = [
            "AAPL": "Apple Inc.",
            "MSFT": "Microsoft Corporation",
            "GOOGL": "Alphabet Inc.",
            "AMZN": "Amazon.com, Inc.",
            "TSLA": "Tesla, Inc.",
            "NFLX": "Netflix, Inc.",
            "NVDA": "NVIDIA Corporation",
            "FB": "Meta Platforms, Inc.",
            "BABA": "Alibaba Group Holding Limited",
            "JPM": "JPMorgan Chase & Co.",
            "V": "Visa Inc.",
            "DIS": "The Walt Disney Company",
            "WMT": "Walmart Inc.",
            "BA": "The Boeing Company",
            "INTC": "Intel Corporation"
        ]
        for (key, value) in defaultListOfStocks {
            let item = StockListItem(symbol: key, name: value)
            modelContext.insert(item)
            stockList.append(item)
        }
    }
}

enum DataServiceError: Error {
    case maximumRequestsExceeded
    case unableToRetrieveAPIKey
    case unableToRetrieveDates
    case unableToCreateURLs
    case unableToRetrieveOverviewResults
    case unknownAPIKey
    case stockAlreadyInTheList
}
