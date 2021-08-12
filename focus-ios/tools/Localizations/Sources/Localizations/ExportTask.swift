//
//  export.swift
//  ios-l10n-tools
//
//  Created by Jeff Boek on 11/2/20.
//

import Foundation

struct ExportTask {
    let xcodeProjPath: String
    let l10nRepoPath: String

    // Locales that are in the Xcode project
    let LOCALES: [String] = [
        "af", "an", "ar", "ast", "az", "bg", "bn", "br", "bs", "ca", "cs", "cy", "da", "de", "dsb",
        "el", "en", "eo", "es-AR", "es-CL", "es-ES", "es-MX", "eu", "fa", "fi", "fil", "fr", "ga", "gd", "gu-IN",
        "he", "hi-IN", "hsb", "hu", "hy-AM", "ia", "id", "is", "it", "ja", "ka", "kab", "kk", "kn", "ko",
        "lo", "lt", "lv", "mr", "ms", "my", "nb", "ne-NP", "nl", "nn", "pl", "pt-BR", "pt-PT", "ro", "ru", "ses", "sk",
        "sl", "sq", "sv", "ta", "te", "th", "tr", "uk", "ur", "uz", "vi", "zh-CN", "zh-TW",
    ]
    
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
        "tzm" : "zgh",
        "sat-Olck" : "sat",
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

    // Process/transform the exported XLIFF
    private func handleXML(path: String, locale: String) {
        let url = URL(fileURLWithPath: path.appending("/\(locale).xcloc/Localized Contents/\(locale).xliff"))
        let xml = try! XMLDocument(contentsOf: url, options: [.nodePreserveWhitespace, .nodeCompactEmptyElement])
        guard let root = xml.rootElement() else {
            print("[W] Locale \(locale) did not have anything to parse?")
            return
        }

        for case let fileNode as XMLElement in try! root.nodes(forXPath: "file") {
            // Remove <file> nodes that we do not care about
            if let original = fileNode.attribute(forName: "original")?.stringValue, EXCLUDED_FILES.contains(original) {
                print("Skipping a file")
                fileNode.detach()
                continue
            }
            
            // Change the target language identifier from Xcode to Pontoon
            if let pontoonLocale = XCODE_TO_PONTOON[locale] {
                fileNode.attribute(forName: "target-language")?.setStringValue(pontoonLocale, resolvingEntities: false)
            }
            
            // Delete <trans-unit> nodes that we don't want to translate
            for case let translation as XMLElement in try! fileNode.nodes(forXPath: "body/trans-unit") {
                if translation.attribute(forName: "id")?.stringValue.map(EXCLUDED_TRANSLATIONS.contains) == true {
                    translation.detach()
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
        print("[*] Exporting \(LOCALES) to \(EXPORT_BASE_PATH)")
        exportLocales()

        LOCALES.forEach { locale in
            print("[*] Exporting \(locale)")
            handleXML(path: EXPORT_BASE_PATH, locale: locale)
            copyToL10NRepo(locale: locale)
        }
    }
}
