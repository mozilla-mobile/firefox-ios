//
//  FlaggableFeatureOptions.swift
//  Client
//
//  Created by Roux Buciu on 2021-09-20.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import Foundation

/// This file contains enums that serve as options for flaggable features.
/// Each should be set as an enum whose first value is the default setting for that feature
/// Furthermore, each enum should conform to Int type and the FlaggableFeatureOptions protocol.

protocol FlaggableFeatureOptions { }

enum StartAtHomeSetting: Int, FlaggableFeatureOptions {
    case afterFourHours
    case always
    case never
}
