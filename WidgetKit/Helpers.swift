// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import SwiftUI
import UIKit
import Shared

var scheme: String {
    return URL.mozInternalScheme
}

func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
    let urlString = "\(scheme)://\(query)\(urlSuffix)"
    return URL(string: urlString)!
}

func getImageForUrl(_ url: URL, completion: @escaping (Image?) -> Void) {
    let queue = DispatchQueue.global()

    var fetchImageWork: DispatchWorkItem?

    fetchImageWork = DispatchWorkItem {
        if let data = try? Data(contentsOf: url) {
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    if fetchImageWork?.isCancelled == true { return }

                    completion(Image(uiImage: image))
                    fetchImageWork = nil
                }
            }
        }
    }

    if let imageWork = fetchImageWork {
        queue.async(execute: imageWork)
    }

    // Timeout the favicon fetch request if it's taking too long
    queue.asyncAfter(deadline: .now() + 2) {
        // If we've already successfully called the completion block, early return
        if fetchImageWork == nil { return }

        fetchImageWork?.cancel()
        completion(nil)
    }
}
