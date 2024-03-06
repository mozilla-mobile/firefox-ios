#!/usr/bin/env swift

import Foundation

var allLocales = Locale.availableIdentifiers

// iOS doesn't directly support zh-CN/zh-TW; instead, it supports zh-Hans-CN
// and zh-Hant-TW, where Hans/Hant are script tags. Remove them so we match
// the expected format.
allLocales = allLocales.map { locale in
    return locale.replacingOccurrences(of: "_Hans", with: "")
                 .replacingOccurrences(of: "_Hant", with: "")
}

print(allLocales)
