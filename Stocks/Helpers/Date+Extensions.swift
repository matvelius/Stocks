//
//  Date+Extensions.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/23/24.
//

import Foundation

extension Date {
    func localDate() -> Date {
        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: self))
        guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: self) else {return self}
    
        return localDate
    }
}
