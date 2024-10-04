//
//  NetworkService.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 10/3/24.
//

import Foundation

public final class NetworkService: NetworkServiceProtocol {
    func getData(for url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        do {
            try check(response)
            return data
        } catch {
            throw error
        }
    }
    
    func check(_ response: URLResponse) throws {
        if let httpURLResponse = response as? HTTPURLResponse {
            switch httpURLResponse.statusCode {
            case 401:
                throw NetworkServiceError.unknownAPIKey
            case 429:
                throw NetworkServiceError.maximumRequestsExceeded
            default:
                break
            }
        }
    }
}

enum NetworkServiceError: Error {
    case maximumRequestsExceeded
    case unknownAPIKey
}
