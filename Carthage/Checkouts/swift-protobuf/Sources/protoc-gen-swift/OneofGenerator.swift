// Sources/protoc-gen-swift/OneofGenerator.swift - Oneof handling
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This class represents a single Oneof in the proto and generates an efficient
/// algebraic enum to store it in memory.
///
// -----------------------------------------------------------------------------
import Foundation
import SwiftProtobufPluginLibrary
import SwiftProtobuf

class OneofGenerator {
    /// Custom FieldGenerator that caches come calculated strings, and bridges
    /// all methods over to the OneofGenerator.
    class MemberFieldGenerator: FieldGeneratorBase, FieldGenerator {
        private weak var oneof: OneofGenerator!
        private(set) var group: Int

        let swiftName: String
        let dottedSwiftName: String
        let swiftType: String
        let swiftDefaultValue: String
        let protoGenericType: String
        let comments: String

        var isGroupOrMessage: Bool {
            switch fieldDescriptor.type {
            case .group, .message:
                return true
            default:
                return false
            }
        }

        // Only valid on message fields.
        var messageType: Descriptor { return fieldDescriptor.messageType }

        init(descriptor: FieldDescriptor, namer: SwiftProtobufNamer) {
            precondition(descriptor.oneofIndex != nil)

            // Set after creation.
            oneof = nil
            group = -1

            let names = namer.messagePropertyNames(field: descriptor,
                                                   prefixed: ".",
                                                   includeHasAndClear: false)
            swiftName = names.name
            dottedSwiftName = names.prefixed
            swiftType = descriptor.swiftType(namer: namer)
            swiftDefaultValue = descriptor.swiftDefaultValue(namer: namer)
            protoGenericType = descriptor.protoGenericType
            comments = descriptor.protoSourceComments()

            super.init(descriptor: descriptor)
        }

        func setParent(_ oneof: OneofGenerator, group: Int) {
            self.oneof = oneof
            self.group = group
        }

        // MARK: Forward all the FieldGenerator methods to the OneofGenerator

        func generateInterface(printer p: inout CodePrinter) {
            oneof.generateInterface(printer: &p, field: self)
        }

        func generateStorage(printer p: inout CodePrinter) {
            oneof.generateStorage(printer: &p, field: self)
        }

        func generateStorageClassClone(printer p: inout CodePrinter) {
            oneof.generateStorageClassClone(printer: &p, field: self)
        }

        func generateDecodeFieldCase(printer p: inout CodePrinter) {
            oneof.generateDecodeFieldCase(printer: &p, field: self)
        }

        func generateFieldComparison(printer p: inout CodePrinter) {
            oneof.generateFieldComparison(printer: &p, field: self)
        }

        func generateRequiredFieldCheck(printer p: inout CodePrinter) {
            // Oneof members are all optional, so no need to forward this.
        }

        func generateIsInitializedCheck(printer p: inout CodePrinter) {
            oneof.generateIsInitializedCheck(printer: &p, field: self)
        }

        func generateTraverse(printer p: inout CodePrinter) {
            oneof.generateTraverse(printer: &p, field: self)
        }
    }

    private let oneofDescriptor: OneofDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer
    private let usesHeapStorage: Bool

    private let fields: [MemberFieldGenerator]
    private let fieldsSortedByNumber: [MemberFieldGenerator]
    // The fields in number order and group into ranges as they are grouped in the parent.
    private let fieldSortedGrouped: [[MemberFieldGenerator]]
    private let swiftRelativeName: String
    private let swiftFullName: String
    private let comments: String

    private let swiftFieldName: String
    private let underscoreSwiftFieldName: String
    private let storedProperty: String

    init(descriptor: OneofDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer, usesHeapStorage: Bool) {
        self.oneofDescriptor = descriptor
        self.generatorOptions = generatorOptions
        self.namer = namer
        self.usesHeapStorage = usesHeapStorage

        comments = descriptor.protoSourceComments()

        swiftRelativeName = namer.relativeName(oneof: descriptor)
        swiftFullName = namer.fullName(oneof: descriptor)
        let names = namer.messagePropertyName(oneof: descriptor)
        swiftFieldName = names.name
        underscoreSwiftFieldName = names.prefixed

        if usesHeapStorage {
            storedProperty = "_storage.\(underscoreSwiftFieldName)"
        } else {
            storedProperty = "self.\(swiftFieldName)"
        }

        fields = descriptor.fields.map {
            return MemberFieldGenerator(descriptor: $0, namer: namer)
        }
        fieldsSortedByNumber = fields.sorted {$0.number < $1.number}

        // Bucked these fields in continuous chunks based on the other fields
        // in the parent and the parent's extension ranges. Insert the `start`
        // from each extension range as an easy way to check for them being
        // mixed in between the fields.
        var parentNumbers = descriptor.containingType.fields.map { Int($0.number) }
        parentNumbers.append(contentsOf: descriptor.containingType.extensionRanges.map { Int($0.start) })
        var parentNumbersIterator = parentNumbers.sorted(by: { $0 < $1 }).makeIterator()
        var nextParentFieldNumber = parentNumbersIterator.next()
        var grouped = [[MemberFieldGenerator]]()
        var currentGroup = [MemberFieldGenerator]()
        for f in fieldsSortedByNumber {
          let nextFieldNumber = f.number
          if nextParentFieldNumber != nextFieldNumber {
            if !currentGroup.isEmpty {
                grouped.append(currentGroup)
                currentGroup.removeAll()
            }
            while nextParentFieldNumber != nextFieldNumber {
                nextParentFieldNumber = parentNumbersIterator.next()
            }
          }
          currentGroup.append(f)
          nextParentFieldNumber = parentNumbersIterator.next()
        }
        if !currentGroup.isEmpty {
            grouped.append(currentGroup)
        }
        self.fieldSortedGrouped = grouped

        // Now that self is fully initialized, set the parent references.
        var group = 0
        for g in fieldSortedGrouped {
            for f in g {
                f.setParent(self, group: group)
            }
            group += 1
        }
    }

    func fieldGenerator(forFieldNumber fieldNumber: Int) -> FieldGenerator {
        for f in fields {
            if f.number == fieldNumber {
                return f
            }
        }
        fatalError("Can't happen")
    }

    func generateMainEnum(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet

        // Repeat the comment from the oneof to provide some context
        // to this enum we generated.
        p.print(
            "\n",
            comments,
            "\(visibility)enum \(swiftRelativeName): Equatable {\n")
        p.indent()

        // Oneof case for each ivar
        for f in fields {
            p.print(
                f.comments,
                "case \(f.swiftName)(\(f.swiftType))\n")
        }

        // Equatable conformance
        p.print("\n")
        p.outdent()
        p.print("#if !swift(>=4.1)\n")
        p.indent()
        p.print(
            "\(visibility)static func ==(lhs: \(swiftFullName), rhs: \(swiftFullName)) -> Bool {\n")
        p.indent()
        p.print("switch (lhs, rhs) {\n")
        for f in fields {
            p.print("case (\(f.dottedSwiftName)(let l), \(f.dottedSwiftName)(let r)): return l == r\n")
        }
        if fields.count > 1 {
            // A tricky edge case: If the oneof only has a single case, then
            // the case pattern generated above is exhaustive and generating a
            // default produces a compiler error. If there is more than one
            // case, then the case patterns are not exhaustive (because we
            // don't compare mismatched pairs), and we have to include a
            // default.
            p.print("default: return false\n")
        }
        p.print("}\n")
        p.outdent()
        p.print("}\n")
        p.outdent()
        p.print("#endif\n")
        p.print("}\n")
    }

    private func gerenateOneofEnumProperty(printer p: inout CodePrinter) {
        let visibility = generatorOptions.visibilitySourceSnippet
        p.print("\n", comments)

        if usesHeapStorage {
            p.print(
              "\(visibility)var \(swiftFieldName): \(swiftRelativeName)? {\n")
            p.indent()
            p.print(
              "get {return _storage.\(underscoreSwiftFieldName)}\n",
              "set {_uniqueStorage().\(underscoreSwiftFieldName) = newValue}\n")
            p.outdent()
            p.print("}\n")
        } else {
            p.print(
              "\(visibility)var \(swiftFieldName): \(swiftFullName)? = nil\n")
        }
    }

    // MARK: Things brindged from MemberFieldGenerator

    func generateInterface(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the oneof enum to get generated.
        if field === fields.first {
          gerenateOneofEnumProperty(printer: &p)
        }

        let getter = usesHeapStorage ? "_storage.\(underscoreSwiftFieldName)" : swiftFieldName
        let setter = usesHeapStorage ? "_uniqueStorage().\(underscoreSwiftFieldName)" : swiftFieldName

        let visibility = generatorOptions.visibilitySourceSnippet

        p.print(
          "\n",
          field.comments,
          "\(visibility)var \(field.swiftName): \(field.swiftType) {\n")
        p.indent()
        p.print("get {\n")
        p.indent()
        p.print(
          "if case \(field.dottedSwiftName)(let v)? = \(getter) {return v}\n",
          "return \(field.swiftDefaultValue)\n")
        p.outdent()
        p.print(
          "}\n",
          "set {\(setter) = \(field.dottedSwiftName)(newValue)}\n")
        p.outdent()
        p.print("}\n")
    }

    func generateStorage(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the output.
        guard field === fields.first else { return }

        if usesHeapStorage {
            p.print("var \(underscoreSwiftFieldName): \(swiftFullName)?\n")
        } else {
            // When not using heap stroage, no extra storage is needed because
            // the public property for the oneof is the storage.
        }
    }

    func generateStorageClassClone(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the output.
        guard field === fields.first else { return }

        p.print("\(underscoreSwiftFieldName) = source.\(underscoreSwiftFieldName)\n")
    }

    func generateDecodeFieldCase(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        p.print("case \(field.number):\n")
        p.indent()

        if field.isGroupOrMessage {
            // Messages need to fetch the current value so new fields are merged into the existing
            // value
            p.print(
              "var v: \(field.swiftType)?\n",
              "if let current = \(storedProperty) {\n")
            p.indent()
            p.print(
              "try decoder.handleConflictingOneOf()\n",
              "if case \(field.dottedSwiftName)(let m) = current {v = m}\n")
            p.outdent()
            p.print("}\n")
        } else {
            p.print(
              "if \(storedProperty) != nil {try decoder.handleConflictingOneOf()}\n",
              "var v: \(field.swiftType)?\n")
        }

        p.print(
          "try decoder.decodeSingular\(field.protoGenericType)Field(value: &v)\n",
          "if let v = v {\(storedProperty) = \(field.dottedSwiftName)(v)}\n")
        p.outdent()
    }

    func generateTraverse(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field in the group causes the output.
        let group = fieldSortedGrouped[field.group]
        guard field === group.first else { return }

        if group.count == 1 {
            p.print("if case \(field.dottedSwiftName)(let v)? = \(storedProperty) {\n")
            p.indent()
            p.print("try visitor.visitSingular\(field.protoGenericType)Field(value: v, fieldNumber: \(field.number))\n")
            p.outdent()
        } else {
            p.print("switch \(storedProperty) {\n")
            for f in group {
                p.print("case \(f.dottedSwiftName)(let v)?:\n")
                p.indent()
                p.print("try visitor.visitSingular\(f.protoGenericType)Field(value: v, fieldNumber: \(f.number))\n")
                p.outdent()
            }
            p.print("case nil: break\n")  // Cover not being set.
            if fieldSortedGrouped.count > 1 {
                p.print("default: break\n")  // Multiple groups, cover other cases.
            }
        }
        p.print("}\n")
    }

    func generateFieldComparison(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the output.
        guard field === fields.first else { return }

        let lhsProperty: String
        let otherStoredProperty: String
        if usesHeapStorage {
          lhsProperty = "_storage.\(underscoreSwiftFieldName)"
          otherStoredProperty = "rhs_storage.\(underscoreSwiftFieldName)"
        } else {
          lhsProperty = "lhs.\(swiftFieldName)"
          otherStoredProperty = "rhs.\(swiftFieldName)"
        }

        p.print("if \(lhsProperty) != \(otherStoredProperty) {return false}\n")
    }

    func generateIsInitializedCheck(printer p: inout CodePrinter, field: MemberFieldGenerator) {
        // First field causes the output.
        guard field === fields.first else { return }

        let fieldsToCheck = fields.filter {
            $0.isGroupOrMessage && $0.messageType.hasRequiredFields()
        }
        if fieldsToCheck.count == 1 {
            let f = fieldsToCheck.first!
            p.print("if case \(f.dottedSwiftName)(let v)? = \(storedProperty), !v.isInitialized {return false}\n")
        } else if fieldsToCheck.count > 1 {
            p.print("switch \(storedProperty) {\n")
            for f in fieldsToCheck {
                p.print("case \(f.dottedSwiftName)(let v)?: if !v.isInitialized {return false}\n")
            }
            // Covers other cases or if the oneof wasn't set (was nil).
            p.print(
              "default: break\n",
              "}\n")
        }
    }
}
