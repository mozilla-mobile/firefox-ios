// Sources/SwiftProtobuf/Google_Protobuf_Any+Registry.swift - Registry for JSON support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Support for registering and looking up Message types. Used
/// in support of Google_Protobuf_Any.
///
// -----------------------------------------------------------------------------

import Foundation
import Dispatch

// TODO: Should these first four be exposed as methods to go with
// the general registry support?

internal func buildTypeURL(forMessage message: Message, typePrefix: String) -> String {
  var url = typePrefix
  let needsSlash = typePrefix.isEmpty || typePrefix.last != "/"
  if needsSlash {
    url += "/"
  }
  return url + typeName(fromMessage: message)
}

internal func typeName(fromMessage message: Message) -> String {
  let messageType = type(of: message)
  return messageType.protoMessageName
}

internal func typeName(fromURL s: String) -> String {
  var typeStart = s.startIndex
  var i = typeStart
  while i < s.endIndex {
    let c = s[i]
    i = s.index(after: i)
    if c == "/" {
      typeStart = i
    }
  }

  return String(s[typeStart..<s.endIndex])
}

fileprivate var serialQueue = DispatchQueue(label: "org.swift.protobuf.typeRegistry")

// All access to this should be done on `serialQueue`.
fileprivate var knownTypes: [String:Message.Type] = [
  // Seeded with the Well Known Types.
  "google.protobuf.Any": Google_Protobuf_Any.self,
  "google.protobuf.BoolValue": Google_Protobuf_BoolValue.self,
  "google.protobuf.BytesValue": Google_Protobuf_BytesValue.self,
  "google.protobuf.DoubleValue": Google_Protobuf_DoubleValue.self,
  "google.protobuf.Duration": Google_Protobuf_Duration.self,
  "google.protobuf.Empty": Google_Protobuf_Empty.self,
  "google.protobuf.FieldMask": Google_Protobuf_FieldMask.self,
  "google.protobuf.FloatValue": Google_Protobuf_FloatValue.self,
  "google.protobuf.Int32Value": Google_Protobuf_Int32Value.self,
  "google.protobuf.Int64Value": Google_Protobuf_Int64Value.self,
  "google.protobuf.ListValue": Google_Protobuf_ListValue.self,
  "google.protobuf.StringValue": Google_Protobuf_StringValue.self,
  "google.protobuf.Struct": Google_Protobuf_Struct.self,
  "google.protobuf.Timestamp": Google_Protobuf_Timestamp.self,
  "google.protobuf.UInt32Value": Google_Protobuf_UInt32Value.self,
  "google.protobuf.UInt64Value": Google_Protobuf_UInt64Value.self,
  "google.protobuf.Value": Google_Protobuf_Value.self,
]

extension Google_Protobuf_Any {

    /// Register a message type so that Any objects can use
    /// them for decoding contents.
    ///
    /// This is currently only required in two cases:
    ///
    /// * When decoding Protobuf Text format.  Currently,
    ///   Any objects do not defer deserialization from Text
    ///   format.  Depending on how the Any objects are stored
    ///   in text format, the Any object may need to look up
    ///   the message type in order to deserialize itself.
    ///
    /// * When re-encoding an Any object into a different
    ///   format than it was decoded from.  For example, if
    ///   you decode a message containing an Any object from
    ///   JSON format and then re-encode the message into Protobuf
    ///   Binary format, the Any object will need to complete the
    ///   deferred deserialization of the JSON object before it
    ///   can re-encode.
    ///
    /// Note that well-known types are pre-registered for you and
    /// you do not need to register them from your code.
    ///
    /// Also note that this is not needed if you only decode and encode
    /// to and from the same format.
    ///
    /// Returns: true if the type was registered, false if something
    ///   else was already registered for the messageName.
    @discardableResult public static func register(messageType: Message.Type) -> Bool {
        let messageTypeName = messageType.protoMessageName
        var result: Bool = false
        serialQueue.sync {
            if let alreadyRegistered = knownTypes[messageTypeName] {
                // Success/failure when something was already registered is
                // based on if they are registering the same class or trying
                // to register a different type
                result = alreadyRegistered == messageType
            } else {
                knownTypes[messageTypeName] = messageType
                result = true
            }
        }
        return result
    }

    /// Returns the Message.Type expected for the given type URL.
    public static func messageType(forTypeURL url: String) -> Message.Type? {
      let messageTypeName = typeName(fromURL: url)
      return messageType(forMessageName: messageTypeName)
    }

    /// Returns the Message.Type expected for the given proto message name.
    public static func messageType(forMessageName name: String) -> Message.Type? {
        var result: Message.Type?
        serialQueue.sync {
            result = knownTypes[name]
        }
        return result
    }

}
