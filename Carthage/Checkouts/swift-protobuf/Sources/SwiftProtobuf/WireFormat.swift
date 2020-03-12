// Sources/SwiftProtobuf/WireFormat.swift - Describes proto wire formats
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Types related to binary wire formats of encoded values.
///
// -----------------------------------------------------------------------------

/// Denotes the wire format by which a value is encoded in binary form.
internal enum WireFormat: UInt8 {
  case varint = 0
  case fixed64 = 1
  case lengthDelimited = 2
  case startGroup = 3
  case endGroup = 4
  case fixed32 = 5
}

extension WireFormat {
  /// Information about the "MessageSet" format. Used when a Message has
  /// the message_set_wire_format option enabled.
  ///
  /// Writing in MessageSet form means instead of writing the Extesions
  /// normally as a simple fields, each gets written wrapped in a group:
  ///   repeated group Item = 1 {
  ///     required int32 type_id = 2;
  ///     required bytes message = 3;
  ///   }
  ///  Where the field number is the type_id, and the message is serilaized
  ///  into the bytes.
  ///
  /// The handling of unknown fields is ill defined. In proto1, they were
  /// dropped. In the C++ for proto2, since it stores them in the unknowns
  /// storage, if preserves any that are length delimited data (since that's
  /// how the message also goes out). While the C++ is parsing, where the
  /// unknowns fall in the flow of the group, sorta decides what happens.
  /// Since it is ill defined, currently SwiftProtobuf will reflect out
  /// anything set in the unknownStorage.  During parsing, unknowns on the
  /// message are preserved, but unknowns within the group are dropped (like
  /// map items).  Any extension in the MessageSet that isn't in the Regisry
  /// being used at parse time will remain in a group and go into the
  /// Messages's unknown fields (this way it reflects back out correctly).
  internal enum MessageSet {

    enum FieldNumbers {
      static let item = 1;
      static let typeId = 2;
      static let message = 3;
    }

    enum Tags {
      static let itemStart = FieldTag(fieldNumber: FieldNumbers.item, wireFormat: .startGroup)
      static let itemEnd = FieldTag(fieldNumber: FieldNumbers.item, wireFormat: .endGroup)
      static let typeId = FieldTag(fieldNumber: FieldNumbers.typeId, wireFormat: .varint)
      static let message = FieldTag(fieldNumber: FieldNumbers.message, wireFormat: .lengthDelimited)
    }

    // The size of all the tags needed to write out an Extension in MessageSet format.
    static let itemTagsEncodedSize =
      Tags.itemStart.encodedSize + Tags.itemEnd.encodedSize +
        Tags.typeId.encodedSize +
        Tags.message.encodedSize
  }
}
