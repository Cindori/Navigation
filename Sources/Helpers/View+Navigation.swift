//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-12.
//

import SwiftUI

struct NavigationDestinationModifier<R: Hashable>: ViewModifier {
    @Environment(\.navigationRouter) private var router
    let routeType: R.Type
    let builder: (R) -> AnyView

    func body(content: Content) -> some View {
        content
            .onAppear {
                router?.navigationDestination(for: routeType, builder)
            }
    }
}

public extension View {
    func registerRoute<R: Hashable>(
        for routeType: R.Type,
        @ViewBuilder _ builder: @escaping (R) -> some View
    ) -> some View {
        self.modifier(
            NavigationDestinationModifier(
                routeType: routeType,
                builder: { route in AnyView(builder(route)) }
            )
        )
    }
}

