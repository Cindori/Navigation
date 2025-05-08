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
open class StackNavigationController: NSViewController {
    static let animationDuration = 0.35

    // MARK: – Dependencies
    
    /// The source of truth for “what’s on the stack”
    public let navigator: StackNavigator
    
    /// Knows how to build a VC for each route
    public let router: NavigationRouter
    
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: – Internal Stack
    
    private var isBusy = false
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
    public init(
        navigator: StackNavigator,
        router: NavigationRouter,
        initialRoute: AnyHashable? = nil
    ) {
        self.navigator = navigator
        self.router    = router
        super.init(nibName: nil, bundle: nil)
        
        // 1) Observe every change to the route array
        navigator.$routes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoutes in
                self?.sync(with: newRoutes)
            }
            .store(in: &cancellables)
        
        // 2) If desired, seed with a first route
        if let r = initialRoute {
            navigator.push(r)
        }
    }
    
    required public init?(coder: NSCoder) { fatalError() }
    
    
    // MARK: – View Lifecycle
    
    open override func loadView() {
        view = NSView(frame: .zero, usingConstraints: true, wantsLayer: true)
        view.clipsToBounds = true
    }
    
    
    // MARK: – Sync Logic
    
    /// Reconcile your child VCs to match the navigator’s route stack
    private func sync(with routes: [AnyHashable]) {
        // 1) POP extras
        while viewControllers.count > routes.count {
            popViewController(animated: true)
        }
        
        // 2) PUSH new
        let newRoutes = routes.suffix(from: viewControllers.count)
        for route in newRoutes {
            // build the VC
            let vc = router.viewController(for: AnyHashable(route))
            
            // inject navigator so SwiftUI VCs can push/pop
//            vc.navigator = navigator
            
            // wrap & register
            let wrapper = NavigationWrapperViewController(viewController: vc, navigationController: self)
            wrappers.append(wrapper)
            
            // call your existing push API
            push(viewController: vc, animated: true)
        }
    }
        
	// MARK: - Pushing
    
	open func push(viewControllers: [NSViewController], contentAnimation: AnimationBlock?, navigationAnimation: AnimationBlock?, completion: (() -> Void)? = nil) {
        guard !isBusy else {
            print("Navigation Controller busy, can't push \(viewControllers)")
            return
        }
        guard Set(self.viewControllers).isDisjoint(with: viewControllers) else {
            print("Navigation Controller tried to push a view controller that's already in the hierarchy")
            return
        }
        guard !viewControllers.isEmpty else {
            print("Navigation Controller tried to push empty view controller collection")
            return
        }
        isBusy = true
        
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
            let shadeView = outWrapper?.view.installShadeView(color: NSColor.black.withAlphaComponent(0.25))
            shadeView?.layer?.opacity = 0
			CATransaction.begin()
			CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else { return }
                shadeView?.removeFromSuperview()
                let constraints = outWrapper?.view.constraintsForPinningEdgesToSuperview() ?? []
                outWrapper?.view.removeConstraints(constraints)
				outWrapper?.view.removeFromSuperview()
				outWrapper?.view.layer?.removeAllAnimations()
				self.delegate?.navigationController(self, didShowViewController: viewController, animated: true)
                self.isBusy = false
                completion?()
			}
            shadeView?.layer?.add(shadeAnimation(shadeLayer: shadeView!.layer!, fadeOut: false), forKey: nil)
			animatePush(contentAnimation)
			CATransaction.commit()
		} else {
			delegate?.navigationController(self, didShowViewController: viewController, animated: false)
            isBusy = false
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
        guard !isBusy else {
            print("Navigation Controller busy, can't pop \(viewController)")
            return
        }
        guard let wrapper = viewController.navigationWrapper else { return }
		guard Set(wrappers).contains(wrapper) else { return }
		guard let rootViewController = wrappers.first else { return }
		guard let topViewController = topViewController else { return }
		guard topViewController != rootViewController else { return }
        isBusy = true

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
            let shadeView = wrapper.view.installShadeView(color: NSColor.black.withAlphaComponent(0.25))
			CATransaction.begin()
			CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else { return }
                shadeView.removeFromSuperview()
                let previousWrapper = self.topViewController?.navigationWrapper
                let constraints = previousWrapper?.view.constraintsForPinningEdgesToSuperview() ?? []
                previousWrapper?.view.removeConstraints(constraints)
				previousWrapper?.view.removeFromSuperview()
				previousWrapper?.view.layer?.removeAllAnimations()
				let range = (viewControllerPosition! + 1)..<self.wrappers.count
                self.wrappers.removeSubrange(range)
				self.delegate?.navigationController(self, didShowViewController: viewController, animated: true)
                self.isBusy = false
                completion?()
			}
            shadeView.layer?.add(shadeAnimation(shadeLayer: shadeView.layer!, fadeOut: true), forKey: nil)
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
            isBusy = false
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
	open func defaultPushAnimation() -> AnimationBlock {
		return { [weak self] (_, _) in
			let containerViewBounds = self?.view.bounds ?? .zero

			let slideToLeftTransform = CATransform3DMakeTranslation(-containerViewBounds.width / 4, 0, 0)
			let slideToLeftAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
			slideToLeftAnimation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
			slideToLeftAnimation.toValue = NSValue(caTransform3D: slideToLeftTransform)
            slideToLeftAnimation.duration = NavigationController.animationDuration
			slideToLeftAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
			slideToLeftAnimation.fillMode = CAMediaTimingFillMode.forwards
			slideToLeftAnimation.isRemovedOnCompletion = false

			let slideFromRightTransform = CATransform3DMakeTranslation(containerViewBounds.width, 0, 0)
			let slideFromRightAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
			slideFromRightAnimation.fromValue = NSValue(caTransform3D: slideFromRightTransform)
			slideFromRightAnimation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
			slideFromRightAnimation.duration = NavigationController.animationDuration
			slideFromRightAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
			slideFromRightAnimation.fillMode = CAMediaTimingFillMode.forwards
			slideFromRightAnimation.isRemovedOnCompletion = false

			return ([slideToLeftAnimation], [slideFromRightAnimation])
		}
	}

	open func defaultPopAnimation() -> AnimationBlock {
		return { [weak self] (_, _) in
			let containerViewBounds = self?.view.bounds ?? .zero

			let slideToRightTransform = CATransform3DMakeTranslation(-containerViewBounds.width / 4, 0, 0)
			let slideToRightAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
			slideToRightAnimation.fromValue = NSValue(caTransform3D: slideToRightTransform)
			slideToRightAnimation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
			slideToRightAnimation.duration = NavigationController.animationDuration
			slideToRightAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
			slideToRightAnimation.fillMode = CAMediaTimingFillMode.forwards
			slideToRightAnimation.isRemovedOnCompletion = false

			let slideToRightFromCenterTransform = CATransform3DMakeTranslation(containerViewBounds.width, 0, 0)
			let slideToRightFromCenterAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
			slideToRightFromCenterAnimation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
			slideToRightFromCenterAnimation.toValue = NSValue(caTransform3D: slideToRightFromCenterTransform)
			slideToRightFromCenterAnimation.duration = NavigationController.animationDuration
            slideToRightFromCenterAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
			slideToRightFromCenterAnimation.fillMode = CAMediaTimingFillMode.forwards
			slideToRightFromCenterAnimation.isRemovedOnCompletion = false

			return ([slideToRightFromCenterAnimation], [slideToRightAnimation])
		}
	}
    
    func shadeAnimation(shadeLayer: CALayer, fadeOut: Bool) -> CABasicAnimation {
        let shadeAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        shadeAnimation.fromValue = fadeOut ? 1.0 : 0
        shadeAnimation.toValue = fadeOut ? 0 : 1.0
        shadeAnimation.duration = NavigationController.animationDuration
        shadeAnimation.timingFunction = CAMediaTimingFunction(name: fadeOut ? .easeIn : .easeOut)
        shadeAnimation.fillMode = CAMediaTimingFillMode.forwards
        shadeAnimation.isRemovedOnCompletion = false
        return shadeAnimation
    }
    
    public func animatePush(_ animation: AnimationBlock) {
        let fromView = previousViewController?.navigationWrapper?.view
        let toView = topViewController?.navigationWrapper?.view
        animate(fromView: fromView, toView: toView, animation: animation)
    }
    
    public func animatePop(toView view: NSView?, animation: AnimationBlock) {
        let fromView = topViewController?.navigationWrapper?.view
        let toView = view
        animate(fromView: fromView, toView: toView, animation: animation)
    }

	// MARK: - Storyboard
	open override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		guard segue.identifier == "rootViewController" else { return }
		guard let destinationController = segue.destinationController as? NSViewController else { return }

		push(viewController: destinationController, animated: false)
	}
}
