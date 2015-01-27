/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

let TableNameFavicons = "favicons"

/*
* Wrapper around a favicon that adds methods for saving and retrieving locally from disk.
* These would normally be an extension, but I wanted to conceal the storage mechanism (i.e.
* files) from consumers of Favicons */
class SavedFavicon: Favicon {
    let filename: String
    let favicon: Favicon

    private let debug_enabled = true
    private func debug(msg: String) {
        if debug_enabled {
            println("SavedFavicon: " + msg)
        }
    }

    override var guid: String? {
        get { return favicon.guid }
        set { favicon.guid = newValue }
    }

    override var url: String {
        get { return favicon.url }
        set { favicon.url = newValue }
    }

    override var updatedDate: NSDate {
        get { return favicon.updatedDate }
        set { favicon.updatedDate = newValue }
    }

    override var image: UIImage? {
        get {
            if let image = favicon.image {
                return image
            }
            // favicon.image = download(files)
            return favicon.image
        }
        set { favicon.image = newValue }
    }

    private func downloadImage(urlString: String, files: FileAccessor) -> UIImage? {
        if let url = NSURL(string: urlString) {
            if let data = NSData(contentsOfURL: url) {
                if let img = UIImage(data: data) {
                    // Don't bother saving something we can't decode
                    saveImage(filename, data: data, files: files)
                    return img
                }
            }
        }
        return nil
    }

    private func saveImage(filename: String, data: NSData, files: FileAccessor) {
        if let file = files.get(filename) {
            data.writeToFile(file, atomically: true)
        }
    }

    func download(files: FileAccessor) {
        if (!files.exists(self.filename)) {
            favicon.image = downloadImage(favicon.url, files: files)
        } else {
            if let file = files.get(self.filename) {
                favicon.image = UIImage(contentsOfFile: file)
            } else {
                println("Unable get get file for \(self.filename)")
            }
        }
    }

    convenience init(favicon: Favicon) {
        self.init(favicon: favicon, name: SavedFavicon.getFilename(favicon.url))
    }

    class func getFilename(url: String) -> String {
        if let url = NSURL(string: url) {
            if let ext = url.pathExtension {
                return "\(url.hash).\(ext)"
            }
        }
        return "\(url.hash)"
    }

    init(favicon: Favicon, name: String) {
        self.favicon = favicon
        self.filename = name
        super.init(url: favicon.url, image: nil, date: nil)
    }
}

class FaviconsTable<T>: GenericTable<SavedFavicon> {
    let files: FileAccessor
    override var name:String { return TableNameFavicons }
    override var rows: String { return "guid TEXT NOT NULL UNIQUE, " +
                                       "url TEXT NOT NULL UNIQUE, " +
                                       "updatedDate DATE, " +
                                       "file TEXT NOT NULL UNIQUE, " +
                                       "size INT"}

    init(files: FileAccessor) {
        self.files = files
    }

    override func getInsertAndArgs(inout item: SavedFavicon) -> (String, [AnyObject?])? {
        // Runtime errors happen if we let Swift try to infer the type of this array
        // so we construct it very specifically.
        var args = [AnyObject?]()
        if item.guid == nil {
            item.guid = NSUUID().UUIDString
        }
        args.append(item.guid)
        args.append(item.url)
        args.append(item.filename)
        args.append(item.updatedDate.timeIntervalSince1970)
        if let image = item.image {
            args.append(image.size.width)
        } else {
            args.append(0)
        }

        return ("INSERT INTO \(TableNameFavicons) (guid, url, file, updatedDate, size) VALUES (?, ?, ?, ?, ?)", args)
    }

    override func getUpdateAndArgs(inout item: SavedFavicon) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.filename)
        args.append(NSDate().timeIntervalSince1970)
        if let image = item.image {
            args.append(image.size.width)
        } else {
            args.append(0)
        }
        args.append(item.url)
        return ("UPDATE \(TableNameFavicons) SET file = ?, updatedDate = ?, size = ? WHERE url = ?", args)
    }

    override func getDeleteAndArgs(inout item: SavedFavicon?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let favicon = item {
            args.append(favicon.url)
            return ("DELETE FROM \(TableNameFavicons) WHERE url = ?", args)
        }
        return ("DELETE FROM \(TableNameFavicons)", args)
    }

    override var factory: ((row: SDRow) -> SavedFavicon)? {
        return { row -> SavedFavicon in
            var image: UIImage? = nil
            let filename = row[2] as String
            if let data = NSData(contentsOfFile: filename) {
                image = UIImage(data: data)
            }

            let dt = NSTimeInterval(row[3] as Double)
            let favicon = Favicon(url: row[1] as String, image: image, date: NSDate(timeIntervalSince1970: dt))
            favicon.guid = row[0] as? String

            return SavedFavicon(favicon: favicon, name: filename)
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let filter = options?.filter {
            args.append("%\(filter)%")
            return ("SELECT guid, url, file, updatedDate FROM \(TableNameFavicons) WHERE url LIKE ?", args)
        }
        return ("SELECT guid, url, file, updatedDate FROM \(TableNameFavicons)", args)
    }
}
