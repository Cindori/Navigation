//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-09.
//

import AppKit

public extension NSViewController {
    
    /// Convenience function for embedding a view controller that will completely fill the view.
    func embed(child: NSViewController, in hostView: NSView? = nil, positioned place: NSWindow.OrderingMode = .above, relativeTo otherView: NSView? = nil) {
        guard child.parent != self else { return }
        addChild(child)
        let targetView = hostView ?? view
        targetView.addSubview(child.view, positioned: place, relativeTo: otherView)
        child.view.activateConstraints(.fillSuperview)
    }
    
    /// Convenience function for removing an embedded view controller.
    func dislodgeFromParent() {
        guard parent != nil else { return }
        view.removeFromSuperview()
        removeFromParent()
    }
    
}
