// Sources/protoc-gen-swift/MessageFieldGenerator.swift - Facts about a single message field
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This code mostly handles the complex mapping between proto types and
/// the types provided by the Swift Protobuf Runtime.
///
// -----------------------------------------------------------------------------
import Foundation
import SwiftProtobufPluginLibrary
import SwiftProtobuf


class MessageFieldGenerator: FieldGeneratorBase, FieldGenerator {
    private let generatorOptions: GeneratorOptions
    private let usesHeapStorage: Bool

    private let hasFieldPresence: Bool
    private let swiftName: String
    private let underscoreSwiftName: String
    private let storedProperty: String
    private let swiftHasName: String
    private let swiftClearName: String
    private let swiftType: String
    private let swiftStorageType: String
    private let swiftDefaultValue: String
    private let traitsType: String
    private let comments: String

    private var isMap: Bool {return fieldDescriptor.isMap}
    private var isPacked: Bool { return fieldDescriptor.isPacked }

    // Note: this could still be a map (since those are repeated message fields
    private var isRepeated: Bool {return fieldDescriptor.label == .repeated}
    private var isGroupOrMessage: Bool {
      switch fieldDescriptor.type {
      case .group, .message:
        return true
      default:
        return false
      }
    }

    init(descriptor: FieldDescriptor,
         generatorOptions: GeneratorOptions,
         namer: SwiftProtobufNamer,
         usesHeapStorage: Bool)
    {
        precondition(descriptor.oneofIndex == nil)

        self.generatorOptions = generatorOptions
        self.usesHeapStorage = usesHeapStorage

        hasFieldPresence = descriptor.hasFieldPresence
        let names = namer.messagePropertyNames(field: descriptor,
                                               prefixed: "_",
                                               includeHasAndClear: hasFieldPresence)
        swiftName = names.name
        underscoreSwiftName = names.prefixed
        swiftHasName = names.has
        swiftClearName = names.clear
        swiftType = descriptor.swiftType(namer: namer)
        swiftStorageType = descriptor.swiftStorageType(namer: namer)
        swiftDefaultValue = descriptor.swiftDefaultValue(namer: namer)
        traitsType = descriptor.traitsType(namer: namer)
        comments = descriptor.protoSourceComments()

        if usesHeapStorage {
            storedProperty = "_storage.\(underscoreSwiftName)"
        } else {
            storedProperty = "self.\(hasFieldPresence ? underscoreSwiftName : swiftName)"
        }

        super.init(descriptor: descriptor)
    }

    func generateStorage(printer p: inout CodePrinter) {
        let defaultValue = hasFieldPresence ? "nil" : swiftDefaultValue
        if usesHeapStorage {
            p.print("var \(underscoreSwiftName): \(swiftStorageType) = \(defaultValue)\n")
        } else {
          // If this field has field presence, the there is a private storage variable.
          if hasFieldPresence {
              p.print("fileprivate var \(underscoreSwiftName): \(swiftStorageType) = \(defaultValue)\n")
          }
        }
    }

    func generateInterface(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        p.print("\n", comments)

        if usesHeapStorage {
            p.print(
              "\(visibility)var \(swiftName): \(swiftType) {\n")
            p.indent()
            let defaultClause = hasFieldPresence ? " ?? \(swiftDefaultValue)" : ""
            p.print(
              "get {return _storage.\(underscoreSwiftName)\(defaultClause)}\n",
              "set {_uniqueStorage().\(underscoreSwiftName) = newValue}\n")
            p.outdent()
            p.print("}\n")
        } else {
            if hasFieldPresence {
                p.print("\(visibility)var \(swiftName): \(swiftType) {\n")
                p.indent()
                p.print(
                  "get {return \(underscoreSwiftName) ?? \(swiftDefaultValue)}\n",
                  "set {\(underscoreSwiftName) = newValue}\n")
                p.outdent()
                p.print("}\n")
            } else {
                p.print("\(visibility)var \(swiftName): \(swiftStorageType) = \(swiftDefaultValue)\n")
            }
        }

        guard hasFieldPresence else { return }

        let immutableStoragePrefix = usesHeapStorage ? "_storage." : "self."
        p.print(
            "/// Returns true if `\(swiftName)` has been explicitly set.\n",
            "\(visibility)var \(swiftHasName): Bool {return \(immutableStoragePrefix)\(underscoreSwiftName) != nil}\n")

        let mutableStoragePrefix = usesHeapStorage ? "_uniqueStorage()." : "self."
        p.print(
            "/// Clears the value of `\(swiftName)`. Subsequent reads from it will return its default value.\n",
            "\(visibility)mutating func \(swiftClearName)() {\(mutableStoragePrefix)\(underscoreSwiftName) = nil}\n")
    }

    func generateStorageClassClone(printer p: inout CodePrinter) {
        p.print("\(underscoreSwiftName) = source.\(underscoreSwiftName)\n")
    }

    func generateFieldComparison(printer p: inout CodePrinter) {
        let lhsProperty: String
        let otherStoredProperty: String
        if usesHeapStorage {
            lhsProperty = "_storage.\(underscoreSwiftName)"
            otherStoredProperty = "rhs_storage.\(underscoreSwiftName)"
        } else {
            lhsProperty = "lhs.\(hasFieldPresence ? underscoreSwiftName : swiftName)"
            otherStoredProperty = "rhs.\(hasFieldPresence ? underscoreSwiftName : swiftName)"
        }

        p.print("if \(lhsProperty) != \(otherStoredProperty) {return false}\n")
    }

   func generateRequiredFieldCheck(printer p: inout CodePrinter) {
       guard fieldDescriptor.label == .required else { return }
       p.print("if \(storedProperty) == nil {return false}\n")
    }

    func generateIsInitializedCheck(printer p: inout CodePrinter) {
        guard isGroupOrMessage && fieldDescriptor.messageType.hasRequiredFields() else { return }

        if isRepeated {  // Map or Array
            p.print("if !SwiftProtobuf.Internal.areAllInitialized(\(storedProperty)) {return false}\n")
        } else {
            p.print("if let v = \(storedProperty), !v.isInitialized {return false}\n")
        }
    }

    func generateDecodeFieldCase(printer p: inout CodePrinter) {
        let decoderMethod: String
        let traitsArg: String
        if isMap {
            decoderMethod = "decodeMapField"
            traitsArg = "fieldType: \(traitsType).self, "
        } else {
            let modifier = isRepeated ? "Repeated" : "Singular"
            decoderMethod = "decode\(modifier)\(fieldDescriptor.protoGenericType)Field"
            traitsArg = ""
        }

        p.print("case \(number): try decoder.\(decoderMethod)(\(traitsArg)value: &\(storedProperty))\n")
    }

    func generateTraverse(printer p: inout CodePrinter) {
        let visitMethod: String
        let traitsArg: String
        if isMap {
            visitMethod = "visitMapField"
            traitsArg = "fieldType: \(traitsType).self, "
        } else {
            let modifier = isPacked ? "Packed" : isRepeated ? "Repeated" : "Singular"
            visitMethod = "visit\(modifier)\(fieldDescriptor.protoGenericType)Field"
            traitsArg = ""
        }

        let varName = hasFieldPresence ? "v" : storedProperty

        let conditional: String
        if isRepeated {  // Also covers maps
            conditional = "!\(varName).isEmpty"
        } else if hasFieldPresence {
            conditional = "let v = \(storedProperty)"
        } else {
            // At this point, the fields would be a primative type, and should only
            // be visted if it is the non default value.
            assert(fieldDescriptor.file.syntax == .proto3)
            switch fieldDescriptor.type {
            case .string, .bytes:
                conditional = ("!\(varName).isEmpty")
            default:
                conditional = ("\(varName) != \(swiftDefaultValue)")
            }
        }

        p.print("if \(conditional) {\n")
        p.indent()
        p.print("try visitor.\(visitMethod)(\(traitsArg)value: \(varName), fieldNumber: \(number))\n")
        p.outdent()
        p.print("}\n")
    }
}
