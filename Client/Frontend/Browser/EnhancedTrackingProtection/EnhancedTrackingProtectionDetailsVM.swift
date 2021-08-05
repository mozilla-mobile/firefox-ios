//
//  EnhancedTrackingProtectionDetailsVM.swift
//  Client
//
//  Created by Roux Buciu on 2021-08-04.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import Foundation

struct EnhancedTrackingProtectionDetailsVM {
    let topLevelDomain: String
    let title: String
    let image: UIImage
    let URL: String

    let lockIcon: UIImage
    let connectionStatusMessage: String
    let connectionVerifier: String
    let connectionSecure: Bool
}
