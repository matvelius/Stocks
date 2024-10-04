//
//  MockNetworkService.swift
//  StocksTests
//
//  Created by Matvey Kostukovsky on 10/3/24.
//

import Foundation

@testable import Stocks

public final class MockNetworkService: NetworkServiceProtocol {
    public func getData(for url: URL) async throws -> Data {
        return Data()
    }
    
    public func check(_ response: URLResponse) throws {}
}
