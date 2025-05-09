//
//  DemoViewController.swift
//  Demo
//
//  Created by Oskar Groth on 2025-05-08.
//

import AppKit
import Navigation

/// A simple demo view controller for testing navigation
class DemoViewController: NSViewController {

    private lazy var navigationCoordinator: NavigationCoordinator = {
        NavigationCoordinator(initialRoutes: [AnyHashable("Welcome to the Demo")]) { router in
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
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // — Toolbar —
        let toolbar = NSView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        let pushButton = NSButton(title: "Push Next", target: self, action: #selector(pushNext))
        pushButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(pushButton)

        let popButton = NSButton(title: "Pop Last", target: self, action: #selector(popLast))
        popButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(popButton)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            pushButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8),
            pushButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            popButton.leadingAnchor.constraint(equalTo: pushButton.trailingAnchor, constant: 8),
            popButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
        ])

        // — Embed the navigation controller —
        let navController = navigationCoordinator.controller
        addChild(navController)
        view.addSubview(navController.view)
        navController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navController.view.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            navController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            navController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: – Actions

    @objc private func pushNext() {
        let next = "Next \(Int.random(in: 1...1000))"
        navigationCoordinator.push(AnyHashable(next))
    }

    @objc private func popLast() {
        navigationCoordinator.pop()
    }
}
