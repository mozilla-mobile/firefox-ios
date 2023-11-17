// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

final class ConnectionButton: UIButton {
        
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

extension ConnectionButton {
    
    private func configureView() {
        clipsToBounds = false
        imageView?.contentMode = .center
        adjustsImageWhenHighlighted = false
        imageEdgeInsets = .init(top: 0, left: 10, bottom: 0, right: 0)
    }
    
    private func updateButtonImageAccordingToStatus(_ status: WebsiteConnectionTypeStatus) {
        setImage(ConnectionStatusImage.getForStatus(status: status), for: .normal)
    }
    
    func updateAppearanceForStatus(_ status: WebsiteConnectionTypeStatus) {
        updateButtonImageAccordingToStatus(status)
    }
    
    func evaluateNeedingVisbilityForURLScheme(_ urlScheme: String?) -> Bool {
        !["https", "http"].contains(urlScheme ?? "")
    }
}
