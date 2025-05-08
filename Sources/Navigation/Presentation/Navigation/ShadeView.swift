//
//  ShadeView.swift
//  Backdrop
//
//  Created by Oskar Groth on 2024-11-26.
//  Copyright © 2024 Cindori AB. All rights reserved.
//

import AppKit
public extension NSView {
    
    private static let ShadeViewName = "ShadeView"
    
    func installShadeView(color: NSColor) -> NSView {
        let shadeView = NSView(frame: bounds)
        shadeView.wantsLayer = true
        shadeView.layer?.backgroundColor = color.cgColor
        shadeView.identifier = .init(NSView.ShadeViewName)
        addSubview(shadeView)
        shadeView.translatesAutoresizingMaskIntoConstraints = false
        shadeView.activateConstraints(.fillSuperview)
        return shadeView
    }
    
}
