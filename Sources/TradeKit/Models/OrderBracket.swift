//
//  OrderBracket.swift
//  TradeKit
//
//  Created by Hans Rietmann on 10/12/2021.
//

import Foundation
import LogKit




public struct OrderBracket: Hashable {
    
    let id = UUID()
    let assetSymbol: AssetSymbol
    let side: PositionSide
    let quantity: Double
    let entryOrderID: UUID
    let entryPlacedAt: Date
    private(set) var entryFilledAt: Date! = nil
    private(set) var exitPlacedAt: Date! = nil
    private(set) var exitFilledAt: Date! = nil
    private(set) var exitOrderID: UUID! = nil
    
    private var components: Set<Calendar.Component> {
        [.nanosecond, .second, .minute, .hour, .day, .weekOfYear, .month, .calendar]
    }
    var entryExecutionDuration: TimeInterval? {
        guard let entryFilledAt = entryFilledAt else { return nil }
        return entryFilledAt.timeIntervalSince1970 - entryPlacedAt.timeIntervalSince1970
    }
    var exitExecutionDuration: TimeInterval? {
        guard let exitPlacedAt = exitPlacedAt, let exitFilledAt = exitFilledAt else { return nil }
        return exitFilledAt.timeIntervalSince1970 - exitPlacedAt.timeIntervalSince1970
    }
    var averageOrderExecutionDuration: TimeInterval? {
        let executions = [entryExecutionDuration, exitExecutionDuration].compactMap { $0 }
        guard !executions.isEmpty else { return nil }
        return executions.reduce(0, +) / Double(executions.count)
    }
     
    enum State: Equatable {
        case placedEntry
        case filledEntry
        case placedExit
        case filledExit(profit: Analytic)
        
        private var rawValue: Int {
            switch self {
            case .placedEntry: return 0
            case .filledEntry: return 1
            case .placedExit: return 2
            case .filledExit: return 3
            }
        }
        
        static func ==(lhs: State, rhs: State) -> Bool { lhs.rawValue == rhs.rawValue }
    }
    private(set) var state: State
    public private(set) var entryPrice: Double! = nil
    private(set) var exitPrice: Double! = nil
    var profit: Analytic? {
        switch state {
        case .filledExit(let profit): return profit
        default: return nil
        }
    }
    var isClosed: Bool {
        switch state {
        case .filledExit: return true
        default: return false
        }
    }
    
    init(placedEntry order: Order) {
        assetSymbol = order.symbol
        switch order.orderSide {
        case .sell: side = .short
        case .buy: side = .long
        }
        quantity = order.quantity
        entryPlacedAt = order.createdAtDate
        entryOrderID = order.id
        state = .placedEntry
    }
    init(position: Position) {
        assetSymbol = position.symbol
        side = position.side
        quantity = position.quantity
        entryPlacedAt = Date()
        entryOrderID = UUID()
        state = .filledEntry
        entryFilledAt = Date()
        entryPrice = position.entryPrice
    }
    
    mutating func fillingEntry(_ order: Order) {
        entryPrice = order.filledAtPrice
        entryFilledAt = order.filledAtDate
        state = .filledEntry
    }
    
    mutating func placingExit(_ order: Order) {
        exitOrderID = order.id
        exitPlacedAt = order.createdAtDate
        state = .placedExit
    }
    
    mutating func fillingExit(_ order: Order) {
        exitPrice = order.filledAtPrice
        exitFilledAt = order.filledAtDate
        let isLong = side == .long
        let entry = quantity * entryPrice
        let exit = quantity * exitPrice
        let amount = isLong ? exit - entry : entry - exit
        let percent = amount / min(entry, exit) * 100
//        log(
//            level: .level0, as: .custom("💶"),
//            "Order bracket closed:",
//            "profit amount: \(amount)$",
//            "profit percent: \(percent)%"
//        )
        let profit = Analytic(amount: amount, percent: percent)
        state = .filledExit(profit: profit)
    }
    
    mutating func cancelExit() {
        exitPlacedAt = nil
        exitOrderID = nil
        state = .filledEntry
    }
    
    public static func ==(lhs: OrderBracket, rhs: OrderBracket) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(quantity)
        hasher.combine(entryOrderID)
    }
    
}
