/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit
import Shared

struct TopSitesProvider: TimelineProvider {
    public typealias Entry = TopSitesEntry

    func placeholder(in context: Context) -> TopSitesEntry {
        return TopSitesEntry(date: Date(), favicons: [String: Image](), sites: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TopSitesEntry) -> Void) {
        var tabFaviconDictionary = [String : Image]()
        let widgetKitTopSites = WidgetKitTopSiteModel.get()
        for site in widgetKitTopSites {
            guard !site.imageKey.isEmpty else { continue }
            let fetchedImage = FaviconFetcher.getFaviconFromDiskCache(imageKey: site.imageKey)
            let bundledFavicon = getBundledFaviconWithBackground(siteUrl: site.url)
            let letterFavicon = FaviconFetcher.letter(forUrl: site.url)
            let image = bundledFavicon ?? fetchedImage ?? letterFavicon
            tabFaviconDictionary[site.imageKey] = Image(uiImage: image)
        }

        let topSitesEntry = TopSitesEntry(date: Date(), favicons: tabFaviconDictionary, sites: widgetKitTopSites)
        completion(topSitesEntry)
    }
    
    func getBundledFaviconWithBackground(siteUrl: URL) -> UIImage? {
        // Get the bundled favicon if available
        guard let bundled = FaviconFetcher.getBundledIcon(forUrl: siteUrl), let image = UIImage(contentsOfFile: bundled.filePath) else { return nil }
        // Add background and padding
        let color = bundled.bgcolor.components.alpha < 0.01 ? UIColor.white : bundled.bgcolor
        return image.withBackgroundAndPadding(color: color)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TopSitesEntry>) -> Void) {
        getSnapshot(in: context, completion: { topSitesEntry in
            let timeline = Timeline(entries: [topSitesEntry], policy: .atEnd)
            completion(timeline)
        })
    }
}

struct TopSitesEntry: TimelineEntry {
    let date: Date
    let favicons: [String : Image]
    let sites: [WidgetKitTopSiteModel]
}

fileprivate extension UIImage {
  func withBackgroundAndPadding(color: UIColor, opaque: Bool = true) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        
    guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
    defer { UIGraphicsEndImageContext() }
        
    // Pad the image in a bit to make the favicons look better
    let newSize = CGSize(width: size.width - 20, height: size.height - 20)
    let rect = CGRect(origin: .zero, size: size)
    let imageRect = CGRect(origin: CGPoint(x: 10, y: 10), size: newSize)
    ctx.setFillColor(color.cgColor)
    ctx.fill(rect)
    ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
    ctx.draw(image, in: imageRect)
        
    return UIGraphicsGetImageFromCurrentImageContext() ?? self
  }
}

fileprivate extension UIColor {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}
