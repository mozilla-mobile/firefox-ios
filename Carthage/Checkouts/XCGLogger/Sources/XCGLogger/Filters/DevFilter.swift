//
//  DevFilter.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-09-01.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - DevFilter
/// Filter log messages by devs
open class DevFilter: UserInfoFilter {

    /// Initializer to create an inclusion list of devs to match against
    ///
    /// Note: Only log messages with a specific dev will be logged, all others will be excluded
    ///
    /// - Parameters:
    ///     - devs: Set or Array of devs to match against.
    ///
    public override init<S: Sequence>(includeFrom devs: S) where S.Iterator.Element == String {
        super.init(includeFrom: devs)
        userInfoKey = XCGLogger.Constants.userInfoKeyDevs
    }

    /// Initializer to create an exclusion list of devs to match against
    ///
    /// Note: Log messages with a specific dev will be excluded from logging
    ///
    /// - Parameters:
    ///     - devs: Set or Array of devs to match against.
    ///
    public override init<S: Sequence>(excludeFrom devs: S) where S.Iterator.Element == String {
        super.init(excludeFrom: devs)
        userInfoKey = XCGLogger.Constants.userInfoKeyDevs
    }
}
