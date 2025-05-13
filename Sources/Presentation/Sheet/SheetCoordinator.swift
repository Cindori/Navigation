//
//  SheetCoordinator.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-09.
//

import AppKit

/// Coordinator for presenting view controllers as sheets.
@MainActor
public final class SheetCoordinator {
    public let navigator: QueueNavigator
    public let router = NavigationRouter()
    public let controller: SheetController
    
    /// - Parameters:
    ///   - host:          the view controller to present modals from
    ///   - initialRoutes: pre-enqueued modal routes
    ///   - configure:     register route-to-VC mappings
    public init(
        host: NSViewController,
        initialRoutes: [AnyHashable] = [],
        configure: (NavigationRouter) -> Void
    ) {
        navigator = .init(initialRoutes: initialRoutes)
        configure(router)
        controller = SheetController(host: host, navigator: navigator, router: router)
    }
    
    /// Enqueues a new modal (sheet) to present.
    public func present(_ route: AnyHashable) {
        navigator.enqueue(route)
    }
    
    /// Dismisses the current modal (dequeues it).
    public func dismiss() {
        _ = navigator.dequeue()
    }
    
    /// Clears all pending modals, dismissing any presented.
    public func clear() {
        navigator.clear()
    }
}

