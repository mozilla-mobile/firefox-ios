// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

extension DeviceInfo {
    
    static let manufacturer = "apple"

    static var currentLocale: String {
        Locale.current.identifier
    }
    
    static var currentCountry: String? {
        if #available(iOS 16, *) {
            return Locale.current.language.region?.identifier
        } else {
            return Locale.current.regionCode
        }
    }

    static var platform: String {
        UIDevice.current.systemName
    }

    static var osVersionNumber: String {
        UIDevice.current.systemVersion
    }

    static var osBuildNumber: String? {
                
        // e.g. Version 16.4 (Build 20E247)
        let fullSystemVersionString = ProcessInfo().operatingSystemVersionString
        
        // Regex to extract the build version
        let regex = try? NSRegularExpression(pattern: "\\(Build\\s(.*?)\\)", options: [])
        
        // Retrieve the check result
        guard let match = regex?.firstMatch(in: fullSystemVersionString,
                                            options: [], range: NSRange(fullSystemVersionString.startIndex..., in: fullSystemVersionString)) else {
            return nil
        }
        
        // Retrieve the range
        guard let range = Range(match.range(at: 1), in: fullSystemVersionString) else {
            return nil
        }
        
        // Retrieve the build number
        // e.g 20E247
        return String(fullSystemVersionString[range])
    }

    static var deviceModelName: String {
        UIDevice.current.name
    }
}
