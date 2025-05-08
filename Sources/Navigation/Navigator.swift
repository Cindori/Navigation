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
    
    public init(initial: [AnyHashable] = []) {
        self.routes = initial
    }
}

/// A Navigator you drive like a LIFO stack.
@MainActor
public final class StackNavigator: Navigator {
    public override init(initial: [AnyHashable] = []) {
        super.init(initial: initial)
    }
    public func push(_ route: AnyHashable) {
        routes.append(route)
    }
    public func pop() {
        _ = routes.popLast()
    }
    public func pop(to route: AnyHashable) {
        // TODO: pop until you find `route`
    }
    public func popToRoot() {
        routes.removeAll()
    }
}

/// A Navigator you drive like a FIFO queue for sheets.
@MainActor
public final class ModalNavigator: Navigator {
    public override init(initial: [AnyHashable] = []) {
        super.init(initial: initial)
    }
    public func push(_ route: AnyHashable) {
        routes.append(route)
    }
    
    public func push(contentsOf newRoutes: [AnyHashable]) {
        routes.append(contentsOf: newRoutes)
    }
    
    public func remove(_ route: AnyHashable) {
        routes.removeAll { $0 == route }
    }
    
    public func removeAll() {
        routes.removeAll()
    }
}
