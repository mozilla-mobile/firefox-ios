//
//  TodayModel.swift
//  Client
//
//  Created by McNoor's  on 6/10/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation

struct TodayModel {
    
    var copiedURL : URL?
    
    var scheme: String {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
            // Something went wrong/weird, but we should fallback to the public one.
            return "firefox"
        }
        return string
    }
}
