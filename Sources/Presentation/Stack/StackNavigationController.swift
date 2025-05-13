//
//  StackNavigationController.swift
//  SenseiUI
//
//  Created by Oskar Groth on 2019-08-30.
//  Copyright © 2019 Oskar Groth. All rights reserved.
//

import AppKit
import SwiftUI
import Combine

final class ObservableWindowView: NSView {
    let windowDidChange = PassthroughSubject<NSWindow?, Never>()
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        windowDidChange.send(self.window)
    }
}

@MainActor
open class StackNavigationController: NSViewController {
    static let animationDuration: CFTimeInterval = 0.35
    
    // MARK: – Dependencies
    public let navigator: RootStackNavigator
    public let router: NavigationRouter
    
    // MARK: – State
    private let navigationItem = NavigationItem()
    private var cancellables = Set<AnyCancellable>()
    private var wrappers: [StackWrapperViewController] = []
    private var vcToRouteHashMap: [NSViewController: AnyHashable] = [:]
    
    /// Bumps on every sync so only the latest animation’s completion does cleanup
    private var animationID: Int = 0
    
    // MARK: – Init
    public init(navigator: RootStackNavigator, router: NavigationRouter) {
        self.navigator = navigator
        self.router    = router
        super.init(nibName: nil, bundle: nil)
        
        // Observe route changes
        navigator.$routes
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoutes in
                self?.sync(with: newRoutes)
            }
            .store(in: &cancellables)
        (view as? ObservableWindowView)?.windowDidChange
            .compactMap { $0 }
            .sink { [weak self] window in
                DispatchQueue.main.async {
                    // Set up navigation item if we have a window
                    self?.setupNavigationItem()
                }
            }
            .store(in: &cancellables)
        // Seed initial stack
        sync(with: navigator.routes)
    }
    
    required public init?(coder: NSCoder) { fatalError() }
    
    // MARK: – View Setup
    public override func loadView() {
        view = ObservableWindowView()
        view.wantsLayer = true
        view.clipsToBounds = true
    }
    
    func setupNavigationItem() {
        view.window?.customToolbar?.setLeading {
            NavigationItemView(item: self.navigationItem)
        }
    }
    private func updateNavigationItem(for wrapper: StackWrapperViewController?, index: Int?) {
        guard let wrapper else {
            navigationItem.title = nil
            navigationItem.backAction = nil
            navigationItem.index = nil
            return
        }
        let oldIndex = navigationItem.index
        let isPush = (oldIndex ?? -1) < (index ?? 0)
        navigationItem.transitionDirection = isPush ? .trailing : .leading
        navigationItem.title = wrapper.viewController.title
        navigationItem.index = index
        navigationItem.backAction = (wrappers.count > 1) ? { [weak self] in self?.navigator.pop() } : nil
        
    }
    
    // MARK: – Sync & Animation
    
    /// Builds (or re-uses) a wrapper VC for each route in order.
    private func buildWrappers(for routes: [AnyHashable]) -> [StackWrapperViewController] {
        let routeToExisting = Dictionary(
            wrappers.map { (vcToRouteHashMap[$0.viewController]!, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return routes.map { route in
            if let w = routeToExisting[route] {
                return w
            }
            let vc = router.viewController(for: route)
            let wrapper = StackWrapperViewController(viewController: vc, navigationController: self)
            vcToRouteHashMap[vc] = route
            return wrapper
        }
    }
    
    /// Core sync: immediately updates `wrappers` & embeds the new top,
    /// then animates from whatever the current presentation transform is,
    /// and in the final CATransaction completion removes all non-top views
    /// and dislodges any fully-popped VCs.
    private func sync(with routes: [AnyHashable]) {
        animationID += 1
        let thisAnimation = animationID
        
        let oldWrappers = wrappers
        let newWrappers = reconcileStack(with: routes)
        
        let isPush = newWrappers.count > oldWrappers.count
        let from = oldWrappers.last
        let to = newWrappers.last
        
        if let to = to {
            prepareTransition(from: from, to: to, isPush: isPush)
            
            if let from = from {
                animateTransition(from: from, to: to, isPush: isPush, animationID: thisAnimation)
            } else {
                finalizeTransition(toKeep: to, animationID: thisAnimation)
            }
        } else {
            finalizeTransition(toKeep: nil, animationID: thisAnimation)
        }
        updateNavigationItem(for: to, index: newWrappers.count - 1)
    }
    
    private func reconcileStack(with routes: [AnyHashable]) -> [StackWrapperViewController] {
        // Pair each existing wrapper with its route and position
        let existingIndexedRoutes = wrappers.enumerated().map { index, wrapper in
            (index, vcToRouteHashMap[wrapper.viewController]!, wrapper)
        }
        
        var newWrappers: [StackWrapperViewController] = []
        var newMap: [NSViewController: AnyHashable] = [:]
        
        for (index, route) in routes.enumerated() {
            if let match = existingIndexedRoutes.first(where: { $0.0 == index && $0.1 == route }) {
                let wrapper = match.2
                newWrappers.append(wrapper)
                newMap[wrapper.viewController] = route
            } else {
                let vc = router.viewController(for: route)
                let wrapper = StackWrapperViewController(viewController: vc, navigationController: self)
                newWrappers.append(wrapper)
                newMap[vc] = route
            }
        }
        
        // Dislodge any wrapper not in the new stack
        let removed = wrappers.filter { !newWrappers.contains($0) }
        removed.forEach { vcToRouteHashMap.removeValue(forKey: $0.viewController) }
        
        wrappers = newWrappers
        vcToRouteHashMap = newMap
        return newWrappers
    }
    
    private func animateTransition(
        from fromWrap: StackWrapperViewController,
        to toWrap: StackWrapperViewController,
        isPush: Bool,
        animationID: Int
    ) {
        fromWrap.view.layer?.removeAllAnimations()
        toWrap.view.layer?.removeAllAnimations()
        
        if isPush {
            fromWrap.addShadeAnimation(active: true)
        } else {
            toWrap.addShadeAnimation(active: false)
        }
        
        let w = view.bounds.width
        let fromStart = fromWrap.view.layer?.presentation()?.transform ?? fromWrap.view.layer?.transform ?? CATransform3DIdentity
        let fromEnd = isPush ? CATransform3DMakeTranslation(-w/4, 0, 0) : CATransform3DMakeTranslation(w, 0, 0)
        
        let toStart = toWrap.view.layer?.presentation()?.transform ?? toWrap.view.layer?.transform ?? CATransform3DIdentity
        let toEnd = CATransform3DIdentity
        
        let fromAnim = slideAnimation(from: fromStart, to: fromEnd)
        let toAnim   = slideAnimation(from: toStart, to: toEnd)
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            guard let self, animationID == self.animationID else { return }
            
            fromWrap.removeShade()
            toWrap.removeShade()
            
            toWrap.view.layer?.removeAllAnimations()
            toWrap.view.layer?.transform = CATransform3DIdentity
            
            for case let child as StackWrapperViewController in self.children {
                if child !== toWrap {
                    child.dislodgeFromParent()
                }
            }
        }
        
        fromWrap.view.layer?.add(fromAnim, forKey: "fromSlide")
        toWrap.view.layer?.add(toAnim,   forKey: "toSlide")
        
        CATransaction.commit()
    }
    
    private func prepareTransition(from fromWrap: StackWrapperViewController?, to toWrap: StackWrapperViewController, isPush: Bool) {
        toWrap.view.layer?.removeAllAnimations()
        
        let w = view.bounds.width
        let startX: CGFloat = isPush ? w : -w / 4
        let startTransform = CATransform3DMakeTranslation(startX, 0, 0)
        
        embed(
            child: toWrap,
            in: view,
            positioned: isPush ? .above : .below,
            relativeTo: isPush ? nil : fromWrap?.view
        )
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        toWrap.view.layer?.transform = startTransform
        CATransaction.commit()
    }
    
    private func finalizeTransition(toKeep: StackWrapperViewController?, animationID: Int) {
        guard animationID == self.animationID else { return }
        
        for case let child as StackWrapperViewController in self.children {
            if child !== toKeep {
                child.dislodgeFromParent()
            }
        }
        
        toKeep?.view.layer?.removeAllAnimations()
        toKeep?.view.layer?.transform = CATransform3DIdentity
        toKeep?.removeShade()
    }
    
    // MARK: - Animations
    
    private func slideAnimation(from: CATransform3D, to: CATransform3D, timing: CAMediaTimingFunctionName = .easeOut) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
        animation.fromValue = NSValue(caTransform3D: from)
        animation.toValue = NSValue(caTransform3D: to)
        animation.duration = Self.animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: timing)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }
    
    private func fadeAnimation(to: Float, timing: CAMediaTimingFunctionName = .easeOut) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        animation.toValue = to
        animation.duration = Self.animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: timing)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }
}

typealias AnimationBlock = (_ fromView: NSView?, _ toView: NSView?) -> (fromViewAnimations: [CAAnimation], toViewAnimations: [CAAnimation])
