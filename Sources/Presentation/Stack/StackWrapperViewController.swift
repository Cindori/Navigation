//
//  NavigationWrapperViewController.swift
//  SenseiUI
//
//  Created by Oskar Groth on 2019-09-01.
//  Copyright © 2019 Oskar Groth. All rights reserved.
//

import AppKit

class StackWrapperViewController: NSViewController {
    
    let containerView = NSView()
    let backgroundView = NSVisualEffectView()
    let viewController: NSViewController
    var viewToTopConstraint: NSLayoutConstraint!

    weak var navigationController: StackNavigationController?
    
    private var shadeView: NSView = {
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor
        view.identifier = .init("ShadeView")
        view.layer?.opacity = 0
//        view.layer?.filters = [.dark]
        return view
    }()
    
    init(viewController: NSViewController, navigationController: StackNavigationController) {
        self.viewController = viewController
        self.navigationController = navigationController
        super.init(nibName: nil, bundle: nil)
        addChild(viewController)
        view.addSubview(containerView)
        containerView.addSubview(viewController.view)
        containerView.activateConstraints(.fillSuperview)
        viewController.view.activateConstraints(.fillSuperview)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.material = .contentBackground
    }
    
    override func loadView() {
        view = NSView(frame: .zero)
        view.wantsLayer = true
        view.layer?.masksToBounds = true
    }
    
    func showDefaultBackground() {
        guard backgroundView.superview == nil else { return }
        view.addSubview(backgroundView, positioned: .below, relativeTo: view.subviews.first)
        
        containerView.removeFromSuperview()
        backgroundView.addSubview(containerView)
        backgroundView.activateConstraints(.fillSuperview)
        containerView.activateConstraints(.fillSuperview)
    }
    
    func setShade(active: Bool) {
        shadeView.layer?.opacity = active ? 1.0 : 0.0
    }
    
    func removeShade() {
        shadeView.removeFromSuperview()
    }
    
    func addShadeAnimation(active: Bool) {
        guard let layer = shadeView.layer else { return }
        if shadeView.superview == nil {
            view.addSubview(shadeView)
            shadeView.activateConstraints(.fillSuperview)
        }
        
        let fromOpacity: Float = active ? 0.0 : 1.0
        let toOpacity: Float = active ? 1.0 : 0.0
        let key = active ? "shadeIn" : "shadeOut"

        let anim = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        anim.fromValue = fromOpacity
        anim.toValue = toOpacity
        anim.duration = StackNavigationController.animationDuration
        anim.timingFunction = CAMediaTimingFunction(name: active ? .easeOut : .easeIn)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: key)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
