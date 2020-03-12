//
//  DispatchQueue+XCGAdditions.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-08-26.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Dispatch

/// Extensions to the DispatchQueue class
extension DispatchQueue {

    /// Extract the current dispatch queue's label name (Temp workaround until this is added to Swift 3.0 properly)
    public static var currentQueueLabel: String? {
        return String(validatingUTF8: __dispatch_queue_get_label(nil))
    }
}
