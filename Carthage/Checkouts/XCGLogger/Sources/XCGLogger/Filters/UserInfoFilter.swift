//
//  UserInfoFilter.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-09-01.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - UserInfoFilter
/// Filter log messages by the contents of a key in the UserInfo dictionary
/// Note: - This is intended to be subclassed, unlikely you'll use it directly
open class UserInfoFilter: FilterProtocol {

    /// The key to check in the LogDetails.userInfo dictionary
    open var userInfoKey: String = ""

    /// Option to also apply the filter to internal messages (ie, app details, error's opening files etc)
    open var applyFilterToInternalMessages: Bool = false

    /// Option to toggle the match results
    open var inverse: Bool = false

    /// Internal list of items to match against
    private var itemsToMatch: Set<String> = []

    /// Initializer to create an inclusion list of items to match against
    ///
    /// Note: Only log messages with a specific item will be logged, all others will be excluded
    ///
    /// - Parameters:
    ///     - items:    Set or Array of items to match against.
    ///
    public init<S: Sequence>(includeFrom items: S) where S.Iterator.Element == String {
        inverse = true
        add(items: items)
    }

    /// Initializer to create an exclusion list of items to match against
    ///
    /// Note: Log messages with a specific item will be excluded from logging
    ///
    /// - Parameters:
    ///     - items:    Set or Array of items to match against.
    ///
    public init<S: Sequence>(excludeFrom items: S) where S.Iterator.Element == String {
        inverse = false
        add(items: items)
    }

    /// Add another fileName to the list of names to match against.
    ///
    /// - Parameters:
    ///     - item: Item to match against.
    ///
    /// - Returns:
    ///     - true:     FileName added.
    ///     - false:    FileName already added.
    ///
    @discardableResult open func add(item: String) -> Bool {
        return itemsToMatch.insert(item).inserted
    }

    /// Add a list of fileNames to the list of names to match against.
    ///
    /// - Parameters:
    ///     - items:     Set or Array of fileNames to match against.
    ///
    /// - Returns:      Nothing
    ///
    open func add<S: Sequence>(items: S) where S.Iterator.Element == String {
        for item in items {
            add(item: item)
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
        itemsToMatch = []
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
        var matched: Bool = false

        if !applyFilterToInternalMessages,
          let isInternal = logDetails.userInfo[XCGLogger.Constants.userInfoKeyInternal] as? Bool,
          isInternal {
            return inverse
        }

        if let messageItemsObject = logDetails.userInfo[userInfoKey] {
            if let messageItemsSet: Set<String> = messageItemsObject as? Set<String> {
                matched = itemsToMatch.intersection(messageItemsSet).count > 0
            }
            else if let messageItemsArray: Array<String> = messageItemsObject as? Array<String> {
                matched = itemsToMatch.intersection(messageItemsArray).count > 0
            }
            else if let messageItem = messageItemsObject as? String {
                matched = itemsToMatch.contains(messageItem)
            }
        }

        if inverse {
            matched = !matched
        }

        return matched
    }

    // MARK: - CustomDebugStringConvertible
    open var debugDescription: String {
        get {
            var description: String = "\(extractTypeName(self)): \(applyFilterToInternalMessages ? "(Filtering Internal) " : "")" + (inverse ? "Including only matches for: " : "Excluding matches for: ")
            if itemsToMatch.count > 5 {
                description += "\n\t- " + itemsToMatch.sorted().joined(separator: "\n\t- ")
            }
            else {
                description += itemsToMatch.sorted().joined(separator: ", ")
            }
            
            return description
        }
    }
}
