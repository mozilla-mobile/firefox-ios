// Sources/SwiftProtobuf/Internal.swift - Message support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Internal helpers on Messages for the library. These are public
/// just so the generated code can call them, but shouldn't be called
/// by developers directly.
///
// -----------------------------------------------------------------------------

import Foundation

/// Functions that are public only because they are used by generated message
/// implementations. NOT INTENDED TO BE CALLED BY CLIENTS.
public enum Internal {

  /// A singleton instance of an empty data that is used by the generated code
  /// for default values. This is a performance enhancement to work around the
  /// fact that the `Data` type in Swift involves a new heap allocation every
  /// time an empty instance is initialized, instead of sharing a common empty
  /// backing storage.
  public static let emptyData = Data()

  /// Helper to loop over a list of Messages to see if they are all
  /// initialized (see Message.isInitialized for what that means).
  public static func areAllInitialized(_ listOfMessages: [Message]) -> Bool {
    for msg in listOfMessages {
      if !msg.isInitialized {
        return false
      }
    }
    return true
  }

  /// Helper to loop over dictionary with values that are Messages to see if
  /// they are all initialized (see Message.isInitialized for what that means).
  public static func areAllInitialized<K>(_ mapToMessages: [K: Message]) -> Bool {
    for (_, msg) in mapToMessages {
      if !msg.isInitialized {
        return false
      }
    }
    return true
  }
}
