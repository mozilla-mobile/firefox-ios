// Sources/SwiftProtobufPluginLibrary/NamingUtils.swift - Utilities for generating names
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This provides some utilities for generating names.
///
/// NOTE: Only a very small subset of this is public. The intent is for this to
/// expose a defined api within the PluginLib, but the the SwiftProtobufNamer
/// to be what exposes the reusable parts at a much higher level. This reduces
/// the changes of something being reimplemented but with minor differences.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

///
/// We won't generate types (structs, enums) with these names:
///
fileprivate let reservedTypeNames: Set<String> = {
  () -> Set<String> in
  var names: Set<String> = []

  // Main SwiftProtobuf namespace
  // Shadowing this leads to Bad Things.
  names.insert(SwiftProtobufInfo.name)

  // Subtype of many messages, used to scope nested extensions
  names.insert("Extensions")

  // Subtypes are static references, so can conflict with static
  // class properties:
  names.insert("protoMessageName")

  // Methods on Message that we need to avoid shadowing.  Testing
  // shows we do not need to avoid `serializedData` or `isEqualTo`,
  // but it's not obvious to me what's different about them.  Maybe
  // because these two are generic?  Because they throw?
  names.insert("decodeMessage")
  names.insert("traverse")

  // Basic Message properties we don't want to shadow:
  names.insert("isInitialized")
  names.insert("unknownFields")

  // Standard Swift property names we don't want
  // to conflict with:
  names.insert("debugDescription")
  names.insert("description")
  names.insert("dynamicType")
  names.insert("hashValue")

  // We don't need to protect all of these keywords, just the ones
  // that interfere with type expressions:
  // names = names.union(swiftKeywordsReservedInParticularContexts)
  names.insert("Type")
  names.insert("Protocol")

  names = names.union(swiftKeywordsUsedInDeclarations)
  names = names.union(swiftKeywordsUsedInStatements)
  names = names.union(swiftKeywordsUsedInExpressionsAndTypes)
  names = names.union(swiftCommonTypes)
  names = names.union(swiftSpecialVariables)
  return names
}()

/*
 * Many Swift reserved words can be used as fields names if we put
 * backticks around them:
 */
fileprivate let quotableFieldNames: Set<String> = {
  () -> Set<String> in
  var names: Set<String> = []

  names = names.union(swiftKeywordsUsedInDeclarations)
  names = names.union(swiftKeywordsUsedInStatements)
  names = names.union(swiftKeywordsUsedInExpressionsAndTypes)
  return names
}()

fileprivate let reservedFieldNames: Set<String> = {
  () -> Set<String> in
  var names: Set<String> = []

  // Properties are instance names, so can't shadow static class
  // properties such as `protoMessageName`.

  // Properties can't shadow methods.  For example, we don't need to
  // avoid `isEqualTo` as a field name.

  // Basic Message properties that we don't want to shadow
  names.insert("isInitialized")
  names.insert("unknownFields")

  // Standard Swift property names we don't want
  // to conflict with:
  names.insert("debugDescription")
  names.insert("description")
  names.insert("dynamicType")
  names.insert("hashValue")
  names.insert("init")
  names.insert("self")

  // We don't need to protect all of these keywords, just the ones
  // that interfere with type expressions:
  // names = names.union(swiftKeywordsReservedInParticularContexts)
  names.insert("Type")
  names.insert("Protocol")

  names = names.union(swiftCommonTypes)
  names = names.union(swiftSpecialVariables)
  return names
}()

/*
 * Many Swift reserved words can be used as enum cases if we put
 * backticks around them:
 */
fileprivate let quotableEnumCases: Set<String> = {
  () -> Set<String> in
  var names: Set<String> = []

  // We don't need to protect all of these keywords, just the ones
  // that interfere with enum cases:
  // names = names.union(swiftKeywordsReservedInParticularContexts)
  names.insert("associativity")
  names.insert("dynamicType")
  names.insert("optional")
  names.insert("required")

  names = names.union(swiftKeywordsUsedInDeclarations)
  names = names.union(swiftKeywordsUsedInStatements)
  names = names.union(swiftKeywordsUsedInExpressionsAndTypes)
  // Common type and variable names don't cause problems as enum
  // cases, because enum case names only appear in special contexts:
  // names = names.union(swiftCommonTypes)
  // names = names.union(swiftSpecialVariables)
  return names
}()

/*
 * Some words cannot be used for enum cases, even if they
 * are quoted with backticks:
 */
fileprivate let reservedEnumCases: Set<String> = [
  // Don't conflict with standard Swift property names:
  "allCases",
  "debugDescription",
  "description",
  "dynamicType",
  "hashValue",
  "init",
  "rawValue",
  "self",
]

/*
 * Message scoped extensions are scoped within the Message struct with
 * `enum Extensions { ... }`, so we resuse the same sets for backticks
 * and reserved words.
 */
fileprivate let quotableMessageScopedExtensionNames: Set<String> = quotableEnumCases
fileprivate let reservedMessageScopedExtensionNames: Set<String> = reservedEnumCases


fileprivate func isAllUnderscore(_ s: String) -> Bool {
  if s.isEmpty {
    return false
  }
  for c in s.unicodeScalars {
    if c != "_" {return false}
  }
  return true
}

fileprivate func sanitizeTypeName(_ s: String, disambiguator: String) -> String {
  if reservedTypeNames.contains(s) {
    return s + disambiguator
  } else if isAllUnderscore(s) {
    return s + disambiguator
  } else if s.hasSuffix(disambiguator) {
    // If `foo` and `fooMessage` both exist, and `foo` gets
    // expanded to `fooMessage`, then we also should expand
    // `fooMessage` to `fooMessageMessage` to avoid creating a new
    // conflict.  This can be resolved recursively by stripping
    // the disambiguator, sanitizing the root, then re-adding the
    // disambiguator:
    let e = s.index(s.endIndex, offsetBy: -disambiguator.count)
    let truncated = String(s[..<e])
    return sanitizeTypeName(truncated, disambiguator: disambiguator) + disambiguator
  } else {
    return s
  }
}

fileprivate func isCharacterUppercase(_ s: String, index: Int) -> Bool {
  let scalars = s.unicodeScalars
  let start = scalars.index(scalars.startIndex, offsetBy: index)
  if start == scalars.endIndex {
    // it ended, so just say the next character wasn't uppercase.
    return false
  }
  return scalars[start].isUppercase
}

fileprivate func makeUnicodeScalarView(
  from unicodeScalar: UnicodeScalar
) -> String.UnicodeScalarView {
  var view = String.UnicodeScalarView()
  view.append(unicodeScalar)
  return view
}


fileprivate func splitIdentifier(_ s: String) -> [String] {
  var out: [String.UnicodeScalarView] = []
  var current = String.UnicodeScalarView()
  // The exact value used to seed this doesn't matter (as long as it's not an
  // underscore); we use it to avoid an extra optional unwrap in every loop
  // iteration.
  var last: UnicodeScalar = "\0"
  var lastIsUpper = false
  var lastIsLower = false

  for scalar in s.unicodeScalars {
    let isUpper = scalar.isUppercase
    let isLower = scalar.isLowercase

    if scalar.isDigit {
      if last.isDigit {
        current.append(scalar)
      } else {
        out.append(current)
        current = makeUnicodeScalarView(from: scalar)
      }
    } else if isUpper {
      if lastIsUpper {
        current.append(scalar.lowercased())
      } else {
        out.append(current)
        current = makeUnicodeScalarView(from: scalar.lowercased())
      }
    } else if isLower {
      if lastIsLower || lastIsUpper {
        current.append(scalar)
      } else {
        out.append(current)
        current = makeUnicodeScalarView(from: scalar)
      }
    } else if last == "_" {
      out.append(current)
      current = makeUnicodeScalarView(from: last)
    }

    last = scalar
    lastIsUpper = isUpper
    lastIsLower = isLower
  }

  out.append(current)
  if last == "_" {
    out.append(makeUnicodeScalarView(from: last))
  }

  // An empty string will always get inserted first, so drop it.
  let slice = out.dropFirst(1)
  return slice.map(String.init)
}

fileprivate let upperInitials: Set<String> = ["url", "http", "https", "id"]

fileprivate let backtickCharacterSet = CharacterSet(charactersIn: "`")

// Scope for the utilies to they are less likely to conflict when imported into
// generators.
public enum NamingUtils {

  // Returns the type prefix to use for a given
  static func typePrefix(protoPackage: String, fileOptions: Google_Protobuf_FileOptions) -> String {
    // Explicit option (including blank), wins.
    if fileOptions.hasSwiftPrefix {
      return fileOptions.swiftPrefix
    }

    if protoPackage.isEmpty {
      return String()
    }

    // Transforms:
    //  "package.name" -> "Package_Name"
    //  "package_name" -> "PackageName"
    //  "pacakge.some_name" -> "Package_SomeName"
    var makeUpper = true
    var prefix = ""
    for c in protoPackage {
      if c == "_" {
        makeUpper = true
      } else if c == "." {
        makeUpper = true
        prefix += "_"
      } else if makeUpper {
        prefix += String(c).uppercased()
        makeUpper = false
      } else {
        prefix += String(c)
      }
    }
    // End in an underscore to split off anything that gets added to it.
    return prefix + "_"
  }

  /// Helper a proto prefix from strings.  A proto prefix means underscores
  /// and letter case are ignored.
  struct PrefixStripper {
    private let prefixChars: String.UnicodeScalarView

    init(prefix: String) {
      self.prefixChars = prefix.lowercased().replacingOccurrences(of: "_", with: "").unicodeScalars
    }

    /// Strip the prefix and return the result, or return nil if it can't
    /// be stripped.
    func strip(from: String) -> String? {
      var prefixIndex = prefixChars.startIndex
      let prefixEnd = prefixChars.endIndex

      let fromChars = from.lowercased().unicodeScalars
      precondition(fromChars.count == from.lengthOfBytes(using: .ascii))
      var fromIndex = fromChars.startIndex
      let fromEnd = fromChars.endIndex

      while (prefixIndex != prefixEnd) {
        if (fromIndex == fromEnd) {
          // Reached the end of the string while still having prefix to go
          // nothing to strip.
          return nil
        }

        if fromChars[fromIndex] == "_" {
          fromIndex = fromChars.index(after: fromIndex)
          continue
        }

        if prefixChars[prefixIndex] != fromChars[fromIndex] {
          // They differed before the end of the prefix, can't drop.
          return nil
        }

        prefixIndex = prefixChars.index(after: prefixIndex)
        fromIndex = fromChars.index(after: fromIndex)
      }

      // Remove any more underscores.
      while fromIndex != fromEnd && fromChars[fromIndex] == "_" {
        fromIndex = fromChars.index(after: fromIndex)
      }

      if fromIndex == fromEnd {
        // They matched, can't strip.
        return nil
      }

      let count = fromChars.distance(from: fromChars.startIndex, to: fromIndex)
      let idx = from.index(from.startIndex, offsetBy: count)
      return String(from[idx..<from.endIndex])
    }
  }

  static func sanitize(messageName s: String) -> String {
    return sanitizeTypeName(s, disambiguator: "Message")
  }

  static func sanitize(enumName s: String) -> String {
    return sanitizeTypeName(s, disambiguator: "Enum")
  }

  static func sanitize(oneofName s: String) -> String {
    return sanitizeTypeName(s, disambiguator: "Oneof")
  }

  static func sanitize(fieldName s: String, basedOn: String) -> String {
    if basedOn.hasPrefix("clear") && isCharacterUppercase(basedOn, index: 5) {
      return s + "_p"
    } else if basedOn.hasPrefix("has") && isCharacterUppercase(basedOn, index: 3) {
      return s + "_p"
    } else if reservedFieldNames.contains(basedOn) {
      return s + "_p"
    } else if basedOn == s && quotableFieldNames.contains(basedOn) {
      // backticks are only used on the base names, if we're sanitizing based on something else
      // this is skipped (the "hasFoo" doesn't get backticks just because the "foo" does).
      return "`\(s)`"
    } else if isAllUnderscore(basedOn) {
      return s + "__"
    } else {
      return s
    }
  }

  static func sanitize(fieldName s: String) -> String {
    return sanitize(fieldName: s, basedOn: s)
  }

  static func sanitize(enumCaseName s: String) -> String {
    if reservedEnumCases.contains(s) {
      return "\(s)_"
    } else if quotableEnumCases.contains(s) {
      return "`\(s)`"
    } else if isAllUnderscore(s) {
      return s + "__"
    } else {
      return s
    }
  }

  static func sanitize(messageScopedExtensionName s: String) -> String {
    if reservedMessageScopedExtensionNames.contains(s) {
      return "\(s)_"
    } else if quotableMessageScopedExtensionNames.contains(s) {
      return "`\(s)`"
    } else if isAllUnderscore(s) {
      return s + "__"
    } else {
      return s
    }
  }

  /// Use toUpperCamelCase() to get leading "HTTP", "URL", etc. correct.
  static func uppercaseFirstCharacter(_ s: String) -> String {
    let out = s.unicodeScalars
    if let first = out.first {
      var result = makeUnicodeScalarView(from: first.uppercased())
      result.append(
        contentsOf: out[out.index(after: out.startIndex)..<out.endIndex])
      return String(result)
    } else {
      return s
    }
  }

  public static func toUpperCamelCase(_ s: String) -> String {
    var out = ""
    let t = splitIdentifier(s)
    for word in t {
      if upperInitials.contains(word) {
        out.append(word.uppercased())
      } else {
        out.append(uppercaseFirstCharacter(word))
      }
    }
    return out
  }

  public static func toLowerCamelCase(_ s: String) -> String {
    var out = ""
    let t = splitIdentifier(s)
    // Lowercase the first letter/word.
    var forceLower = true
    for word in t {
      if forceLower {
        out.append(word.lowercased())
      } else if upperInitials.contains(word) {
        out.append(word.uppercased())
      } else {
        out.append(uppercaseFirstCharacter(word))
      }
      forceLower = false
    }
    return out
  }

  static func trimBackticks(_ s: String) -> String {
    return s.trimmingCharacters(in: backtickCharacterSet)
  }

  static func periodsToUnderscores(_ s: String) -> String {
    return s.replacingOccurrences(of: ".", with: "_")
  }

  /// This must be exactly the same as the corresponding code in the
  /// SwiftProtobuf library.  Changing it will break compatibility of
  /// the generated code with old library version.
  public static func toJsonFieldName(_ s: String) -> String {
    var result = String.UnicodeScalarView()
    var capitalizeNext = false

    for c in s.unicodeScalars {
      if c == "_" {
        capitalizeNext = true
      } else if capitalizeNext {
        result.append(c.uppercased())
        capitalizeNext = false
      } else {
        result.append(c)
      }
    }
    return String(result)
  }
}
