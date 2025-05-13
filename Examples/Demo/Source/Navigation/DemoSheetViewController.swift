//
//  DemoSheetViewController.swift
//  Demo
//
//  Created by Oskar Groth on 2025-05-09.
//

import AppKit
import Navigation

class DemoSheetViewController: NSViewController {

    private lazy var sheetCoordinator: SheetCoordinator = {
        SheetCoordinator(host: self) { router in
            router.navigationDestination(for: String.self) { value in
                let color = NSColor(
                    calibratedHue: CGFloat(drand48()),
                    saturation: 0.5,
                    brightness: 0.8,
                    alpha: 1
                )
                return SheetDetailViewController(name: value, color: color, icon: nil)
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

        // Present Sheet button
        let presentButton = NSButton(title: "Present Sheet", target: self, action: #selector(presentSheet))
        presentButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(presentButton)

        // Dismiss Sheet button
        let dismissButton = NSButton(title: "Dismiss Sheet", target: self, action: #selector(dismissSheet))
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(dismissButton)

        // Enqueue 5 Sheets button
        let enqueueFiveButton = NSButton(title: "Enqueue 5 Sheets", target: self, action: #selector(enqueueFiveSheets))
        enqueueFiveButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(enqueueFiveButton)

        NSLayoutConstraint.activate([
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            presentButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8),
            presentButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            dismissButton.leadingAnchor.constraint(equalTo: presentButton.trailingAnchor, constant: 8),
            dismissButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            enqueueFiveButton.leadingAnchor.constraint(equalTo: dismissButton.trailingAnchor, constant: 8),
            enqueueFiveButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
        ])
    }

    // MARK: – Actions
    @objc private func presentSheet() {
        let next = "Sheet \(Int.random(in: 1...1000))"
        sheetCoordinator.present(AnyHashable(next))
    }

    @objc private func dismissSheet() {
        sheetCoordinator.dismiss()
    }
    
    @objc private func enqueueFiveSheets() {
        for _ in 1...5 {
            let next = "Sheet \(Int.random(in: 1...1000))"
            sheetCoordinator.present(AnyHashable(next))
        }
    }
}

class SheetDetailViewController: DetailViewController {

    /// Override the designated initializer to accept the same parameters.
    override init(name: String, color: NSColor? = nil, icon: NSImage? = nil) {
        super.init(name: name, color: color, icon: icon)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add a Close button to the existing stack
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeSheet))
        closeButton.bezelStyle = .rounded
        stack.addArrangedSubview(closeButton)
    }

    @objc private func closeSheet() {
        dismiss(self)
    }
}
