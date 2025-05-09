//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-08.
//

import Foundation

@MainActor
public final class NavigationCoordinator {
    public let navigator: StackNavigator
    public let router = NavigationRouter()
    public let controller: NavigationController
    
    public init(initialRoutes: [AnyHashable] = [], configure: (NavigationRouter) -> Void) {
        navigator = .init(initialRoutes: initialRoutes)
        configure(router)
        controller = NavigationController(navigator: navigator, router: router)
    }
    
    public func push(_ route: AnyHashable) {
        navigator.push(route)
    }
    
    public func pop() {
        navigator.pop()
    }
}
