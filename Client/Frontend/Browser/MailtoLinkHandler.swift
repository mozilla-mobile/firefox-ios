/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

public class MailtoLinkHandler {

    lazy var mailSchemeProviders: [String:MailProvider] = self.fetchMailSchemeProviders()

    func launchMailClientForScheme(scheme: String, metadata: MailToMetadata, defaultMailtoURL: NSURL) {
        guard let provider = mailSchemeProviders[scheme], let mailURL = provider.newEmailURLFromMetadata(metadata) else {
            UIApplication.sharedApplication().openURL(defaultMailtoURL)
            return
        }

        if UIApplication.sharedApplication().canOpenURL(mailURL) {
            UIApplication.sharedApplication().openURL(mailURL)
        } else {
            UIApplication.sharedApplication().openURL(defaultMailtoURL)
        }
    }

    func fetchMailSchemeProviders() -> [String:MailProvider] {
        var providerDict = [String:MailProvider]()
        if let path = NSBundle.mainBundle().pathForResource("MailSchemes", ofType: "plist"), let dictRoot = NSArray(contentsOfFile: path) {
            dictRoot.forEach({ dict in
                let scheme = dict["scheme"] as! String
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
                }
            })
        }
        return providerDict
    }
}
