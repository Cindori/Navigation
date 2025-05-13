//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-10.
//

import Foundation
import Combine

public final class RootStackNavigator: Navigator {

    public var currentPublisher: AnyPublisher<AnyHashable, Never> {
        $routes
            .compactMap { $0.last }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    public convenience init(root: AnyHashable) {
        self.init(initialRoutes: [root])
    }
    
    public override init(initialRoutes: [AnyHashable] = []) {
        super.init(initialRoutes: initialRoutes)
    }

    public func push(_ route: AnyHashable) {
        routes.append(route)
    }

    public func pop() {
        guard routes.count > 1 else { return }
        routes.removeLast()
    }

    public func pop(to route: AnyHashable) {
        guard let index = routes.lastIndex(of: route), index < routes.count - 1 else { return }
        routes = Array(routes.prefix(through: index))
    }

    public func popToRoot() {
        routes = [routes.first!]
    }

    public func setStack(_ newStack: [AnyHashable]) {
        guard !newStack.isEmpty else {
            assertionFailure("RootStackNavigator must have at least one route.")
            return
        }
        routes = newStack
    }

    public func setRoot(_ newRoot: AnyHashable) {
        if routes.isEmpty {
            routes = [newRoot]
        } else {
            routes[0] = newRoot
        }
    }

    public var root: AnyHashable {
        routes[0]
    }
}
