// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

protocol ContentBlockerFileManager {
    func getEntityList() -> [String: Any]
    func getCategoryFile(categoryTitle: FileCategory) -> [String]
    func write(fileContent: String, categoryTitle: FileCategory, actionType: ActionType)
}

struct DefaultContentBlockerFileManager: ContentBlockerFileManager {

    private let jsonHelper: JsonHelper
    private let fileManager: FileManager
    // We expect this command to be executed as 'cd <dir of swift package>; swift run',
    // if not, use the fallback path generated from the path to main.swift. Running from
    // an xcodeproj will use fallbackPath.
    private let fallbackPath: String = (#file as NSString).deletingLastPathComponent + "/../.."
    private let outputDir: URL
    private let rootDirectory: String

    init(fileManager: FileManager = FileManager.default,
         jsonHelper: JsonHelper = JsonHelper()) {
        self.fileManager = fileManager
        self.jsonHelper = jsonHelper

        let execIsFromCorrectDir = fileManager.fileExists(atPath: fileManager.currentDirectoryPath + "/Package.swift")
        self.rootDirectory = execIsFromCorrectDir ? fileManager.currentDirectoryPath : fallbackPath
        self.outputDir = URL(fileURLWithPath: "\(rootDirectory)/../Lists")

        createDirectory()
    }

    func getEntityList() -> [String: Any] {
        let entityPath = FileCategory.entity.getPath(rootDirectory: rootDirectory)
        return jsonHelper.jsonEntityListFrom(filename: entityPath)
    }

    func getCategoryFile(categoryTitle: FileCategory) -> [String] {
        let fileName = categoryTitle.getPath(rootDirectory: rootDirectory)
        return jsonHelper.jsonListFrom(filename: fileName)
    }

    func write(fileContent: String, categoryTitle: FileCategory, actionType: ActionType) {
        let fileLocation = categoryTitle.getOutputFile(outputDirectory: outputDir.path, actionType: actionType)
        let fileURL = URL(fileURLWithPath: fileLocation)

        do {
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            fatalError("Could not write to file \(categoryTitle.rawValue) with action \(actionType.rawValue)")
        }
    }

    /// Remove and create the output dir
    private func createDirectory() {
        do {
            try fileManager.removeItem(at: outputDir)
            try fileManager.createDirectory(at: outputDir, withIntermediateDirectories: false, attributes: nil)
        } catch {
            fatalError("Could not create directory")
        }
    }
}
