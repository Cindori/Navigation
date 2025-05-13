//
//  ContentView.swift
//  TestApp
//
//  Created by Oskar Groth on 2024-09-11.
//

import SwiftUI
import AppKit
import Navigation

enum Demo: String, CaseIterable, Identifiable {
    case navigation
    case sheet
    case splitView
    case child
    var id: String { rawValue }
}

enum DemoPane: Hashable {
    case sidebar
    case content(Demo)

    enum Sidebar: Hashable {
        case options
    }
}

struct AppView: View {
    @State private var demo = Demo.navigation
    @State var coordinator = SplitViewCoordinator(initialRoutes: [
        DemoPane.sidebar,
        DemoPane.content(.navigation)
    ])

    var body: some View {
        SplitNavigationView(coordinator: coordinator) { router in
            router.navigationDestination(for: DemoPane.self) { pane in
                switch pane {
                    case .sidebar:
                        SidebarPane(demo: $demo)
                    case .content(.navigation):
                        ViewControllerWrapper(StackDemoViewController())
                    case .content(.sheet):
                        ViewControllerWrapper(DemoSheetViewController())
                    case .content(.splitView):
                        DemoSplitView()
                    case .content(.child):
                        ChildView()
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onChange(of: demo, initial: true) {
            coordinator.replace(at: 1, with: DemoPane.content(demo))
        }
        .environment(\.splitViewCoordinator, coordinator)
        .environment(\.navigationRouter, coordinator.router)
        .environment(\.demoSelection, $demo)
    }
}

struct ChildView: View {
    @Environment(\.demoSelection) var demo
    
    var body: some View {
        ZStack {
            Button("Go to Navigation") {
                demo?.wrappedValue = .navigation
            }
        }
    }
}



struct SidebarPane: View {
    @Binding var demo: Demo
    
    var body: some View {
        List(Demo.allCases, selection: $demo) { demo in
            Text(demo.rawValue.capitalized)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    self.demo == demo ? Color.white.opacity(0.15) : Color.clear
                )
                .cornerRadius(6)
                .contentShape(Rectangle())
                .onTapGesture {
                    self.demo = demo
                }
        }
        .listStyle(.sidebar)
    }
}
