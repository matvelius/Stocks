//
//  DataServiceTests.swift
//  StocksTests
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import XCTest
@testable import Stocks
import SwiftData

// I would really want to make the tests more extensive,
// and cover most of the data service and view model code,
// however given the time constraints I decided to prioritize
// functionality and edge cases instead.

final class DataServiceTests: XCTestCase {
    
    var dataService: DataService!
    var keychainHelper: KeychainHelper!

    override func setUpWithError() throws {
        keychainHelper = KeychainHelper()
        keychainHelper.deleteAPIKeyFromKeychain()
        dataService = DataService(modelContext: ModelContext(try ModelContainer(for: StockListItem.self)),
                                  keychainHelper: keychainHelper)
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
