//
//  ModalController.swift
//  TestApp
//
//  Created by Oskar Groth on 2025-05-08.
//

import AppKit
import Combine

@MainActor
public final class SheetController {
    private weak var host: NSViewController?
    private let navigator: QueueNavigator
    private let router: NavigationRouter
    private var cancellables = Set<AnyCancellable>()
    private var presentedVC: NSViewController?

    private var pendingRoute: AnyHashable?

    public init(
        host: NSViewController,
        navigator: QueueNavigator,
        router: NavigationRouter
    ) {
        self.host = host
        self.navigator = navigator
        self.router = router
        registerLogEmoji("📃")
        logDebug("Initialized")

        observeHostWindowChanges(for: host)

        navigator.$routes
            .map(\.first)
            .removeDuplicates(by: ==)
            .sink { [weak self] route in
                Task { @MainActor in
                    self?.handleRouteChange(route)
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSWindow.didEndSheetNotification)
            .sink { [weak self] notification in
                guard
                    let host = self?.host,
                    notification.object as? NSWindow == host.view.window
                else { return }

                logDebug("Received didEndSheetNotification")
                self?.handleSheetDismissal()
            }
            .store(in: &cancellables)
    }

    private func observeHostWindowChanges(for host: NSViewController) {
        host.view.publisher(for: \.window)
            .removeDuplicates()
            .sink { [weak self] window in
                guard window != nil else { return }
                logDebug("host.view.window became non-nil")
                self?.tryPresentPendingRoute()
            }
            .store(in: &cancellables)
    }

    private func handleRouteChange(_ route: AnyHashable?) {
        logDebug("Route changed: \(String(describing: route))")
        if route == nil {
            dismissCurrentSheet()
        } else {
            present(route!)
        }
    }

    private func present(_ route: AnyHashable) {
        guard let host = host else {
            logDebug("No host controller")
            return
        }

        guard let window = host.view.window else {
            logDebug("Host view has no window — deferring route \(route)")
            pendingRoute = route
            return
        }

        logDebug("Presenting sheet for route: \(route)")
        pendingRoute = nil

        dismissCurrentSheet()

        let vc = router.viewController(for: route)

        if #available(macOS 14.0, *) {
            vc.loadViewIfNeeded()
        } else {
            _ = vc.view
        }

        vc.view.layoutSubtreeIfNeeded()
        let fitting = vc.view.fittingSize
        let defaultSize = NSSize(width: 400, height: 300)
        vc.preferredContentSize = (fitting.width > 0 && fitting.height > 0) ? fitting : defaultSize

        logDebug("Preferred content size: \(vc.preferredContentSize)")

        if !window.isVisible || !window.isKeyWindow {
            logDebug("host.window is not key or visible — calling makeKeyAndOrderFront")
            window.makeKeyAndOrderFront(nil)
        }

        host.presentAsSheet(vc)
        logDebug("Sheet presentation triggered")
        presentedVC = vc
    }

    private func tryPresentPendingRoute() {
        guard let route = pendingRoute else {
            logDebug("No pending route to present")
            return
        }
        logDebug("Trying to present deferred route: \(route)")
        present(route)
    }

    private func dismissCurrentSheet() {
        guard let host = host else { return }

        if let vc = presentedVC {
            logDebug("Dismissing current sheet")
            host.dismiss(vc)
            presentedVC = nil
        }
    }

    private func handleSheetDismissal() {
        guard let hostWindow = host?.view.window,
              hostWindow.sheets.isEmpty else {
            logDebug("Sheet dismissal skipped — sheets still active")
            return
        }
        logDebug("Sheet dismissed — dequeueing next")
        presentedVC = nil
        _ = navigator.dequeue()
    }
}
