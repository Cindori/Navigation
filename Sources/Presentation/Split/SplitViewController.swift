//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-11.
//

import AppKit
import Combine
import SwiftUI

@MainActor
public final class SplitViewController: NSSplitViewController {

    private let navigator: CollectionNavigator
    private let router: NavigationRouter
    private var cancellable: AnyCancellable?
    private var currentRoutes: [AnyHashable] = []
    private var trackedItemIndex: Int? = 1
    private var windowResizeCancellable: AnyCancellable?
    private var isInLayout = false
    private var routeToItem: [AnyHashable: NSSplitViewItem] = [:]
    
    public init(navigator: CollectionNavigator, router: NavigationRouter) {
        self.navigator = navigator
        self.router = router
        super.init(nibName: nil, bundle: nil)
        self.splitView.isVertical = true

//        updateSplitItems(for: navigator.routes)

        cancellable = navigator.$routes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] routes in
                self?.updateSplitItems(for: routes)
            }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func updateSplitItems(for newRoutes: [AnyHashable]) {
        guard newRoutes != currentRoutes else { return }
        currentRoutes = newRoutes

        // Step 1: remove items no longer present
        let newRouteSet = Set(newRoutes)
        let removedRoutes = routeToItem.keys.filter { !newRouteSet.contains($0) }

        for route in removedRoutes {
            if let item = routeToItem[route] {
                removeSplitViewItem(item)
                routeToItem.removeValue(forKey: route)
            }
        }

        // Step 2: build split view in order
        for (index, route) in newRoutes.enumerated() {
            if let existingItem = routeToItem[route] {
                // Already exists, ensure it’s in the correct position
                if splitViewItems.indices.contains(index),
                   splitViewItems[index] !== existingItem {
                    removeSplitViewItem(existingItem)
                    insertSplitViewItem(existingItem, at: index)
                }
                continue
            }

            // Not yet created — instantiate
            let viewController = router.viewController(for: route)
            if let hostingController = viewController as? NSHostingController<AnyView> {
                // conform to the layout constraints of the container
                hostingController.sizingOptions = []
            }
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
            viewController.view.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
            viewController.view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            viewController.view.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
            
            let item = NSSplitViewItem(viewController: viewController)
            item.canCollapse = false
            item.isCollapsed = false
            item.minimumThickness = 200
            item.maximumThickness = index == 0 ? 200 : -1
//            item.maximumThickness = 300
            insertSplitViewItem(item, at: index)
            routeToItem[route] = item
        }
    }
    
    override public func viewWillLayout() {
        super.viewWillLayout()
        isInLayout = true
    }

    override public func viewDidLayout() {
        super.viewDidLayout()
        self.isInLayout = false
    }
    
    override public func viewDidAppear() {
        super.viewDidAppear()
        updateToolbarTracking()
    }
    
    override public func splitViewDidResizeSubviews(_ notification: Notification) {
        if !isInLayout || view.window?.inLiveResize ?? false {
            // Fix some issues with toolbar jitter
            splitView.needsLayout = true
//            splitView.layoutSubtreeIfNeeded() may be needed for mouse
        }
        updateToolbarTracking()
    }
    
    private func updateToolbarTracking() {
        guard let toolbar = view.window?.customToolbar,
              let index = trackedItemIndex,
              splitView.subviews.indices.contains(index)
        else { return }
        let x = splitView.subviews[index].frame.origin.x
        toolbar.setLeading(x)
    }
}
