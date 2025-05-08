//
//  ModalController.swift
//  TestApp
//
//  Created by Oskar Groth on 2025-05-08.
//

import AppKit
import Combine

/// Drives “present as sheet” from a ModalNavigator ↔ SheetRouter combo.
@MainActor
final class ModalController {
    private weak var host: NSViewController?
    private let navigator: QueueNavigator
    private let router:   NavigationRouter
    private var cancellable: AnyCancellable?
    private var presentedVC: NSViewController?
    
    /// - Parameters:
    ///   - host:      the view controller you’ll call `presentAsSheet(_:)` on
    ///   - navigator: your FIFO-queue navigator (no-ops removed)
    ///   - router:    the same route→VC factory you use for your nav stack
    init(
        host: NSViewController,
        navigator: QueueNavigator,
        router:   NavigationRouter
    ) {
        self.host      = host
        self.navigator = navigator
        self.router    = router
        
        // Observe only the first route in the queue
        cancellable = navigator.$routes
            .map { $0.first }
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] route in
                self?.transition(to: route)
            }
    }
    
    private func transition(to route: AnyHashable?) {
        guard let host = host else { return }
        
        // 1) Dismiss any currently shown sheet
        if let vc = presentedVC {
            host.dismiss(vc)
            presentedVC = nil
        }
        
        // 2) If there’s a new route, build & present its sheet
//        guard let route = route else { return }
//        let vc = router.viewController(for: route, on: /* your nav stack */ .init())
//        vc.loadViewIfNeeded()
//        host.presentAsSheet(vc)
//        presentedVC = vc
    }
}
