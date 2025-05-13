//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-12.
//

import AppKit
import SwiftUI

@MainActor
public final class NavigationRouter {
    private enum Destination {
        case view((AnyHashable) -> AnyView)
        case viewController((AnyHashable) -> NSViewController)
    }
    
    private var factories: [ObjectIdentifier: Destination] = [:]
    
    public init() {
        registerLogEmoji("🧭")
        logDebug("Initialized NavigationRouter")
    }
    
    // MARK: - Registration
    
    @discardableResult
    public func navigationDestination<R: Hashable>(
        for routeType: R.Type,
        _ builder: @escaping (R) -> NSViewController
    ) -> Self {
        let key = ObjectIdentifier(routeType)
        factories[key] = .viewController { any in
            guard let route = any.base as? R else {
                fatalError("Router expected route of type \(R.self), got \(type(of: any.base))")
            }
            return builder(route)
        }
        logDebug("Registered ViewController destination for \(routeType)")
        return self
    }
    
    @discardableResult
    public func navigationDestination<R: Hashable>(
        for routeType: R.Type,
        @ViewBuilder _ builder: @escaping (R) -> some View
    ) -> Self {
        let key = ObjectIdentifier(routeType)
        factories[key] = .view { any in
            guard let route = any.base as? R else {
                fatalError("Router expected route of type \(R.self), got \(type(of: any.base))")
            }
            return AnyView(builder(route).id(route))
        }
        logDebug("Registered View destination for \(routeType)")
        return self
    }
    
    // MARK: - Resolution
    
    public func view(for route: AnyHashable) -> some View {
        let key = ObjectIdentifier(type(of: route.base))
        switch factories[key] {
            case .view(let build):
                logDebug("Resolved view for route \(route)")
                return build(route)
            case .viewController(let build):
                logDebug("Resolved ViewController for route \(route), wrapping in AnyView")
                return AnyView(
                    ViewControllerWrapper(controller: build(route))
                        .id(route)
                )
            case nil:
                logWarn("Attempting to present unregistered route: \(route)")
                return AnyView(EmptyView())
        }
    }
    
    public func viewController(for route: AnyHashable) -> NSViewController {
        let key = ObjectIdentifier(type(of: route.base))
        switch factories[key] {
            case .viewController(let build):
                logDebug("Resolved ViewController for route \(route)")
                return build(route)
            case .view(let build):
                logDebug("Resolved View for route \(route), wrapping in NSHostingController")
                return NSHostingController(rootView: build(route))
            case nil:
                logWarn("Attempting to present unregistered route: \(route)")
                return NSViewController()
        }
    }
    
    // MARK: - Internal wrapper
    
    private struct ViewControllerWrapper: NSViewControllerRepresentable {
        let controller: NSViewController
        
        func makeNSViewController(context: Context) -> NSViewController { controller }
        func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
    }
}

