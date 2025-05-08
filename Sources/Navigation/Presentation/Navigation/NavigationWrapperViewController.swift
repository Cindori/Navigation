//
//  NavigationWrapperViewController.swift
//  SenseiUI
//
//  Created by Oskar Groth on 2019-09-01.
//  Copyright © 2019 Oskar Groth. All rights reserved.
//

import AppKit

class NavigationWrapperViewController: NSViewController {
    
    let containerView = NSView()
    let backgroundView = NSVisualEffectView()
    var viewController: NSViewController?
    var viewToTopConstraint: NSLayoutConstraint!

    weak var navigationController: NavigationController?
    
    init(viewController: NSViewController, navigationController: NavigationController) {
        self.viewController = viewController
        self.navigationController = navigationController
        super.init(nibName: nil, bundle: nil)
        addChild(viewController)
        view.addSubview(containerView)
        containerView.addSubview(viewController.view)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.activateConstraints(.fillSuperview)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewToTopConstraint = viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor)
        NSLayoutConstraint.activate([
            viewToTopConstraint,
            viewController.view.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            viewController.view.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.material = .contentBackground
    }
    
    func showDefaultBackground() {
        guard backgroundView.superview == nil else { return }
        view.addSubview(backgroundView, positioned: .below, relativeTo: view.subviews.first)
        
        containerView.removeFromSuperview()
        backgroundView.addSubview(containerView)
        backgroundView.activateConstraints(.fillSuperview)
        containerView.activateConstraints(.fillSuperview)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView(frame: .zero, usingConstraints: true, wantsLayer: true)
    }
    
}
