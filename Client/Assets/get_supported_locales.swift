#!/usr/bin/env swift

import Foundation

var allLocales = NSLocale.availableLocaleIdentifiers()

// iOS doesn't directly support zh-CN/zh-TW; instead, it supports zh-Hans-CN and zh-Hant-TW, respectively.
// These transformations are done in SearchEngines.swift. Add them to the list of supported engines so
// that we download them.
allLocales.append("zh_CN")
allLocales.append("zh_TW")

print(allLocales)
