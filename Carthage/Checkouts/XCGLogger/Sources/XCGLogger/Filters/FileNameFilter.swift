//
//  FileNameFilter.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-08-31.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation

// MARK: - FileNameFilter
/// Filter log messages by fileName
open class FileNameFilter: FilterProtocol {

    /// Option to toggle the match results
    open var inverse: Bool = false

    /// Option to match full path or just the fileName
    private var excludePath: Bool = true

    /// Internal list of fileNames to match against
    private var fileNamesToMatch: Set<String> = []

    /// Initializer to create an inclusion list of fileNames to match against
    ///
    /// Note: Only log messages from the specified files will be logged, all others will be excluded
    ///
    /// - Parameters:
    ///     - fileNames:                Set or Array of fileNames to match against.
    ///     - excludePathWhenMatching:  Whether or not to ignore the path for matches. **Default: true **
    ///
    public init<S: Sequence>(includeFrom fileNames: S, excludePathWhenMatching: Bool = true) where S.Iterator.Element == String {
        inverse = true
        excludePath = excludePathWhenMatching
        add(fileNames: fileNames)
    }

    /// Initializer to create an exclusion list of fileNames to match against
    ///
    /// Note: Log messages from the specified files will be excluded from logging
    ///
    /// - Parameters:
    ///     - fileNames:                Set or Array of fileNames to match against.
    ///     - excludePathWhenMatching:  Whether or not to ignore the path for matches. **Default: true **
    ///
    public init<S: Sequence>(excludeFrom fileNames: S, excludePathWhenMatching: Bool = true) where S.Iterator.Element == String {
        inverse = false
        excludePath = excludePathWhenMatching
        add(fileNames: fileNames)
    }

    /// Add another fileName to the list of names to match against.
    ///
    /// - Parameters:
    ///     - fileName: Name of the file to match against.
    ///
    /// - Returns:
    ///     - true:     FileName added.
    ///     - false:    FileName already added.
    ///
    @discardableResult open func add(fileName: String) -> Bool {
        return fileNamesToMatch.insert(excludePath ? (fileName as NSString).lastPathComponent : fileName).inserted
    }

    /// Add a list of fileNames to the list of names to match against.
    ///
    /// - Parameters:
    ///     - fileNames:    Set or Array of fileNames to match against.
    ///
    /// - Returns:          Nothing
    ///
    open func add<S: Sequence>(fileNames: S) where S.Iterator.Element == String {
        for fileName in fileNames {
            add(fileName: fileName)
        }
    }

    /// Clear the list of fileNames to match against.
    ///
    /// - Note: Doesn't change whether or not the filter is inclusive of exclusive
    ///
    /// - Parameters:   None
    ///
    /// - Returns:      Nothing
    ///
    open func clear() {
        fileNamesToMatch = []
    }

    /// Check if the log message should be excluded from logging.
    /// 
    /// - Note: If the fileName matches
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    ///
    /// - Returns:
    ///     - true:     Drop this log message.
    ///     - false:    Keep this log message and continue processing.
    ///
    open func shouldExclude(logDetails: inout LogDetails, message: inout String) -> Bool {
        var matched: Bool = fileNamesToMatch.contains(excludePath ? (logDetails.fileName as NSString).lastPathComponent : logDetails.fileName)
        if inverse {
            matched = !matched
        }

        return matched
    }

    // MARK: - CustomDebugStringConvertible
    open var debugDescription: String {
        get {
            var description: String = "\(extractTypeName(self)): " + (inverse ? "Including only matches for: " : "Excluding matches for: ")
            if fileNamesToMatch.count > 5 {
                description += "\n\t- " + fileNamesToMatch.sorted().joined(separator: "\n\t- ")
            }
            else {
                description += fileNamesToMatch.sorted().joined(separator: ", ")
            }

            return description
        }
    }
}
