//
//  DataServiceHelpers.swift
//  Stocks
//
//  Created by Matvey Kostukovsky on 9/22/24.
//

import Foundation

extension DataService {
    // get the last market closing date before the given date in Eastern Time
    // (one day prior at the latest, due to the free tier limitation)
    func lastValidMarketClosingDate(from currentDate: Date) -> Date? {
        guard let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else {
            print("Error: Could not create a date for the day before")
            return nil
        }
        
        let calendar = Calendar.current
        
        var currentDate = dayBefore
        
        // keep moving back by one day until it's a valid trading day
        while calendar.isDateInToday(currentDate) || isHoliday(date: currentDate) || calendar.isDateInWeekend(currentDate) {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                return nil
            }
            currentDate = previousDay
        }

        return currentDate
    }
    
    // helper function to check if a given date is a holiday
    func isHoliday(date: Date) -> Bool {
        let dateString = formatDate(date)
        return Constants.marketHolidays.contains(dateString)
    }

    // function to format the date into "yyyy-MM-dd" Eastern Time
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: date)
    }
    
    struct Constants {
        static let apiUrl = "https://api.polygon.io/"
        
        // List of known U.S. stock market holidays for the years 2022, 2023, and 2024
        static let marketHolidays: Set<String> = [
            // 2022 holidays
            "2022-01-01",  // New Year's Day
            "2022-01-17",  // Martin Luther King Jr. Day
            "2022-02-21",  // Presidents' Day
            "2022-04-15",  // Good Friday
            "2022-05-30",  // Memorial Day
            "2022-06-20",  // Juneteenth National Independence Day (observed)
            "2022-07-04",  // Independence Day
            "2022-09-05",  // Labor Day
            "2022-11-24",  // Thanksgiving Day
            "2022-12-26",  // Christmas Day (observed)

            // 2023 holidays
            "2023-01-02",  // New Year's Day
            "2023-01-16",  // Martin Luther King Jr. Day
            "2023-02-20",  // Presidents' Day
            "2023-04-07",  // Good Friday
            "2023-05-29",  // Memorial Day
            "2023-06-19",  // Juneteenth National Independence Day
            "2023-07-04",  // Independence Day
            "2023-09-04",  // Labor Day
            "2023-11-23",  // Thanksgiving Day
            "2023-12-25",  // Christmas Day

            // 2024 holidays
            "2024-01-01",  // New Year's Day
            "2024-01-15",  // Martin Luther King Jr. Day
            "2024-02-19",  // Presidents' Day
            "2024-03-29",  // Good Friday
            "2024-05-27",  // Memorial Day
            "2024-06-19",  // Juneteenth National Independence Day
            "2024-07-04",  // Independence Day
            "2024-09-02",  // Labor Day
            "2024-11-28",  // Thanksgiving Day
            "2024-12-25"   // Christmas Day
        ]
    }
}
