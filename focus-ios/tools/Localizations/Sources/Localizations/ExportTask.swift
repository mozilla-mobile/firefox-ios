//
//  export.swift
//  ios-l10n-tools
//
//  Created by Jeff Boek on 11/2/20.
//

import Foundation

var LOCALES:[String] = []

struct ExportTask {
    let xcodeProjPath: String
    let l10nRepoPath: String
    
    private let EXCLUDED_FILES: Set<String> = [
    ]
    
    private let EXCLUDED_TRANSLATIONS: Set<String> = [
        "CFBundleName",
        "CFBundleDisplayName",
        "CFBundleShortVersionString",
        "1Password Fill Browser Action"
    ]
    
    // Keys in Info.plist that we require. TODO Does this work because focus does not have that
    // ShortcutItemTitleQRCode and no warnings are raised. This is the Firefox iOS list.
    private let REQUIRED_TRANSLATIONS: Set<String> = [
        "NSCameraUsageDescription",
        "NSLocationWhenInUseUsageDescription",
        "NSMicrophoneUsageDescription",
        "NSPhotoLibraryAddUsageDescription",
        "ShortcutItemTitleNewPrivateTab",
        "ShortcutItemTitleNewTab",
        "ShortcutItemTitleQRCode",
    ]

    // Mapping locale identifiers from Pontoon to Xcode
    private let XCODE_TO_PONTOON = [
        "en" : "en-US",
        "ga" : "ga-IE",
        "nb" : "nb-NO",
        "nn" : "nn-NO",
        "sv" : "sv-SE",
        "fil" : "tl",
    ]
    
    private var EXPORT_BASE_PATH: String {
        "/tmp/ios-localization-\(getpid())"
    }
    
    // Ask xcodebuild to export all locales
    private func exportLocales() {
        
        let command = "xcodebuild -exportLocalizations -project \(xcodeProjPath) -localizationPath \(EXPORT_BASE_PATH)"
        let command2 = LOCALES.map { "-exportLanguage \($0)" }.joined(separator: " ")

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command + " " + command2]
        try! task.run()
        task.waitUntilExit()
    }

    private func getBlockzillaFolder() -> [String] {
        guard let blockzillaFolder = FileManager.default.enumerator(atPath: URL(fileURLWithPath: xcodeProjPath).deletingLastPathComponent().appendingPathComponent("Blockzilla").path),
              let filePaths = blockzillaFolder.allObjects as? [String] else {
                return[]
        }
        return filePaths
    }
    
    // Get Locales that are in the Xcode project
    private func getProjectLocales() -> [String] {
    
        var localesList:[String] = []

        let filePaths = getBlockzillaFolder()

        filePaths.filter { $0.contains(".lproj") }.forEach { path in
            if let index = path.firstIndex(of: ".") {
                let firstPart = path.prefix(upTo: index)
                localesList.append(String(firstPart))
            }
        }
        // Removing duplicates locales as there are several folders/subfolders for same locale
        var uniqueLocales = Array(Set(localesList))
        // Removing Settings from the locales list as it a folder containing locales
        let toRemove = "Settings"
        uniqueLocales = uniqueLocales.filter { $0 != toRemove }
        
        // Alphabetically ordered array for simplicity
        return uniqueLocales.sorted(by:<)
    }

    /// Load all trans-units by id from the old (from checkout)
    private func loadOldTransUnits(forLocale locale: String) -> [String: XMLElement]? {
        var result = [String: XMLElement]()

        let pontoonLocale = XCODE_TO_PONTOON[locale] ?? locale
        let xml = try! XMLDocument(contentsOf: URL(fileURLWithPath: "\(l10nRepoPath)/\(pontoonLocale)/focus-ios.xliff"))
        guard let root = xml.rootElement() else {
            print("[W] No valid XML in \(l10nRepoPath)/\(pontoonLocale)/focus-ios.xliff ?")
            return nil
        }

        for case let file as XMLElement in try! root.nodes(forXPath: "file") {
            // Skip <file> nodes that we do not care about
            if let original = file.attribute(forName: "original")?.stringValue, EXCLUDED_FILES.contains(original) {
                continue
            }
            
            for case let transUnit as XMLElement in try! file.nodes(forXPath: "body/trans-unit") {
                // Skip <trans-unit> nodes that we don't want to translate
                if transUnit.attribute(forName: "id")?.stringValue.map(EXCLUDED_TRANSLATIONS.contains) == true {
                    continue
                }

                if result[transUnit.attribute(forName: "id")!.stringValue!] != nil {
                    print("[F] Unexpected duplicate string id <\(transUnit.attribute(forName: "id")!.stringValue!)>")
                }

                result[transUnit.attribute(forName: "id")!.stringValue!] = transUnit
            }
        }

        return result
    }

    /// Return the string value of the <source> element on a given <trans-unit>. Will
    /// return nil if there is no <source> element.
    private func getSourceText(fromTransUnit element: XMLElement) -> String? {
        if let children = element.children {
            for node in children {
                if node.name == "source" {
                    return node.stringValue
                }
            }
        }
        return nil
    }

    /// Return the string value of the <target> element on a given <trans-unit>. Will
    /// return nil if there is no <target> element.
    private func getTargetText(fromTransUnit element: XMLElement) -> String? {
        if let children = element.children {
            for node in children {
                if node.name == "target" {
                    return node.stringValue
                }
            }
        }
        return nil
    }

    // Process/transform the exported XLIFF
    private func handleXML(path: String, locale: String) {
        let url = URL(fileURLWithPath: path.appending("/\(locale).xcloc/Localized Contents/\(locale).xliff"))
        let xml = try! XMLDocument(contentsOf: url, options: [.nodePreserveWhitespace, .nodeCompactEmptyElement])
        guard let root = xml.rootElement() else {
            print("[W] Locale \(locale) did not have anything to parse?")
            return
        }

        guard let oldTransUnits = loadOldTransUnits(forLocale: locale) else {
            print("[E] Can't load old trans units")
            return
        }

        for case let fileNode as XMLElement in try! root.nodes(forXPath: "file") {
            // Remove <file> nodes that we do not care about
            if let original = fileNode.attribute(forName: "original")?.stringValue, EXCLUDED_FILES.contains(original) {
                print("[I] Skipping excluded file <\(original)>")
                fileNode.detach()
                continue
            }
            
            // Change the target language identifier from Xcode to Pontoon
            if let pontoonLocale = XCODE_TO_PONTOON[locale] {
                fileNode.attribute(forName: "target-language")?.setStringValue(pontoonLocale, resolvingEntities: false)
            }
            
            for case let newTransUnit as XMLElement in try! fileNode.nodes(forXPath: "body/trans-unit") {
                // Delete <trans-unit> nodes that we don't want to translate
                if newTransUnit.attribute(forName: "id")?.stringValue.map(EXCLUDED_TRANSLATIONS.contains) == true {
                    newTransUnit.detach()
                    continue
                }

                // If the new export does not have a <target> then check if the old export had one. If it did then
                // the string was invalidated and it's translation removed. If this is because the <source> string
                // differs only in case changes between old and new then do not invalidate the string. Other
                // invalidations that do not match the above are still exported and can be reviewed manually.
                if let oldTransUnit = oldTransUnits[newTransUnit.attribute(forName: "id")!.stringValue!] {
                    // This is an existing string
                    if getTargetText(fromTransUnit: oldTransUnit) != nil && getTargetText(fromTransUnit: newTransUnit) == nil {
                        // And both old and new have a <source> (unsurprising)
                        if let oldSource = getSourceText(fromTransUnit: oldTransUnit), let newSource = getSourceText(fromTransUnit: newTransUnit) {
                            // If source has changed, but it is only a case change then do not invalidate this string
                            if (oldSource != newSource) && (oldSource.caseInsensitiveCompare(newSource) == .orderedSame) {
                                // Xcode removed <target>, so we put it back.
                                newTransUnit.insertChild(XMLNode.element(withName: "target", stringValue: getTargetText(fromTransUnit: oldTransUnit)!) as! XMLNode, at: 1)
                                newTransUnit.insertChild(XMLNode.text(withStringValue: "\n        ") as! XMLNode, at: 1) // To maintain formatting
                            }
                        }
                    }
                }
            }
            
            // If this <file> node has no translations left then remove it
            let remainingTranslations = try! fileNode.nodes(forXPath: "body/trans-unit")
            if remainingTranslations.isEmpty {
                fileNode.detach()
            }
        }
        
        // Drop the xml:space="preserve" that is being added. XMLDocument adds it but we don't care
        // about it and it adds a lot of noise to the diff.
        let s = xml.xmlString.replacingOccurrences(of: " xml:space=\"preserve\">", with: ">") + "\n\n"
        try! s.write(to: url, atomically: true, encoding: .utf8)
    }
    
    
    // Copy the xliff file from the export into the pontoon repository
    private func copyToL10NRepo(locale: String) {
        let source = URL(fileURLWithPath: "\(EXPORT_BASE_PATH)/\(locale).xcloc/Localized Contents/\(locale).xliff")
        let pontoonLocale = XCODE_TO_PONTOON[locale] ?? locale
        let destination = URL(fileURLWithPath: "\(l10nRepoPath)/\(pontoonLocale)/focus-ios.xliff")
        let _ = try! FileManager.default.replaceItemAt(destination, withItemAt: source)
    }

    func run() {
        LOCALES = getProjectLocales()
        print("[*] Exporting \(LOCALES) to \(EXPORT_BASE_PATH)")
        exportLocales()

        LOCALES.forEach { locale in
            print("[*] Exporting \(locale)")
            handleXML(path: EXPORT_BASE_PATH, locale: locale)
            copyToL10NRepo(locale: locale)
        }
    }
}
