// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

import enum MozillaAppServices.VisitType

extension LibraryViewController: LibraryPanelDelegate {
    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        delegate?.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate)
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func libraryPanel(didSelectURL url: URL, visitType: VisitType) {
        delegate?.libraryPanel(didSelectURL: url, visitType: visitType)
        dismiss(animated: true, completion: nil)
    }

    var libraryPanelWindowUUID: WindowUUID {
        return windowUUID
    }
}
