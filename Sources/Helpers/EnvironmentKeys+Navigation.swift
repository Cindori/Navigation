//
//  EnvironmentKeys.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-10.
//

import SwiftUI

// MARK: NavigationRouter

private struct NavigationRouterKey: EnvironmentKey {
    static let defaultValue: NavigationRouter? = nil
}

public extension EnvironmentValues {
    var navigationRouter: NavigationRouter? {
        get { self[NavigationRouterKey.self] }
        set { self[NavigationRouterKey.self] = newValue }
    }
}

// MARK: SplitView

private struct SplitViewCoordinatorKey: EnvironmentKey {
    static let defaultValue: SplitViewCoordinator? = nil
}

public extension EnvironmentValues {
    var splitViewCoordinator: SplitViewCoordinator? {
        get { self[SplitViewCoordinatorKey.self] }
        set { self[SplitViewCoordinatorKey.self] = newValue }
    }
}


// MARK: NavigationItem

private struct NavigationItemKey: EnvironmentKey {
    static let defaultValue: NavigationItem? = nil
}

public extension EnvironmentValues {
    var navigationItem: NavigationItem? {
        get { self[NavigationItemKey.self] }
        set { self[NavigationItemKey.self] = newValue }
    }
}

// MARK: Toolbar

private struct ToolbarContentSetterKey: EnvironmentKey {
    static let defaultValue: ((() -> AnyView)?) -> Void = { _ in }
}

public extension EnvironmentValues {
    var setToolbarContent: ((() -> AnyView)?) -> Void {
        get { self[ToolbarContentSetterKey.self] }
        set { self[ToolbarContentSetterKey.self] = newValue }
    }
}

struct ToolbarContentModifier<ToolbarView: View>: ViewModifier {
    @Environment(\.setToolbarContent) private var setToolbarContent

    let builder: () -> ToolbarView

    func body(content: Content) -> some View {
        content
            .onAppear {
                setToolbarContent({ AnyView(builder()) })
            }
//            .onDisappear {
//                setToolbarContent(nil)
//            }
    }
}

extension View {
    func toolbarContent<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
        self.modifier(ToolbarContentModifier(builder: content))
    }
}
