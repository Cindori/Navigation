//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-08.
//

import AppKit

extension Collection where Iterator.Element == NSLayoutConstraint {
    
    /// Activates the constraints
    func activate() {
        forEach {
            $0.isActive = true
        }
    }
    
    /// Deactivates the constraints
    func deactivate() {
        forEach {
            $0.isActive = false
        }
    }
    
}



extension NSLayoutConstraint {
    
    /// Represents a set of constraints for use in `UIView.activateConstraintsSet(_ set:)`
    enum ConstraintsSet {
        
        /// Centers the view within its superview.
        case centerInSuperview
        
        /// Pins all edges to the view's superview. Requires a superview.
        case fillSuperview
        
        /// Pins height and width anchors to current view size.
        case pinToSize
        
    }
    
}

extension NSView {
    
    /**
     * Gets self.constraints + superview?.constraints for this particular view
     */
    var immediateConstraints: [NSLayoutConstraint] {
        let constraints = self.superview?.constraints.filter {
            $0.firstItem as? NSView === self || $0.secondItem as? NSView === self
        } ?? []
        return self.constraints + constraints
    }
    
    /**
     * Gets self.constraints + superview?.constraints affecting this particular view
     */
    var immediateConstraintsAffectingSelf: [NSLayoutConstraint] {
        return immediateConstraints.filter {
            $0.firstItem as? NSView === self
        }
    }
    
    /**
     * Crawls up superview hierarchy and gets all constraints that affect this view
     */
    var allConstraints: [NSLayoutConstraint] {
        var view: NSView? = self
        var constraints:[NSLayoutConstraint] = []
        while let currentView = view {
            constraints += currentView.constraints.filter {
                return $0.firstItem as? NSView === self || $0.secondItem as? NSView === self
            }
            view = view?.superview
        }
        return constraints
    }
    
    convenience init(frame: CGRect = .zero, usingConstraints: Bool = false, wantsLayer: Bool = false) {
        self.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = !usingConstraints
        self.wantsLayer = wantsLayer
    }
    
    func activateConstraints(_ set: NSLayoutConstraint.ConstraintsSet) {
        translatesAutoresizingMaskIntoConstraints = false
        switch set {
            case .centerInSuperview:
                constraintsForCenteringInSuperview().activate()
            case .fillSuperview:
                constraintsForPinningEdgesToSuperview().activate()
            case .pinToSize:
                constraintsForSize().activate()
        }
    }
    
    func deactivateConstraints(_ set: NSLayoutConstraint.ConstraintsSet) {
        switch set {
            case .centerInSuperview:
                for setConstraint in constraintsForCenteringInSuperview() {
                    constraints.first(where: { $0 == setConstraint })?.isActive = false
                }
            case .fillSuperview:
                for setConstraint in constraintsForPinningEdgesToSuperview() {
                    constraints.first(where: { $0 == setConstraint })?.isActive = false
                }
            case .pinToSize:
                for setConstraint in constraintsForSize() {
                    constraints.first(where: { $0 == setConstraint })?.isActive = false
                }
        }
    }
    
    /// Returns constraints for pinning all edges to its superview's. Requires a superview.
    ///
    /// - Parameters:
    ///   - adheringToMargins: Constraints to superviews `layoutMarginsGuide` when sets. Defaults to `false`.
    func constraintsForPinningEdgesToSuperview() -> [NSLayoutConstraint] {
        guard let superview = superview else {
            fatalError("Must have a super view to construct constraints")
        }
        return [
            topAnchor.constraint(equalTo: superview.topAnchor),
            leftAnchor.constraint(equalTo: superview.leftAnchor),
            rightAnchor.constraint(equalTo: superview.rightAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ]
    }
    
    /// Returns constraints for centering the view in its superview. Requires a superview.
    func constraintsForCenteringInSuperview() -> [NSLayoutConstraint] {
        guard let superview = superview else {
            fatalError("Must have a super view to construct constraints")
        }
        
        return [
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor)
        ]
        
    }
    
    func constraintsForSize() -> [NSLayoutConstraint] {
        return [
            widthAnchor.constraint(equalToConstant: bounds.width),
            heightAnchor.constraint(equalToConstant: bounds.height)
        ]
    }
}
