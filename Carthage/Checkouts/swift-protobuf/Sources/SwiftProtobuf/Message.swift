// Sources/SwiftProtobuf/Message.swift - Message support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//

/// The protocol which all generated protobuf messages implement.
/// `Message` is the protocol type you should use whenever
/// you need an argument or variable which holds "some message".
///
/// Generated messages also implement `Hashable`, and thus `Equatable`.
/// However, the protocol conformance is declared on a different protocol.
/// This allows you to use `Message` as a type directly:
///
///     func consume(message: Message) { ... }
///
/// Instead of needing to use it as a type constraint on a generic declaration:
///
///     func consume<M: Message>(message: M) { ... }
///
/// If you need to convince the compiler that your message is `Hashable` so
/// you can insert it into a `Set` or use it as a `Dictionary` key, use
/// a generic declaration with a type constraint:
///
///     func insertIntoSet<M: Message & Hashable>(message: M) {
///         mySet.insert(message)
///     }
///
/// The actual functionality is implemented either in the generated code or in
/// default implementations of the below methods and properties.
public protocol Message: CustomDebugStringConvertible {
  /// Creates a new message with all of its fields initialized to their default
  /// values.
  init()

  // Metadata
  // Basic facts about this class and the proto message it was generated from
  // Used by various encoders and decoders

  /// The fully-scoped name of the message from the original .proto file,
  /// including any relevant package name.
  static var protoMessageName: String { get }

  /// True if all required fields (if any) on this message and any nested
  /// messages (recursively) have values set; otherwise, false.
  var isInitialized: Bool { get }

  /// Some formats include enough information to transport fields that were
  /// not known at generation time. When encountered, they are stored here.
  var unknownFields: UnknownStorage { get set }

  //
  // General serialization/deserialization machinery
  //

  /// Decode all of the fields from the given decoder.
  ///
  /// This is a simple loop that repeatedly gets the next field number
  /// from `decoder.nextFieldNumber()` and then uses the number returned
  /// and the type information from the original .proto file to decide
  /// what type of data should be decoded for that field.  The corresponding
  /// method on the decoder is then called to get the field value.
  ///
  /// This is the core method used by the deserialization machinery. It is
  /// `public` to enable users to implement their own encoding formats by
  /// conforming to `Decoder`; it should not be called otherwise.
  ///
  /// Note that this is not specific to binary encodng; formats that use
  /// textual identifiers translate those to field numbers and also go
  /// through this to decode messages.
  ///
  /// - Parameters:
  ///   - decoder: a `Decoder`; the `Message` will call the method
  ///     corresponding to the type of this field.
  /// - Throws: an error on failure or type mismatch.  The type of error
  ///     thrown depends on which decoder is used.
  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws

  /// Traverses the fields of the message, calling the appropriate methods
  /// of the passed `Visitor` object.
  ///
  /// This is used internally by:
  ///
  /// * Protobuf binary serialization
  /// * JSON serialization (with some twists to account for specialty JSON)
  /// * Protobuf Text serialization
  /// * `Hashable` computation
  ///
  /// Conceptually, serializers create visitor objects that are
  /// then passed recursively to every message and field via generated
  /// `traverse` methods.  The details get a little involved due to
  /// the need to allow particular messages to override particular
  /// behaviors for specific encodings, but the general idea is quite simple.
  func traverse<V: Visitor>(visitor: inout V) throws

  // Standard utility properties and methods.
  // Most of these are simple wrappers on top of the visitor machinery.
  // They are implemented in the protocol, not in the generated structs,
  // so can be overridden in user code by defining custom extensions to
  // the generated struct.

#if swift(>=4.2)
  /// An implementation of hash(into:) to provide conformance with the
  /// `Hashable` protocol.
  func hash(into hasher: inout Hasher)
#else  // swift(>=4.2)
  /// The hash value generated from this message's contents, for conformance
  /// with the `Hashable` protocol.
  var hashValue: Int { get }
#endif  // swift(>=4.2)

  /// Helper to compare `Message`s when not having a specific type to use
  /// normal `Equatable`. `Equatable` is provided with specific generated
  /// types.
  func isEqualTo(message: Message) -> Bool
}

extension Message {
  /// Generated proto2 messages that contain required fields, nested messages
  /// that contain required fields, and/or extensions will provide their own
  /// implementation of this property that tests that all required fields are
  /// set. Users of the generated code SHOULD NOT override this property.
  public var isInitialized: Bool {
    // The generated code will include a specialization as needed.
    return true
  }

  /// A hash based on the message's full contents.
#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    var visitor = HashVisitor(hasher)
    try? traverse(visitor: &visitor)
    hasher = visitor.hasher
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    var visitor = HashVisitor()
    try? traverse(visitor: &visitor)
    return visitor.hashValue
  }
#endif  // swift(>=4.2)

  /// A description generated by recursively visiting all fields in the message,
  /// including messages.
  public var debugDescription: String {
    // TODO Ideally there would be something like serializeText() that can
    // take a prefix so we could do something like:
    //   [class name](
    //      [text format]
    //   )
    let className = String(reflecting: type(of: self))
    let header = "\(className):\n"
    return header + textFormatString()
  }

  /// Creates an instance of the message type on which this method is called,
  /// executes the given block passing the message in as its sole `inout`
  /// argument, and then returns the message.
  ///
  /// This method acts essentially as a "builder" in that the initialization of
  /// the message is captured within the block, allowing the returned value to
  /// be set in an immutable variable. For example,
  ///
  ///     let msg = MyMessage.with { $0.myField = "foo" }
  ///     msg.myOtherField = 5  // error: msg is immutable
  ///
  /// - Parameter populator: A block or function that populates the new message,
  ///   which is passed into the block as an `inout` argument.
  /// - Returns: The message after execution of the block.
  public static func with(
    _ populator: (inout Self) throws -> ()
  ) rethrows -> Self {
    var message = Self()
    try populator(&message)
    return message
  }
}

/// Implementation base for all messages; not intended for client use.
///
/// In general, use `SwiftProtobuf.Message` instead when you need a variable or
/// argument that can hold any type of message. Occasionally, you can use
/// `SwiftProtobuf.Message & Equatable` or `SwiftProtobuf.Message & Hashable` as
/// generic constraints if you need to write generic code that can be applied to
/// multiple message types that uses equality tests, puts messages in a `Set`,
/// or uses them as `Dictionary` keys.
public protocol _MessageImplementationBase: Message, Hashable {

  // Legacy function; no longer used, but left to maintain source compatibility.
  func _protobuf_generated_isEqualTo(other: Self) -> Bool
}

extension _MessageImplementationBase {
  public func isEqualTo(message: Message) -> Bool {
    guard let other = message as? Self else {
      return false
    }
    return self == other
  }

  // Legacy default implementation that is used by old generated code, current
  // versions of the plugin/generator provide this directly, but this is here
  // just to avoid breaking source compatibility.
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs._protobuf_generated_isEqualTo(other: rhs)
  }

  // Legacy function that is generated by old versions of the plugin/generator,
  // defaulted to keep things simple without changing the api surface.
  public func _protobuf_generated_isEqualTo(other: Self) -> Bool {
    return self == other
  }
}
