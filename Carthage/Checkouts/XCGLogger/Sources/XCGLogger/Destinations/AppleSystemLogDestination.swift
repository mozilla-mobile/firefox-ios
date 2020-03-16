//
//  AppleSystemLogDestination.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation
import Dispatch

// MARK: - AppleSystemLogDestination
/// A standard destination that outputs log details to the Apple System Log using NSLog instead of print
open class AppleSystemLogDestination: BaseQueuedDestination {
    // MARK: - Properties
    /// Option: whether or not to output the date the log was created (Always false for this destination)
    open override var showDate: Bool {
        get {
            return false
        }
        set {
            // ignored, NSLog adds the date, so we always want showDate to be false in this subclass
        }
    }

    // MARK: - Overridden Methods
    /// Print the log to the Apple System Log facility (using NSLog).
    ///
    /// - Parameters:
    ///     - message:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func write(message: String) {
        NSLog("%@", message)
    }
}
