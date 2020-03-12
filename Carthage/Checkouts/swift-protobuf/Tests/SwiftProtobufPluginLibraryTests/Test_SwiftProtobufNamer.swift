// Tests/SwiftProtobufPluginLibraryTests/Test_SwiftProtobufNamer.swift - Test SwiftProtobufNamer.swift
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------

import XCTest
import SwiftProtobuf
import SwiftProtobufPluginLibrary

class Test_SwiftProtobufNamer: XCTestCase {

  func testEnumValueHandling_AliasNameMatches() throws {
    let txt = [
      "name: \"test.proto\"",
      "syntax: \"proto2\"",
      "enum_type {",
      "  name: \"TestEnum\"",
      "  options {",
      "     allow_alias: true",
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_FOO\"",
      "    number: 0",  // Master
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_BAR\"",
      "    number: 1",
      "  }",
      "  value {",
      "    name: \"TESTENUM_FOO\"",
      "    number: 0",  // Alias
      "  }",
      "  value {",
      "    name: \"_FOO\"",
      "    number: 0",  // Alias
      "  }",
      "  value {",
      "    name: \"FOO\"",
      "    number: 0",  // Alias
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_ALIAS\"",
      "    number: 0",  // Alias (unique name)
      "  }",
      "}"
    ]

    let fileProto: Google_Protobuf_FileDescriptorProto
    do {
     fileProto = try Google_Protobuf_FileDescriptorProto(textFormatStrings: txt)
    } catch let e {
      XCTFail("Error: \(e)")
      return
    }

    let descriptorSet = DescriptorSet(protos: [fileProto])
    let namer =
      SwiftProtobufNamer(currentFile: descriptorSet.lookupFileDescriptor(protoName: "test.proto"),
                         protoFileToModuleMappings: ProtoFileToModuleMappings())

    let e = descriptorSet.lookupEnumDescriptor(protoName: ".TestEnum")
    let values = e.values
    XCTAssertEqual(values.count, 6)

    // Test relativeName(enumValue:)

    XCTAssertEqual(namer.relativeName(enumValue: values[0]), "foo")
    XCTAssertEqual(namer.relativeName(enumValue: values[1]), "bar")
    XCTAssertEqual(namer.relativeName(enumValue: values[2]), "foo")
    XCTAssertEqual(namer.relativeName(enumValue: values[3]), "foo")
    XCTAssertEqual(namer.relativeName(enumValue: values[4]), "foo")
    XCTAssertEqual(namer.relativeName(enumValue: values[5]), "alias")

    // Test uniquelyNamedValues(enum:)

    let filtered = namer.uniquelyNamedValues(enum: e)
    XCTAssertEqual(filtered.count, 3)

    XCTAssertEqual(filtered[0].name, "TEST_ENUM_FOO")
    XCTAssertEqual(filtered[1].name, "TEST_ENUM_BAR")
    XCTAssertEqual(filtered[2].name, "TEST_ENUM_ALIAS")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[0]), "foo")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[1]), "bar")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[2]), "alias")
  }

  func testEnumValueHandling_NameCollisions() {
    let txt = [
      "name: \"test.proto\"",
      "syntax: \"proto2\"",
      "enum_type {",
      "  name: \"TestEnum\"",
      "  value {",
      "    name: \"TEST_ENUM_FOO\"",
      "    number: 0",  // Collision
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_BAR\"",
      "    number: 1",
      "  }",
      "  value {",
      "    name: \"TESTENUM_FOO\"",
      "    number: 2",  // Collision
      "  }",
      "  value {",
      "    name: \"_FOO\"",
      "    number: -1",  // Collision - negative value
      "  }",
      "}"
    ]

    let fileProto: Google_Protobuf_FileDescriptorProto
    do {
      fileProto = try Google_Protobuf_FileDescriptorProto(textFormatStrings: txt)
    } catch let e {
      XCTFail("Error: \(e)")
      return
    }

    let descriptorSet = DescriptorSet(protos: [fileProto])
    let namer =
      SwiftProtobufNamer(currentFile: descriptorSet.lookupFileDescriptor(protoName: "test.proto"),
                         protoFileToModuleMappings: ProtoFileToModuleMappings())

    let e = descriptorSet.lookupEnumDescriptor(protoName: ".TestEnum")
    let values = e.values
    XCTAssertEqual(values.count, 4)

    // Test relativeName(enumValue:)

    XCTAssertEqual(namer.relativeName(enumValue: values[0]), "foo_0")
    XCTAssertEqual(namer.relativeName(enumValue: values[1]), "bar")
    XCTAssertEqual(namer.relativeName(enumValue: values[2]), "foo_2")
    XCTAssertEqual(namer.relativeName(enumValue: values[3]), "foo_n1")

    // Test uniquelyNamedValues(enum:)

    let filtered = namer.uniquelyNamedValues(enum: e)
    XCTAssertEqual(filtered.count, 4)

    XCTAssertEqual(filtered[0].name, "TEST_ENUM_FOO")
    XCTAssertEqual(filtered[1].name, "TEST_ENUM_BAR")
    XCTAssertEqual(filtered[2].name, "TESTENUM_FOO")
    XCTAssertEqual(filtered[3].name, "_FOO")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[0]), "foo_0")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[1]), "bar")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[2]), "foo_2")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[3]), "foo_n1")
  }

  func testEnumValueHandling_NameCollisionsAndAliasMatches() {
    let txt = [
      "name: \"test.proto\"",
      "syntax: \"proto2\"",
      "enum_type {",
      "  name: \"TestEnum\"",
      "  options {",
      "     allow_alias: true",
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_FOO\"",
      "    number: 0",  // Collision/Master0
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_BAR\"",
      "    number: 1",
      "  }",
      "  value {",
      "    name: \"TESTENUM_FOO\"",
      "    number: 0",  // Alias 0
      "  }",
      "  value {",
      "    name: \"_FOO\"",
      "    number: 2",  // Collision/Master2
      "  }",
      "  value {",
      "    name: \"FOO\"",
      "    number: 2",  // Alias 2
      "  }",
      "  value {",
      "    name: \"TEST_ENUM_ALIAS\"",
      "    number: 0",  // Alias 0 - Unique name
      "  }",
      "  value {",
      "    name: \"mumble\"",
      "    number: 1",  // Alias 1 - Collision with next alias
      "  }",
      "  value {",
      "    name: \"MUMBLE\"",
      "    number: 0",  // Alias 0 - Collision with previous alias
      "  }",
      "}"
    ]

    let fileProto: Google_Protobuf_FileDescriptorProto
    do {
      fileProto = try Google_Protobuf_FileDescriptorProto(textFormatStrings: txt)
    } catch let e {
      XCTFail("Error: \(e)")
      return
    }

    let descriptorSet = DescriptorSet(protos: [fileProto])
    let namer =
      SwiftProtobufNamer(currentFile: descriptorSet.lookupFileDescriptor(protoName: "test.proto"),
                         protoFileToModuleMappings: ProtoFileToModuleMappings())

    let e = descriptorSet.lookupEnumDescriptor(protoName: ".TestEnum")
    let values = e.values
    XCTAssertEqual(values.count, 8)

    // Test relativeName(enumValue:)

    XCTAssertEqual(namer.relativeName(enumValue: values[0]), "foo_0")
    XCTAssertEqual(namer.relativeName(enumValue: values[1]), "bar")
    XCTAssertEqual(namer.relativeName(enumValue: values[2]), "foo_0")
    XCTAssertEqual(namer.relativeName(enumValue: values[3]), "foo_2")
    XCTAssertEqual(namer.relativeName(enumValue: values[4]), "foo_2")
    XCTAssertEqual(namer.relativeName(enumValue: values[5]), "alias")
    XCTAssertEqual(namer.relativeName(enumValue: values[6]), "mumble_1")
    XCTAssertEqual(namer.relativeName(enumValue: values[7]), "mumble_0")

    // Test uniquelyNamedValues(enum:)

    let filtered = namer.uniquelyNamedValues(enum: e)
    XCTAssertEqual(filtered.count, 6)

    XCTAssertEqual(filtered[0].name, "TEST_ENUM_FOO")
    XCTAssertEqual(filtered[1].name, "TEST_ENUM_BAR")
    XCTAssertEqual(filtered[2].name, "_FOO")
    XCTAssertEqual(filtered[3].name, "TEST_ENUM_ALIAS")
    XCTAssertEqual(filtered[4].name, "mumble")
    XCTAssertEqual(filtered[5].name, "MUMBLE")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[0]), "foo_0")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[1]), "bar")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[2]), "foo_2")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[3]), "alias")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[4]), "mumble_1")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[5]), "mumble_0")
  }

  func testEnumValueHandling_UniqueAliasNameCollisions() {
    // Tests were the aliases collided in naming, but not with
    // the original.

    let txt = [
      "name: \"test.proto\"",
      "syntax: \"proto2\"",
      "enum_type {",
      "  name: \"AliasedEnum\"",
      "  options {",
      "     allow_alias: true",
      "  }",
      "  value {",
      "    name: \"ALIAS_FOO\"",
      "    number: 0",
      "  }",
      "  value {",
      "    name: \"ALIAS_BAR\"",
      "    number: 1",
      "  }",
      "  value {",
      "    name: \"ALIAS_BAZ\"",
      "    number: 2",
      "  }",
      "  value {",
      "    name: \"QUX\"",
      "    number: 2",  // short name merged with the next because they have the same value.
      "  }",
      "  value {",
      "    name: \"qux\"",
      "    number: 2",
      "  }",
      "  value {",
      "    name: \"bAz\"",
      "    number: 2",
      "  }",
      "}"
    ]

    let fileProto: Google_Protobuf_FileDescriptorProto
    do {
      fileProto = try Google_Protobuf_FileDescriptorProto(textFormatStrings: txt)
    } catch let e {
      XCTFail("Error: \(e)")
      return
    }

    let descriptorSet = DescriptorSet(protos: [fileProto])
    let namer =
      SwiftProtobufNamer(currentFile: descriptorSet.lookupFileDescriptor(protoName: "test.proto"),
                         protoFileToModuleMappings: ProtoFileToModuleMappings())

    let e = descriptorSet.lookupEnumDescriptor(protoName: ".AliasedEnum")
    let values = e.values
    XCTAssertEqual(values.count, 6)

    XCTAssertEqual(values[0].name, "ALIAS_FOO")
    XCTAssertEqual(values[1].name, "ALIAS_BAR")
    XCTAssertEqual(values[2].name, "ALIAS_BAZ")
    XCTAssertEqual(values[3].name, "QUX")
    XCTAssertEqual(values[4].name, "qux")
    XCTAssertEqual(values[5].name, "bAz")

    // Test relativeName(enumValue:)

    XCTAssertEqual(namer.relativeName(enumValue: values[0]), "aliasFoo")
    XCTAssertEqual(namer.relativeName(enumValue: values[1]), "aliasBar")
    XCTAssertEqual(namer.relativeName(enumValue: values[2]), "aliasBaz")
    XCTAssertEqual(namer.relativeName(enumValue: values[3]), "qux")
    XCTAssertEqual(namer.relativeName(enumValue: values[4]), "qux")
    XCTAssertEqual(namer.relativeName(enumValue: values[5]), "bAz")

    // Test uniquelyNamedValues(enum:)

    // QUX & qux collided, so only one remains.

    let filtered = namer.uniquelyNamedValues(enum: e)
    XCTAssertEqual(filtered.count, 5)

    XCTAssertEqual(filtered[0].name, "ALIAS_FOO")
    XCTAssertEqual(filtered[1].name, "ALIAS_BAR")
    XCTAssertEqual(filtered[2].name, "ALIAS_BAZ")
    XCTAssertEqual(filtered[3].name, "QUX")
    XCTAssertEqual(filtered[4].name, "bAz")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[0]), "aliasFoo")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[1]), "aliasBar")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[2]), "aliasBaz")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[3]), "qux")
    XCTAssertEqual(namer.relativeName(enumValue: filtered[4]), "bAz")
  }

}
