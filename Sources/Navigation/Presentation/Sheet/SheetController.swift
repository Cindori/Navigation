//
//  ModalController.swift
//  TestApp
//
//  Created by Oskar Groth on 2025-05-08.
//

import AppKit
import Combine

@MainActor
public class SheetController {
    private weak var host: NSViewController?
    private let navigator: QueueNavigator
    private let router: NavigationRouter
    private var cancellables = Set<AnyCancellable>()
    private var presentedVC: NSViewController?

    /// - Parameters:
    ///   - host:      the view controller you’ll call `presentAsSheet(_:)` on
    ///   - navigator: your FIFO-queue navigator (no-ops removed)
    ///   - router:    the same route→VC factory you use for your nav stack
    init(host: NSViewController, navigator: QueueNavigator, router: NavigationRouter) {
        self.host      = host
        self.navigator = navigator
        self.router    = router
        
        // Observe only the first route in the queue
        navigator.$routes
            .map { $0.first }
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] route in
                Task { @MainActor in
                    self?.transition(to: route)
                }
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSWindow.didEndSheetNotification)
            .sink { [weak self] notification in
                guard notification.object as? NSWindow == self?.host?.view.window else { return }
                self?.windowWidEndSheet()
            }
            .store(in: &cancellables)
    }
    
    private func windowWidEndSheet() {
        guard let hostWindow = host?.view.window, hostWindow.sheets.isEmpty else {
            return
        }
        // Only dequeue if the navigator still thinks our presentedRoute is front–
        // most. Then clear our state so we don’t dequeue again.
        presentedVC = nil
        _ = navigator.dequeue()
    }
    
    /// Handles dismissing the current sheet (if any) and presenting the next one.
    private func transition(to route: AnyHashable?) {
        guard let host = host else { return }

        // 1) Dismiss existing sheet
        if let vc = presentedVC {
            host.dismiss(vc)
            presentedVC = nil
        }

        // 2) Present new sheet if available
        guard let route = route else { return }
        let vc = router.viewController(for: route)

        // Force view load for correct sizing and outlet initialization
        if #available(macOS 14.0, *) {
            vc.loadViewIfNeeded()
        } else {
            _ = vc.view
        }

        // Layout now so fittingSize is valid
        vc.view.layoutSubtreeIfNeeded()

        // 3) Present as sheet
        host.presentAsSheet(vc)

        // 4) Adjust sheet window size based on content (fall back to a default size)
        if let sheetWindow = vc.view.window {
            let fitting = vc.view.fittingSize
            if fitting.width > 0 && fitting.height > 0 {
                sheetWindow.setContentSize(fitting)
            } else {
                sheetWindow.setContentSize(NSSize(width: 400, height: 300))
            }
        }

        presentedVC = vc
    }
}
