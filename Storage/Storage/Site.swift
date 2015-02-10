/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol Identifiable {
    var id: Int? { get set }
}

public enum IconType: Int {
    case Icon = 0
    case AppleIcon = 1
    case AppleIconPrecomposed = 2
    case Guess = 3
}

public class Favicon : Identifiable {
    var id: Int? = nil
    var img: UIImage? = nil
    var filename: String {
        if let url = NSURL(string: self.url) {
            if let ext = url.pathExtension {
                return "\(url.hash).\(ext)"
            }
        }
        return "\(url.hash)"
    }

    public let url: String
    public let date: NSDate
    public let width: Int?
    public let height: Int?
    public let type: IconType

    public func getImage(files: FileAccessor) -> UIImage? {
        if img == nil {
            // If there's a file for this url, try to load it
            if let dir = files.getDir("favicons", basePath: nil) {
                if files.exists(filename, basePath: dir) {
                    if let file = files.get(filename, basePath: dir) {
                        img = UIImage(contentsOfFile: file)
                    } else {
                        println("Can't get file \(filename)")
                    }
                } else if let url = NSURL(string: self.url) {
                    // Otherwise, we'll pull from the net
                    if let data = NSData(contentsOfURL: url) {
                        if let path = files.get(self.filename, basePath: dir) {
                            data.writeToFile(path, atomically: true)
                        }
                        img = UIImage(data: data)
                    } else {
                        println("Can't get data \(url)")
                    }
                } else {
                    println("Invalid url \(self.url)")
                }
            } else {
                println("couldn't get favicons dir")
            }
        }

        return img
    }

    public init(url: String, date: NSDate = NSDate(), type: IconType) {
        self.url = url
        self.date = date
        self.type = type
    }
}

public class Site : Identifiable {
    var id: Int? = nil
    var guid: String? = nil

    public let url: String
    public let title: String
     // Sites may have multiple favicons. We'll return the largest.
    public var icon: Favicon?

    public init(url: String, title: String) {
        self.url = url
        self.title = title
    }
}
