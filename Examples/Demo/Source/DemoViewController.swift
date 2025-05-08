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
    // Helper to create a view controller with a centered label and custom background/icon/hideNavigation
    static func createViewController(
        name: String,
        color: NSColor? = nil,
        icon: NSImage? = nil,
        hideNavigation: Bool = false
    ) -> NSViewController {
        let vc = NSViewController()
        if let bg = color {
            vc.view.wantsLayer = true
            vc.view.layer?.backgroundColor = bg.cgColor
        }
        vc.title = "Page \(name)"
        let label = NSTextField(labelWithString: name)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 64)
        label.textColor = .white
        vc.view.addSubview(label)
        label.activateConstraints(.centerInSuperview)
        return vc
    }

    private lazy var navigationCoordinator: NavigationCoordinator = {
        NavigationCoordinator(initialRoutes: [AnyHashable("Welcome to the Demo")]) { router in
            router.navigationDestination(for: String.self) { value in
                // Create a distinct VC for each pushed string
                let color = NSColor(calibratedHue: CGFloat(drand48()), saturation: 0.5, brightness: 0.8, alpha: 1)
                return Self.createViewController(name: value, color: color)
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

        let toolbar = NSView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        let pushButton = NSButton(title: "Push Next", target: self, action: #selector(pushNext))
        pushButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(pushButton)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            pushButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8),
            pushButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
        ])

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

    @objc private func pushNext() {
        let next = "Next \(Int.random(in: 1...1000))"
        navigationCoordinator.push(AnyHashable(next))
    }
}

/// A simple detail view controller to be pushed onto the stack
class DemoDetailViewController: NSViewController {
    let detailText: String

    init(detailText: String) {
        self.detailText = detailText
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = NSTextField(labelWithString: detailText)
        label.font = NSFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let popButton = NSButton(title: "Pop", target: self, action: #selector(popSelf))
        popButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popButton)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            popButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            popButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func popSelf() {
//        navigationController?.popViewController(animated: true)
    }
}
