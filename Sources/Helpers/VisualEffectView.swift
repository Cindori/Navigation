//
//  File.swift
//  Navigation
//
//  Created by Oskar Groth on 2025-05-13.
//

import SwiftUI

public struct VisualEffectView: View {
    private var material: NSVisualEffectView.Material
    private var blendingMode: NSVisualEffectView.BlendingMode
    private var state: NSVisualEffectView.State
    private var emphasized: Bool
    
    public init(
        material: NSVisualEffectView.Material = .headerView,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .followsWindowActiveState,
        emphasized: Bool = false
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.emphasized = emphasized
    }
    
    public var body: some View {
        Representable(
            material: material,
            blendingMode: blendingMode,
            state: state,
            emphasized: emphasized
        ).accessibility(hidden: true)
    }
}

public extension NSVisualEffectView.Material {
    static let hudControlsBackground: NSVisualEffectView.Material = .init(rawValue: 25)!
    static let bezelBackground: NSVisualEffectView.Material = .init(rawValue: 26)!
}

// MARK: - Representable
extension VisualEffectView {
    struct Representable: NSViewRepresentable {
        var material: NSVisualEffectView.Material
        var blendingMode: NSVisualEffectView.BlendingMode
        var state: NSVisualEffectView.State
        var emphasized: Bool
        
        func makeNSView(context: Context) -> NSVisualEffectView {
            context.coordinator.visualEffectView
        }
        
        func updateNSView(_ view: NSVisualEffectView, context: Context) {
            context.coordinator.update(material: material)
            context.coordinator.update(blendingMode: blendingMode)
            context.coordinator.update(state: state)
            context.coordinator.update(emphasized: emphasized)
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator()
        }
        
    }

    @MainActor class Coordinator {
        let visualEffectView = NSVisualEffectView()
        
        init() {
            visualEffectView.blendingMode = .withinWindow
        }
        
        func update(material: NSVisualEffectView.Material) {
            visualEffectView.material = material
        }
        
        func update(blendingMode: NSVisualEffectView.BlendingMode) {
            visualEffectView.blendingMode = blendingMode
        }
        
        func update(state: NSVisualEffectView.State) {
            visualEffectView.state = state
        }
        
        func update(emphasized: Bool) {
            visualEffectView.isEmphasized = emphasized
        }
    }
}
