//
//  NavigationRouter.swift
//  TestApp
//
//  Created by Oskar Groth on 2025-05-08.
//

import AppKit

// MARK: - Navigation Router
/// Factory registry mapping route types to view controllers
@MainActor
public final class NavigationRouter {
    private typealias Factory = (AnyHashable) -> NSViewController
    private var factories: [ObjectIdentifier: Factory] = [:]
    
    @discardableResult
    public func navigationDestination<R: Hashable>(
        for routeType: R.Type,
        _ build: @escaping (R) -> NSViewController
    ) -> Self {
        let key = ObjectIdentifier(routeType)
        factories[key] = { anyRoute in
            guard let route = anyRoute.base as? R else {
                fatalError("Router expected route of type \(R.self)")
            }
            return build(route)
        }
        return self
    }
    
    @MainActor
    public func viewController(for anyRoute: AnyHashable) -> NSViewController {
        let key = ObjectIdentifier(type(of: anyRoute.base))
        guard let factory = factories[key] else {
            fatalError("No destination registered for route type \(type(of: anyRoute.base))")
        }
        return factory(anyRoute)
    }
}
