//
//  NetworkServiceProtocol.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 10/3/24.
//

import Foundation

protocol NetworkServiceProtocol {
    func getData(for url: URL) async throws -> Data
    func check(_ response: URLResponse) throws
}

protocol SomeOtherServiceProtocol {
    func someFunc() -> String
}
