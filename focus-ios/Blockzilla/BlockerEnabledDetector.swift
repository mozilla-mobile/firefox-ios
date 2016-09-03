/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers
import SafariServices
import SnapKit

// The alpha to use to hide SFSafariViewController's view.
// Why 0.05 and not 0? Because if the alpha is lower than 0.05, the SFSVC
// will refuse to load the URL. Setting view.hidden = true also doesn't work.
private let HiddenViewAlpha: CGFloat = 0.05

class BlockerEnabledDetector: NSObject, SFSafariViewControllerDelegate {
    private let server = GCDWebServer()

    private var svc: SFSafariViewController!
    private var callback: (Bool -> ())!
    private var blocked = false

    override init() {
        super.init()

        server.addHandlerForMethod("GET", path: "/enabled-detector", requestClass: GCDWebServerRequest.self) { [weak self] request -> GCDWebServerResponse! in
            if let loadedBlockedPage = request.query["blocked"] as? String where loadedBlockedPage == "1" {
                // Second page loaded, so we aren't blocked.
                self?.blocked = false
                return nil
            }

            // The blocker list is loaded asynchronously, so the first page load of the SVC may not be blocked
            // even if we have a block rule enabled. As a workaround, try redirecting to a second page; if it
            // still loads, assume the blocker isn't enabled.
            return GCDWebServerDataResponse(HTML: "<html><head><meta http-equiv=\"refresh\" content=\"0; url=/enabled-detector?blocked=1\"></head></html>")
        }

        server.startWithPort(0, bonjourName: nil)
    }

    func detectEnabled(parentVC: UIViewController, callback: Bool -> ()) {
        guard self.svc == nil && self.callback == nil else { return }

        blocked = true
        self.callback = callback

        let detectURL = NSURL(string: "http://localhost:\(server.port)/enabled-detector")!
        svc = SFSafariViewController(URL: detectURL)
        svc.delegate = self

        parentVC.presentViewController(svc, animated: false, completion: nil)
        svc.view.alpha = HiddenViewAlpha
    }

    func safariViewController(controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        // The trigger page loaded; now try loading the blocked page. We don't get any callback if the page
        // was blocked, so set an arbitrary timeout.
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(100 * Double(NSEC_PER_MSEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            controller.dismissViewControllerAnimated(false, completion: nil)
            self.svc = nil
            self.callback(self.blocked)
            self.callback = nil
        }
    }

    deinit {
        server.stop()
    }
}
