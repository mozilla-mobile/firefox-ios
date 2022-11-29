// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
    // We expect this command to be executed as 'cd <dir of swift package>; swift run',
    // if not, use the fallback path generated from the path to main.swift. Running from
    // an xcodeproj will use fallbackPath.
    private let fallbackPath: String = (#file as NSString).deletingLastPathComponent + "/../.."
    private let contentBlockerParser: ContentBlockerParser
    private let outputDir: URL
    private let rootDirectory: String

    init(fileManager: FileManager = FileManager.default,
         contentBlockerParser: ContentBlockerParser = ContentBlockerParser()) {
        self.fileManager = fileManager
        self.contentBlockerParser = contentBlockerParser

        let execIsFromCorrectDir = fileManager.fileExists(atPath: fileManager.currentDirectoryPath + "/Package.swift")
        self.rootDirectory = execIsFromCorrectDir ? fileManager.currentDirectoryPath : fallbackPath

        self.outputDir = URL(fileURLWithPath: "\(rootDirectory)/../Lists")
        let entityList = FileCategory.entity.getPath(rootDirectory: rootDirectory)
        let jsonList = JsonHelper().jsonEntityListFrom(filename: entityList)
        contentBlockerParser.parseEntityList(json: jsonList)

        createDirectory()
    }

    func generateList() {
        write(to: outputDir, actionType: .blockAll, categories: [.advertising, .analytics, .social, .cryptomining, .fingerprinting])
        write(to: outputDir, actionType: .blockCookies, categories: [.advertising, .analytics, .social])
    }

    // MARK: - Private

    /// Remove and create the output dir
    private func createDirectory() {
        do {
            try fileManager.removeItem(at: outputDir)
            try fileManager.createDirectory(at: outputDir, withIntermediateDirectories: false, attributes: nil)
        } catch {
            fatalError("Could not create directory")
        }
    }

    private func write(to outputDir: URL,
                       actionType: ActionType,
                       categories: [FileCategory]) {

        for categoryTitle in categories {
            let fileContent = generateFileContent(actionType: actionType, categoryTitle: categoryTitle)
            let fileLocation = categoryTitle.getOutputFile(outputDirectory: outputDir.path, actionType: actionType)
            let fileURL = URL(fileURLWithPath: fileContent)

            do {
                try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                fatalError("Could not write to file \(categoryTitle.rawValue) with action \(actionType.rawValue)")
            }
        }
    }

    private func generateFileContent(actionType: ActionType,
                                     categoryTitle: FileCategory) -> String {

        let fileName = categoryTitle.getPath(rootDirectory: rootDirectory)
        let jsonFile = JsonHelper().jsonListFrom(filename: fileName)
        let result = contentBlockerParser.newParseFile(json: jsonFile,
                                                       actionType: actionType,
                                                       categoryTitle: categoryTitle)


        return "[\n" + result.joined(separator: ",\n") + "\n]"
    }
}
