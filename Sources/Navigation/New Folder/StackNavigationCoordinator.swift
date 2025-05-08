//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-08.
//

import Foundation

@MainActor
final class StackNavigationCoordinator {
    let navigator = StackNavigator()
    let router    = StackNavigationRouter()
    let controller: StackNavigationController
    
    init(initial: AnyHashable? = nil,
         configure: (StackNavigationRouter) -> Void) {
        configure(router)
        controller = StackNavigationController(
            navigator: navigator,
            router: router,
            initialRoute: initial
        )
    }
    
    func push(_ route: AnyHashable) {
        navigator.push(route)
    }
    func pop() {
        navigator.pop()
    }
}
