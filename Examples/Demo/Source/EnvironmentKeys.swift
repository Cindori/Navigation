//
//  EnvironmentKeys.swift
//  TestApp
//
//  Created by Oskar Groth on 2025-05-13.
//

import SwiftUI

private struct DemoSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Demo>? = nil
}

extension EnvironmentValues {
    var demoSelection: Binding<Demo>? {
        get { self[DemoSelectionKey.self] }
        set { self[DemoSelectionKey.self] = newValue }
    }
}
