//
//  EnvDelegate+start.swift
//  TradeKit
//
//  Created by Hans Rietmann on 12/12/2021.
//

import Foundation




extension TradeEnvironment {
    
    
    public func run() async throws {
        try await listner.listen()
        #if os(Linux)
        #else
        guard #available(iOS 15, macOS 12, *) else { return }
        result.makeSummaryInConsole()
        #endif
    }
    
    
}
