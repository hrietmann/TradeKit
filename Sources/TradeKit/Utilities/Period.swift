//
//  Period.swift
//  TradeKit
//
//  Created by Hans Rietmann on 04/12/2021.
//

import Foundation



public enum Period: Int, Codable, CaseIterable, Hashable {
    
    case none = 0
    case _1 = 1
    case _2 = 2
    case _3 = 3
    case _4 = 4
    case _5 = 5
    case _6 = 6
    case _7 = 7
    case _8 = 8
    case _9 = 9
    case _10 = 10
    case _12 = 12
    case _14 = 14
    case _15 = 15
    case _20 = 20
    case _26 = 26
    case _30 = 30
    case _50 = 50
    case _52 = 52
    case _60 = 60
    case _80 = 80
    case _100 = 100
    case _120 = 120
    case _200 = 200
    case _240 = 240
    
    public static var min: Period { Period.allCases[1] }
    public static var max: Period { Period.allCases.lazy.last! }
    
    public var next: Period {
        switch self {
        case .none: return ._1
        case ._1: return ._2
        case ._2: return ._3
        case ._3: return ._4
        case ._4: return ._5
        case ._5: return ._6
        case ._6: return ._7
        case ._7: return ._8
        case ._8: return ._9
        case ._9: return ._10
        case ._10: return ._12
        case ._12: return ._14
        case ._14: return ._15
        case ._15: return ._20
        case ._20: return ._26
        case ._26: return ._30
        case ._30: return ._50
        case ._50: return ._52
        case ._52: return ._60
        case ._60: return ._80
        case ._80: return ._100
        case ._100: return ._120
        case ._120: return ._200
        case ._200: return ._240
        case ._240: return ._240
        }
    }
    
    public var previous: Period {
        switch self {
        case .none: return ._1
        case ._1: return ._1
        case ._2: return ._1
        case ._3: return ._2
        case ._4: return ._3
        case ._5: return ._4
        case ._6: return ._5
        case ._7: return ._6
        case ._8: return ._7
        case ._9: return ._8
        case ._10: return ._9
        case ._12: return ._10
        case ._14: return ._12
        case ._15: return ._14
        case ._20: return ._15
        case ._26: return ._20
        case ._30: return ._26
        case ._50: return ._30
        case ._52: return ._50
        case ._60: return ._52
        case ._80: return ._60
        case ._100: return ._80
        case ._120: return ._100
        case ._200: return ._120
        case ._240: return ._200
        }
    }
    
    public func previous(_ n: Int) -> Period {
        var period = self
        for _ in 0..<n {
            period = period.previous
            guard period == .min else { return period }
        }
        return period
    }
    
    public func next(_ n: Int) -> Period {
        var period = self
        for _ in 0..<n {
            period = period.next
            guard period == .max else { return period }
        }
        return period
    }
    
    public func min(_ period: Period = ._2) -> Period {
        rawValue < period.rawValue ? period : self
    }
    
    public func max(_ period: Period) -> Period {
        rawValue > period.rawValue ? period : self
    }
}

public typealias Periods = [Period]
