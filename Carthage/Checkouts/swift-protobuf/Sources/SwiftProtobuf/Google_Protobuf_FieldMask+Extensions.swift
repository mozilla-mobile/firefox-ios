// Sources/SwiftProtobuf/Google_Protobuf_FieldMask+Extensions.swift - Fieldmask extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extend the generated FieldMask message with customized JSON coding and
/// convenience methods.
///
// -----------------------------------------------------------------------------

// TODO: We should have utilities to apply a fieldmask to an arbitrary
// message, intersect two fieldmasks, etc.

private func ProtoToJSON(name: String) -> String? {
  var jsonPath = String()
  var chars = name.makeIterator()
  while let c = chars.next() {
    switch c {
    case "_":
      if let toupper = chars.next() {
        switch toupper {
        case "a"..."z":
          jsonPath.append(String(toupper).uppercased())
        default:
          return nil
        }
      } else {
        return nil
      }
    case "A"..."Z":
      return nil
    default:
      jsonPath.append(c)
    }
  }
  return jsonPath
}

private func JSONToProto(name: String) -> String? {
  var path = String()
  for c in name {
    switch c {
    case "_":
      return nil
    case "A"..."Z":
      path.append(Character("_"))
      path.append(String(c).lowercased())
    default:
      path.append(c)
    }
  }
  return path
}

private func parseJSONFieldNames(names: String) -> [String]? {
  // An empty field mask is the empty string (no paths).
  guard !names.isEmpty else { return [] }
  var fieldNameCount = 0
  var fieldName = String()
  var split = [String]()
  for c in names {
    switch c {
    case ",":
      if fieldNameCount == 0 {
        return nil
      }
      if let pbName = JSONToProto(name: fieldName) {
        split.append(pbName)
      } else {
        return nil
      }
      fieldName = String()
      fieldNameCount = 0
    default:
      fieldName.append(c)
      fieldNameCount += 1
    }
  }
  if fieldNameCount == 0 { // Last field name can't be empty
    return nil
  }
  if let pbName = JSONToProto(name: fieldName) {
    split.append(pbName)
  } else {
    return nil
  }
  return split
}

extension Google_Protobuf_FieldMask {
  /// Creates a new `Google_Protobuf_FieldMask` from the given array of paths.
  ///
  /// The paths should match the names used in the .proto file, which may be
  /// different than the corresponding Swift property names.
  ///
  /// - Parameter protoPaths: The paths from which to create the field mask,
  ///   defined using the .proto names for the fields.
  public init(protoPaths: [String]) {
    self.init()
    paths = protoPaths
  }

  /// Creates a new `Google_Protobuf_FieldMask` from the given paths.
  ///
  /// The paths should match the names used in the .proto file, which may be
  /// different than the corresponding Swift property names.
  ///
  /// - Parameter protoPaths: The paths from which to create the field mask,
  ///   defined using the .proto names for the fields.
  public init(protoPaths: String...) {
    self.init(protoPaths: protoPaths)
  }

  /// Creates a new `Google_Protobuf_FieldMask` from the given paths.
  ///
  /// The paths should match the JSON names of the fields, which may be
  /// different than the corresponding Swift property names.
  ///
  /// - Parameter jsonPaths: The paths from which to create the field mask,
  ///   defined using the JSON names for the fields.
  public init?(jsonPaths: String...) {
    // TODO: This should fail if any of the conversions from JSON fails
    #if swift(>=4.1)
      self.init(protoPaths: jsonPaths.compactMap(JSONToProto))
    #else
      self.init(protoPaths: jsonPaths.flatMap(JSONToProto))
    #endif
  }

  // It would be nice if to have an initializer that accepted Swift property
  // names, but translating between swift and protobuf/json property
  // names is not entirely deterministic.
}

extension Google_Protobuf_FieldMask: _CustomJSONCodable {
  mutating func decodeJSON(from decoder: inout JSONDecoder) throws {
    let s = try decoder.scanner.nextQuotedString()
    if let names = parseJSONFieldNames(names: s) {
      paths = names
    } else {
      throw JSONDecodingError.malformedFieldMask
    }
  }

  func encodedJSONString(options: JSONEncodingOptions) throws -> String {
    // Note:  Proto requires alphanumeric field names, so there
    // cannot be a ',' or '"' character to mess up this formatting.
    var jsonPaths = [String]()
    for p in paths {
      if let jsonPath = ProtoToJSON(name: p) {
        jsonPaths.append(jsonPath)
      } else {
        throw JSONEncodingError.fieldMaskConversion
      }
    }
    return "\"" + jsonPaths.joined(separator: ",") + "\""
  }
}
