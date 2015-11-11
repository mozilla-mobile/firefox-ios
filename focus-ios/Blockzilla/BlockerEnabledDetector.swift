/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers
import SafariServices
import SnapKit

class BlockerEnabledDetector: NSObject, SFSafariViewControllerDelegate {
    private let server = GCDWebServer()

    private var svc: SFSafariViewController!
    private var callback: (Bool -> ())!
    private var blocked = false

    override init() {
        super.init()

        server.addHandlerForMethod("GET", path: "/focus-detector", requestClass: GCDWebServerRequest.self) { [weak self] request -> GCDWebServerResponse! in
            if let loadedBlockedPage = request.query["blocked"] as? String where loadedBlockedPage == "1" {
                // Second page loaded, so we aren't blocked.
                self?.blocked = false
                return nil
            }

            // The blocker list is loaded asynchronously, so the first page load of the SVC may not be blocked
            // even if we have a block rule enabled. As a workaround, try redirecting to a second page; if it
            // still loads, assume the blocker isn't enabled.
            return GCDWebServerDataResponse(HTML: "<html><head><meta http-equiv=\"refresh\" content=\"0; url=/focus-detector?blocked=1\"></head></html>")
        }

        server.startWithPort(0, bonjourName: nil)
    }

    func detectEnabled(parentView: UIView, callback: Bool -> ()) {
        guard self.svc == nil && self.callback == nil else { return }

        blocked = true
        self.callback = callback

        let detectURL = NSURL(string: "http://localhost:\(server.port)/focus-detector")!
        svc = SFSafariViewController(URL: detectURL)
        svc.delegate = self
        parentView.addSubview(svc.view)
    }

    func safariViewController(controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        // The trigger page loaded; now try loading the blocked page. We don't get any callback if the page
        // was blocked, so set an arbitrary timeout.
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(100 * Double(NSEC_PER_MSEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.svc.view.removeFromSuperview()
            self.svc = nil
            self.callback(self.blocked)
            self.callback = nil
        }
    }

    deinit {
        server.stop()
    }
}
