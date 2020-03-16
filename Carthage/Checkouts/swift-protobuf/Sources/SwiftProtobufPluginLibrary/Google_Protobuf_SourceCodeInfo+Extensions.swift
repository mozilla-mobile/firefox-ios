// Sources/SwiftProtobufPluginLibrary/Google_Protobuf_SourceCodeInfo+Extensions.swift - SourceCodeInfo Additions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobuf

extension Google_Protobuf_SourceCodeInfo.Location {

  /// Builds a source comment out of the location's comment fields.
  ///
  /// If leadingDetachedPrefix is not provided, those comments won't
  /// be collected.
  public func asSourceComment(commentPrefix: String,
                              leadingDetachedPrefix: String? = nil) -> String {
    func escapeMarkup(_ text: String) -> String {
      // Proto file comments don't really have any markup associated with
      // them.  Swift uses something like MarkDown:
      //   "Markup Formatting Reference"
      //   https://developer.apple.com/library/content/documentation/Xcode/Reference/xcode_markup_formatting_ref/index.html
      // Sadly that format doesn't really lend itself to any form of
      // escaping to ensure comments are interpreted markup when they
      // really aren't. About the only thing that could be done is to
      // try and escape some set of things that could start directives,
      // and that gets pretty chatty/ugly pretty quickly.
      return text
    }

    func prefixLines(text: String, prefix: String) -> String {
      var result = String()
      var lines = text.components(separatedBy: .newlines)
      // Trim any blank lines off the end.
      while !lines.isEmpty && lines.last!.trimmingCharacters(in: .whitespaces).isEmpty {
        lines.removeLast()
      }
      for line in lines {
        result.append(prefix + line + "\n")
      }
      return result
    }

    var result = String()

    if let leadingDetachedPrefix = leadingDetachedPrefix {
      for detached in leadingDetachedComments {
        let comment = prefixLines(text: detached, prefix: leadingDetachedPrefix)
        if !comment.isEmpty {
          result += comment
          // Detached comments have blank lines between then (and
          // anything that follows them).
          result += "\n"
        }
      }
    }

    let comments = hasLeadingComments ? leadingComments : trailingComments
    result += prefixLines(text: escapeMarkup(comments), prefix: commentPrefix)
    return result
  }
}
