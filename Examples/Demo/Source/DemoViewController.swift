//
//  DemoViewController.swift
//  Demo
//
//  Created by Oskar Groth on 2025-05-08.
//

import AppKit
import Navigation
import NavigationCore

/// A simple demo view controller for testing navigation
class DemoViewController: NSViewController {

    override func loadView() {
        // Set up a plain view
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Label
        let label = NSTextField(labelWithString: "Welcome to the Demo")
        label.font = NSFont.systemFont(ofSize: 24, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        // Push button
        let pushButton = NSButton(title: "Push Next View", target: self, action: #selector(pushNext))
        pushButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pushButton)

        // Layout
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            pushButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            pushButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func pushNext() {
        let route: AnyHashable = "Detail at \(Date())"
        if let nav = navigationController?.stackNavigator {
            nav.push(route)
        } else {
            print("No navigator found!")
        }
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
