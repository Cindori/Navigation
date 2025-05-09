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
    static let animationDuration = 2.95
    
    // MARK: – Dependencies
    
    /// The source of truth for “what’s on the stack”
    public let navigator: Navigator
    
    /// Knows how to build a VC for each route
    public let router: NavigationRouter
    
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: – Internal Stack
    
    private var wrappers: [NavigationWrapperViewController] = []
    
    var viewControllers: [NSViewController] {
        wrappers.compactMap { $0.viewController }
    }
    var topViewController: NSViewController? {
        viewControllers.last
    }
    var previousViewController: NSViewController? {
        viewControllers.dropLast().last
    }
    
    // MARK: – Init
    
    /// Initialize with your navigator & router. Optionally push an initial route.
    init(navigator: StackNavigator, router: NavigationRouter) {
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
    
    public override func loadView() {
        view = NSView(frame: .zero, usingConstraints: true, wantsLayer: true)
        view.clipsToBounds = true
    }
    
    
    // MARK: – Sync Logic
    
    private var vcToRouteHashMap: [NSViewController: AnyHashable] = [:]
    
    private func sync(with routes: [AnyHashable]) {
        // 1. Convert routes to VCs, reusing existing ones
        let routeToVC: [AnyHashable: NSViewController] = Dictionary(
            viewControllers.compactMap { vc in
                if let route = vcToRouteHashMap[vc] {
                    return (route, vc)
                }
                return nil
            },
            uniquingKeysWith: { first, _ in first }
        )
        
        let targetVCs = routes.map { route -> NSViewController in
            if let existingVC = routeToVC[route] {
                return existingVC
            } else {
                let newVC = router.viewController(for: route)
                vcToRouteHashMap[newVC] = route
                return newVC
            }
        }
        
        // 2. Early exit if nothing changed
        if targetVCs == viewControllers {
            return
        }
        
        // 3. Find VCs to remove
        let targetVCSet = Set(targetVCs)
        let currentVCSet = Set(viewControllers)
        let vcsToRemove = currentVCSet.subtracting(targetVCSet)
        
        // 4. Figure out the animation type
        let needsAnimation = !viewControllers.isEmpty && !targetVCs.isEmpty
        let isPush = needsAnimation && targetVCs.count > viewControllers.count
        let isPop = needsAnimation && targetVCs.count < viewControllers.count
    
        // 6. Create a dictionary of existing wrappers by VC
        let vcToWrapper = Dictionary(
            wrappers.map { ($0.viewController, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        
        // 7. Create the new wrappers array
        let newWrappers = targetVCs.map { vc -> NavigationWrapperViewController in
            if let existingWrapper = vcToWrapper[vc] {
                return existingWrapper
            } else {
                // Create new wrapper but don't add as child yet
                let wrapper = NavigationWrapperViewController(viewController: vc, navigationController: self)
                return wrapper
            }
        }
        
        // 8. Determine action and handle view updates and animations
        if isPush, let targetWrapper = newWrappers.last {
            // Get the current visible wrapper
            let sourceWrapper = wrappers.last!
            
            // Update state
            wrappers = newWrappers
            
            // Add target wrapper using the convenience method
            embed(child: targetWrapper)
            
            // Animate with a completion handler that does cleanup
            animatePush(fromView: sourceWrapper.view, toView: targetWrapper.view) {
                // Cleanup happens here after animation completes
                
                // 1. Remove unused views from hierarchy (keep in stack)
                for wrapper in self.wrappers.dropLast() {
                    wrapper.view.removeFromSuperview()
                }
                
                // 2. Clean up completely removed view controllers
                for vc in vcsToRemove {
                    if let wrapper = vcToWrapper[vc] {
                        wrapper.dislodgeFromParent()
                    }
                    self.vcToRouteHashMap.removeValue(forKey: vc)
                }
            }
        } else if isPop, let targetWrapper = newWrappers.last {
            // Get the current visible wrapper
            let sourceWrapper = wrappers.last!
            
            // Update state
            wrappers = newWrappers
            
            // Add target wrapper below source view using the convenience method
            embed(child: targetWrapper, positioned: .below, relativeTo: sourceWrapper.view)
            
            // Animate with a completion handler that does cleanup
            animatePop(fromView: sourceWrapper.view, toView: targetWrapper.view) {
                // Cleanup happens here after animation completes
                
                // Clean up completely removed view controllers
                for vc in vcsToRemove {
                    if let wrapper = vcToWrapper[vc] {
                        wrapper.dislodgeFromParent()
                    }
                    self.vcToRouteHashMap.removeValue(forKey: vc)
                }
            }
        } else {
            // No animation needed - just update views
            
            // Update state first
            wrappers = newWrappers
            
            // Remove all views from hierarchy
            for wrapper in wrappers.dropLast() {
                wrapper.view.removeFromSuperview()
            }
            
            // Add the last wrapper using the convenience method
            if let lastWrapper = wrappers.last {
                // Make sure it's added as a child if it's new
                if lastWrapper.parent == nil {
                    embed(child: lastWrapper)
                } else {
                    // Just add the view if it's already a child
                    view.addSubview(lastWrapper.view)
                    lastWrapper.view.activateConstraints(.fillSuperview)
                }
            }
            
            // Clean up removed wrappers
            for vc in vcsToRemove {
                if let wrapper = vcToWrapper[vc] {
                    wrapper.dislodgeFromParent()
                }
                self.vcToRouteHashMap.removeValue(forKey: vc)
            }
        }
    }
    
    // MARK: - Pushing
    
    private func animatePush(fromView: NSView, toView: NSView, completion: @escaping () -> Void) {
        
        // Get current transform from presentation layer if possible
        let currentTransform = fromView.layer?.presentation()?.transform ?? CATransform3DIdentity
        fromView.layer?.removeAllAnimations()
        toView.layer?.removeAllAnimations()
        
        // Ensure current transform is applied immediately
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fromView.layer?.transform = currentTransform
        CATransaction.commit()
        
        // Create animations
        let slideOut = slideAnimation(
            from: currentTransform,
            to: CATransform3DMakeTranslation(-view.bounds.width / 4, 0, 0)
        )
        
        let slideIn = slideAnimation(
            from: CATransform3DMakeTranslation(view.bounds.width, 0, 0),
            to: CATransform3DIdentity
        )
        
        let fromGroup = CAAnimationGroup()
        fromGroup.animations = [slideOut]
        fromGroup.duration = slideOut.duration
        fromGroup.timingFunction = slideOut.timingFunction
        fromGroup.fillMode = .forwards
        fromGroup.isRemovedOnCompletion = false
        
        let toGroup = CAAnimationGroup()
        toGroup.animations = [slideIn]
        toGroup.duration = slideIn.duration
        toGroup.timingFunction = slideIn.timingFunction
        toGroup.fillMode = .forwards
        toGroup.isRemovedOnCompletion = false
        
        // Apply animations with cleanup on completion
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion()
        }
        
        fromView.layer?.add(fromGroup, forKey: "groupFrom")
        toView.layer?.add(toGroup, forKey: "groupTo")
        CATransaction.commit()
    }
    
    
    // MARK: - Popping
    
    private func animatePop(fromView: NSView, toView: NSView, completion: @escaping () -> Void) {
        // Get current transforms
        let fromCurrentTransform = fromView.layer?.presentation()?.transform ?? CATransform3DIdentity
        let toCurrentTransform = toView.layer?.presentation()?.transform ?? CATransform3DMakeTranslation(-view.bounds.width / 4, 0, 0)
        
        fromView.layer?.removeAllAnimations()
        toView.layer?.removeAllAnimations()
        
        // Apply current transforms immediately
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fromView.layer?.transform = fromCurrentTransform
        toView.layer?.transform = toCurrentTransform
        CATransaction.commit()
        
        // Create animations
        let slideRight = slideAnimation(
            from: fromCurrentTransform,
            to: CATransform3DMakeTranslation(view.bounds.width, 0, 0),
            timing: .default
        )
        
        let slideCenter = slideAnimation(
            from: toCurrentTransform,
            to: CATransform3DIdentity
        )
        
        // Apply animations with cleanup on completion
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion()
        }
        
        fromView.layer?.add(slideRight, forKey: "popFrom")
        toView.layer?.add(slideCenter, forKey: "popTo")
        CATransaction.commit()
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
    
    func shadeAnimation(shadeLayer: CALayer, fadeOut: Bool) -> CABasicAnimation {
        // Capture the current opacity value from the presentation layer if it exists
        var currentOpacity: Float = fadeOut ? 1.0 : 0.0
        if let presentationLayer = shadeLayer.presentation() {
            currentOpacity = presentationLayer.opacity
        }
        
        let shadeAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        if let presentationLayer = shadeLayer.presentation() {
            shadeAnimation.fromValue = presentationLayer.opacity
        }
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
    
    // 3. Keep your defaultPushAnimation and defaultPopAnimation functions
    func defaultPushAnimation() -> AnimationBlock {
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
    
    func defaultPopAnimation() -> AnimationBlock {
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

typealias AnimationBlock = (_ fromView: NSView?, _ toView: NSView?) -> (fromViewAnimations: [CAAnimation], toViewAnimations: [CAAnimation])
