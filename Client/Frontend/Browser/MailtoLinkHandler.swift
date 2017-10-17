/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

open class MailtoLinkHandler {

    lazy var mailSchemeProviders: [String: MailProvider] = self.fetchMailSchemeProviders()

    func launchMailClientForScheme(_ scheme: String, metadata: MailToMetadata, defaultMailtoURL: URL) {
        guard let provider = mailSchemeProviders[scheme], let mailURL = provider.newEmailURLFromMetadata(metadata) else {
            UIApplication.shared.open(defaultMailtoURL, options: [:])
            return
        }

        if UIApplication.shared.canOpenURL(mailURL) {
            UIApplication.shared.open(mailURL, options: [:])
        } else {
            UIApplication.shared.open(defaultMailtoURL, options: [:])
        }
    }

    func fetchMailSchemeProviders() -> [String: MailProvider] {
        var providerDict = [String: MailProvider]()
        if let path = Bundle.main.path(forResource: "MailSchemes", ofType: "plist"), let dictRoot = NSArray(contentsOfFile: path) {
            dictRoot.forEach({ dict in
                if let schemeDict = dict as? [String: Any], let scheme = schemeDict["scheme"] as? String {
                    if scheme == "readdle-spark://" {
                        providerDict[scheme] = ReaddleSparkIntegration()
                    } else if scheme == "mymail-mailto://" {
                        providerDict[scheme] = MyMailIntegration()
                    } else if scheme == "mailru-mailto://" {
                        providerDict[scheme] = MailRuIntegration()
                    } else if scheme == "airmail://" {
                        providerDict[scheme] = AirmailIntegration()
                    } else if scheme == "ms-outlook://" {
                        providerDict[scheme] = MSOutlookIntegration()
                    } else if scheme == "ymail://" {
                        providerDict[scheme] = YMailIntegration()
                    } else if scheme == "googlegmail://" {
                        providerDict[scheme] = GoogleGmailIntegration()
                    } else if scheme == "inbox-gmail://" {
                        providerDict[scheme] = GoogleInboxIntegration()
                    }
                }
            })
        }
        return providerDict
    }
}
