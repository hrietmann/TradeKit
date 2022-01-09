//
//  Listener.swift
//  TradeKit
//
//  Created by Hans Rietmann on 11/12/2021.
//

import Foundation
import Collections



public protocol Listener: Actor {
    
    var delegate: ListenerDelegate! { get set }
    
#if compiler(>=5.5) && canImport(_Concurrency)
    func listen() async throws
    #endif
    
    
}
