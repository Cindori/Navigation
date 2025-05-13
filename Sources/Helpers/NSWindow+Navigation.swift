//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-10.
//

import AppKit

@MainActor private var ToolbarAssociationKey: UInt8 = 0

public extension NSWindow {
    var customToolbar: Toolbar? {
        get {
            (objc_getAssociatedObject(self, &ToolbarAssociationKey) as? WeakObjectContainer<Toolbar>)?.object
        }
        set {
            if let newValue {
                objc_setAssociatedObject(
                    self,
                    &ToolbarAssociationKey,
                    WeakObjectContainer(with: newValue),
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            } else {
                objc_setAssociatedObject(self, &ToolbarAssociationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}
