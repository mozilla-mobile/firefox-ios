// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
    // if not, use the fallback path generated from the path to the current swift file. Running from
    // an xcodeproj will use fallbackPath.
    private let fallbackRootDirectoryPath: String = (#file as NSString).deletingLastPathComponent + "/../.."
    private let outputDirectory: URL
    private let rootDirectory: String
    private let inputDirectory: String

    init(fileManager: FileManager = FileManager.default,
         jsonHelper: JsonHelper = JsonHelper()) {
        self.fileManager = fileManager
        self.jsonHelper = jsonHelper

        let execIsFromCorrectDir = fileManager.fileExists(atPath: fileManager.currentDirectoryPath + "/Package.swift")
        self.rootDirectory = execIsFromCorrectDir ? fileManager.currentDirectoryPath : fallbackRootDirectoryPath
        self.outputDirectory = URL(fileURLWithPath: "\(rootDirectory)/../ContentBlockingLists")
        self.inputDirectory = "\(rootDirectory)/../shavar-prod-lists"

        createDirectory()
    }

    func getEntityList() -> [String: Any] {
        let entityPath = FileCategory.entity.getPath(inputDirectory: inputDirectory)
        return jsonHelper.jsonEntityListFrom(filename: entityPath)
    }

    func getCategoryFile(categoryTitle: FileCategory) -> [String] {
        let fileName = categoryTitle.getPath(inputDirectory: inputDirectory)
        return jsonHelper.jsonListFrom(filename: fileName)
    }

    func write(fileContent: String, categoryTitle: FileCategory, actionType: ActionType) {
        let fileLocation = categoryTitle.getOutputFile(outputDirectory: outputDirectory.path, actionType: actionType)
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
            try fileManager.removeItem(at: outputDirectory)
        } catch {
            // Possibly can't remove and this is fine. Creating directory is the crucial part here.
        }

        do {
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: false, attributes: nil)
        } catch {
            fatalError("Could not create directory at \(outputDirectory)")
        }
    }
}
