//
//  DemoViewController.swift
//  Demo
//
//  Created by Oskar Groth on 2025-05-08.
//

import AppKit
import Navigation

/// A simple demo view controller for testing navigation
class StackDemoViewController: NSViewController {

    private lazy var navigationCoordinator: StackNavigationCoordinator = {
        StackNavigationCoordinator(initialRoutes: [AnyHashable("Welcome to the Demo")]) { router in
            router.navigationDestination(for: String.self) { value in
                // Create a distinct VC for each pushed string
                let color = NSColor(
                    calibratedHue: CGFloat(drand48()),
                    saturation: 0.5,
                    brightness: 0.8,
                    alpha: 1
                )
                return DetailViewController(name: value, color: color)
            }
        }
    }()

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let navController = navigationCoordinator.controller
        embed(child: navController)

        let toolbar = NSView()
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toolbar)

        let pushButton = NSButton(title: "Push Next", target: self, action: #selector(pushNext))
        pushButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(pushButton)

        let popButton = NSButton(title: "Pop Last", target: self, action: #selector(popLast))
        popButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(popButton)
        
        let popRootButton = NSButton(title: "Pop To Root", target: self, action: #selector(popRoot))
        popRootButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(popRootButton)

        NSLayoutConstraint.activate([
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            pushButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8),
            pushButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            popButton.leadingAnchor.constraint(equalTo: pushButton.trailingAnchor, constant: 8),
            popButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            
            popRootButton.leadingAnchor.constraint(equalTo: popButton.trailingAnchor, constant: 8),
            popRootButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])
    }
    // MARK: – Actions

    @objc private func pushNext() {
        let next = "Next \(Int.random(in: 1...10))"
        navigationCoordinator.push(AnyHashable(next))
    }

    @objc private func popLast() {
        navigationCoordinator.pop()
    }
    
    @objc private func popRoot() {
        navigationCoordinator.popRoot()
    }
}
