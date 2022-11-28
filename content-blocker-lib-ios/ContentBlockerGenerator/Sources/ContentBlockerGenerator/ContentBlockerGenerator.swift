// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

// We expect this command to be executed as 'cd <dir of swift package>; swift run',
// if not, use the fallback path generated from the path to main.swift. Running from
// an xcodeproj will use fallbackPath.

import Foundation

@main
public struct ContentBlockerGenerator {

    static let shared = ContentBlockerGenerator()

    // Static main needs to be used for executable, providing a shared instance so we can
    // call it from the terminal, while also keeping the init() for unit tests.
    public static func main() {
        shared.generateList()
    }

    private let fileManager: FileManager
    private let fallbackPath: String = (#file as NSString).deletingLastPathComponent + "/../.."
    private let contentBlockerParser: ContentBlockerParser
    private let outputDir: URL
    private let rootdir: String

    init(fileManager: FileManager = FileManager.default,
         contentBlockerParser: ContentBlockerParser = ContentBlockerParser()) {
        self.fileManager = fileManager
        self.contentBlockerParser = contentBlockerParser

        let execIsFromCorrectDir = fileManager.fileExists(atPath: fileManager.currentDirectoryPath + "/Package.swift")
        rootdir = execIsFromCorrectDir ? fileManager.currentDirectoryPath : fallbackPath
        outputDir = URL(fileURLWithPath: "\(rootdir)/../Lists")

        let entityList = "\(rootdir)/../../shavar-prod-lists/disconnect-entitylist.json"
        contentBlockerParser.parseEntityList(json: jsonFrom(filename: entityList))

        createDirectory()
    }

    func generateList() {
        write(to: outputDir, action: .blockAll, categories: [.Advertising, .Analytics, .Social, .Cryptomining])
        write(to: outputDir, action: .blockCookies, categories: [.Advertising, .Analytics, .Social, .Content])
    }

    private func createDirectory() {
        // Remove and create the output dir
        try? fileManager.removeItem(at: outputDir)
        try! fileManager.createDirectory(at: outputDir, withIntermediateDirectories: false, attributes: nil)
    }

    private func write(to outputDir: URL, action: Action, categories: [CategoryTitle]) {
        for categoryTitle in categories {
            let blocklist = "\(rootdir)/../../shavar-prod-lists/disconnect-blacklist.json"
            let result = contentBlockerParser.parseBlocklist(json: jsonFrom(filename: blocklist),
                                                             action: action,
                                                             categoryTitle: categoryTitle)
            let actionName = action == .blockAll ? "block" : "block-cookies"
            let outputFile = "\(outputDir.path)/disconnect-\(actionName)-\(categoryTitle.rawValue.lowercased()).json"
            let output = "[\n" + result.joined(separator: ",\n") + "\n]"
            try! output.write(to: URL(fileURLWithPath: outputFile), atomically: true, encoding: .utf8)
        }
    }

    private func jsonFrom(filename: String) -> [String: Any] {
        let file = URL(fileURLWithPath: filename)
        let data = try! Data(contentsOf: file)
        return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
}
