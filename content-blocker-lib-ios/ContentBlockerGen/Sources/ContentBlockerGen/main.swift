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
let blocklist = "\(rootdir)/../../Carthage/Checkouts/shavar-prod-lists/disconnect-blacklist.json"
let entityList = "\(rootdir)/../../Carthage/Checkouts/shavar-prod-lists/disconnect-entitylist.json"
let fingerprintingList = "\(rootdir)/../../Carthage/Checkouts/shavar-prod-lists/normalized-lists/base-fingerprinting-track.json"

func jsonFrom(filename: String) -> [String: Any] {
    let file = URL(fileURLWithPath: filename)
    let data = try! Data(contentsOf: file)
    return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
}

let gen = ContentBlockerGenLib(entityListJson: jsonFrom(filename: entityList))

// Remove and create the output dir
let outputDir = URL(fileURLWithPath: "\(rootdir)/../Lists")
try? fm.removeItem(at: outputDir)
try! fm.createDirectory(at: outputDir, withIntermediateDirectories: false, attributes: nil)

func write(to outputDir: URL, action: Action, categories: [CategoryTitle]) {
    for categoryTitle in categories {
        let result = gen.parseBlocklist(json: jsonFrom(filename: blocklist), action: action, categoryTitle: categoryTitle)
        let actionName = action == .blockAll ? "block" : "block-cookies"
        let outputFile = "\(outputDir.path)/disconnect-\(actionName)-\(categoryTitle.rawValue.lowercased()).json"
        let output = "[\n" + result.joined(separator: ",\n") + "\n]"
        try! output.write(to: URL(fileURLWithPath: outputFile), atomically: true, encoding: .utf8)
    }
}

write(to: outputDir, action: .blockAll, categories: [.Advertising, .Analytics, .Social, .Cryptomining])
write(to: outputDir, action: .blockCookies, categories: [.Advertising, .Analytics, .Social, .Content])

func writeFingerprintingList(_ path: String, to outputDir: URL) {
    let file = URL(fileURLWithPath: path)
    let data = try! Data(contentsOf: file)
    let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String]
    let result = gen.parseFingerprintingList(json: json)
    let outputFile = "\(outputDir.path)/disconnect-block-fingerprinting.json"
    let output = "[\n" + result.joined(separator: ",\n") + "\n]"
    try! output.write(to: URL(fileURLWithPath: outputFile), atomically: true, encoding: .utf8)
}

writeFingerprintingList(fingerprintingList, to: outputDir)
