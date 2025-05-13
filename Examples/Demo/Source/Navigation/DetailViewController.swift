//
//  DetailViewController.swift
//  Demo
//
//  Created by Oskar Groth on 2025-05-09.
//

import AppKit

class DetailViewController: NSViewController {
    private let name: String
    private let color: NSColor?
    private let icon: NSImage?
    let stack = NSStackView()
    
    init(
        name: String,
        color: NSColor? = nil,
        icon: NSImage? = nil
    ) {
        self.name = name
        self.color = color
        self.icon = icon
        super.init(nibName: nil, bundle: nil)
//        // Optional: guide sheet sizing
//        self.preferredContentSize = NSSize(width: 300, height: 200) bad
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let container = NSView(frame: .zero)
        container.wantsLayer = true
//        container.layer?.opacity = 0.95
        if let bg = color {
            container.layer?.backgroundColor = bg.cgColor
        }
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Page \(name)"

        // Build vertical stack
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 20
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Optional icon at top
        if let icon = icon {
            let imageView = NSImageView(image: icon)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(imageView)
        }

        // Title label
        let label = NSTextField(labelWithString: name)
        label.font = NSFont.systemFont(ofSize: 64, weight: .regular)
        label.textColor = .white
        label.alignment = .center
        stack.addArrangedSubview(label)

        // Add stack to view and center
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            // Center the stack
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Boundaries so the stack doesn't float without reference
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            
            // Optional: limit max width so it doesn't stretch too much
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 600)
        ])
    }
}
