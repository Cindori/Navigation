//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-13.
//

import SwiftUI
import AppKit
 
/// Wraps a specific NSViewController instance for use in SwiftUI.
public struct ViewControllerWrapper<VC: NSViewController>: NSViewControllerRepresentable {

    public let viewController: VC
    public let fill: Bool

    public init(_ viewController: VC, fill: Bool = true) {
        self.viewController = viewController
        self.fill = fill
    }

    public func makeNSViewController(context: Context) -> VC {
        if fill {
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            // Use more balanced priorities - too low can cause layout issues
            viewController.view.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
            viewController.view.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
            // Keep compression resistance higher to prevent collapsing
            viewController.view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            viewController.view.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        }

        return viewController
    }

    public func updateNSViewController(_ nsViewController: VC, context: Context) {
        // no-op by default
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, nsViewController: VC, context: Context) -> CGSize? {
        if fill {
             return proposal.replacingUnspecifiedDimensions(by: nsViewController.preferredContentSize)
         } else {
             return nsViewController.preferredContentSize
         }
    }
}
