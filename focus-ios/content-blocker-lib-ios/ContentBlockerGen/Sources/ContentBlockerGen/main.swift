/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import ContentBlockerGenLib

let fm = FileManager.default
let fallbackPath: String = (#file as NSString).deletingLastPathComponent + "/../.."
// We expect this command to be executed as 'cd <dir of swift package>; swift run', if not, use the fallback path generated from the path to main.swift. Running from an xcodeproj will use fallbackPath.
let execIsFromCorrectDir = fm.fileExists(atPath: fm.currentDirectoryPath + "/Package.swift")
let rootdir = execIsFromCorrectDir ? fm.currentDirectoryPath : fallbackPath
let blacklist = "\(rootdir)/../../shavar-prod-lists/disconnect-blacklist.json"
let entityList = "\(rootdir)/../../shavar-prod-lists/disconnect-entitylist.json"
let fingerprintingList = "\(rootdir)/../../shavar-prod-lists/normalized-lists/base-fingerprinting-track.json"

func jsonFrom(filename: String) -> [String: Any] {
    let file = URL(fileURLWithPath: filename)
    let data = try! Data(contentsOf: file)
    return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
}

let gen = ContentBlockerGenLib(entityListJson: jsonFrom(filename: entityList))

let outputDir = URL(fileURLWithPath: "\(rootdir)/../../Lists")

func write(to outputDir: URL, action: Action, categories: [CategoryTitle]) {
    for categoryTitle in categories {
        let result = gen.parseBlacklist(json: jsonFrom(filename: blacklist), action: action, categoryTitle: categoryTitle)
        let outputFile = "\(outputDir.path)/disconnect-\(categoryTitle.rawValue.lowercased()).json"
        let output = "[\n" + result.joined(separator: ",\n") + "\n]"
        removeAndReplace(filePath: outputFile, output: output)
    }
}

func removeAndReplace(filePath: String, output: String) {
    if fm.fileExists(atPath: filePath) {
        do {
            try fm.removeItem(atPath: filePath)
        } catch let error {
            print("error occurred, here are the details:\n \(error)")
        }
    }
    try! output.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8)
}

write(to: outputDir, action: .blockAll, categories: [.Advertising, .Analytics, .Social, .Content])
