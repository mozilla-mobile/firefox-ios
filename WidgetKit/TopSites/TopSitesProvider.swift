/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Commenting it out until it is refactored

/*

import SwiftUI
import WidgetKit
import Shared
import Storage
import SyncTelemetry

struct TopSitesProvider: TimelineProvider {
    public typealias Entry = TopSitesEntry

    func placeholder(in context: Context) -> TopSitesEntry {
        return TopSitesEntry(date: Date(), favicons: [String: Image](), sites: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TopSitesEntry) -> Void) {
        let profile = BrowserProfile(localName: "profile")
        TopSitesHandler.getTopSites(profile: profile).uponQueue(.main) { topSites in

            let faviconFetchGroup = DispatchGroup()
            var tabFaviconDictionary = [String : Image]()
            
            // Concurrently fetch each of the top sites icons
            for site in topSites {
                faviconFetchGroup.enter()
                
                // Get the bundled top site favicon, if available
                if let siteURL = URL(string: site.url) {
                    if let bundled = FaviconFetcher.getBundledIcon(forUrl: siteURL),
                       let uiImage = UIImage(contentsOfFile: bundled.filePath) {
                        let color = bundled.bgcolor.components.alpha < 0.01 ? UIColor.white : bundled.bgcolor
                        
                        tabFaviconDictionary[site.url] = Image(uiImage: uiImage.withBackgroundAndPadding(color: color))
                        faviconFetchGroup.leave()
                    } else {
                        // Fetch the favicon from the faviconURL if available
                        if let faviconPath = site.icon?.url, let faviconURL = URL(string: faviconPath) {
                            getImageForUrl(faviconURL, completion: { image in
                                if image != nil {
                                    tabFaviconDictionary[site.url] = image
                                }
                                faviconFetchGroup.leave()
                                
                            })
                        } else {
                            faviconFetchGroup.leave()
                        }
                    }
                } else {
                    faviconFetchGroup.leave()
                }
            }

            faviconFetchGroup.notify(queue: .main) {
                let topSitesEntry = TopSitesEntry(date: Date(), favicons: tabFaviconDictionary, sites: topSites)

                completion(topSitesEntry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TopSitesEntry>) -> Void) {
        getSnapshot(in: context, completion: { topSitesEntry in
            let timeline = Timeline(entries: [topSitesEntry], policy: .atEnd)
            completion(timeline)
        })
    }

    fileprivate func tabsStateArchivePath() -> String? {
        let profilePath: String?
        profilePath = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?.appendingPathComponent("profile.profile").path
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("tabsState.archive").path
    }
}

struct TopSitesEntry: TimelineEntry {
    let date: Date
    let favicons: [String : Image]
    let sites: [Site]
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

*/
