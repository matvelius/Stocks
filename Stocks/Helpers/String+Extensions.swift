//
//  String+Extensions.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/22/24.
//

import Foundation

extension String {
    var isAlpha: Bool {
       allSatisfy { $0.isLetter }
    }
}
