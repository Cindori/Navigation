//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-08.
//

import Foundation

@MainActor
public final class StackNavigationCoordinator {
    public let navigator: RootStackNavigator
    public let router = NavigationRouter()
    public let controller: StackNavigationController
    
    public init(initialRoutes: [AnyHashable] = [], configure: (NavigationRouter) -> Void) {
        navigator = .init(initialRoutes: initialRoutes)
        configure(router)
        controller = StackNavigationController(navigator: navigator, router: router)
    }
    
    public func push(_ route: AnyHashable) {
        navigator.push(route)
    }
    
    public func pop() {
        navigator.pop()
    }
    
    public func popRoot() {
        navigator.popToRoot()
    }
}
