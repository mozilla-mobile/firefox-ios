// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import ComponentLibrary

class FakespotImageLoadingView: UIImageView, ThemeApplicable {
    private enum UX {
        static let minimumAlpha: CGFloat = 0.25
    }

    private let imageCache = URLCache.shared
    var theme: Theme?

    // MARK: Image Loading
    @MainActor
    func loadImage(from url: URL) async {
        if let cachedData = imageCache.cachedResponse(for: URLRequest(url: url))?.data,
           let image = UIImage(data: cachedData) {
            self.image = image
            return
        }

        do {
            startLoadingAnimation()
            self.image = nil

            let (data, response) = try await URLSession.shared.data(from: url)
            let cacheData = CachedURLResponse(response: response, data: data)
            imageCache.storeCachedResponse(cacheData, for: URLRequest(url: url))

            if let image = UIImage(data: data) {
                self.image = image
                stopLoadingAnimation()
            }
        } catch {
            stopLoadingAnimation()
            guard let colors = theme?.colors else { return }
            backgroundColor = colors.layer3
        }
    }

    // MARK: Animations
    private func startLoadingAnimation() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            alpha = UX.minimumAlpha
            return
        }
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.alpha = UX.minimumAlpha
        }

        backgroundColor = theme?.colors.layer3
    }

    private func stopLoadingAnimation() {
        layer.removeAllAnimations()

        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 1.0
        })
        backgroundColor = .clear
    }

    func applyTheme(theme: Theme) {
        self.theme = theme
    }
}
