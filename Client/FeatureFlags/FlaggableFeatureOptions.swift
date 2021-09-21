//
//  FlaggableFeatureOptions.swift
//  Client
//
//  Created by Roux Buciu on 2021-09-20.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import Foundation

/// This file contains enums that serve as options for flaggable features.
/// Each should be set as an enum and should conform to String type and
/// the FlaggableFeatureOptions protocol.

protocol FlaggableFeatureOptions { }

enum StartAtHomeSetting: String, FlaggableFeatureOptions {
    case afterFourHours
    case always
    case never
}
