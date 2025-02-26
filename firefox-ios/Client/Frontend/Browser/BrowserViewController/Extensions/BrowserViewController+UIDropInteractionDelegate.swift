// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import enum MozillaAppServices.VisitType

extension BrowserViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        // Prevent tabs from being dragged and dropped into the address bar.
        if let localDragSession = session.localDragSession,
           let item = localDragSession.items.first,
           item.localObject != nil {
            return false
        }

        return session.canLoadObjects(ofClass: URL.self)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let tab = tabManager.selectedTab else { return }

        TelemetryWrapper.recordEvent(category: .action, method: .drop, object: .url, value: .browser)

        _ = session.loadObjects(ofClass: URL.self) { urls in
            guard let draggedUrl = urls.first, let url = URIFixup.getURL(draggedUrl.absoluteString) else { return }

            self.finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: tab)
        }
    }
}
