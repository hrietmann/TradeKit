//
//  Calendar+GMT0.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation




extension Calendar {
    
    
    public static let GMT0: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    
    
}
