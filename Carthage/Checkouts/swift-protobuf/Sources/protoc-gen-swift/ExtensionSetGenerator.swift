// Sources/protoc-gen-swift/ExtensionSetGenerator.swift - Handle Proto2 extension
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Each instance of ExtensionGenerator represents a single Proto2 extension
/// and contains the logic necessary to emit the various required sources.
/// Note that this wraps the same FieldDescriptorProto used by MessageFieldGenerator,
/// even though the Swift source emitted is very, very different.
///
// -----------------------------------------------------------------------------
import Foundation
import SwiftProtobufPluginLibrary
import SwiftProtobuf

/// Provides the generation for proto2 syntax extensions in a file.
class ExtensionSetGenerator {

    /// Private helper used for the ExtensionSetGenerator.
    private class ExtensionGenerator {
        let fieldDescriptor: FieldDescriptor
        let generatorOptions: GeneratorOptions
        let namer: SwiftProtobufNamer

        let comments: String
        let containingTypeSwiftFullName: String
        let swiftFullExtensionName: String

        var extensionFieldType: String {
            let label: String
            switch fieldDescriptor.label {
            case .optional: label = "Optional"
            case .required: label = "Required"
            case .repeated: label = fieldDescriptor.isPacked ? "Packed" : "Repeated"
            }

            let modifier: String
            switch fieldDescriptor.type {
            case .group: modifier = "Group"
            case .message: modifier = "Message"
            case .enum: modifier = "Enum"
            default: modifier = ""
            }

            return "SwiftProtobuf.\(label)\(modifier)ExtensionField"
        }

        init(descriptor: FieldDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer) {
            self.fieldDescriptor = descriptor
            self.generatorOptions = generatorOptions
            self.namer = namer

            swiftFullExtensionName = namer.fullName(extensionField: descriptor)

            comments = descriptor.protoSourceComments()
            containingTypeSwiftFullName = namer.fullName(message: fieldDescriptor.containingType)
        }

        func generateProtobufExtensionDeclarations(printer p: inout CodePrinter) {
            let scope = fieldDescriptor.extensionScope == nil ? "" : "static "
            let traitsType = fieldDescriptor.traitsType(namer: namer)
            let swiftRelativeExtensionName = namer.relativeName(extensionField: fieldDescriptor)

            var fieldNamePath: String
            if fieldDescriptor.containingType.useMessageSetWireFormat &&
                fieldDescriptor.type == .message &&
                fieldDescriptor.label == .optional &&
                fieldDescriptor.messageType === fieldDescriptor.extensionScope {
                fieldNamePath = fieldDescriptor.messageType.fullName
            } else {
                fieldNamePath = fieldDescriptor.fullName
            }
            assert(fieldNamePath.hasPrefix("."))
            fieldNamePath.remove(at: fieldNamePath.startIndex)  // Remove the leading '.'

            p.print(
              comments,
              "\(scope)let \(swiftRelativeExtensionName) = SwiftProtobuf.MessageExtension<\(extensionFieldType)<\(traitsType)>, \(containingTypeSwiftFullName)>(\n")
            p.indent()
            p.print(
              "_protobuf_fieldNumber: \(fieldDescriptor.number),\n",
              "fieldName: \"\(fieldNamePath)\"\n")
            p.outdent()
            p.print(")\n")
        }

        func generateMessageSwiftExtension(printer p: inout CodePrinter) {
            let visibility = generatorOptions.visibilitySourceSnippet
            let apiType = fieldDescriptor.swiftType(namer: namer)
            let extensionNames = namer.messagePropertyNames(extensionField: fieldDescriptor)
            let defaultValue = fieldDescriptor.swiftDefaultValue(namer: namer)

            // ExtensionGenerator.Set provides the context to write out the properties.

            p.print(
              "\n",
              comments,
              "\(visibility)var \(extensionNames.value): \(apiType) {\n")
            p.indent()
            p.print(
              "get {return getExtensionValue(ext: \(swiftFullExtensionName)) ?? \(defaultValue)}\n",
              "set {setExtensionValue(ext: \(swiftFullExtensionName), value: newValue)}\n")
            p.outdent()
            p.print("}\n")

            p.print(
                "/// Returns true if extension `\(swiftFullExtensionName)`\n/// has been explicitly set.\n",
                "\(visibility)var \(extensionNames.has): Bool {\n")
            p.indent()
            p.print("return hasExtensionValue(ext: \(swiftFullExtensionName))\n")
            p.outdent()
            p.print("}\n")

            p.print(
                "/// Clears the value of extension `\(swiftFullExtensionName)`.\n/// Subsequent reads from it will return its default value.\n",
                "\(visibility)mutating func \(extensionNames.clear)() {\n")
            p.indent()
            p.print("clearExtensionValue(ext: \(swiftFullExtensionName))\n")
            p.outdent()
            p.print("}\n")
        }
    }

    private let fileDescriptor: FileDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer

    // The order of these is as they are created, so it keeps them grouped by
    // where they were declared.
    private var extensions: [ExtensionGenerator] = []

    var isEmpty: Bool { return extensions.isEmpty }

    init(
      fileDescriptor: FileDescriptor,
      generatorOptions: GeneratorOptions,
      namer: SwiftProtobufNamer
    ) {
        self.fileDescriptor = fileDescriptor
        self.generatorOptions = generatorOptions
        self.namer = namer
    }

    func add(extensionFields: [FieldDescriptor]) {
        for e in extensionFields {
            assert(e.isExtension)
            let extensionGenerator = ExtensionGenerator(descriptor: e,
                                                        generatorOptions: generatorOptions,
                                                        namer: namer)
            extensions.append(extensionGenerator)
        }
    }

    func generateMessageSwiftExtensions(printer p: inout CodePrinter) {
        guard !extensions.isEmpty else { return }

        // Reorder the list so they are grouped by the Message being extended, but
        // maintaining the order they were within the file within those groups.
        let grouped: [ExtensionGenerator] = extensions.enumerated().sorted {
            // When they extend the same Message, use the original order.
            if $0.element.containingTypeSwiftFullName == $1.element.containingTypeSwiftFullName {
                return $0.offset < $1.offset
            }
            // Otherwise, sort by the Message being extended.
            return $0.element.containingTypeSwiftFullName < $1.element.containingTypeSwiftFullName
        }.map {
            // Now strip off the original index to just get the list of ExtensionGenerators
            // again.
            return $0.element
        }

        // Loop through the group list and each time a new containing type is hit,
        // generate the Swift Extension block. This way there is only one Swift
        // Extension for each Message rather then one for every extension.  This make
        // the file a little easier to navigate.
        var currentType: String = ""
        for e in grouped {
            if currentType != e.containingTypeSwiftFullName {
                if !currentType.isEmpty {
                    p.outdent()
                    p.print("}\n")
                }
                currentType = e.containingTypeSwiftFullName
                p.print(
                  "\n",
                  "extension \(currentType) {\n")
                p.indent()
            }
            e.generateMessageSwiftExtension(printer: &p)
        }
        p.outdent()
        p.print(
          "\n",
          "}\n")
    }

    func generateFileProtobufExtensionRegistry(printer p: inout CodePrinter) {
        guard !extensions.isEmpty else { return }

        let pathParts = splitPath(pathname: fileDescriptor.name)
        let filenameAsIdentifer = NamingUtils.toUpperCamelCase(pathParts.base)
        let filePrefix = namer.typePrefix(forFile: fileDescriptor)
        p.print(
          "\n",
          "/// A `SwiftProtobuf.SimpleExtensionMap` that includes all of the extensions defined by\n",
          "/// this .proto file. It can be used any place an `SwiftProtobuf.ExtensionMap` is needed\n",
          "/// in parsing, or it can be combined with other `SwiftProtobuf.SimpleExtensionMap`s to create\n",
          "/// a larger `SwiftProtobuf.SimpleExtensionMap`.\n",
          "\(generatorOptions.visibilitySourceSnippet)let \(filePrefix)\(filenameAsIdentifer)_Extensions: SwiftProtobuf.SimpleExtensionMap = [\n")
        p.indent()
        var separator = ""
        for e in extensions {
            p.print(separator, e.swiftFullExtensionName)
            separator = ",\n"
        }
        p.print("\n")
        p.outdent()
        p.print("]\n")
    }

    func generateProtobufExtensionDeclarations(printer p: inout CodePrinter) {
      guard !extensions.isEmpty else { return }

      func endScope() {
          p.outdent()
          p.print("}\n")
          p.outdent()
          p.print("}\n")
      }

      var currentScope: Descriptor? = nil
      var addNewline = true
      for e in extensions {
        if currentScope !== e.fieldDescriptor.extensionScope {
          if currentScope != nil { endScope() }
          currentScope = e.fieldDescriptor.extensionScope
          let scopeSwiftFullName = namer.fullName(message: currentScope!)
          p.print(
            "\n",
            "extension \(scopeSwiftFullName) {\n")
          p.indent()
          p.print("enum Extensions {\n")
          p.indent()
          addNewline = false
        }

        if addNewline {
          p.print("\n")
        } else {
          addNewline = true
        }
        e.generateProtobufExtensionDeclarations(printer: &p)
      }
      if currentScope != nil { endScope() }
    }
}
