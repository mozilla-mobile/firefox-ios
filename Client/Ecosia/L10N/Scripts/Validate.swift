/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private final class Translations {
    private var count = [String : Int]()
    private let dictionary: [String : String]
    private static let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    private static let url = directory.appendingPathComponent("Client/Ecosia/L10N/String.swift")
    
    init() {
        dictionary = Translations.url.asLines.filter {
            $0.hasPrefix("case")
        }.reduce(into: [:]) {
            let equals = $1.components(separatedBy: " = \"")
            $0[.init(equals.first!.dropFirst(5))] = .init(equals.last!.dropLast())
        }
    }
    
    func validate() {
        count = dictionary.mapValues { _ in 0 }
        FileManager.default.enumerator(at: Translations.directory, includingPropertiesForKeys: nil, options: [.producesRelativePathURLs, .skipsHiddenFiles, .skipsPackageDescendants])?.forEach {
            let url = $0 as! URL
            guard !url.hasDirectoryPath, url.relativePath.hasSuffix(".swift") else { return }
            Translations.directory.appendingPathComponent(url.relativePath).content
                .components(separatedBy: ".localized(")
                .dropFirst().forEach {
                    count[$0.components(separatedBy: ")").first!.replacingOccurrences(of: ".", with: "")]? += 1
            }
        }
        let unused = count.filter { $0.1 == 0 }.keys.sorted()
        print("Unused keys: (\(unused.count))")
        unused.forEach {
            print($0)
        }
    }
}

private extension URL {
    var asLines: [String] {
        content
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var content: String {
        try! String(data: .init(contentsOf: self), encoding: .utf8)!
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

Translations().validate()
