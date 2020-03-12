//
//  UserInfoHelpers.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-09-19.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

/// Protocol for creating tagging objects (ie, a tag, a developer, etc) to filter log messages by
public protocol UserInfoTaggingProtocol {
    /// The name of the tagging object
    var name: String { get set }

    /// Convert the object to a userInfo compatible dictionary
    var dictionary: [String: String] { get }

    /// initialize the object with a name
    init(_ name: String)
}

/// Struction for tagging log messages with Tags
public struct Tag: UserInfoTaggingProtocol {

    /// The name of the tag
    public var name: String

    /// Dictionary representation compatible with the userInfo paramater of log messages
    public var dictionary: [String: String] {
        return [XCGLogger.Constants.userInfoKeyTags: name]
    }

    /// Initialize a Tag object with a name
    public init(_ name: String) {
        self.name = name
    }

    /// Create a Tag object with a name
    public static func name(_ name: String) -> Tag {
        return Tag(name)
    }

    /// Generate a userInfo compatible dictionary for the array of tag names
    public static func names(_ names: String...) -> [String: [String]] {
        var tags: [String] = []

        for name in names {
            tags.append(name)
        }

        return [XCGLogger.Constants.userInfoKeyTags: tags]
    }
}

/// Struction for tagging log messages with Developers
public struct Dev: UserInfoTaggingProtocol {

    /// The name of the developer
    public var name: String

    /// Dictionary representation compatible with the userInfo paramater of log messages
    public var dictionary: [String: String] {
        return [XCGLogger.Constants.userInfoKeyDevs: name]
    }

    /// Initialize a Dev object with a name
    public init(_ name: String) {
        self.name = name
    }

    /// Create a Dev object with a name
    public static func name(_ name: String) -> Dev {
        return Dev(name)
    }

    /// Generate a userInfo compatible dictionary for the array of dev names
    public static func names(_ names: String...) -> [String: [String]] {
        var tags: [String] = []

        for name in names {
            tags.append(name)
        }

        return [XCGLogger.Constants.userInfoKeyDevs: tags]
    }
}

/// Overloaded operator to merge userInfo compatible dictionaries together
/// Note: should correctly handle combining single elements of the same key, or an element and an array, but will skip sets
public func |<Key: Any, Value: Any> (lhs: Dictionary<Key, Value>, rhs: Dictionary<Key, Value>) -> Dictionary<Key, Any> {
    var mergedDictionary: Dictionary<Key, Any> = lhs

    rhs.forEach { key, rhsValue in
        guard let lhsValue = lhs[key] else { mergedDictionary[key] = rhsValue; return }
        guard !(rhsValue is Set<AnyHashable>) else { return }
        guard !(lhsValue is Set<AnyHashable>) else { return }

        if let lhsValue = lhsValue as? [Any],
            let rhsValue = rhsValue as? [Any] {
            // array, array -> array
            var mergedArray: [Any] = lhsValue
            mergedArray.append(contentsOf: rhsValue)
            mergedDictionary[key] = mergedArray
        }
        else if let lhsValue = lhsValue as? [Any] {
            // array, item -> array
            var mergedArray: [Any] = lhsValue
            mergedArray.append(rhsValue)
            mergedDictionary[key] = mergedArray
        }
        else if let rhsValue = rhsValue as? [Any] {
            // item, array -> array
            var mergedArray: [Any] = rhsValue
            mergedArray.append(lhsValue)
            mergedDictionary[key] = mergedArray
        }
        else {
            // two items -> array
            mergedDictionary[key] = [lhsValue, rhsValue]
        }
    }

    return mergedDictionary
}

/// Overloaded operator, converts UserInfoTaggingProtocol types to dictionaries and then merges them
public func | (lhs: UserInfoTaggingProtocol, rhs: UserInfoTaggingProtocol) -> Dictionary<String, Any> {
    return lhs.dictionary | rhs.dictionary
}

/// Overloaded operator, converts UserInfoTaggingProtocol types to dictionaries and then merges them
public func | (lhs: UserInfoTaggingProtocol, rhs: Dictionary<String, Any>) -> Dictionary<String, Any> {
    return lhs.dictionary | rhs
}

/// Overloaded operator, converts UserInfoTaggingProtocol types to dictionaries and then merges them
public func | (lhs: Dictionary<String, Any>, rhs: UserInfoTaggingProtocol) -> Dictionary<String, Any> {
    return rhs.dictionary | lhs
}

/// Extend UserInfoFilter to be able to use UserInfoTaggingProtocol objects
public extension UserInfoFilter {

    /// Initializer to create an inclusion list of tags to match against
    ///
    /// Note: Only log messages with a specific tag will be logged, all others will be excluded
    ///
    /// - Parameters:
    ///     - tags: Array of UserInfoTaggingProtocol objects to match against.
    ///
    convenience init(includeFrom tags: [UserInfoTaggingProtocol]) {
        var names: [String] = []
        for tag in tags {
            names.append(tag.name)
        }

        self.init(includeFrom: names)
    }

    /// Initializer to create an exclusion list of tags to match against
    ///
    /// Note: Log messages with a specific tag will be excluded from logging
    ///
    /// - Parameters:
    ///     - tags: Array of UserInfoTaggingProtocol objects to match against.
    ///
    convenience init(excludeFrom tags: [UserInfoTaggingProtocol]) {
        var names: [String] = []
        for tag in tags {
            names.append(tag.name)
        }

        self.init(excludeFrom: names)
    }
}
