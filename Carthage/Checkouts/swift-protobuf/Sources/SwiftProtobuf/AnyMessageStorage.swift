// Sources/SwiftProtobuf/AnyMessageStorage.swift - Custom stroage for Any WKT
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Hand written storage class for Google_Protobuf_Any to support on demand
/// transforms between the formats.
///
// -----------------------------------------------------------------------------

import Foundation

#if !swift(>=4.2)
private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)
#endif

fileprivate func serializeAnyJSON(
  for message: Message,
  typeURL: String,
  options: JSONEncodingOptions
) throws -> String {
  var visitor = try JSONEncodingVisitor(message: message, options: options)
  visitor.startObject()
  visitor.encodeField(name: "@type", stringValue: typeURL)
  if let m = message as? _CustomJSONCodable {
    let value = try m.encodedJSONString(options: options)
    visitor.encodeField(name: "value", jsonText: value)
  } else {
    try message.traverse(visitor: &visitor)
  }
  visitor.endObject()
  return visitor.stringResult
}

fileprivate func emitVerboseTextForm(visitor: inout TextFormatEncodingVisitor, message: Message, typeURL: String) {
  let url: String
  if typeURL.isEmpty {
    url = buildTypeURL(forMessage: message, typePrefix: defaultAnyTypeURLPrefix)
  } else {
    url = typeURL
  }
  visitor.visitAnyVerbose(value: message, typeURL: url)
}

fileprivate func asJSONObject(body: Data) -> Data {
  let asciiOpenCurlyBracket = UInt8(ascii: "{")
  let asciiCloseCurlyBracket = UInt8(ascii: "}")
  var result = Data([asciiOpenCurlyBracket])
  result.append(body)
  result.append(asciiCloseCurlyBracket)
  return result
}

fileprivate func unpack(contentJSON: Data,
                        options: JSONDecodingOptions,
                        as messageType: Message.Type) throws -> Message {
  guard messageType is _CustomJSONCodable.Type else {
    let contentJSONAsObject = asJSONObject(body: contentJSON)
    return try messageType.init(jsonUTF8Data: contentJSONAsObject, options: options)
  }

  var value = String()
  try contentJSON.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
    if body.count > 0 {
      var scanner = JSONScanner(source: body,
                                messageDepthLimit: options.messageDepthLimit,
                                ignoreUnknownFields: options.ignoreUnknownFields)
      let key = try scanner.nextQuotedString()
      if key != "value" {
        // The only thing within a WKT should be "value".
        throw AnyUnpackError.malformedWellKnownTypeJSON
      }
      try scanner.skipRequiredColon()  // Can't fail
      value = try scanner.skip()
      if !scanner.complete {
        // If that wasn't the end, then there was another key,
        // and WKTs should only have the one.
        throw AnyUnpackError.malformedWellKnownTypeJSON
      }
    }
  }
  return try messageType.init(jsonString: value, options: options)
}

internal class AnyMessageStorage {
  // The two properties generated Google_Protobuf_Any will reference.
  var _typeURL = String()
  var _value: Data {
    // Remapped to the internal `state`.
    get {
      switch state {
      case .binary(let value):
        return value
      case .message(let message):
        do {
          return try message.serializedData(partial: true)
        } catch {
          return Internal.emptyData
        }
      case .contentJSON(let contentJSON, let options):
        guard let messageType = Google_Protobuf_Any.messageType(forTypeURL: _typeURL) else {
          return Internal.emptyData
        }
        do {
          let m = try unpack(contentJSON: contentJSON,
                             options: options,
                             as: messageType)
          return try m.serializedData(partial: true)
        } catch {
          return Internal.emptyData
        }
      }
    }
    set {
      state = .binary(newValue)
    }
  }

  enum InternalState {
    // a serialized binary
    // Note: Unlike contentJSON below, binary does not bother to capture the
    // decoding options. This is because the actual binary format is the binary
    // blob, i.e. - when decoding from binary, the spec doesn't include decoding
    // the binary blob, it is pass through. Instead there is a public api for
    // unpacking that takes new options when a developer decides to decode it.
    case binary(Data)
    // a message
    case message(Message)
    // parsed JSON with the @type removed and the decoding options.
    case contentJSON(Data, JSONDecodingOptions)
  }
  var state: InternalState = .binary(Internal.emptyData)

  static let defaultInstance = AnyMessageStorage()

  private init() {}

  init(copying source: AnyMessageStorage) {
    _typeURL = source._typeURL
    state = source.state
  }

  func isA<M: Message>(_ type: M.Type) -> Bool {
    if _typeURL.isEmpty {
      return false
    }
    let encodedType = typeName(fromURL: _typeURL)
    return encodedType == M.protoMessageName
  }

  // This is only ever called with the expactation that target will be fully
  // replaced during the unpacking and never as a merge.
  func unpackTo<M: Message>(
    target: inout M,
    extensions: ExtensionMap?,
    options: BinaryDecodingOptions
  ) throws {
    guard isA(M.self) else {
      throw AnyUnpackError.typeMismatch
    }

    switch state {
    case .binary(let data):
      target = try M(serializedData: data, extensions: extensions, partial: true, options: options)

    case .message(let msg):
      if let message = msg as? M {
        // Already right type, copy it over.
        target = message
      } else {
        // Different type, serialize and parse.
        let data = try msg.serializedData(partial: true)
        target = try M(serializedData: data, extensions: extensions, partial: true)
      }

    case .contentJSON(let contentJSON, let options):
      target = try unpack(contentJSON: contentJSON,
                          options: options,
                          as: M.self) as! M
    }
  }

  // Called before the message is traversed to do any error preflights.
  // Since traverse() will use _value, this is our chance to throw
  // when _value can't.
  func preTraverse() throws {
    switch state {
    case .binary:
      // Nothing to be checked.
      break

    case .message:
      // When set from a developer provided message, partial support
      // is done. Any message that comes in from another format isn't
      // checked, and transcoding the isInitialized requirement is
      // never inserted.
      break

    case .contentJSON:
      // contentJSON requires a good URL and our ability to look up
      // the message type to transcode.
      if Google_Protobuf_Any.messageType(forTypeURL: _typeURL) == nil {
        // Isn't registered, we can't transform it for binary.
        throw BinaryEncodingError.anyTranscodeFailure
      }
    }
  }
}

/// Custom handling for Text format.
extension AnyMessageStorage {
  func decodeTextFormat(typeURL url: String, decoder: inout TextFormatDecoder) throws {
    // Decoding the verbose form requires knowing the type.
    _typeURL = url
    guard let messageType = Google_Protobuf_Any.messageType(forTypeURL: url) else {
      // The type wasn't registered, can't parse it.
      throw TextFormatDecodingError.malformedText
    }
    let terminator = try decoder.scanner.skipObjectStart()
    var subDecoder = try TextFormatDecoder(messageType: messageType, scanner: decoder.scanner, terminator: terminator)
    if messageType == Google_Protobuf_Any.self {
      var any = Google_Protobuf_Any()
      try any.decodeTextFormat(decoder: &subDecoder)
      state = .message(any)
    } else {
      var m = messageType.init()
      try m.decodeMessage(decoder: &subDecoder)
      state = .message(m)
    }
    decoder.scanner = subDecoder.scanner
    if try decoder.nextFieldNumber() != nil {
      // Verbose any can never have additional keys.
      throw TextFormatDecodingError.malformedText
    }
  }

  // Specialized traverse for writing out a Text form of the Any.
  // This prefers the more-legible "verbose" format if it can
  // use it, otherwise will fall back to simpler forms.
  internal func textTraverse(visitor: inout TextFormatEncodingVisitor) {
    switch state {
    case .binary(let valueData):
      if let messageType = Google_Protobuf_Any.messageType(forTypeURL: _typeURL) {
        // If we can decode it, we can write the readable verbose form:
        do {
          let m = try messageType.init(serializedData: valueData, partial: true)
          emitVerboseTextForm(visitor: &visitor, message: m, typeURL: _typeURL)
          return
        } catch {
          // Fall through to just print the type and raw binary data
        }
      }
      if !_typeURL.isEmpty {
        try! visitor.visitSingularStringField(value: _typeURL, fieldNumber: 1)
      }
      if !valueData.isEmpty {
        try! visitor.visitSingularBytesField(value: valueData, fieldNumber: 2)
      }

    case .message(let msg):
      emitVerboseTextForm(visitor: &visitor, message: msg, typeURL: _typeURL)

    case .contentJSON(let contentJSON, let options):
      // If we can decode it, we can write the readable verbose form:
      if let messageType = Google_Protobuf_Any.messageType(forTypeURL: _typeURL) {
        do {
          let m = try unpack(contentJSON: contentJSON,
                             options: options,
                             as: messageType)
          emitVerboseTextForm(visitor: &visitor, message: m, typeURL: _typeURL)
          return
        } catch {
          // Fall through to just print the raw JSON data
        }
      }
      if !_typeURL.isEmpty {
        try! visitor.visitSingularStringField(value: _typeURL, fieldNumber: 1)
      }
      // Build a readable form of the JSON:
      let contentJSONAsObject = asJSONObject(body: contentJSON)
      visitor.visitAnyJSONDataField(value: contentJSONAsObject)
    }
  }
}

/// The obvious goal for Hashable/Equatable conformance would be for
/// hash and equality to behave as if we always decoded the inner
/// object and hashed or compared that.  Unfortunately, Any typically
/// stores serialized contents and we don't always have the ability to
/// deserialize it.  Since none of our supported serializations are
/// fully deterministic, we can't even ensure that equality will
/// behave this way when the Any contents are in the same
/// serialization.
///
/// As a result, we can only really perform a "best effort" equality
/// test.  Of course, regardless of the above, we must guarantee that
/// hashValue is compatible with equality.
extension AnyMessageStorage {
#if swift(>=4.2)
  // Can't use _valueData for a few reasons:
  // 1. Since decode is done on demand, two objects could be equal
  //    but created differently (one from JSON, one for Message, etc.),
  //    and the hash values have to be equal even if we don't have data
  //    yet.
  // 2. map<> serialization order is undefined. At the time of writing
  //    the Swift, Objective-C, and Go runtimes all tend to have random
  //    orders, so the messages could be identical, but in binary form
  //    they could differ.
  public func hash(into hasher: inout Hasher) {
    if !_typeURL.isEmpty {
      hasher.combine(_typeURL)
    }
  }
#else  // swift(>=4.2)
  var hashValue: Int {
    var hash: Int = i_2166136261
    if !_typeURL.isEmpty {
      hash = (hash &* i_16777619) ^ _typeURL.hashValue
    }
    return hash
  }
#endif  // swift(>=4.2)

  func isEqualTo(other: AnyMessageStorage) -> Bool {
    if (_typeURL != other._typeURL) {
      return false
    }

    // Since the library does lazy Any decode, equality is a very hard problem.
    // It things exactly match, that's pretty easy, otherwise, one ends up having
    // to error on saying they aren't equal.
    //
    // The best option would be to have Message forms and compare those, as that
    // removes issues like map<> serialization order, some other protocol buffer
    // implementation details/bugs around serialized form order, etc.; but that
    // would also greatly slow down equality tests.
    //
    // Do our best to compare what is present have...

    // If both have messages, check if they are the same.
    if case .message(let myMsg) = state, case .message(let otherMsg) = other.state, type(of: myMsg) == type(of: otherMsg) {
      // Since the messages are known to be same type, we can claim both equal and
      // not equal based on the equality comparison.
      return myMsg.isEqualTo(message: otherMsg)
    }

    // If both have serialized data, and they exactly match; the messages are equal.
    // Because there could be map in the message, the fact that the data isn't the
    // same doesn't always mean the messages aren't equal. Likewise, the binary could
    // have been created by a library that doesn't order the fields, or the binary was
    // created using the appending ability in of the binary format.
    if case .binary(let myValue) = state, case .binary(let otherValue) = other.state, myValue == otherValue {
      return true
    }

    // If both have contentJSON, and they exactly match; the messages are equal.
    // Because there could be map in the message (or the JSON could just be in a different
    // order), the fact that the JSON isn't the same doesn't always mean the messages
    // aren't equal.
    if case .contentJSON(let myJSON, _) = state,
       case .contentJSON(let otherJSON, _) = other.state,
       myJSON == otherJSON {
      return true
    }

    // Out of options. To do more compares, the states conversions would have to be
    // done to do comparisions; and since equality can be used somewhat removed from
    // a developer (if they put protos in a Set, use them as keys to a Dictionary, etc),
    // the conversion cost might be to high for those uses.  Give up and say they aren't equal.
    return false
  }
}

// _CustomJSONCodable support for Google_Protobuf_Any
extension AnyMessageStorage {
  // Override the traversal-based JSON encoding
  // This builds an Any JSON representation from one of:
  //  * The message we were initialized with,
  //  * The JSON fields we last deserialized, or
  //  * The protobuf field we were deserialized from.
  // The last case requires locating the type, deserializing
  // into an object, then reserializing back to JSON.
  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    switch state {
    case .binary(let valueData):
      // Transcode by decoding the binary data to a message object
      // and then recode back into JSON.
      guard let messageType = Google_Protobuf_Any.messageType(forTypeURL: _typeURL) else {
        // If we don't have the type available, we can't decode the
        // binary value, so we're stuck.  (The Google spec does not
        // provide a way to just package the binary value for someone
        // else to decode later.)
        throw JSONEncodingError.anyTranscodeFailure
      }
      let m = try messageType.init(serializedData: valueData, partial: true)
      return try serializeAnyJSON(for: m, typeURL: _typeURL, options: options)

    case .message(let msg):
      // We should have been initialized with a typeURL, but
      // ensure it wasn't cleared.
      let url = !_typeURL.isEmpty ? _typeURL : buildTypeURL(forMessage: msg, typePrefix: defaultAnyTypeURLPrefix)
      return try serializeAnyJSON(for: msg, typeURL: url, options: options)

    case .contentJSON(let contentJSON, _):
      var jsonEncoder = JSONEncoder()
      jsonEncoder.startObject()
      jsonEncoder.startField(name: "@type")
      jsonEncoder.putStringValue(value: _typeURL)
      if !contentJSON.isEmpty {
        jsonEncoder.append(staticText: ",")
        // NOTE: This doesn't really take `options` into account since it is
        // just reflecting out what was taken in originally.
        jsonEncoder.append(utf8Data: contentJSON)
      }
      jsonEncoder.endObject()
      return jsonEncoder.stringResult
    }
  }

  // TODO: If the type is well-known or has already been registered,
  // we should consider decoding eagerly.  Eager decoding would
  // catch certain errors earlier (good) but would probably be
  // a performance hit if the Any contents were never accessed (bad).
  // Of course, we can't always decode eagerly (we don't always have the
  // message type available), so the deferred logic here is still needed.
  func decodeJSON(from decoder: inout JSONDecoder) throws {
    try decoder.scanner.skipRequiredObjectStart()
    // Reset state
    _typeURL = String()
    state = .binary(Internal.emptyData)
    if decoder.scanner.skipOptionalObjectEnd() {
      return
    }

    var jsonEncoder = JSONEncoder()
    while true {
      let key = try decoder.scanner.nextQuotedString()
      try decoder.scanner.skipRequiredColon()
      if key == "@type" {
        _typeURL = try decoder.scanner.nextQuotedString()
      } else {
        jsonEncoder.startField(name: key)
        let keyValueJSON = try decoder.scanner.skip()
        jsonEncoder.append(text: keyValueJSON)
      }
      if decoder.scanner.skipOptionalObjectEnd() {
        // Capture the options, but set the messageDepthLimit to be what
        // was left right now, as that is the limit when the JSON is finally
        // parsed.
        var updatedOptions = decoder.options
        updatedOptions.messageDepthLimit = decoder.scanner.recursionBudget
        state = .contentJSON(jsonEncoder.dataResult, updatedOptions)
        return
      }
      try decoder.scanner.skipRequiredComma()
    }
  }
}
