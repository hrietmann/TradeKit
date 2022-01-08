//
//  EnvironmentResult.swift
//  TradeKit
//
//  Created by Hans Rietmann on 07/12/2021.
//

import Foundation
import LogKit


#if os(Linux)
#else
@available(iOS 15, macOS 12, *)
public struct EnvironmentResult {
    public let initialCash: Double
    public let equity: Double
    public let buyingPower: Double
    public let cash: Double
    /// Gain on account
    public let goa: Analytic
    public var dailyGOA: Analytic {
        let calendar = Calendar.current
        // Replace the hour (time) of both dates with 00:00
        let start = calendar.startOfDay(for: self.start)
        let end = calendar.startOfDay(for: self.end)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return goa / (components.day ?? 1)
    }
    public let averagePositionGains: Analytic
    public let averagePositionLoss: Analytic
    public let averagePositionProfit: Analytic
    public let minPositionProfit: Analytic
    public let maxPositionProfit: Analytic
    public let wonClosedPositions: Int
    public let lostClosedPositions: Int
    public var winRate: Double { Double(wonClosedPositions) / Double(lostClosedPositions + wonClosedPositions) }
    public let longClosedPositions: Int
    public let shortClosedPositions: Int
    public let longOpenPositions: Int
    public let shortOpenPositions: Int
    public var totalPositions: Int { totalOpenPositions + totalClosedPostions }
    public var totalOpenPositions: Int { longOpenPositions + shortOpenPositions }
    public var totalClosedPostions: Int { longClosedPositions + shortClosedPositions }
    public var closedPositionsRate: Double { Double(totalClosedPostions) / Double(totalPositions) }
    public var openPositionsRate: Double { Double(totalOpenPositions) / Double(totalPositions) }
    
    // Orders filling analysis
    public let averageOrderFillingDuration: TimeInterval?
    public var averageOrderFillingDurationString: String {
        guard let duration = averageOrderFillingDuration?.components else { return "—" }
        return DateComponentsFormatter.localizedString(from: duration, unitsStyle: .full) ?? "—"
    }
    public let minOrderFillingDuration: TimeInterval?
    public var minOrderFillingDurationString: String {
        guard let duration = minOrderFillingDuration?.components else { return "—" }
        return DateComponentsFormatter.localizedString(from: duration, unitsStyle: .full) ?? "—"
    }
    public let maxOrderFillingDuration: TimeInterval?
    public var maxOrderFillingDurationString: String {
        guard let duration = maxOrderFillingDuration?.components else { return "—" }
        return DateComponentsFormatter.localizedString(from: duration, unitsStyle: .full) ?? "—"
    }
    public let oldestOpenPositionPlacedAt: Date?
    public var oldestOpenPositionPlacedAtString: String {
        guard let date = oldestOpenPositionPlacedAt?.timeIntervalSince1970,
              let duration = (end.timeIntervalSince1970 - date).components
        else { return "—" }
        return DateComponentsFormatter.localizedString(from: duration, unitsStyle: .full) ?? "—"
    }
    
    public let start: Date
    public let duration: DateComponents
    public var end: Date { Calendar.GMT0.date(byAdding: duration, to: start)! }
    public var days: Int { Calendar.GMT0.dateComponents([.day], from: start, to: end).day ?? 0 }
    
    public func makeSummaryInConsole() {
        
        log(
            level: .level0, as: .custom("🧾"),
            "Session summary",
            "*** ACCOUNT ***",
            "Initial cash: \(initialCash.currency)",
            "Final equity: \(equity.currency)",
            "Remaining cash: \(cash.currency)",
            "Remaining buying power: \(buyingPower.currency)",
            "Profit on account: \(goa.amount.currency) (\(goa.percentString))",
            "Daily profit on account: \(dailyGOA.amount.currency) (\(dailyGOA.percentString))",
            "Average daily positions: \((Double(totalPositions) / Double(days)).rounded())",
            "",
            "*** CLOSED POSITIONS ***",
            "Win/Loss: \(wonClosedPositions)/\(lostClosedPositions) — \(winRate.percent) win rate",
            "Maximum position loss: \(minPositionProfit.amount.currency) (\(minPositionProfit.percentString))",
            "Average position loss: \(averagePositionLoss.amount.currency) (\(averagePositionLoss.percentString))",
            "Average position profit/loss: \(averagePositionGains.amount.currency) (\(averagePositionGains.percentString))",
            "Average position profit: \(averagePositionProfit.amount.currency) (\(averagePositionProfit.percentString))",
            "Maximum position profit: \(maxPositionProfit.amount.currency) (\(maxPositionProfit.percentString))",
            "",
            "*** ALL POSITIONS DETAILS ***",
            "Closed/open positions: \(totalClosedPostions)/\(totalOpenPositions) — \(closedPositionsRate.percent) closed rate",
            "Positions closed: \(totalClosedPostions) (\(longClosedPositions) longs, \(shortClosedPositions) shorts)",
            "Positions open: \(totalOpenPositions) (\(longOpenPositions) longs, \(shortOpenPositions) shorts)",
            "",
            "*** ENTRIES/EXITS TIMING ***",
            "Average order filling duration: \(averageOrderFillingDurationString)",
            "Minimum order filling duration: \(minOrderFillingDurationString)",
            "Maximum order filling duration: \(maxOrderFillingDurationString)",
            "Oldest open position is: \(oldestOpenPositionPlacedAtString) old",
            "",
            "*** SESSION TIMING ***",
            "From date: \(DateFormatter.localizedString(from: start, dateStyle: .full, timeStyle: .short))",
            "To date: \(DateFormatter.localizedString(from: end, dateStyle: .full, timeStyle: .short))",
            "Duration: \(DateComponentsFormatter.localizedString(from: duration, unitsStyle: .full)!)"
        )
    }
}
#endif


extension TimeInterval {
    var components: DateComponents? {
        let from = Date(timeIntervalSince1970: 0)
        let to = Date(timeIntervalSince1970: self)
        let comps: Set<Calendar.Component> = [.nanosecond, .second, .minute, .hour, .day, .weekOfYear, .month, .calendar]
        return Calendar.GMT0.dateComponents(comps, from: from, to: to)
    }
}
