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
    static let animationDuration = 0.35

    // MARK: – Dependencies
    
    /// The source of truth for “what’s on the stack”
    public let navigator: Navigator
    
    /// Knows how to build a VC for each route
    public let router: NavigationRouter
    
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: – Internal Stack
    
    private var wrappers: [NavigationWrapperViewController] = []
    
    open var viewControllers: [NSViewController] {
        wrappers.compactMap { $0.viewController }
    }
    open var topViewController: NSViewController? {
        viewControllers.last
    }
    open var previousViewController: NSViewController? {
        viewControllers.dropLast().last
    }
    open weak var delegate: (any NavigationControllerDelegate)?
    
    // MARK: – Init
    
    /// Initialize with your navigator & router. Optionally push an initial route.
    public init(navigator: StackNavigator, router: NavigationRouter) {
        self.navigator = navigator
        self.router    = router
        super.init(nibName: nil, bundle: nil)
        
        // 1) Observe every change to the route array
        navigator.$routes
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoutes in
                self?.sync(with: newRoutes)
            }
            .store(in: &cancellables)
        
        // 2) If desired, seed with a first route
        sync(with: navigator.routes)
    }
    
    required public init?(coder: NSCoder) { fatalError() }
    
    
    // MARK: – View Lifecycle
    
    open override func loadView() {
        view = NSView(frame: .zero, usingConstraints: true, wantsLayer: true)
        view.clipsToBounds = true
    }
    
    
    // MARK: – Sync Logic
    
    /// Reconcile child VCs to match the navigator’s route stack immediately
    private func sync(with routes: [AnyHashable]) {
        // 1) POP any extra view controllers
        while viewControllers.count > routes.count {
            popViewController(animated: true)
        }
        // 2) PUSH any new routes
        let newRoutes = routes.suffix(from: viewControllers.count)
        for route in newRoutes {
            let vc = router.viewController(for: route)
            let shouldAnimate = !viewControllers.isEmpty
            push(viewController: vc, animated: shouldAnimate)
        }
    }
        
    // MARK: - Pushing
    
    open func push(viewControllers: [NSViewController], contentAnimation: AnimationBlock?, navigationAnimation: AnimationBlock?, completion: (() -> Void)? = nil) {
        guard Set(self.viewControllers).isDisjoint(with: viewControllers) else {
            print("Navigation Controller tried to push a view controller that's already in the hierarchy")
            return
        }
        guard !viewControllers.isEmpty else {
            print("Navigation Controller tried to push empty view controller collection")
            return
        }
        
        let isPushingNewRoot = self.viewControllers.isEmpty
        let outWrapper = topViewController?.navigationWrapper

        var wrappers = [NavigationWrapperViewController]()
        viewControllers.forEach({ viewController in
            let wrapper = NavigationWrapperViewController(viewController: viewController, navigationController: self)
            self.wrappers.append(wrapper)
            wrappers.append(wrapper)
        })
        let viewController = viewControllers.last!
        let wrapper = viewController.navigationWrapper!
        
        delegate?.navigationController(self, willShowViewController: viewController, animated: (contentAnimation != nil))
        
//        Toolbar.shared.setNavigationItem(.init(title: viewController.title, backAction: isPushingNewRoot ? nil : { [weak self] in
//            self?.popViewController(animated: true)
//        }), animated: navigationAnimation != nil)
        
        // Add the new view
        view.addSubview(wrapper.view)
        
        wrapper.view.activateConstraints(.fillSuperview)
        
        if let contentAnimation = contentAnimation {
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else { return }
                let constraints = outWrapper?.view.constraintsForPinningEdgesToSuperview() ?? []
                outWrapper?.view.removeConstraints(constraints)
                outWrapper?.view.removeFromSuperview()
                outWrapper?.view.layer?.removeAllAnimations()
                self.delegate?.navigationController(self, didShowViewController: viewController, animated: true)
                completion?()
            }
            animatePush(contentAnimation)
            CATransaction.commit()
        } else {
            delegate?.navigationController(self, didShowViewController: viewController, animated: false)
            completion?()
        }
    }

    open func push(viewControllers: [NSViewController], animation: AnimationBlock?, completion: (() -> Void)? = nil) {
        let navAnimation: AnimationBlock? = animation != nil ? defaultPushAnimation() : nil
        push(viewControllers: viewControllers, contentAnimation: animation, navigationAnimation: navAnimation, completion: completion)
    }

    open func push(viewControllers: [NSViewController], animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            push(viewControllers: viewControllers, animation: defaultPushAnimation(), completion: completion)
        } else {
            push(viewControllers: viewControllers, animation: nil, completion: completion)
        }
    }
    
    open func push(viewController: NSViewController, animated: Bool, completion: (() -> Void)? = nil) {
        push(viewControllers: [viewController], animated: animated, completion: completion)
    }
    
    // MARK: - Popping
    
    open func pop(toViewController viewController: NSViewController, contentAnimation: AnimationBlock?, navigationAnimation: AnimationBlock?, completion: (() -> Void)? = nil) {
        guard let wrapper = viewController.navigationWrapper else { return }
        guard Set(wrappers).contains(wrapper) else { return }
        guard let rootViewController = wrappers.first else { return }
        guard let topViewController = topViewController else { return }
        guard topViewController != rootViewController else { return }

        delegate?.navigationController(self, willShowViewController: viewController, animated: (contentAnimation != nil))

        let viewControllerPosition = wrappers.firstIndex(of: wrapper)
        
        let isRoot = viewControllerPosition == 0
//        Toolbar.shared.setNavigationItem(.init(title: viewController.title, backAction: isRoot ? nil : { [weak self] in
//            self?.popViewController(animated: true)
//        }), animated: navigationAnimation != nil)

        // Add the new view
        
        view.addSubview(wrapper.view, positioned: .below, relativeTo: topViewController.view)
        wrapper.view.translatesAutoresizingMaskIntoConstraints = false
        wrapper.view.activateConstraints(.fillSuperview)
        
        if let contentAnimation = contentAnimation {
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else { return }
                let previousWrapper = self.topViewController?.navigationWrapper
                let constraints = previousWrapper?.view.constraintsForPinningEdgesToSuperview() ?? []
                previousWrapper?.view.removeConstraints(constraints)
                previousWrapper?.view.removeFromSuperview()
                previousWrapper?.view.layer?.removeAllAnimations()
                let range = (viewControllerPosition! + 1)..<self.wrappers.count
                self.wrappers.removeSubrange(range)
                self.delegate?.navigationController(self, didShowViewController: viewController, animated: true)
                completion?()
            }
            animatePop(toView: wrapper.view, animation: contentAnimation)
            CATransaction.commit()
        } else {
            let previousWrapper = self.topViewController?.navigationWrapper
            if let constraints = previousWrapper?.view.constraintsForPinningEdgesToSuperview() {
                previousWrapper?.view.removeConstraints(constraints)
            }
            previousWrapper?.view.removeFromSuperview()
            let range = (viewControllerPosition! + 1)..<self.wrappers.count
            wrappers.removeSubrange(range)
            delegate?.navigationController(self, didShowViewController: viewController, animated: false)
            completion?()
        }
    }

    open func pop(toViewController viewController: NSViewController, animation: AnimationBlock?, completion: (() -> Void)?) {
        let navAnimation: AnimationBlock? = animation != nil ? defaultPopAnimation() : nil
        pop(toViewController: viewController, contentAnimation: animation, navigationAnimation: navAnimation, completion: completion)
    }

    open func pop(toViewController viewController: NSViewController, animated: Bool, completion: (() -> Void)?) {
        if animated {
            pop(toViewController: viewController, animation: defaultPopAnimation(), completion: completion)
        } else {
            pop(toViewController: viewController, animation: nil, completion: completion)
        }
    }

    open func popViewController(contentAnimation: AnimationBlock?, navigationAnimation: AnimationBlock?, completion: (() -> Void)?) {
        guard let previousViewController = previousViewController else { return }
        pop(toViewController: previousViewController, contentAnimation: contentAnimation, navigationAnimation: navigationAnimation, completion: completion)
    }

    open func popViewController(animation: AnimationBlock?, completion: (() -> Void)?) {
        let navAnimation: AnimationBlock? = animation != nil ? defaultPopAnimation() : nil
        popViewController(contentAnimation: animation, navigationAnimation: navAnimation, completion: completion)
    }

    open func popViewController(animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            popViewController(animation: defaultPopAnimation(), completion: completion)
        } else {
            popViewController(animation: nil, completion: completion)
        }
    }

    open func set(viewControllers: [NSViewController], animated: Bool, completion: (() -> Void)? = nil) {
        guard !viewControllers.isEmpty else { completion?(); return }
        if animated {
            if let lastViewController = viewControllers.last,
                let wrapper = lastViewController.navigationWrapper,
                self.wrappers.contains(wrapper),
                wrapper != topViewController {
                pop(toViewController: lastViewController, animated: true, completion: completion)
            } else {
                push(viewControllers: viewControllers, animated: true, completion: completion)
            }
        } else {
            push(viewControllers: viewControllers, animated: false, completion: completion)
        }
    }
    
    open func popToRootViewController(contentAnimation: AnimationBlock?, navigationAnimation: AnimationBlock?, completion: (() -> Void)?) {
        guard let rootViewController = wrappers.first,
            let topViewController = topViewController,
            topViewController != rootViewController else { completion?(); return }

        pop(toViewController: rootViewController, contentAnimation: contentAnimation, navigationAnimation: navigationAnimation, completion: completion)
    }

    open func popToRootViewController(animation: AnimationBlock?, completion: (() -> Void)?) {
        let navAnimation: AnimationBlock? = animation != nil ? defaultPopAnimation() : nil
        popToRootViewController(contentAnimation: animation, navigationAnimation: navAnimation, completion: completion)
    }

    open func popToRootViewController(animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            popToRootViewController(animation: defaultPopAnimation(), completion: completion)
        } else {
            popToRootViewController(animation: nil, completion: completion)
        }
    }

    // MARK: - Animations

    
    func shadeAnimation(shadeLayer: CALayer, fadeOut: Bool) -> CABasicAnimation {
        // Capture the current opacity value from the presentation layer if it exists
        var currentOpacity: Float = fadeOut ? 1.0 : 0.0
        if let presentationLayer = shadeLayer.presentation() {
            currentOpacity = presentationLayer.opacity
        }
        
        let shadeAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        shadeAnimation.fromValue = currentOpacity
        shadeAnimation.toValue = fadeOut ? 0.0 : 1.0
        shadeAnimation.duration = Self.animationDuration
        shadeAnimation.timingFunction = CAMediaTimingFunction(name: fadeOut ? .easeIn : .easeOut)
        shadeAnimation.fillMode = CAMediaTimingFillMode.forwards
        shadeAnimation.isRemovedOnCompletion = false
        
        // Update the model value to match current presentation state
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shadeLayer.opacity = currentOpacity
        CATransaction.commit()
        
        return shadeAnimation
    }
    
    // 1. Update the animatePush method to use defaultPushAnimation
    public func animatePush(_ animation: AnimationBlock) {
        guard let fromView = previousViewController?.navigationWrapper?.view,
              let toView = topViewController?.navigationWrapper?.view else {
            animate(fromView: nil, toView: nil, animation: animation)
            return
        }
        
        // Handle main view animations
        var fromCurrentTransform = CATransform3DIdentity
        if let presentationLayer = fromView.layer?.presentation() {
            fromCurrentTransform = presentationLayer.transform
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fromView.layer?.transform = fromCurrentTransform
        CATransaction.commit()
        
        fromView.layer?.removeAllAnimations()
        toView.layer?.removeAllAnimations()
        
        let (fromViewAnimations, toViewAnimations) = animation(fromView, toView)
        
        for (index, anim) in fromViewAnimations.enumerated() {
            fromView.layer?.add(anim, forKey: "pushAnimation\(index)")
        }
        
        for (index, anim) in toViewAnimations.enumerated() {
            toView.layer?.add(anim, forKey: "pushAnimation\(index)")
        }
        
        // Create the shade view
        let shadeView = fromView.installShadeView(color: NSColor.black.withAlphaComponent(0.25))
        shadeView.layer?.opacity = 0
        
        // Animate the shade view
        let shadeAnim = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        shadeAnim.fromValue = 0
        shadeAnim.toValue = 1.0
        shadeAnim.duration = Self.animationDuration
        shadeAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        shadeAnim.fillMode = CAMediaTimingFillMode.forwards
        shadeAnim.isRemovedOnCompletion = false
        
        // Set up a separate transaction for the shade animation to handle its removal
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            // Remove the shade view when animation completes
            shadeView.removeFromSuperview()
        }
        shadeView.layer?.add(shadeAnim, forKey: "shadeAnimation")
        CATransaction.commit()
    }

    // 2. Update the animatePop method similarly
    public func animatePop(toView view: NSView?, animation: AnimationBlock) {
        guard let fromView = topViewController?.navigationWrapper?.view,
              let toView = view else {
            animate(fromView: nil, toView: view, animation: animation)
            return
        }
        
        // Handle main view animations
        var fromCurrentTransform = CATransform3DIdentity
        if let presentationLayer = fromView.layer?.presentation() {
            fromCurrentTransform = presentationLayer.transform
        }
        
        var toCurrentTransform = CATransform3DMakeTranslation(-self.view.bounds.width / 4, 0, 0)
        if let presentationLayer = toView.layer?.presentation() {
            toCurrentTransform = presentationLayer.transform
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fromView.layer?.transform = fromCurrentTransform
        toView.layer?.transform = toCurrentTransform
        CATransaction.commit()
        
        fromView.layer?.removeAllAnimations()
        toView.layer?.removeAllAnimations()
        
        let (fromViewAnimations, toViewAnimations) = animation(fromView, toView)
        
        for (index, anim) in fromViewAnimations.enumerated() {
            fromView.layer?.add(anim, forKey: "popAnimation\(index)")
        }
        
        for (index, anim) in toViewAnimations.enumerated() {
            toView.layer?.add(anim, forKey: "popAnimation\(index)")
        }
        
        // Create the shade view
        let shadeView = toView.installShadeView(color: NSColor.black.withAlphaComponent(0.25))
        
        // Animate the shade view
        let shadeAnim = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        shadeAnim.fromValue = 1.0
        shadeAnim.toValue = 0.0
        shadeAnim.duration = Self.animationDuration
        shadeAnim.timingFunction = CAMediaTimingFunction(name: .easeIn)
        shadeAnim.fillMode = CAMediaTimingFillMode.forwards
        shadeAnim.isRemovedOnCompletion = false
        
        // Set up a separate transaction for the shade animation to handle its removal
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            // Remove the shade view when animation completes
            shadeView.removeFromSuperview()
        }
        shadeView.layer?.add(shadeAnim, forKey: "shadeAnimation")
        CATransaction.commit()
    }

    // 3. Keep your defaultPushAnimation and defaultPopAnimation functions
    open func defaultPushAnimation() -> AnimationBlock {
        return { [weak self] (fromView, toView) in
            let containerViewBounds = self?.view.bounds ?? .zero
            
            // For the view being pushed out
            let slideToLeftTransform = CATransform3DMakeTranslation(-containerViewBounds.width / 4, 0, 0)
            let slideToLeftAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
            
            // Important: Get the current transform if view is mid-animation
            var fromStartTransform = CATransform3DIdentity
            if let fromView = fromView, let presentationLayer = fromView.layer?.presentation() {
                fromStartTransform = presentationLayer.transform
            }
            
            slideToLeftAnimation.fromValue = NSValue(caTransform3D: fromStartTransform)
            slideToLeftAnimation.toValue = NSValue(caTransform3D: slideToLeftTransform)
            slideToLeftAnimation.duration = Self.animationDuration
            slideToLeftAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            slideToLeftAnimation.fillMode = CAMediaTimingFillMode.forwards
            slideToLeftAnimation.isRemovedOnCompletion = false

            // For the view coming in from the right
            let slideFromRightAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
            slideFromRightAnimation.fromValue = NSValue(caTransform3D: CATransform3DMakeTranslation(containerViewBounds.width, 0, 0))
            slideFromRightAnimation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
            slideFromRightAnimation.duration = Self.animationDuration
            slideFromRightAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            slideFromRightAnimation.fillMode = CAMediaTimingFillMode.forwards
            slideFromRightAnimation.isRemovedOnCompletion = false

            return ([slideToLeftAnimation], [slideFromRightAnimation])
        }
    }

    open func defaultPopAnimation() -> AnimationBlock {
        return { [weak self] (fromView, toView) in
            let containerViewBounds = self?.view.bounds ?? .zero

            // For the view being popped (moving right)
            let slideToRightFromCenterAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
            
            // Important: Get the current transform if view is mid-animation
            var fromStartTransform = CATransform3DIdentity
            if let fromView = fromView, let presentationLayer = fromView.layer?.presentation() {
                fromStartTransform = presentationLayer.transform
            }
            
            slideToRightFromCenterAnimation.fromValue = NSValue(caTransform3D: fromStartTransform)
            slideToRightFromCenterAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeTranslation(containerViewBounds.width, 0, 0))
            slideToRightFromCenterAnimation.duration = Self.animationDuration
            slideToRightFromCenterAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
            slideToRightFromCenterAnimation.fillMode = CAMediaTimingFillMode.forwards
            slideToRightFromCenterAnimation.isRemovedOnCompletion = false

            // For the view being revealed (moving from left to center)
            let slideToRightAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
            
            // Important: Get the current transform if view is mid-animation
            var toStartTransform = CATransform3DMakeTranslation(-containerViewBounds.width / 4, 0, 0)
            if let toView = toView, let presentationLayer = toView.layer?.presentation() {
                toStartTransform = presentationLayer.transform
            }
            
            slideToRightAnimation.fromValue = NSValue(caTransform3D: toStartTransform)
            slideToRightAnimation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
            slideToRightAnimation.duration = Self.animationDuration
            slideToRightAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            slideToRightAnimation.fillMode = CAMediaTimingFillMode.forwards
            slideToRightAnimation.isRemovedOnCompletion = false

            return ([slideToRightFromCenterAnimation], [slideToRightAnimation])
        }
    }

    // MARK: - Storyboard
    open override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard segue.identifier == "rootViewController" else { return }
        guard let destinationController = segue.destinationController as? NSViewController else { return }

        push(viewController: destinationController, animated: false)
    }
    
    // MARK: - Animating
    func animate(fromView: NSView?, toView: NSView?, animation: AnimationBlock) {
        fromView?.wantsLayer = true
        toView?.wantsLayer = true
        
        // Get the animations
        let (fromViewAnimations, toViewAnimations) = animation(fromView, toView)
        
        // Apply animations with specific keys instead of nil
        for (index, anim) in fromViewAnimations.enumerated() {
            fromView?.layer?.add(anim, forKey: "animation\(index)")
        }
        
        for (index, anim) in toViewAnimations.enumerated() {
            toView?.layer?.add(anim, forKey: "animation\(index)")
        }
    }
}

public typealias AnimationBlock = (_ fromView: NSView?, _ toView: NSView?) -> (fromViewAnimations: [CAAnimation], toViewAnimations: [CAAnimation])
