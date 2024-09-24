//
//  StocksModels.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import Foundation
import SwiftData

@Model
class StockListItem: Identifiable {
    @Attribute(.unique)
    let symbol: String
    let name: String
    
    init(symbol: String, name: String) {
        self.symbol = symbol
        self.name = name
    }
}

struct AggregateResponse: Decodable {
    let results: [StockInfo]?
    let error: String?
}

// model for data fetched from the server
struct StockInfo: Decodable, Hashable {
    let T: String
    let c: Float
}

// model for local use
struct Stock: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let currentPrice: Float
    let dailyChange: Float
}

struct TickerSearchResponse: Decodable {
    let results: [Ticker]
    let error: String?
}

struct Ticker: Decodable {
    let ticker: String
    let name: String?
}

struct StockHistoryResponse: Decodable {
    let results: [StockHistoryResponseItem]
    let error: String?
}

struct StockHistoryResponseItem: Decodable {
    let c: Float
    let t: Int
}

struct StockHistoryDataItem: Identifiable {
    var id = UUID()
    let price: Float
    let date: Date
}
