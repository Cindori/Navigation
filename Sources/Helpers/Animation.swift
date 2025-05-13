//
//  File.swift
//  Navigation
//
//  Created by Oskar Groth on 2025-05-13.
//

import SwiftUI

public extension Animation {
    
    /// A default animation (ease-in-out) with a duration of 0.2s.
    static let defaultQuick = Animation.easeInOut(duration: 0.2)
    /// A default animation (ease-in-out) with a duration of 0.15s.
    static let defaultQuickest = Animation.easeInOut(duration: 0.15)
    /// A default animation (ease-in-out) with a duration of 0.1s.
    static let defaultUltraQuick = Animation.easeInOut(duration: 0.1)
    /// A  spring animation with a 0.3s response and 0.7 damping
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    /// A  spring animation with a 0.2s response and 0.9 damping
    static let quickestSpring = Animation.spring(response: 0.2, dampingFraction: 0.9)
    
}
