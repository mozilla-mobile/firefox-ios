// Sources/SwiftProtobufPluginLibrary/SwiftLanguage.swift - Swift language utilities
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Utility functions for dealing with Swift language issues
///
// -----------------------------------------------------------------------------

import Swift
import Foundation

fileprivate func isSwiftIdentifierHeadCharacter(_ c: UnicodeScalar) -> Bool {
    switch c.value {
    // identifier-head → Upper- or lowercase letter A through Z
    case 0x61...0x7a, 0x41...0x5a: return true
    // identifier-head → _
    case 0x5f: return true
    // identifier-head → U+00A8, U+00AA, U+00AD, U+00AF, U+00B2–U+00B5, or U+00B7–U+00BA
    case 0xa8, 0xaa, 0xad, 0xaf, 0xb2...0xb5, 0xb7...0xba: return true
    // identifier-head → U+00BC–U+00BE, U+00C0–U+00D6, U+00D8–U+00F6, or U+00F8–U+00FF
    case 0xbc...0xbe, 0xc0...0xd6, 0xd8...0xf6, 0xf8...0xff: return true
    // identifier-head → U+0100–U+02FF, U+0370–U+167F, U+1681–U+180D, or U+180F–U+1DBF
    case 0x100...0x2ff, 0x370...0x167f, 0x1681...0x180d, 0x180f...0x1dbf: return true
    // identifier-head → U+1E00–U+1FFF
    case 0x1e00...0x1fff: return true
    // identifier-head → U+200B–U+200D, U+202A–U+202E, U+203F–U+2040, U+2054, or U+2060–U+206F
    case 0x200b...0x200d, 0x202a...0x202e, 0x203F, 0x2040, 0x2054, 0x2060...0x206f: return true
    // identifier-head → U+2070–U+20CF, U+2100–U+218F, U+2460–U+24FF, or U+2776–U+2793
    case 0x2070...0x20cf, 0x2100...0x218f, 0x2460...0x24ff, 0x2776...0x2793: return true
    // identifier-head → U+2C00–U+2DFF or U+2E80–U+2FFF
    case 0x2c00...0x2dff, 0x2e80...0x2fff: return true
    // identifier-head → U+3004–U+3007, U+3021–U+302F, U+3031–U+303F, or U+3040–U+D7FF
    case 0x3004...0x3007, 0x3021...0x302f, 0x3031...0x303f, 0x3040...0xd7ff: return true
    // identifier-head → U+F900–U+FD3D, U+FD40–U+FDCF, U+FDF0–U+FE1F, or U+FE30–U+FE44
    case 0xf900...0xfd3d, 0xfd40...0xfdcf, 0xfdf0...0xfe1f, 0xfe30...0xfe44: return true
    // identifier-head → U+FE47–U+FFFD
    case 0xfe47...0xfffd: return true
    // identifier-head → U+10000–U+1FFFD, U+20000–U+2FFFD, U+30000–U+3FFFD, or U+40000–U+4FFFD
    case 0x10000...0x1fffd, 0x20000...0x2fffd, 0x30000...0x3fffd, 0x40000...0x4fffd: return true
    // identifier-head → U+50000–U+5FFFD, U+60000–U+6FFFD, U+70000–U+7FFFD, or U+80000–U+8FFFD
    case 0x50000...0x5fffd, 0x60000...0x6fffd, 0x70000...0x7fffd, 0x80000...0x8fffd: return true
    // identifier-head → U+90000–U+9FFFD, U+A0000–U+AFFFD, U+B0000–U+BFFFD, or U+C0000–U+CFFFD
    case 0x90000...0x9fffd, 0xa0000...0xafffd, 0xb0000...0xbfffd, 0xc0000...0xcfffd: return true
    // identifier-head → U+D0000–U+DFFFD or U+E0000–U+EFFFD
    case 0xd0000...0xdfffd, 0xe0000...0xefffd: return true

    default: return false
    }
}

fileprivate func isSwiftIdentifierCharacter(_ c: UnicodeScalar) -> Bool {
    switch c.value {
    // identifier-character → Digit 0 through 9
    case 0x30...0x39: return true
    // identifier-character → U+0300–U+036F, U+1DC0–U+1DFF, U+20D0–U+20FF, or U+FE20–U+FE2F
    case 0x300...0x36F, 0x1dc0...0x1dff, 0x20d0...0x20ff, 0xfe20...0xfe2f: return true
    // identifier-character → identifier-head
    default: return isSwiftIdentifierHeadCharacter(c)
    }
}

fileprivate func isValidSwiftLoneIdentifier(_ s: String) -> Bool {
    var i = s.unicodeScalars.makeIterator()
    if let first = i.next(), isSwiftIdentifierHeadCharacter(first) {
        while let c = i.next() {
            if !isSwiftIdentifierCharacter(c) {
                return false
            }
        }
        return true
    }
    return false
}

fileprivate func isValidSwiftQuotedIdentifier(_ s: String) -> Bool {
    var s = s
    if s.hasPrefix("`") {
        s.remove(at: s.startIndex)
        if s.hasSuffix("`") {
            s.remove(at: s.index(before: s.endIndex))
            return isValidSwiftLoneIdentifier(s)
        }
    }
    return false
}

/// Use this to check whether a generated identifier is actually
/// valid for use in generated Swift code.
///
/// This implements the full grammar for validating an arbitrary Swift
/// identifier as documented in "The Swift Programming Language."
/// In particular, it does correctly handle identifiers with
/// arbitrary Unicode in them.
///
/// For details, see:
///
/// https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/zzSummaryOfTheGrammar.html
///
/// Note: This is purely a syntactic check; it does not test whether
/// the identifier is a Swift reserved word.  We do exclude implicit
/// parameter identifiers ("$1", "$2", etc) and "_", though.
///
public func isValidSwiftIdentifier(_ s: String) -> Bool {
    // "_" is technically a valid identifier but is magic so we don't
    // want to generate it.
    if s == "_" {
        return false
    }
    return isValidSwiftLoneIdentifier(s) || isValidSwiftQuotedIdentifier(s)
}

/// These lists of keywords are taken directly from the Swift language
/// spec.  See:
///
/// https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/zzSummaryOfTheGrammar.html

public let swiftKeywordsUsedInDeclarations: Set<String> = [
    "associatedtype", "class", "deinit", "enum", "extension",
    "fileprivate", "func", "import", "init", "inout", "internal",
    "let", "open", "operator", "private", "protocol", "public",
    "static", "struct", "subscript", "typealias", "var"
]

public let swiftKeywordsUsedInStatements: Set<String> = [ "break", "case",
    "continue", "default", "defer", "do", "else", "fallthrough",
    "for", "guard", "if", "in", "repeat", "return", "switch", "where",
    "while"
]

public let swiftKeywordsUsedInExpressionsAndTypes: Set<String> = [ "as",
    "Any", "catch", "false", "is", "nil", "rethrows", "super", "self",
    "Self", "throw", "throws", "true", "try"
]

public let swiftKeywordsWithNumberSign: Set<String> = [ "#available",
    "#colorLiteral", "#column", "#else", "#elseif", "#endif", "#file",
    "#fileLiteral", "#function", "#if", "#imageLiteral", "#line",
    "#selector", "#sourceLocation"
]

public let swiftKeywordsReservedInParticularContexts: Set<String> = [
    "associativity", "convenience", "dynamic", "didSet", "final",
    "get", "infix", "indirect", "lazy", "left", "mutating", "none",
    "nonmutating", "optional", "override", "postfix", "precedence",
    "prefix", "Protocol", "required", "right", "set", "Type",
    "unowned", "weak", "willSet"
]

/// These are standard Swift types that are heavily used, although
/// they are not technically reserved.  Defining fields or structs
/// with these names would break our generated code quite badly:
public let swiftCommonTypes: Set<String> = [ "Bool", "Data", "Double", "Float", "Int",
    "Int32", "Int64", "String", "UInt", "UInt32", "UInt64",
]

/// Special magic variables defined by the compiler that we don't
/// really want to interfere with:
public let swiftSpecialVariables: Set<String> = [ "__COLUMN__",
    "__FILE__", "__FUNCTION__", "__LINE__",
]
