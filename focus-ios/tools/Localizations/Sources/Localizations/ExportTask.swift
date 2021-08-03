//
//  export.swift
//  ios-l10n-tools
//
//  Created by Jeff Boek on 11/2/20.
//

import Foundation
//    locale_mapping = {
//        'es-ES': 'es',
//        'ga-IE': 'ga',
//        'nb-NO': 'nb',
//        'nn-NO': 'nn',
//        'sv-SE': 'sv',
//        'tl'   : 'fil',
//        'zgh'  : 'tzm',
//        'sat'  : 'sat-Olck'


struct ExportTask {
    let xcodeProjPath: String
    let l10nRepoPath: String

    let locales: [String] = [
        "af",
        "an",
        "ar",
        "ast",
        "az",
        "bg",
        "bn",
        "br",
        "bs",
        "ca",
        "cs",
        "cy",
        "da",
        "de",
        "dsb",
        "el",
        "en-US",
        "eo",
        "es-AR",
        "es-CL",
        "es-ES",
        "es-MX",
        "eu",
        "fa",
        "fi",
        "fr",
        "ga-IE",
        "gd",
        "gu-IN",
        "hsb",
        "hu",
        "hy-AM",
        "ia",
        "id",
        "is",
        "it",
        "ja",
        "ka",
        "kab",
        "kk",
        "kn",
        "ko",
        "lo",
        "lt",
        "lv",
        "mr",
        "ms",
        "my",
        "nb-NO",
        "ne-NP",
        "nl",
        "nn-NO",
        "pl",
        "pt-BR",
        "pt-PT",
        "ro",
        "ru",
        "ses",
        "sk",
        "sl",
        "sq",
        "sv-SE",
        "ta",
        "te",
        "th",
        "tl",
        "tr",
        "uk",
        "ur",
        "uz",
        "vi",
        "zh-CN",
        "zh-TW"
    ]
    
    private let EXCLUDED_FILES: Set<String> = [
        "Blockzilla/Settings.bundle/en.lproj/Root.strings",
        "Blockzilla/en.lproj/Intents.strings"
    ]
    
    private let EXCLUDED_TRANSLATIONS: Set<String> = [
        "CFBundleName",
        "CFBundleDisplayName",
        "CFBundleShortVersionString",
        "1Password Fill Browser Action"
    ]
    
    private let REQUIRED_TRANSLATIONS: Set<String> = [
        "NSCameraUsageDescription",
        "NSLocationWhenInUseUsageDescription",
        "NSMicrophoneUsageDescription",
        "NSPhotoLibraryAddUsageDescription",
        "ShortcutItemTitleNewPrivateTab",
        "ShortcutItemTitleNewTab",
        "ShortcutItemTitleQRCode",
    ]
    private let LOCALE_MAPPING = [
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
    
    
    private func exportLocales() {
        let command = "xcodebuild -exportLocalizations -project \(xcodeProjPath) -localizationPath \(EXPORT_BASE_PATH)"
        let command2 = locales
            .map { "-exportLanguage \($0)" }.joined(separator: " ")

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command + " " + command2]
        try! task.run()
        task.waitUntilExit()
    }
    
    private func handleXML(path: String, locale: String, commentOverrides: [String : String]) {
        let url = URL(fileURLWithPath: path.appending("/\(locale).xcloc/Localized Contents/\(locale).xliff"))
        //let manifestUrl = URL(fileURLWithPath: path.appending("/\(locale).xcloc/contents.json"))
        let xml = try! XMLDocument(contentsOf: url, options: [.nodePreserveWhitespace, .nodeCompactEmptyElement])
        guard let root = xml.rootElement() else { return }
        let fileNodes = try! root.nodes(forXPath: "file")
        for case let fileNode as XMLElement in fileNodes {
            if let original = fileNode.attribute(forName: "original")?.stringValue, EXCLUDED_FILES.contains(original) {
                print("Skipping a file")
                fileNode.detach()
                continue
            }
            
            if let xcodeLocale = LOCALE_MAPPING[locale] {
                fileNode.attribute(forName: "target-language")?.setStringValue(xcodeLocale, resolvingEntities: false)
            }
            
            let translations = try! fileNode.nodes(forXPath: "body/trans-unit")
            for case let translation as XMLElement in translations {
                if translation.attribute(forName: "id")?.stringValue.map(EXCLUDED_TRANSLATIONS.contains) == true {
                    translation.detach()
                }
                
                if let comment = translation.attribute(forName: "id")?.stringValue.flatMap({ commentOverrides[$0] }) {
                    if let element = try? translation.nodes(forXPath: "note").first {
                        element.setStringValue(comment, resolvingEntities: true)
                    }
                }
            }
            
            let remainingTranslations = try! fileNode.nodes(forXPath: "body/trans-unit")
            
            if remainingTranslations.isEmpty {
                fileNode.detach()
            }
        }
        
        // Drop the xml:space="preserve" that is being added. Nobody cares about that.
        let s = xml.xmlString.replacingOccurrences(of: " xml:space=\"preserve\">", with: ">")
        try! s.write(to: url, atomically: true, encoding: .utf8)
    }
    
    
    private func copyToL10NRepo(locale: String) {
        let source = URL(fileURLWithPath: "\(EXPORT_BASE_PATH)/\(locale).xcloc/Localized Contents/\(locale).xliff")
        let l10nLocale: String
        if locale == "en" {
            l10nLocale = "en-US"
        } else {
            l10nLocale = LOCALE_MAPPING[locale] ?? locale
        }
        let destination = URL(fileURLWithPath: "\(l10nRepoPath)/\(l10nLocale)/focus-ios.xliff")
        let _ = try! FileManager.default.replaceItemAt(destination, withItemAt: source)
    }

    
    func run() {
        exportLocales()
        let commentOverrideURL = URL(fileURLWithPath: xcodeProjPath).deletingLastPathComponent().appendingPathComponent("l10n_comments.txt")
        let commentOverrides: [String : String] = (try? String(contentsOf: commentOverrideURL))?
            .split(whereSeparator: \.isNewline)
            .reduce(into: [String : String]()) { result, item in
                let items = item.split(separator: "=")
                guard let key = items.first, let value = items.last else { return }
                result[String(key)] = String(value)
            } ?? [:]
        
        locales.forEach { locale in
            handleXML(path: EXPORT_BASE_PATH, locale: locale, commentOverrides: commentOverrides)
            copyToL10NRepo(locale: locale)
        }

        print(xcodeProjPath, l10nRepoPath, locales)
    }
}
