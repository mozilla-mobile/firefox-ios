/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol AppConfig {
    var adjustFile: String { get }
    var firefoxAppStoreURL: URL { get }
    var productName: String { get }
    var rightsFile: String { get }
    var supportPath: String { get }
    var wordmark: UIImage { get }
}

struct FocusAppConfig: AppConfig {
    let adjustFile = "Adjust-Focus"
    let firefoxAppStoreURL = URL(string: "https://app.adjust.com/gs1ao4")!
    let productName = "Focus"
    let rightsFile = "rights-focus.html"
    let supportPath = "kb/focus"
    let wordmark = #imageLiteral(resourceName: "img_focus_wordmark")
}

struct KlarAppConfig: AppConfig {
    let adjustFile = "Adjust-Klar"
    let firefoxAppStoreURL = URL(string: "https://app.adjust.com/c04cts")!
    let productName = "Klar"
    let rightsFile = "rights-klar.html"
    let supportPath = "products/klar"
    let wordmark = #imageLiteral(resourceName: "img_klar_wordmark")
}
