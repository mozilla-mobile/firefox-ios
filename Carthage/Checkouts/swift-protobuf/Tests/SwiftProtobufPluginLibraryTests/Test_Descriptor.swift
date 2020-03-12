// Tests/SwiftProtobufPluginLibraryTests/Test_Descriptor.swift - Test Descriptor.swift
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

class Test_Descriptor: XCTestCase {

  func testParsing() throws {
    let fileSet = try Google_Protobuf_FileDescriptorSet(serializedData: fileDescriptorSetData)

    let descriptorSet = DescriptorSet(proto: fileSet)
    XCTAssertEqual(descriptorSet.files.count, 4)
    // descriptor.proto documents the protoc will order the files based on the import
    // from plugin on descriptor.
    XCTAssertEqual(descriptorSet.files[0].name, "google/protobuf/descriptor.proto")
    XCTAssertEqual(descriptorSet.files[1].name, "google/protobuf/compiler/plugin.proto")
    XCTAssertEqual(descriptorSet.files[2].name, "pluginlib_descriptor_test.proto")
    XCTAssertEqual(descriptorSet.files[3].name, "SwiftProtobufPluginLibrary/swift_protobuf_module_mappings.proto")

    let pluginFileDescriptor = descriptorSet.files[1]

    XCTAssertEqual(pluginFileDescriptor.messages.count, 3)
    XCTAssertEqual(pluginFileDescriptor.messages[0].fullName, ".google.protobuf.compiler.Version")
    XCTAssertNil(pluginFileDescriptor.messages[0].containingType)
    XCTAssertEqual(pluginFileDescriptor.messages[0].messages.count, 0)
    XCTAssertEqual(pluginFileDescriptor.messages[1].fullName, ".google.protobuf.compiler.CodeGeneratorRequest")
    XCTAssertNil(pluginFileDescriptor.messages[1].containingType)
    XCTAssertEqual(pluginFileDescriptor.messages[1].messages.count, 0)
    XCTAssertEqual(pluginFileDescriptor.messages[2].fullName, ".google.protobuf.compiler.CodeGeneratorResponse")
    XCTAssertNil(pluginFileDescriptor.messages[2].containingType)
    XCTAssertEqual(pluginFileDescriptor.messages[2].messages.count, 1)
    XCTAssertEqual(pluginFileDescriptor.messages[2].messages[0].fullName, ".google.protobuf.compiler.CodeGeneratorResponse.File")
    XCTAssertTrue(pluginFileDescriptor.messages[2].messages[0].containingType === pluginFileDescriptor.messages[2])

    let descriptorFileDescriptor = descriptorSet.files[0]

    XCTAssertEqual(descriptorFileDescriptor.enums.count, 0)
    XCTAssertEqual(descriptorFileDescriptor.messages[4].enums.count, 2)
    XCTAssertEqual(descriptorFileDescriptor.messages[4].enums[0].fullName, ".google.protobuf.FieldDescriptorProto.Type")
    XCTAssertTrue(descriptorFileDescriptor.messages[4].enums[0].containingType === descriptorFileDescriptor.messages[4])
    XCTAssertEqual(descriptorFileDescriptor.messages[4].enums[1].fullName, ".google.protobuf.FieldDescriptorProto.Label")
    XCTAssertTrue(descriptorFileDescriptor.messages[4].enums[1].containingType === descriptorFileDescriptor.messages[4])

    let testFileDesciptor = descriptorSet.files[2]

    XCTAssertEqual(testFileDesciptor.enums.count, 1)
    XCTAssertEqual(testFileDesciptor.enums[0].fullName, ".swift_descriptor_test.TopLevelEnum")
    XCTAssertNil(testFileDesciptor.enums[0].containingType)

    XCTAssertEqual(testFileDesciptor.messages[0].oneofs.count, 1)
    XCTAssertEqual(testFileDesciptor.messages[0].oneofs[0].name, "o")
    XCTAssertEqual(testFileDesciptor.messages[1].oneofs.count, 0)

    XCTAssertEqual(testFileDesciptor.extensions.count, 1)
    XCTAssertEqual(testFileDesciptor.extensions[0].name, "ext_str")
    XCTAssertEqual(testFileDesciptor.messages[3].extensions.count, 2)
    XCTAssertEqual(testFileDesciptor.messages[3].extensions[0].name, "ext_enum")
    XCTAssertEqual(testFileDesciptor.messages[3].extensions[1].name, "ext_msg")

    XCTAssertEqual(testFileDesciptor.services.count, 1)
    XCTAssertEqual(testFileDesciptor.services[0].fullName, ".swift_descriptor_test.SomeService")
    XCTAssertEqual(testFileDesciptor.services[0].methods.count, 2)
    XCTAssertEqual(testFileDesciptor.services[0].methods[0].name, "Foo")
    XCTAssertEqual(testFileDesciptor.services[0].methods[1].name, "Bar")
  }

  func testLookup() throws {
    let fileSet = try Google_Protobuf_FileDescriptorSet(serializedData: fileDescriptorSetData)

    let descriptorSet = DescriptorSet(proto: fileSet)

    XCTAssertTrue(descriptorSet.lookupFileDescriptor(protoName: "google/protobuf/descriptor.proto") === descriptorSet.files[0])
    XCTAssertTrue(descriptorSet.lookupFileDescriptor(protoName: "google/protobuf/compiler/plugin.proto") === descriptorSet.files[1])

    XCTAssertTrue(descriptorSet.lookupDescriptor(protoName: ".google.protobuf.compiler.CodeGeneratorRequest") === descriptorSet.files[1].messages[1])
    XCTAssertTrue(descriptorSet.lookupDescriptor(protoName: ".google.protobuf.DescriptorProto") === descriptorSet.files[0].messages[2])
    XCTAssertTrue(descriptorSet.lookupDescriptor(protoName: ".google.protobuf.DescriptorProto.ExtensionRange") === descriptorSet.files[0].messages[2].messages[0])

    XCTAssertTrue(descriptorSet.lookupEnumDescriptor(protoName: ".google.protobuf.FieldDescriptorProto.Type") === descriptorSet.files[0].messages[4].enums[0])
    XCTAssertTrue(descriptorSet.lookupEnumDescriptor(protoName: ".google.protobuf.FieldDescriptorProto.Label") === descriptorSet.files[0].messages[4].enums[1])

    XCTAssertTrue(descriptorSet.lookupServiceDescriptor(protoName: ".swift_descriptor_test.SomeService") === descriptorSet.files[2].services[0])
  }

  func testParents() throws {
    let fileSet = try Google_Protobuf_FileDescriptorSet(serializedData: fileDescriptorSetData)

    let descriptorSet = DescriptorSet(proto: fileSet)

    let codeGenResponse = descriptorSet.lookupDescriptor(protoName: ".google.protobuf.compiler.CodeGeneratorResponse")
    XCTAssertTrue(codeGenResponse.containingType == nil)
    let codeGenResponseFile = descriptorSet.lookupDescriptor(protoName: ".google.protobuf.compiler.CodeGeneratorResponse.File")
    XCTAssertTrue(codeGenResponseFile.containingType === codeGenResponse)

    let fieldDescProto = descriptorSet.lookupDescriptor(protoName: ".google.protobuf.FieldDescriptorProto")
    let fieldDescType = descriptorSet.lookupEnumDescriptor(protoName: ".google.protobuf.FieldDescriptorProto.Type")
    XCTAssertTrue(fieldDescType.containingType === fieldDescProto)
    let fieldDescLabel = descriptorSet.lookupEnumDescriptor(protoName: ".google.protobuf.FieldDescriptorProto.Label")
    XCTAssertTrue(fieldDescLabel.containingType === fieldDescProto)

    let serviceDescProto = descriptorSet.lookupServiceDescriptor(protoName: ".swift_descriptor_test.SomeService")
    let fooMethod = serviceDescProto.methods[0]
    XCTAssertTrue(fooMethod.service === serviceDescProto)
    let barMethod = serviceDescProto.methods[1]
    XCTAssertTrue(barMethod.service === serviceDescProto)

    let descriptorFile = descriptorSet.files[0]
    let pluginFile = descriptorSet.files[1]
    let descriptorTestFile = descriptorSet.files[2]

    XCTAssertTrue(codeGenResponse.file === pluginFile)
    XCTAssertTrue(codeGenResponseFile.file === pluginFile)

    XCTAssertTrue(fieldDescProto.file === descriptorFile)
    XCTAssertTrue(fieldDescType.file === descriptorFile)
    XCTAssertTrue(fieldDescLabel.file === descriptorFile)

    XCTAssertTrue(serviceDescProto.file === descriptorTestFile)
  }

  func testFields() throws {
    let fileSet = try Google_Protobuf_FileDescriptorSet(serializedData: fileDescriptorSetData)

    let descriptorSet = DescriptorSet(proto: fileSet)

    let topLevelEnum = descriptorSet.lookupEnumDescriptor(protoName: ".swift_descriptor_test.TopLevelEnum")
    let topLevelMessage = descriptorSet.lookupDescriptor(protoName: ".swift_descriptor_test.TopLevelMessage")
    let subEnum = topLevelMessage.enums[0]
    let subMessage = topLevelMessage.messages[0]
    let topLevelMessage2 = descriptorSet.lookupDescriptor(protoName: ".swift_descriptor_test.TopLevelMessage2")

    XCTAssertEqual(topLevelMessage.fields.count, 6)
    XCTAssertEqual(topLevelMessage.fields[0].name, "field1")
    XCTAssertEqual(topLevelMessage.fields[1].name, "field2")
    XCTAssertEqual(topLevelMessage.fields[2].name, "field3")
    XCTAssertEqual(topLevelMessage.fields[3].name, "field4")
    XCTAssertEqual(topLevelMessage.fields[4].name, "field5")
    XCTAssertEqual(topLevelMessage.fields[5].name, "field6")
    XCTAssertTrue(topLevelMessage.fields[2].enumType === topLevelEnum)
    XCTAssertTrue(topLevelMessage.fields[3].enumType === subEnum)
    XCTAssertTrue(topLevelMessage.fields[4].messageType === subMessage)
    XCTAssertTrue(topLevelMessage.fields[5].messageType === topLevelMessage2)

    let oneof = topLevelMessage.oneofs[0]
    XCTAssertTrue(oneof.containingType === topLevelMessage)
    XCTAssertEqual(oneof.fields.count, 4)
    XCTAssertTrue(oneof.fields[0] === topLevelMessage.fields[2])
    XCTAssertTrue(oneof.fields[1] === topLevelMessage.fields[3])
    XCTAssertTrue(oneof.fields[2] === topLevelMessage.fields[4])
    XCTAssertTrue(oneof.fields[3] === topLevelMessage.fields[5])

    XCTAssertEqual(topLevelMessage2.fields.count, 2)
    XCTAssertEqual(topLevelMessage2.fields[0].name, "left")
    XCTAssertEqual(topLevelMessage2.fields[1].name, "right")
    XCTAssertTrue(topLevelMessage2.fields[0].messageType === topLevelMessage)
    XCTAssertTrue(topLevelMessage2.fields[1].messageType === topLevelMessage2)

    let externalRefs = descriptorSet.lookupDescriptor(protoName: ".swift_descriptor_test.ExternalRefs")
    let googleProtobufDescriptorProto = descriptorSet.lookupDescriptor(protoName: ".google.protobuf.DescriptorProto")
    let googleProtobufCompilerVersion = descriptorSet.lookupDescriptor(protoName: ".google.protobuf.compiler.Version")

    XCTAssertEqual(externalRefs.fields.count, 2)
    XCTAssertEqual(externalRefs.fields[0].name, "desc")
    XCTAssertEqual(externalRefs.fields[1].name, "ver")
    XCTAssertTrue(externalRefs.fields[0].messageType === googleProtobufDescriptorProto)
    XCTAssertTrue(externalRefs.fields[1].messageType === googleProtobufCompilerVersion)
  }

  func testExtensions() throws {
    // Extensions are a little different in how they have extensionScope and
    // containingType, so they are split out to be a clear test of their behaviors.

    let fileSet = try Google_Protobuf_FileDescriptorSet(serializedData: fileDescriptorSetData)

    let descriptorSet = DescriptorSet(proto: fileSet)

    let googleProtobufFieldOptions = descriptorSet.lookupDescriptor(protoName: ".google.protobuf.FieldOptions")
    let googleProtobufMessageOptions = descriptorSet.lookupDescriptor(protoName: ".google.protobuf.MessageOptions")

    let descriptorTestFile = descriptorSet.files[2]

    let topLevelExt = descriptorTestFile.extensions[0]
    XCTAssertNil(topLevelExt.extensionScope)
    XCTAssertTrue(topLevelExt.containingType === googleProtobufFieldOptions)

    let extScoper = descriptorSet.lookupDescriptor(protoName: ".swift_descriptor_test.ScoperForExt")
    let nestedExt1 = descriptorTestFile.messages[3].extensions[0]
    let nestedExt2 = descriptorTestFile.messages[3].extensions[1]
    XCTAssertTrue(nestedExt1.extensionScope === extScoper)
    XCTAssertTrue(nestedExt1.containingType === googleProtobufMessageOptions)
    XCTAssertTrue(nestedExt2.extensionScope === extScoper)
    XCTAssertTrue(nestedExt2.containingType === googleProtobufMessageOptions)

    XCTAssertTrue(nestedExt1.enumType === descriptorTestFile.enums[0])
    XCTAssertTrue(nestedExt2.messageType === descriptorTestFile.messages[1])

    XCTAssertTrue(topLevelExt.file === descriptorTestFile)
    XCTAssertTrue(nestedExt1.file === descriptorTestFile)
    XCTAssertTrue(nestedExt2.file === descriptorTestFile)
  }

}
