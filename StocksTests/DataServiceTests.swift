//
//  DataServiceTests.swift
//  StocksTests
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import SwiftData
import XCTest

@testable import Stocks

final class DataServiceTests: XCTestCase {
    
    var dataService: DataService!
    var keychainHelper: KeychainHelper!
    var mockNetworkService: NetworkServiceProtocol!

    override func setUpWithError() throws {
        keychainHelper = KeychainHelper()
        keychainHelper.deleteAPIKeyFromKeychain()
        mockNetworkService = MockNetworkService()
        dataService = DataService(modelContext: ModelContext(try ModelContainer(for: StockListItem.self)),
                                  keychainHelper: keychainHelper,
                                  networkService: mockNetworkService)
    }
    
    func testAggregateUrlString_whenNoAPIKeyExists_throwsError() {
        XCTAssertThrowsError(try dataService.aggregateUrlString(using: "2024-01-01"))
    }

    func testAggregateUrlString_whenAPIKeyExists_returnsCorrectString() {
        keychainHelper.saveAPIKeyToKeychain(apiKey: "123")
        let testString = try? dataService.aggregateUrlString(using: "2024-01-01")
        XCTAssertEqual(testString, "https://api.polygon.io/v2/aggs/grouped/locale/us/market/stocks/2024-01-01?adjusted=true&include_otc=false&apiKey=123")
    }
    
    func testSearchUrlString_whenNoAPIKeyExists_throwsError() {
        XCTAssertThrowsError(try dataService.searchUrlString(for: "test"))
    }

    func testSearchUrlString_whenAPIKeyExists_returnsCorrectString() {
        keychainHelper.saveAPIKeyToKeychain(apiKey: "123")
        let testString = try? dataService.searchUrlString(for: "test")
        XCTAssertEqual(testString, "https://api.polygon.io/v3/reference/tickers?search=test&active=true&limit=10&apiKey=123")
    }
    
    func testStockHistoryUrlString_whenNoAPIKeyExists_throwsError() {
        XCTAssertThrowsError(try dataService.stockHistoryUrlString(for: "TEST"))
    }
}
