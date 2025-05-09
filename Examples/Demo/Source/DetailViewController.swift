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

    init(
        name: String,
        color: NSColor? = nil,
        icon: NSImage? = nil,
    ) {
        self.name = name
        self.color = color
        self.icon = icon
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: .zero)
        view.wantsLayer = true
        if let bg = color {
            view.layer?.backgroundColor = bg.cgColor
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Page \(name)"

        // Centered label
        let label = NSTextField(labelWithString: name)
        label.font = NSFont.systemFont(ofSize: 64)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        // Optional icon above the label
        if let icon = icon {
            let imageView = NSImageView(image: icon)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -20),
            ])
        }

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
