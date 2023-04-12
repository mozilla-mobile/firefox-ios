//
//  SummarizeViewController.swift
//

import UIKit
import SwiftUI

public class SummarizeViewController: UIHostingController<SummarizeView> {
    public init(url: URL) {
        super.init(rootView: SummarizeView(url: url))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Adaptive Delegate
extension SummarizeViewController: UIAdaptivePresentationControllerDelegate {
    // Returning None here, for the iPhone makes sure that the Popover is actually presented as a
    // Popover and not as a full-screen modal, which is the default on compact device classes.
    public func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        shouldUseiPadSetup(traitCollection: traitCollection) ? .overFullScreen : .none
    }
}

extension UIViewController {
    func shouldUseiPadSetup(traitCollection: UITraitCollection? = nil) -> Bool {
        let trait = traitCollection == nil ? self.traitCollection : traitCollection
        if UIDevice.current.userInterfaceIdiom == .pad {
            return trait!.horizontalSizeClass != .compact
        }
        
        return false
    }
}
