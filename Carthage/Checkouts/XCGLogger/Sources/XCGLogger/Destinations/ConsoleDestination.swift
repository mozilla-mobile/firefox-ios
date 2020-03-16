//
//  ConsoleDestination.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Dispatch

// MARK: - ConsoleDestination
/// A standard destination that outputs log details to the console
open class ConsoleDestination: BaseQueuedDestination {
    // MARK: - Overridden Methods
    /// Print the log to the console.
    ///
    /// - Parameters:
    ///     - message:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func write(message: String) {
        print(message)
    }
}
