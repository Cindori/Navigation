//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-12.
//

import SwiftUI

public struct SplitNavigationView: View {
    private let coordinator: SplitViewCoordinator
    private let registerRoutes: (NavigationRouter) -> Void

    public init(
        coordinator: SplitViewCoordinator,
        registerRoutes: @escaping (NavigationRouter) -> Void
    ) {
        self.coordinator = coordinator
        self.registerRoutes = registerRoutes
    }

    public var body: some View {
        ViewControllerWrapper(coordinator.controller)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onAppear {
                registerRoutes(coordinator.router)
            }
    }
}
