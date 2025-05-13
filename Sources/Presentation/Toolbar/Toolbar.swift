//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-09.
//

import AppKit
import SwiftUI

@MainActor
public final class Toolbar {
    public static let height: CGFloat = 52.0

    public final class Model: ObservableObject {
        @Published var leadingContent: (() -> AnyView)? = nil
        @Published var trailingContent: (() -> AnyView)? = nil
        @Published var isHidden = false
        @Published var leading: CGFloat?
    }

    let model = Model()
    lazy var view = NSHostingView(rootView: ToolbarView(model: model))

    public init() {}

    public func setHidden(_ hidden: Bool, animated: Bool = false) {
        model.isHidden = hidden
    }
    
    public func setLeading(_ leading: CGFloat) {
        model.leading = leading
    }

    public func setLeading<Content: View>(_ view: @escaping () -> Content, animated: Bool = false) {
        model.leadingContent = { AnyView(view()) }
    }

    public func setTrailing<Content: View>(_ view: @escaping () -> Content, animated: Bool = false) {
        model.trailingContent = { AnyView(view()) }
    }

    public func reset(animated: Bool = false) {
        model.leadingContent = nil
        model.trailingContent = nil
        model.isHidden = false
    }
}

struct ToolbarView: View {
    @ObservedObject var model: Toolbar.Model

    var body: some View {
        HStack {
            if let leading = model.leadingContent?() {
                leading
            }

            Spacer(minLength: 0)

            if let trailing = model.trailingContent?() {
                trailing
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(
            VisualEffectView(material: .titlebar, blendingMode: .withinWindow, state: .active)
//                .boxShadowNoPad(Rectangle(), color: Color.black.opacity(0.2), radius: 1, y: 1)
                .overlay {
                    Rectangle()
                        .foregroundStyle(Color.white.opacity(0.10))
                        .frame(height: 0.5)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .opacity(model.isHidden ? 0 : 1)
        )
        .animation(.defaultQuick, value: model.isHidden)
        .animation(.defaultQuick, value: model.leadingContent != nil)
        .animation(.defaultQuick, value: model.trailingContent != nil)
        .padding(.leading, model.leading)
    }
}

struct ToolbarButton<Content: View>: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let action: (() -> Void)
    let content: () -> Content
    
    @State private var mouseDown = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            action()
        }, label: {
            content()
                .foregroundColor(Color(.labelColor))
                .font(.system(size: 13, weight: .regular))
                .padding(.bottom, 1)
                .padding([.leading, .trailing], 10)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.unemphasizedSelectedContentBackgroundColor).opacity(backgroundOpacity()))
                        .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
                )
                .onHover { isHovered = $0 }
                .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }
    
    func foregroundOpacity() -> Double {
        if mouseDown {
            return 1
        }
        return colorScheme == .dark ? 0.65 : 0.65
    }
    
    func backgroundOpacity() -> Double {
        if mouseDown {
            return colorScheme == .dark ? 0.16 : 0.75
        } else if isHovered {
            return colorScheme == .dark ? 0.08 : 0.4
        }
        return 0
    }
    
}

extension ToolbarButton where Content == Text {
    init(_ title: String, action: @escaping () -> Void) {
        self.action = action
        self.content = { Text(title) }
    }
}
