//
//  EnvDelegate+result.swift
//  TradeKit
//
//  Created by Hans Rietmann on 10/12/2021.
//

import Foundation
import Collections
import Algorithms





extension TradeEnvironment {
    
    
    public var result: EnvironmentResult {
        let closedPositions = filledBracketOrders.lazy
        let closedPositionsCount = closedPositions.count
        let profits = closedPositions.compactMap { $0.profit }
        let profitsAmount = profits.map { $0.amount }
        let profitsPercent = profits.map { $0.percent }
        
        let goa = profitsAmount.reduce(0, +)
        let goaPct = goa / initialCash * 100
        let averagePositionGains = goa / Double(closedPositionsCount)
        let averagePositionGainsPct = profitsPercent.reduce(0, +) / Double(closedPositionsCount)
        let lossPositions = profits.filter { $0.amount < 0 }
        let averagePositionLoss = lossPositions
            .reduce(Analytic(amount: 0, percent: 0), +) / lossPositions.count
        
        let profitPositions = profits.filter { $0.amount >= 0 }
        let averagePositionProfit = profitPositions
            .reduce(Analytic(amount: 0, percent: 0), +) / profitPositions.count
        let (minPositionProfit, maxPositionProfit) = profits.minAndMax(by: { $0.amount < $1.amount }) ??
        (.init(amount: 0, percent: 0), .init(amount: 0, percent: 0))
        
        let wonClosedPositions = profitsAmount.filter { $0 >= 0 }.count
        let lostClosedPositions = profitsAmount.filter { $0 < 0 }.count
        
        let longClosed = closedPositions.lazy.filter { $0.side == .long }.count
        let shortClosed = closedPositionsCount - longClosed
        let openPositions = openBracketOrders.lazy.filter { $0.isClosed == false }
        let longOpen = openPositions.filter { $0.side == .long }.count
        let shortOpen = openPositions.filter { $0.side == .short }.count
        
        let positions = chain(openBracketOrders, filledBracketOrders)
        let entryOrders = positions.lazy.compactMap { $0.entryExecutionDuration }
        let exitOrders = positions.lazy.compactMap { $0.exitExecutionDuration }
        let orders = chain(entryOrders, exitOrders)
        let orderCount = Double(orders.count)
        let averageOrderFillingDuration: TimeInterval? = orderCount == 0 ? nil : orders.reduce(0, +) / orderCount
        let (minOrderFillingDuration, maxOrderFillingDuration) = orders.minAndMax() ?? (nil, nil)
        let oldestOpenPositionPlacedAt = openPositions.sorted(by: { $0.entryPlacedAt < $1.entryPlacedAt }).first?.entryPlacedAt
        
        return .init(
            initialCash: initialCash,
            equity: equity,
            buyingPower: buyingPower,
            cash: cash,
            goa: .init(amount: goa, percent: goaPct),
            averagePositionGains: .init(amount: averagePositionGains, percent: averagePositionGainsPct),
            averagePositionLoss: averagePositionLoss,
            averagePositionProfit: averagePositionProfit,
            minPositionProfit: minPositionProfit,
            maxPositionProfit: maxPositionProfit,
            wonClosedPositions: wonClosedPositions,
            lostClosedPositions: lostClosedPositions,
            longClosedPositions: longClosed,
            shortClosedPositions: shortClosed,
            longOpenPositions: longOpen,
            shortOpenPositions: shortOpen,
            averageOrderFillingDuration: averageOrderFillingDuration,
            minOrderFillingDuration: minOrderFillingDuration,
            maxOrderFillingDuration: maxOrderFillingDuration,
            oldestOpenPositionPlacedAt: oldestOpenPositionPlacedAt,
            start: start,
            duration: Calendar.GMT0.dateComponents([.weekdayOrdinal, .day, .minute, .timeZone, .month, .calendar, .year, .era, .nanosecond, .hour, .quarter, .second, .weekOfYear, .weekOfMonth, .yearForWeekOfYear], from: start, to: self.end ?? .init())
        )
    }
    
    
}
