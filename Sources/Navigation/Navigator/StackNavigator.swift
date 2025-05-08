//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-08.
//

import Foundation

/// A Navigator you drive like a LIFO stack.
public final class StackNavigator: Navigator {
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
