//
//  ImportTask.swift
//  ios-l10n-tools
//
//  Created by Jeff Boek on 11/2/20.
//

import Foundation

let generateManifest: (String) -> String = { targetLocale in
    return """
        {
          "developmentRegion" : "en",
          "project" : "Client.xcodeproj",
          "targetLocale" : "\(targetLocale)",
          "toolInfo" : {
            "toolBuildNumber" : "12E262",
            "toolID" : "com.apple.dt.xcode",
            "toolName" : "Xcode",
            "toolVersion" : "12.5"
          },
          "version" : "1.0"
        }
    """
}

struct ImportTask {
    let xcodeProjPath: String
    let l10nRepoPath: String
    let locales: [String]

    private let temporaryDir = FileManager.default.temporaryDirectory.appendingPathComponent("locales_to_import")

    // Pontoon has slightly different keys than Xcode for a handful of locales.
    private let LOCALE_MAPPING = [
        "es-ES": "es",
        "ga-IE": "ga",
        "nb-NO": "nb",
        "nn-NO": "nn",
        "sv-SE": "sv",
        "tl"   : "fil",
        "zgh"  : "tzm",
        "sat"  : "sat-Olck"
    ]

    // We don't want to expose these to our localization team
    private let EXCLUDED_TRANSLATIONS: Set<String> = [
        "CFBundleName",
        "CFBundleDisplayName",
        "CFBundleShortVersionString",
    ]

    // Locales that we do not want to import
    private let EXCLUDED_LOCALES: Set<String> = [
        "en-US", // This is our base language and the source of truth is in the app, not Pontoon
        "es-ES", "lt", "lv" // These are only excluded because they are new and we don't know yet what to do with them
    ]

    // InfoPlist.strings requre these keys to have content or the application will crash
    private let REQUIRED_TRANSLATIONS: Set<String> = [
        "NSCameraUsageDescription",
        "NSLocationWhenInUseUsageDescription",
        "NSMicrophoneUsageDescription",
        "NSPhotoLibraryAddUsageDescription",
        "ShortcutItemTitleNewPrivateTab",
        "ShortcutItemTitleNewTab",
        "ShortcutItemTitleQRCode",
    ]
    
    func createXcloc(locale: String) -> URL {
        let source = URL(fileURLWithPath: "\(l10nRepoPath)/\(locale)/focus-ios.xliff")
        let locale = LOCALE_MAPPING[locale] ?? locale
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("temp.xliff")
        let destination = temporaryDir.appendingPathComponent("\(locale).xcloc/Localized Contents/\(locale).xliff")
        let sourceContentsDestination = temporaryDir.appendingPathComponent("\(locale).xcloc/Source Contents/temp.txt")
        let manifestDestination = temporaryDir.appendingPathComponent("\(locale).xcloc/contents.json")
    
        let fileExists = FileManager.default.fileExists(atPath: tmp.path)
        let destinationExists = FileManager.default.fileExists(atPath: destination.deletingLastPathComponent().path)
        
        if fileExists {
            try! FileManager.default.removeItem(at: tmp)
        }
        
        try! FileManager.default.copyItem(at: source, to: tmp)
        
        if !destinationExists {
            try! FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            try! FileManager.default.createDirectory(at: sourceContentsDestination, withIntermediateDirectories: true)
        }

        try! generateManifest(LOCALE_MAPPING[locale] ?? locale).write(to: manifestDestination, atomically: true, encoding: .utf8)
        return try! FileManager.default.replaceItemAt(destination, withItemAt: tmp)!
    }
    
    func validateXml(fileUrl: URL, locale: String) {
        let xml = try! XMLDocument(contentsOf: fileUrl, options: .nodePreserveWhitespace)
        guard let root = xml.rootElement() else { return }
        let fileNodes =  try! root.nodes(forXPath: "file")
        
        for case let fileNode as XMLElement in fileNodes {
            if let xcodeLocale = LOCALE_MAPPING[locale] {
                fileNode.attribute(forName: "target-language")?.setStringValue(xcodeLocale, resolvingEntities: false)
            }
            
            var translations = try! fileNode.nodes(forXPath: "body/trans-unit")
            for case let translation as XMLElement in translations {
                // Skip translations that we do not care about (CFBundle*)
                if translation.attribute(forName: "id")?.stringValue.map(EXCLUDED_TRANSLATIONS.contains) == true {
                    translation.detach()
                    continue
                }

                // The app will crash if one of the NS* permission prompt strings is empty so
                // in case those are missing, default to the english base for it.
                if translation.attribute(forName: "id")?.stringValue.map(REQUIRED_TRANSLATIONS.contains) == true {
                    let nodes = try! translation.nodes(forXPath: "target")
                    let source = try! translation.nodes(forXPath: "source").first!.stringValue ?? ""
                    if nodes.isEmpty {
                        let element = XMLNode.element(withName: "target", stringValue: source) as! XMLNode
                        translation.insertChild(element, at: 1)
                    }
                }
            }

            // Drop this file if after the above checks, no trans-unit elements remain
            translations = try! fileNode.nodes(forXPath: "body/trans-unit")
            if translations.isEmpty {
                fileNode.detach()
            }
        }
        
        try! xml.xmlString(options: .nodePrettyPrint).write(to: fileUrl, atomically: true, encoding: .utf16)
    }
    
    private func importLocale(xclocPath: URL) {
        let command = "xcodebuild -importLocalizations -project \(xcodeProjPath) -localizationPath \(xclocPath.path)"

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        try! task.run()
        task.waitUntilExit()
    }
    
    private func prepareLocale(locale: String) {
        let xliffUrl = createXcloc(locale: locale)
        validateXml(fileUrl: xliffUrl, locale: locale)
        importLocale(xclocPath: xliffUrl.deletingLastPathComponent().deletingLastPathComponent())
    }

    func run() {
        locales.forEach { locale in
            if !EXCLUDED_LOCALES.contains(locale) {
                print("[*] Processing locale \(locale)")
                prepareLocale(locale: locale)
            }
        }
    }
}
