//
//  Environment.swift
//  Alpaca
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation




public enum Environment {
    
    case backtest(cash: Double, paperPublicKey: String, paperSecretKey: String)
    case paper(publicKey: String, secretKey: String)
    case production(publicKey: String, secretKey: String)
    
    public var isBacktest: Bool {
        switch self {
        case .backtest: return true
        default: return false
        }
    }
    
    public var isPaper: Bool {
        switch self {
        case .paper: return true
        default: return false
        }
    }
    
    public var isProduction: Bool {
        switch self {
        case .production: return true
        default: return false
        }
    }
}
