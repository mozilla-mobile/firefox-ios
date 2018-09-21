/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import GCDWebServers
import SafariServices
import SnapKit

typealias EnabledCallback = (Bool) -> ()

class BlockerEnabledDetector: NSObject {
    fileprivate override init() {}

    func detectEnabled(_ parentView: UIView, callback: @escaping EnabledCallback) {}

    static func makeInstance() -> BlockerEnabledDetector {
        if #available(iOS 10.0, *) {
            return BlockerEnabledDetector10()
        }

        return BlockerEnabledDetector9()
    }
}

private class BlockerEnabledDetector9: BlockerEnabledDetector, SFSafariViewControllerDelegate {
    private let server = GCDWebServer()

    private var svc: SFSafariViewController!
    private var callback: ((Bool) -> ())!
    private var enabled = false

    override init() {
        super.init()

        server?.addHandler(forMethod: "GET", path: "/enabled-detector", request: GCDWebServerRequest.self) { [weak self] request -> GCDWebServerResponse? in
            if let loadedBlockedPage = request?.query["blocked"] as? String , loadedBlockedPage == "1" {
                // Second page loaded, so we aren't blocked.
                self?.enabled = false
                return nil
            }

            // The blocker list is loaded asynchronously, so the first page load of the SVC may not be blocked
            // even if we have a block rule enabled. As a workaround, try redirecting to a second page; if it
            // still loads, assume the blocker isn't enabled.
            return GCDWebServerDataResponse(html: "<html><head><meta http-equiv=\"refresh\" content=\"0; url=/enabled-detector?blocked=1\"></head></html>")
        }

        server?.start(withPort: 0, bonjourName: nil)
    }

    override func detectEnabled(_ parentView: UIView, callback: @escaping EnabledCallback) {
        guard self.svc == nil && self.callback == nil else { return }
        guard let server = server else { return }
        
        enabled = true
        self.callback = callback

        let detectURL = URL(string: "http://localhost:\(server.port)/enabled-detector")!
        svc = SFSafariViewController(url: detectURL)
        svc.delegate = self
        parentView.addSubview(svc.view)
    }

    @objc func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        // The trigger page loaded; now try loading the blocked page. We don't get any callback if the page
        // was blocked, so set an arbitrary timeout.
        let delayTime = DispatchTime.now() + Double(Int64(100 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.svc.view.removeFromSuperview()
            self.svc = nil
            self.callback(self.enabled)
            self.callback = nil
        }
    }

    deinit {
        server?.stop()
    }
}

@available(iOS 10.0, *)
private class BlockerEnabledDetector10: BlockerEnabledDetector {
    override func detectEnabled(_ parentView: UIView, callback: @escaping EnabledCallback) {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: AppInfo.contentBlockerBundleIdentifier) { state, error in
            DispatchQueue.main.async {
                guard let state = state else {
                    print("Detection error: \(error!.localizedDescription)")
                    callback(false)
                    return
                }

                callback(state.isEnabled)
            }
        }
    }
}
