/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared

/**
 * The sqlite-backed implementation of the metadata protocol containing images and content for pages.
 */
public class SQLitePageMetadata {
    let db: BrowserDB

    required public init(db: BrowserDB) {
        self.db = db
    }
}

extension SQLitePageMetadata: Metadata {
    private typealias CacheKey = String

    // TODO: Theres probably a better query here. Currently, this grabs all of the metadata rows then
    //       performs a query _per_each_object_ to grab it's associated images. To work around the immutable
    //       object returned from the SDRow factory, there's some hackery to assign the images to the
    //       metadata object (see extension defined below).
    public func metadataForSites(sites: [Site]) -> Deferred<Maybe<[PageMetadata]>> {
        let urls = sites.flatMap { $0.url.asURL }
        return metadataForURLs(urls)
    }

    public func metadataForURLs(urls: [NSURL]) -> Deferred<Maybe<[PageMetadata]>> {
        let cacheKeys = urls.flatMap({ cacheKeyForURL($0) })

        let args: Args = cacheKeys
        let query =
        "SELECT pi.* " +
        "FROM \(TablePageMetadata) as pm" +
        "JOIN \(TablePageMetadataImages) AS pmi ON pm.id = pmi.metadata_id " +
        "JOIN \(TablePageImages) AS pi ON pi.id = pmi.image_id" +
        "WHERE id IN \(BrowserDB.varlist(cacheKeys.count))"

        return self.db.runQuery(query, args: args, factory: SQLitePageMetadata.pageMetadataFactory) >>== { metadatas in
            var processedMetadatas: [PageMetadata] = []
            return walk(metadatas.asArray(), f: { metadata in
                return self.imagesForMetadata(metadata) >>== { images in
                    processedMetadatas.append(metadata.setImages(images.asArray()))
                    return succeed()
                }
            }) >>> { return deferMaybe(processedMetadatas) }
        }
    }

    public func storeMetadata(metadata: PageMetadata, forPageURL pageURL: NSURL) -> Success {
        guard let cacheKey = cacheKeyForURL(pageURL) else {
            return succeed()
        }

        let args: Args = [cacheKey, metadata.siteURL, metadata.title, metadata.type, metadata.description, nil, nil]

        let insert =
        "INSERT INTO page_metadata " +
        "(cache_key, site_url, title, type, description, media_url, expired_at) " +
        "VALUES " +
        "\(BrowserDB.varlist(args.count))"

        return self.db.run(insert, withArgs: args)
    }

    private func imagesForMetadata(metadata: PageMetadata) -> Deferred<Maybe<Cursor<PageMetadataImage>>> {
        let args: Args = [metadata.id]
        let query =
        "SELECT pi.* " +
        "FROM \(TablePageMetadata) as pm" +
        "JOIN \(TablePageMetadataImages) AS pmi ON pm.id = pmi.metadata_id " +
        "JOIN \(TablePageImages) AS pi ON pi.id = pmi.image_id" +
        "WHERE id = ?"
        
        return self.db.runQuery(query, args: args, factory: SQLitePageMetadata.pageMetadataImageFactory)
    }

    // A cache key is a conveninent, readable identifier for a site in the metadata database which helps 
    // with deduping entries for the same page.
    private func cacheKeyForURL(url: NSURL) -> CacheKey? {
        var key = url.normalizedHost() ?? ""
        key = key + (url.path ?? "") + (url.query ?? "")
        return key
    }

    private func cacheKeyForURL(urlString: String) -> CacheKey? {
        guard let url = urlString.asURL else {
            return nil
        }
        return cacheKeyForURL(url)
    }

    private class func pageMetadataFactory(row: SDRow) -> PageMetadata {
        let id = row["id"] as! Int
        let siteURL = row["site_url"] as! String
        let title = row["title"] as? String
        let description = row["description"] as? String
        let type = row["type"] as? String
        return PageMetadata(id: id, siteURL: siteURL, title: title, description: description, type: type, images: [])
    }

    private class func pageMetadataImageFactory(row: SDRow) -> PageMetadataImage {
        let imageURL = row["image_url"] as! String
        let type = MetadataImageType(rawValue: row["type"] as! Int)!
        let height = row["height"] as! Int
        let width = row["width"] as! Int
        let color = row["color"] as! String
        return PageMetadataImage(imageURL: imageURL, type: type, height: height, width: width, color: color)
    }
}

private extension PageMetadata {
    func setImages(images: [PageMetadataImage]) -> PageMetadata {
        return PageMetadata(id: id, siteURL: siteURL, title: title, description: description, type: type, images: images)
    }
}
