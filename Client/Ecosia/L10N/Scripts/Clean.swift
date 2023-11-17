/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private final class Translations {
    private var keys = Set<String>()
    private let strings: [String : String]
    private static let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    private static let strings = directory.appendingPathComponent("Client/Ecosia/L10N/en.lproj/Ecosia.strings")
    private static let keys = directory.appendingPathComponent("Client/Ecosia/L10N/String.swift")

    init() {
        strings = Translations.strings.asLines.filter {
            $0.hasPrefix("\"")
        }.reduce(into: [:]) {
            let equals = $1.components(separatedBy: "\" = \"")
            let key = String(equals.first!.dropFirst())
            let value = String(equals.last!.dropLast(2))
            if $0[key] == nil {
                $0[key] = value
            } else {
                print("repeated \(key)")
            }
        }
        
        keys = Translations.keys.asLines.filter {
            $0.hasPrefix("case")
        }.reduce(into: []) {
            let equals = $1.components(separatedBy: " = \"")
            $0.insert(.init(equals.last!.dropLast()))
        }
    }
    
    func save() {
        let filtered = strings.filter { keys.contains($0.0) }.keys.sorted()
        let result = filtered.reduce(into: "") {
            $0 += "\"" + $1 + "\" = \"" + strings[$1]! + "\";\n"
        }
        
        try! Data(result.utf8).write(to: Translations.strings, options: .atomic)
        
        print("Read: \(strings.count); wrote: \(filtered.count) translations!")
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

Translations().save()
