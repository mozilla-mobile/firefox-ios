/* This Source Code Form is subject to the terms of the Mozilla
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
#if canImport(UIKit)
    import UIKit
#endif

/// `Variables` provides a type safe key-value style interface to configure application features
///
/// The feature developer requests a typed value with a specific `key`. If the key is present, and
/// the value is of the correct type, then it is returned. If neither of these are true, then `nil`
/// is returned.
///
/// The values may be under experimental control, but if not, `nil` is returned. In this case, the app should
/// provide the default value.
///
/// ```
/// let variables = nimbus.getVariables("about_welcome")
///
/// let title = variables.getString("title") ?? "Welcome, oo vudge"
/// let numSections = variables.getInt("num-sections") ?? 2
/// let isEnabled = variables.getBool("isEnabled") ?? true
/// ```
///
/// This may become the basis of a generated-from-manifest solution.
public protocol Variables {
    var resourceBundles: [Bundle] { get }

    /// Finds a string typed value for this key. If none exists, `nil` is returned.
    ///
    /// N.B. the `key` and type `String` should be listed in the experiment manifest.
    func getString(_ key: String) -> String?

    /// Find an array for this key, and returns all the strings in that array. If none exists, `nil`
    /// is returned.
    func getStringList(_ key: String) -> [String]?

    /// Find a map for this key, and returns a map containing all the entries that have strings
    /// as their values. If none exists, then `nil` is returned.
    func getStringMap(_ key: String) -> [String: String]?

    /// Returns the whole variables object as a string map
    /// will return `nil` if it cannot be converted
    ///  - Note: This function will omit any variables that could not be converted to strings
    ///  - Returns: a `[String:String]` dictionary representing the whole variables object
    func asStringMap() -> [String: String]?

    /// Finds a integer typed value for this key. If none exists, `nil` is returned.
    ///
    /// N.B. the `key` and type `Int` should be listed in the experiment manifest.
    func getInt(_ key: String) -> Int?

    /// Find an array for this key, and returns all the integers in that array. If none exists, `nil`
    /// is returned.
    func getIntList(_ key: String) -> [Int]?

    /// Find a map for this key, and returns a map containing all the entries that have integers
    /// as their values. If none exists, then `nil` is returned.
    func getIntMap(_ key: String) -> [String: Int]?

    /// Returns the whole variables object as an Int map
    /// will return `nil` if it cannot be converted
    ///  - Note: This function will omit any variables that could not be converted to Ints
    ///  - Returns: a `[String:Int]` dictionary representing the whole variables object
    func asIntMap() -> [String: Int]?

    /// Finds a boolean typed value for this key. If none exists, `nil` is returned.
    ///
    /// N.B. the `key` and type `String` should be listed in the experiment manifest.
    func getBool(_ key: String) -> Bool?

    /// Find an array for this key, and returns all the booleans in that array. If none exists, `nil`
    /// is returned.
    func getBoolList(_ key: String) -> [Bool]?

    /// Find a map for this key, and returns a map containing all the entries that have booleans
    /// as their values. If none exists, then `nil` is returned.
    func getBoolMap(_ key: String) -> [String: Bool]?

    /// Returns the whole variables object as a boolean map
    /// will return `nil` if it cannot be converted
    ///  - Note: This function will omit any variables that could not be converted to booleans
    ///  - Returns: a `[String:Bool]` dictionary representing the whole variables object
    func asBoolMap() -> [String: Bool]?

    /// Uses `getString(key: String)` to find the name of a drawable resource. If no value for `key`
    /// exists, or no resource named with that value exists, then `nil` is returned.
    ///
    /// N.B. the `key` and type `Image` should be listed in the experiment manifest. The
    /// names of the drawable resources should also be listed.
    func getImage(_ key: String) -> UIImage?

    /// Uses `getStringList(key: String)` to get a list of strings, then coerces the
    /// strings in the list into Images. Values that cannot be coerced are omitted.
    func getImageList(_ key: String) -> [UIImage]?

    /// Uses `getStringList(key: String)` to get a list of strings, then coerces the
    /// values into Images. Values that cannot be coerced are omitted.
    func getImageMap(_ key: String) -> [String: UIImage]?

    /// Uses `getString(key: String)` to find the name of a string resource. If a value exists, and
    /// a string resource exists with that name, then returns the string from the resource. If no
    /// such resource exists, then return the string value as the text.
    ///
    /// For strings, this is almost always the right choice.
    ///
    /// N.B. the `key` and type `LocalizedString` should be listed in the experiment manifest. The
    /// names of the string resources should also be listed.
    func getText(_ key: String) -> String?

    /// Uses `getStringList(key: String)` to get a list of strings, then coerces the
    /// strings in the list into localized text strings.
    func getTextList(_ key: String) -> [String]?

    /// Uses `getStringMap(key: String)` to get a map of strings, then coerces the
    /// string values into localized text strings.
    func getTextMap(_ key: String) -> [String: String]?

    /// Gets a nested `JSONObject` value for this key, and creates a new `Variables` object. If
    /// the value at the key is not a JSONObject, then return `nil`.
    func getVariables(_ key: String) -> Variables?

    /// Gets a list value for this key, and transforms all `JSONObject`s in the list into `Variables`.
    /// If the value isn't a list, then returns `nil`. Items in the list that are not `JSONObject`s
    /// are omitted from the final list.
    func getVariablesList(_ key: String) -> [Variables]?

    /// Gets a map value for this key, and transforms all `JSONObject`s that are values into `Variables`.
    /// If the value isn't a `JSONObject`, then returns `nil`. Values in the map that are not `JSONObject`s
    /// are omitted from the final map.
    func getVariablesMap(_ key: String) -> [String: Variables]?

    /// Returns the whole variables object as a variables map
    /// will return `nil` if it cannot be converted
    ///  - Note: This function will omit any variables that could not be converted to a class representing variables
    ///  - Returns: a `[String:Variables]` dictionary representing the whole variables object
    func asVariablesMap() -> [String: Variables]?
}

public extension Variables {
    // This may be important when transforming in to a code generated object.
    /// Get a `Variables` object for this key, and transforms it to a `T`. If this is not possible, then the
    /// `transform` should return `nil`.
    func getVariables<T>(_ key: String, transform: (Variables) -> T?) -> T? {
        if let value = getVariables(key) {
            return transform(value)
        } else {
            return nil
        }
    }

    /// Uses `getVariablesList(key)` then transforms each `Variables` into a `T`.
    /// If any item cannot be transformed, it is skipped.
    func getVariablesList<T>(_ key: String, transform: (Variables) -> T?) -> [T]? {
        return getVariablesList(key)?.compactMap(transform)
    }

    /// Uses `getVariablesMap(key)` then transforms each `Variables` value into a `T`.
    /// If any value cannot be transformed, it is skipped.
    func getVariablesMap<T>(_ key: String, transform: (Variables) -> T?) -> [String: T]? {
        return getVariablesMap(key)?.compactMapValues(transform)
    }

    /// Uses `getString(key: String)` to find a string value for the given key, and coerce it into
    /// the `Enum<T>`. If the value doesn't correspond to a variant of the type T, then `nil` is
    /// returned.
    func getEnum<T: RawRepresentable>(_ key: String) -> T? where T.RawValue == String {
        if let string = getString(key) {
            return asEnum(string)
        } else {
            return nil
        }
    }

    /// Uses `getStringList(key: String)` to find a value that is a list of strings for the given key,
    /// and coerce each item into an `Enum<T>`.
    ///
    /// If the value doesn't correspond to a variant of the list, then `nil` is
    /// returned.
    ///
    /// Items of the list that are not underlying strings, or cannot be coerced into variants,
    /// are omitted.
    func getEnumList<T: RawRepresentable>(_ key: String) -> [T]? where T.RawValue == String {
        return getStringList(key)?.compactMap(asEnum)
    }

    /// Uses `getStringMap(key: String)` to find a value that is a map of strings for the given key, and
    /// coerces each value into an `Enum<T>`.
    ///
    /// If the value doesn't correspond to a variant of the list, then `nil` is returned.
    ///
    /// Values that are not underlying strings, or cannot be coerced into variants,
    /// are omitted.
    func getEnumMap<T: RawRepresentable>(_ key: String) -> [String: T]? where T.RawValue == String {
        return getStringMap(key)?.compactMapValues(asEnum)
    }
}

public extension Dictionary where Key == String {
    func compactMapKeys<T>(_ transform: (String) -> T?) -> [T: Value] {
        let pairs = keys.compactMap { (k: String) -> (T, Value)? in
            guard let value = self[k],
                  let key = transform(k)
            else {
                return nil
            }

            return (key, value)
        }
        return [T: Value](uniqueKeysWithValues: pairs)
    }

    /// Convenience extension method for maps with `String` keys.
    /// If a `String` key cannot be coerced into a variant of the given Enum, then the entry is
    /// omitted.
    ///
    /// This is useful in combination with `getVariablesMap(key, transform)`:
    ///
    /// ```
    /// let variables = nimbus.getVariables("menu-feature")
    /// let menuItems: [MenuItemId: MenuItem] = variables
    ///     .getVariablesMap("items", ::toMenuItem)
    ///     ?.compactMapKeysAsEnums()
    /// let menuItemOrder: [MenuItemId] = variables.getEnumList("item-order")
    /// ```
    func compactMapKeysAsEnums<T: RawRepresentable>() -> [T: Value] where T.RawValue == String {
        return compactMapKeys(asEnum)
    }
}

public extension Dictionary where Value == String {
    /// Convenience extension method for maps with `String` values.
    /// If a `String` value cannot be coerced into a variant of the given Enum, then the entry is
    /// omitted.
    func compactMapValuesAsEnums<T: RawRepresentable>() -> [Key: T] where T.RawValue == String {
        return compactMapValues(asEnum)
    }
}

private func asEnum<T: RawRepresentable>(_ string: String) -> T? where T.RawValue == String {
    return T(rawValue: string)
}

protocol VariablesWithBundle: Variables {}

extension VariablesWithBundle {
    func getImage(_ key: String) -> UIImage? {
        return lookup(key, transform: asImage)
    }

    func getImageList(_ key: String) -> [UIImage]? {
        return lookupList(key, transform: asImage)
    }

    func getImageMap(_ key: String) -> [String: UIImage]? {
        return lookupMap(key, transform: asImage)
    }

    func getText(_ key: String) -> String? {
        return lookup(key, transform: asLocalizedString)
    }

    func getTextList(_ key: String) -> [String]? {
        return lookupList(key, transform: asLocalizedString)
    }

    func getTextMap(_ key: String) -> [String: String]? {
        return lookupMap(key, transform: asLocalizedString)
    }

    private func lookup<T>(_ key: String, transform: (String) -> T?) -> T? {
        guard let value = getString(key) else {
            return nil
        }
        return transform(value)
    }

    private func lookupList<T>(_ key: String, transform: (String) -> T?) -> [T]? {
        return getStringList(key)?.compactMap(transform)
    }

    private func lookupMap<T>(_ key: String, transform: (String) -> T?) -> [String: T]? {
        return getStringMap(key)?.compactMapValues(transform)
    }

    /// Search through the resource bundles looking for an image of the given name.
    ///
    /// If no image is found in any of the `resourceBundles`, then the `nil` is returned.
    func asImage(name: String) -> UIImage? {
        return resourceBundles.getImage(named: name)
    }

    /// Search through the resource bundles looking for localized strings with the given name.
    /// If the `name` contains exactly one slash, it is split up and the first part of the string is used
    /// as the `tableName` and the second the `key` in localized string lookup.
    /// If no string is found in any of the `resourceBundles`, then the `name` is passed back unmodified.
    func asLocalizedString(name: String) -> String? {
        return resourceBundles.getString(named: name) ?? name
    }
}

/// A thin wrapper around the JSON produced by the `get_feature_variables_json(feature_id)` call, useful
/// for configuring a feature, but without needing the developer to know about experiment specifics.
class JSONVariables: VariablesWithBundle {
    private let json: [String: Any]
    let resourceBundles: [Bundle]

    init(with json: [String: Any], in bundles: [Bundle] = [Bundle.main]) {
        self.json = json
        resourceBundles = bundles
    }

    // These `get*` methods get values from the wrapped JSON object, and transform them using the
    // `as*` methods.
    func getString(_ key: String) -> String? {
        return value(key)
    }

    func getStringList(_ key: String) -> [String]? {
        return values(key)
    }

    func getStringMap(_ key: String) -> [String: String]? {
        return valueMap(key)
    }

    func asStringMap() -> [String: String]? {
        return nil
    }

    func getInt(_ key: String) -> Int? {
        return value(key)
    }

    func getIntList(_ key: String) -> [Int]? {
        return values(key)
    }

    func getIntMap(_ key: String) -> [String: Int]? {
        return valueMap(key)
    }

    func asIntMap() -> [String: Int]? {
        return nil
    }

    func getBool(_ key: String) -> Bool? {
        return value(key)
    }

    func getBoolList(_ key: String) -> [Bool]? {
        return values(key)
    }

    func getBoolMap(_ key: String) -> [String: Bool]? {
        return valueMap(key)
    }

    func asBoolMap() -> [String: Bool]? {
        return nil
    }

    // Methods used to get sub-objects. We immediately re-wrap an JSON object if it exists.
    func getVariables(_ key: String) -> Variables? {
        if let dictionary: [String: Any] = value(key) {
            return JSONVariables(with: dictionary, in: resourceBundles)
        } else {
            return nil
        }
    }

    func getVariablesList(_ key: String) -> [Variables]? {
        return values(key)?.map { (dictionary: [String: Any]) in
            JSONVariables(with: dictionary, in: resourceBundles)
        }
    }

    func getVariablesMap(_ key: String) -> [String: Variables]? {
        return valueMap(key)?.mapValues { (dictionary: [String: Any]) in
            JSONVariables(with: dictionary, in: resourceBundles)
        }
    }

    func asVariablesMap() -> [String: Variables]? {
        return json.compactMapValues { value in
            if let jsonMap = value as? [String: Any] {
                return JSONVariables(with: jsonMap)
            }
            return nil
        }
    }

    private func value<T>(_ key: String) -> T? {
        return json[key] as? T
    }

    private func values<T>(_ key: String) -> [T]? {
        guard let list = json[key] as? [Any] else {
            return nil
        }
        return list.compactMap {
            $0 as? T
        }
    }

    private func valueMap<T>(_ key: String) -> [String: T]? {
        guard let map = json[key] as? [String: Any] else {
            return nil
        }
        return map.compactMapValues { $0 as? T }
    }
}

// Another implementation of `Variables` may just return nil for everything.
public class NilVariables: Variables {
    public static let instance = NilVariables()

    public private(set) var resourceBundles: [Bundle] = [Bundle.main]

    public func set(bundles: [Bundle]) {
        resourceBundles = bundles
    }

    public func getString(_: String) -> String? {
        return nil
    }

    public func getStringList(_: String) -> [String]? {
        return nil
    }

    public func getStringMap(_: String) -> [String: String]? {
        return nil
    }

    public func asStringMap() -> [String: String]? {
        return nil
    }

    public func getInt(_: String) -> Int? {
        return nil
    }

    public func getIntList(_: String) -> [Int]? {
        return nil
    }

    public func getIntMap(_: String) -> [String: Int]? {
        return nil
    }

    public func asIntMap() -> [String: Int]? {
        return nil
    }

    public func getBool(_: String) -> Bool? {
        return nil
    }

    public func getBoolList(_: String) -> [Bool]? {
        return nil
    }

    public func getBoolMap(_: String) -> [String: Bool]? {
        return nil
    }

    public func asBoolMap() -> [String: Bool]? {
        return nil
    }

    public func getImage(_: String) -> UIImage? {
        return nil
    }

    public func getImageList(_: String) -> [UIImage]? {
        return nil
    }

    public func getImageMap(_: String) -> [String: UIImage]? {
        return nil
    }

    public func getText(_: String) -> String? {
        return nil
    }

    public func getTextList(_: String) -> [String]? {
        return nil
    }

    public func getTextMap(_: String) -> [String: String]? {
        return nil
    }

    public func getVariables(_: String) -> Variables? {
        return nil
    }

    public func getVariablesList(_: String) -> [Variables]? {
        return nil
    }

    public func getVariablesMap(_: String) -> [String: Variables]? {
        return nil
    }

    public func asVariablesMap() -> [String: Variables]? {
        return nil
    }
}
