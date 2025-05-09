//
//  NavigationController.swift
//  SenseiUI
//
//  Created by Oskar Groth on 2019-08-30.
//  Copyright © 2019 Oskar Groth. All rights reserved.
//

import AppKit
import SwiftUI
import Combine

struct NavigationItem {
    var title: String? = nil
    var backAction: (() -> Void)? = nil
    
    init(title: String? = nil, backAction: (() -> Void)? = nil) {
        self.title = title
        self.backAction = backAction
    }
}

@MainActor
open class NavigationController: NSViewController {
    static let animationDuration: CFTimeInterval = 0.35

    // MARK: – Dependencies
    public let navigator: StackNavigator
    public let router: NavigationRouter

    // MARK: – State
    private var cancellables = Set<AnyCancellable>()
    private var wrappers: [NavigationWrapperViewController] = []
    private var vcToRouteHashMap: [NSViewController: AnyHashable] = [:]

    /// Bumps on every sync so only the latest animation’s completion does cleanup
    private var animationID: Int = 0

    // MARK: – Init
    public init(navigator: StackNavigator, router: NavigationRouter) {
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

        // Seed initial stack
        sync(with: navigator.routes)
    }

    required public init?(coder: NSCoder) { fatalError() }

    // MARK: – View Setup
    public override func loadView() {
        view = NSView(frame: .zero, usingConstraints: true, wantsLayer: true)
        view.clipsToBounds = true
    }

    // MARK: – Sync & Animation


    /// Builds (or re-uses) a wrapper VC for each route in order.
    private func buildWrappers(for routes: [AnyHashable]) -> [NavigationWrapperViewController] {
        let routeToExisting = Dictionary(
            wrappers.map { (vcToRouteHashMap[$0.viewController]!, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return routes.map { route in
            if let w = routeToExisting[route] {
                return w
            }
            let vc = router.viewController(for: route)
            let wrapper = NavigationWrapperViewController(viewController: vc, navigationController: self)
            vcToRouteHashMap[vc] = route
            return wrapper
        }
    }

    /// Core sync: immediately updates `wrappers` & embeds the new top,
    /// then animates from whatever the current presentation transform is,
    /// and in the final CATransaction completion removes all non-top views
    /// and dislodges any fully-popped VCs.
    private func sync(with routes: [AnyHashable]) {
        // 1) bump the token so only this animation’s completion runs cleanup
        animationID += 1
        let thisAnimation = animationID

        // 2) snapshot old stack
        let oldWrappers = wrappers

        // 3) build + replace with new desired stack
        let newWrappers = buildWrappers(for: routes)
        wrappers = newWrappers

        // 4) remove any fully‐popped routes from your hash map
        let fullyRemoved = oldWrappers.filter { old in
            !newWrappers.contains { $0 === old }
        }
        fullyRemoved.forEach { vcToRouteHashMap.removeValue(forKey: $0.viewController) }

        // 5) detect push vs pop
        let isPush   = newWrappers.count > oldWrappers.count
        let fromWrap = oldWrappers.last
        let toWrap   = newWrappers.last

        // 6) embed + prime the incoming wrapper
        if let toWrap = toWrap {
            // clear out any old animations so we start from a clean slate
            toWrap.view.layer?.removeAnimation(forKey: "fromSlide")
            toWrap.view.layer?.removeAnimation(forKey: "toSlide")
            toWrap.view.wantsLayer = true

            // embed it
            embed(
                child:      toWrap,
                in:         view,
                positioned: isPush ? .above : .below,
                relativeTo: isPush ? nil : fromWrap?.view
            )

            // immediately snap it to its start position
            let w = view.bounds.width
            let startX: CGFloat = isPush ?  w : -w/4
            let startTransform = CATransform3DMakeTranslation(startX, 0, 0)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            toWrap.view.layer?.transform = startTransform
            CATransaction.commit()
        }

        // 7) animate slide + shade + cleanup
        if let fromWrap = fromWrap, let toWrap = toWrap {
            // clear out any old animations on the outgoing view too
            fromWrap.view.layer?.removeAnimation(forKey: "fromSlide")
            fromWrap.view.layer?.removeAnimation(forKey: "toSlide")

            // shade the right wrapper
            if isPush {
                fromWrap.addShadeAnimation(active: true)
            } else {
                toWrap.addShadeAnimation(active: false)
            }

            let w = view.bounds.width

            // grab the real starting transform (presentation if mid‐anim, else model)
            let fromStart = fromWrap.view.layer?.presentation()?.transform
                            ?? fromWrap.view.layer?.transform
                            ?? CATransform3DIdentity
            let fromEnd   = isPush
                            ? CATransform3DMakeTranslation(-w/4, 0, 0)
                            : CATransform3DMakeTranslation( w,   0, 0)

            // we just primed toWrap’s model layer, so use that as start
            let toStart = toWrap.view.layer?.presentation()?.transform
                          ?? toWrap.view.layer?.transform
                          ?? CATransform3DIdentity
            let toEnd   = CATransform3DIdentity

            let fromAnim = slideAnimation(from: fromStart, to: fromEnd)
            let toAnim   = slideAnimation(from: toStart,   to: toEnd)

            // keep a reference for cleanup
            let keeper = toWrap

            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard
                    let self = self,
                    thisAnimation == self.animationID
                else { return }

                // ➊ remove the shade if we just popped
                fromWrap.removeShade()
                toWrap.removeShade()

                // ➋ snap the keeper’s model layer to identity and clear its animations
                keeper.view.layer?.removeAnimation(forKey: "fromSlide")
                keeper.view.layer?.removeAnimation(forKey: "toSlide")
                keeper.view.layer?.transform = CATransform3DIdentity

                // ➌ dislodge everything except the keeper
                for case let child as NavigationWrapperViewController in self.children {
                    if child !== keeper {
                        child.dislodgeFromParent()
                    }
                }
            }

            fromWrap.view.layer?.add(fromAnim, forKey: "fromSlide")
            toWrap.view.layer?.add(toAnim,   forKey: "toSlide")
            CATransaction.commit()
        }
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
