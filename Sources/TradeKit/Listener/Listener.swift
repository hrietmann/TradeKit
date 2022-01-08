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
    
    func listen() async throws
    
    
}
