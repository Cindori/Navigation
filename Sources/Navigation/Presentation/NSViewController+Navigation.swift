//
//  NSViewController+Navigation.swift
//  SenseiKit
//
//  Created by Oskar Groth on 2019-01-25.
//  Copyright © 2019 Oskar Groth. All rights reserved.
//

import AppKit
import ObjectiveC

public extension NSViewController {
    
    //TODO: This should be a Coordinator, not navigator
    var _navigator: Navigator? {
        return navigationWrapper?.navigationController?.navigator
    }

    /// Returns the immediate parent cast to NavigationWrapperViewController, if present.
    internal var navigationWrapper: NavigationWrapperViewController? {
        return parent as? NavigationWrapperViewController
    }
}
