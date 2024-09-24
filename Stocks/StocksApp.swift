//
//  StocksApp.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/18/24.
//

import SwiftData
import SwiftUI

@main
struct StocksApp: App {
    var body: some Scene {
        WindowGroup {
            StocksOverviewView(StocksOverviewViewModel())
        }
        .modelContainer(for: StockListItem.self)
    }
}
