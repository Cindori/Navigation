//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-08.
//

import Foundation

/// A Navigator you drive like a FIFO queue.
public final class QueueNavigator: Navigator {
    /// Enqueue a single route at the back
    public func enqueue(_ route: AnyHashable) {
        routes.append(route)
    }

    /// Enqueue multiple routes at the back
    public func enqueue(contentsOf newRoutes: [AnyHashable]) {
        routes.append(contentsOf: newRoutes)
    }

    /// Dequeue the front-most route, returning it (or nil if empty)
    @discardableResult
    public func dequeue() -> AnyHashable? {
        guard !routes.isEmpty else { return nil }
        return routes.removeFirst()
    }

    /// Peek at the current front-most route without removing
    public var current: AnyHashable? {
        routes.first
    }

    /// Remove all occurrences of a specific route
    public func remove(_ route: AnyHashable) {
        routes.removeAll { $0 == route }
    }

    /// Remove all routes
    public func clear() {
        routes.removeAll()
    }

    /// Replace the entire queue with a new list of routes
    public func replaceAll(with newRoutes: [AnyHashable]) {
        routes = newRoutes
    }
}
