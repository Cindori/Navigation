//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-09.
//

import AppKit

public class ToolbarWindow: NSWindow {

    private let toolbarView: Toolbar

    public override init(contentRect: NSRect,
                         styleMask style: NSWindow.StyleMask,
                         backing backingStoreType: NSWindow.BackingStoreType,
                         defer flag: Bool) {
        self.toolbarView = Toolbar()
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        commonInit()
    }

    private func commonInit() {
        styleMask.insert(.fullSizeContentView)

        let customToolbar = NSToolbar(identifier: .init("AppWindowToolbar"))
        customToolbar.showsBaselineSeparator = false
        toolbar = customToolbar
        toolbarStyle = .unified
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // ✅ Store it on the window for later access
        self.customToolbar = toolbarView

        installCustomToolbarView()
    }

    private func installCustomToolbarView() {
        guard
            let container = contentView?
                .superview?
                .subviews
                .first(where: { NSStringFromClass(type(of: $0)).contains("NSTitlebarContainerView") }),
            let titlebarView = container
                .subviews
                .first(where: { NSStringFromClass(type(of: $0)).contains("NSTitlebarView") })
        else {
            return
        }

        let hostView = toolbarView.view
        hostView.translatesAutoresizingMaskIntoConstraints = false

        titlebarView.addSubview(hostView, positioned: .below, relativeTo: nil)

        NSLayoutConstraint.activate([
            hostView.topAnchor.constraint(equalTo: titlebarView.topAnchor),
            hostView.leadingAnchor.constraint(equalTo: titlebarView.leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: titlebarView.trailingAnchor),
            hostView.bottomAnchor.constraint(equalTo: titlebarView.bottomAnchor)
        ])
    }
}
