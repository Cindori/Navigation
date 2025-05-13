//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-11.
//

import Foundation

@MainActor
public final class SplitViewCoordinator {
    public let navigator: CollectionNavigator
    public let router: NavigationRouter
    public let controller: SplitViewController

    public init(
        initialRoutes: [AnyHashable] = [],
        configure: ((NavigationRouter) -> Void)? = nil
    ) {
        self.navigator = CollectionNavigator(initialRoutes: initialRoutes)
        router = NavigationRouter()
        configure?(router)
        self.controller = SplitViewController(navigator: navigator, router: router)
    }

    public func setRoutes(_ routes: [AnyHashable]) {
        navigator.setRoutes(routes)
    }

    public func insert(_ route: AnyHashable, at index: Int) {
        navigator.insert(route, at: index)
    }
    
    public func replace(at index: Int, with newRoute: AnyHashable) {
        navigator.replace(at: index, with: newRoute)
    }

    public func append(_ route: AnyHashable) {
        navigator.append(route)
    }

    public func remove(at index: Int) {
        navigator.remove(at: index)
    }

    public func remove(_ route: AnyHashable) {
        navigator.remove(route)
    }

    public func move(from sourceIndex: Int, to destinationIndex: Int) {
        navigator.move(from: sourceIndex, to: destinationIndex)
    }

    public func clear() {
        navigator.clear()
    }
}
