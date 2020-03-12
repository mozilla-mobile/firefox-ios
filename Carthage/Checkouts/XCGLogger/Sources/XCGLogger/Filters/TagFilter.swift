//
//  TagFilter.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-09-01.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - TagFilter
/// Filter log messages by tags
open class TagFilter: UserInfoFilter {

    /// Initializer to create an inclusion list of tags to match against
    ///
    /// Note: Only log messages with a specific tag will be logged, all others will be excluded
    ///
    /// - Parameters:
    ///     - tags: Set or Array of tags to match against.
    ///
    public override init<S: Sequence>(includeFrom tags: S) where S.Iterator.Element == String {
        super.init(includeFrom: tags)
        userInfoKey = XCGLogger.Constants.userInfoKeyTags
    }

    /// Initializer to create an exclusion list of tags to match against
    ///
    /// Note: Log messages with a specific tag will be excluded from logging
    ///
    /// - Parameters:
    ///     - tags: Set or Array of tags to match against.
    ///
    public override init<S: Sequence>(excludeFrom tags: S) where S.Iterator.Element == String {
        super.init(excludeFrom: tags)
        userInfoKey = XCGLogger.Constants.userInfoKeyTags
    }
}
