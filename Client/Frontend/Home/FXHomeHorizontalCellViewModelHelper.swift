// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

// Helper for view models that configures the FXHomeHorizontalCell
protocol FXHomeHorizontalCellViewModelHelper {
    var siteImageHelper: SiteImageHelper { get }
    func configureCellForGroups(group: ASGroup<Tab>, cell: FxHomeHorizontalCell, indexPath: IndexPath)
    func configureCellForTab(item: Tab, cell: FxHomeHorizontalCell, indexPath: IndexPath)
}

extension FXHomeHorizontalCellViewModelHelper {
    
    func configureCellForGroups(group: ASGroup<Tab>, cell: FxHomeHorizontalCell, indexPath: IndexPath) {
        let firstGroupItem = group.groupedItems.first
        let site = Site(url: firstGroupItem?.lastKnownUrl?.absoluteString ?? "", title: firstGroupItem?.lastTitle ?? "")

        cell.itemTitle.text = group.searchTerm.localizedCapitalized
        cell.faviconImage.image = UIImage(imageLiteralResourceName: "recently_closed").withRenderingMode(.alwaysTemplate)
        cell.descriptionLabel.text = String.localizedStringWithFormat(.FirefoxHomepage.JumpBackIn.GroupSiteCount, group.groupedItems.count)

        getHeroImage(forSite: site) { image in
            guard cell.tag == indexPath.item else { return }
            cell.heroImage.image = image
        }
    }

    func configureCellForTab(item: Tab, cell: FxHomeHorizontalCell, indexPath: IndexPath) {
        let itemURL = item.lastKnownUrl?.absoluteString ?? ""
        let site = Site(url: itemURL, title: item.displayTitle)

        cell.itemTitle.text = site.title
        cell.descriptionLabel.text = site.tileURL.shortDisplayString.capitalized

        /// Sets a small favicon in place of the hero image in case there's no hero image
        getFaviconImage(forSite: site) { image in
            guard cell.tag == indexPath.item else { return }
            cell.faviconImage.image = image

            if cell.heroImage.image == nil {
                cell.fallbackFaviconImage.image = image
            }
        }

        /// Replace the fallback favicon image when it's ready or available
        getHeroImage(forSite: site) { image in
            guard cell.tag == indexPath.item else { return }

            // If image is a square use it as a favicon
            if image?.size.width == image?.size.height {
                cell.fallbackFaviconImage.image = image
                return
            }

            cell.setFallBackFaviconVisibility(isHidden: true)
            cell.heroImage.image = image
        }
    }

    private func getFaviconImage(forSite site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .favicon, shouldFallback: false) { image in
            completion(image)
        }
    }

    private func getHeroImage(forSite site: Site, completion: @escaping (UIImage?) -> Void) {
        siteImageHelper.fetchImageFor(site: site, imageType: .heroImage, shouldFallback: false) { image in
            completion(image)
        }
    }
}
