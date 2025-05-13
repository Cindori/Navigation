//
//  Navigator.swift
//  TestApp
//
//  Created by Oskar Groth on 2025-05-08.
//

import Foundation

/// A generic base class that owns an array of routes and publishes changes.
@MainActor
open class Navigator: ObservableObject {
    /// The live array of routes (stack or queue)
    @Published internal(set) public var routes: [AnyHashable]
    
    public init(initialRoutes: [AnyHashable] = []) {
        self.routes = initialRoutes
    }
}
