//
//  File.swift
//  CindoriKit
//
//  Created by Oskar Groth on 2025-05-10.
//

import Foundation
import SwiftUI

@MainActor
public final class NavigationItem: ObservableObject {
    @Published public var title: String? = nil
    @Published public var index: Int? = nil
    @Published public var backAction: (() -> Void)? = nil
    @Published public var isHidden: Bool = false
    @Published public var transitionDirection: Edge = .trailing
}

struct NavigationItemView: View {
    struct Label: Equatable {
        let title: String?
        let index: Int?
    }
    
    @ObservedObject var item: NavigationItem
    @State var label: Label? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            if let back = item.backAction {
                ToolbarButton(action: back) {
                    Image(systemName: "chevron.left")
                }
            }
            HStack {
                if let title = label?.title {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .opacity(item.isHidden ? 0 : 1)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: item.transitionDirection).combined(with: .opacity.animation(.defaultQuick)),
                                removal: .move(edge: item.transitionDirection == .leading ? .trailing : .leading).combined(with: .opacity.animation(.defaultUltraQuick))
                            )
                        )
                        .id("title-\(label?.index ?? 0)-\(title)")
                }
            }
            .padding(.horizontal, 16) // increase clipping view while keeping position
            .clipped()
            .padding(.leading, -8)
        }
        .animation(.defaultQuick, value: label)
        .animation(.defaultQuick, value: item.backAction != nil)
        .animation(.defaultQuick, value: item.isHidden)
        .onReceive(
            item.$title.combineLatest(item.$index),
            perform: { (title, index) in
                DispatchQueue.main.async { // next frame
                    label = .init(title: title, index: item.index)
                }
            }
        )
    }
}
