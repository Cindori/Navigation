//
//  DemoSplitView.swift
//  TestApp
//
//  Created by Oskar Groth on 2025-05-11.
//

import SwiftUI
import Navigation

struct DemoSplitView: View {
    @Environment(\.splitViewCoordinator) var coordinator

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Add Sidebar") {
                    coordinator?.insert("Sidebar", at: 0)
                }
                Button("Add Content") {
                    coordinator?.append("Content \(Int.random(in: 1...100))")
                }
                Button("Clear") {
                    coordinator?.clear()
                }
            }
        }
        .padding()
    }
}
