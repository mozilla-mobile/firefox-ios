/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import MobileCoreServices

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequestWithExtensionContext(context: NSExtensionContext) {
        // NSItemProvider apparently doesn't support multiple attachments as a way to load multiple blocking lists.
        // As a workaround, we load each list into memory, then merge them into a single attachment.
        var mergedList = itemsFromFile("blocker-enabled-detector")

        if Settings.getBool(Settings.KeyBlockAds) ?? false {
            mergedList.appendContentsOf(itemsFromFile("disconnect-advertising"))
        }

        if Settings.getBool(Settings.KeyBlockAnalytics) ?? false {
            mergedList.appendContentsOf(itemsFromFile("disconnect-analytics"))
        }

        if Settings.getBool(Settings.KeyBlockSocial) ?? false {
            mergedList.appendContentsOf(itemsFromFile("disconnect-social"))
        }

        if Settings.getBool(Settings.KeyBlockOther) ?? false {
            mergedList.appendContentsOf(itemsFromFile("disconnect-content"))
        }

        if Settings.getBool(Settings.KeyBlockFonts) ?? false {
            mergedList.appendContentsOf(itemsFromFile("web-fonts"))
        }

        let mergedListJSON = try! NSJSONSerialization.dataWithJSONObject(mergedList, options: NSJSONWritingOptions(rawValue: 0))
        let attachment = NSItemProvider(item: mergedListJSON, typeIdentifier: kUTTypeJSON as String)
        let item = NSExtensionItem()
        item.attachments = [attachment]
        context.completeRequestReturningItems([item], completionHandler: nil)
    }

    /// Gets the dictionary form of the tracking list with the specified file name.
    private func itemsFromFile(name: String) -> [NSDictionary] {
        let url = NSBundle.mainBundle().URLForResource(name, withExtension: "json")
        let data = NSData(contentsOfURL: url!)
        return try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [NSDictionary]
    }
}
