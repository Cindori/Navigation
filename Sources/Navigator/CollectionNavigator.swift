//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-08.
//

import Foundation

public final class CollectionNavigator: Navigator {

    public func setRoutes(_ newRoutes: [AnyHashable]) {
        routes = newRoutes
    }

    public func insert(_ route: AnyHashable, at index: Int) {
        guard index <= routes.count else { return }
        routes.insert(route, at: index)
    }

    public func append(_ route: AnyHashable) {
        routes.append(route)
    }
    
    public func replace(at index: Int, with newRoute: AnyHashable) {
        guard routes.indices.contains(index) else { return }
        routes[index] = newRoute
    }

    public func remove(at index: Int) {
        guard routes.indices.contains(index) else { return }
        routes.remove(at: index)
    }

    public func remove(_ route: AnyHashable) {
        routes.removeAll { $0 == route }
    }

    public func move(from sourceIndex: Int, to destinationIndex: Int) {
        guard routes.indices.contains(sourceIndex),
              destinationIndex <= routes.count else { return }
        let route = routes.remove(at: sourceIndex)
        routes.insert(route, at: destinationIndex)
    }

    public func clear() {
        routes.removeAll()
    }
}
