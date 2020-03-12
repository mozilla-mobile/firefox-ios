// Sources/protoc-gen-swift/EnumGenerator.swift - Enum logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This file handles the generation of a Swift enum for each .proto enum.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobufPluginLibrary
import SwiftProtobuf

/// The name of the case used to represent unrecognized values in proto3.
/// This case has an associated value containing the raw integer value.
private let unrecognizedCaseName = "UNRECOGNIZED"

/// Generates a Swift enum from a protobuf enum descriptor.
class EnumGenerator {
  private let enumDescriptor: EnumDescriptor
  private let generatorOptions: GeneratorOptions
  private let namer: SwiftProtobufNamer

  /// The values that aren't aliases, as ordered in the .proto.
  private let mainEnumValueDescriptors: [EnumValueDescriptor]
  /// The values that aren't aliases, sorted by number.
  private let mainEnumValueDescriptorsSorted: [EnumValueDescriptor]

  private let swiftRelativeName: String
  private let swiftFullName: String

  init(descriptor: EnumDescriptor,
       generatorOptions: GeneratorOptions,
       namer: SwiftProtobufNamer
  ) {
    self.enumDescriptor = descriptor
    self.generatorOptions = generatorOptions
    self.namer = namer

    mainEnumValueDescriptors = descriptor.values.filter({
      return $0.aliasOf == nil
    })
    mainEnumValueDescriptorsSorted = mainEnumValueDescriptors.sorted(by: {
      return $0.number < $1.number
    })

    swiftRelativeName = namer.relativeName(enum: descriptor)
    swiftFullName = namer.fullName(enum: descriptor)
  }

  func generateMainEnum(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    p.print("\n")
    p.print(enumDescriptor.protoSourceComments())
    p.print("\(visibility)enum \(swiftRelativeName): SwiftProtobuf.Enum {\n")
    p.indent()
    p.print("\(visibility)typealias RawValue = Int\n")

    // Cases/aliases
    generateCasesOrAliases(printer: &p)

    // Generate the default initializer.
    p.print("\n")
    p.print("\(visibility)init() {\n")
    p.indent()
    let dottedDefault = namer.dottedRelativeName(enumValue: enumDescriptor.defaultValue)
    p.print("self = \(dottedDefault)\n")
    p.outdent()
    p.print("}\n")

    p.print("\n")
    generateInitRawValue(printer: &p)

    p.print("\n")
    generateRawValueProperty(printer: &p)

    p.outdent()
    p.print("\n")
    p.print("}\n")
  }

  func generateCaseIterable(
    printer p: inout CodePrinter,
    includeGuards: Bool = true
  ) {
    // NOTE: When we can assume Swift 4.2, this should move from an extension
    // to being directly done when declaring the type.

    let visibility = generatorOptions.visibilitySourceSnippet

    p.print("\n")
    if includeGuards {
      p.print("#if swift(>=4.2)\n\n")
    }
    p.print("extension \(swiftFullName): CaseIterable {\n")
    p.indent()
    if enumDescriptor.hasUnknownPreservingSemantics {
      p.print("// The compiler won't synthesize support with the \(unrecognizedCaseName) case.\n")
      p.print("\(visibility)static var allCases: [\(swiftFullName)] = [\n")
      for v in mainEnumValueDescriptors {
        let dottedName = namer.dottedRelativeName(enumValue: v)
        p.print("  \(dottedName),\n")
      }
      p.print("]\n")
    } else {
      p.print("// Support synthesized by the compiler.\n")
    }
    p.outdent()
    p.print("}\n")
    if includeGuards {
      p.print("\n#endif  // swift(>=4.2)\n")
    }
  }

  func generateRuntimeSupport(printer p: inout CodePrinter) {
    p.print("\n")
    p.print("extension \(swiftFullName): SwiftProtobuf._ProtoNameProviding {\n")
    p.indent()
    generateProtoNameProviding(printer: &p)
    p.outdent()
    p.print("}\n")
  }

  /// Generates the cases or statics (for alias) for the values.
  ///
  /// - Parameter p: The code printer.
  private func generateCasesOrAliases(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet
    for enumValueDescriptor in namer.uniquelyNamedValues(enum: enumDescriptor) {
      let comments = enumValueDescriptor.protoSourceComments()
      if !comments.isEmpty {
        p.print("\n", comments)
      }
      let relativeName = namer.relativeName(enumValue: enumValueDescriptor)
      if let aliasOf = enumValueDescriptor.aliasOf {
        let aliasOfName = namer.relativeName(enumValue: aliasOf)
        p.print("\(visibility)static let \(relativeName) = \(aliasOfName)\n")
      } else {
        p.print("case \(relativeName) // = \(enumValueDescriptor.number)\n")
      }
    }
    if enumDescriptor.hasUnknownPreservingSemantics {
      p.print("case \(unrecognizedCaseName)(Int)\n")
    }
  }

  /// Generates the mapping from case numbers to their text/JSON names.
  ///
  /// - Parameter p: The code printer.
  private func generateProtoNameProviding(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    p.print("\(visibility)static let _protobuf_nameMap: SwiftProtobuf._NameMap = [\n")
    p.indent()
    for v in mainEnumValueDescriptorsSorted {
      if v.aliases.isEmpty {
        p.print("\(v.number): .same(proto: \"\(v.name)\"),\n")
      } else {
        let aliasNames = v.aliases.map({ "\"\($0.name)\"" }).joined(separator: ", ")
        p.print("\(v.number): .aliased(proto: \"\(v.name)\", aliases: [\(aliasNames)]),\n")
      }
    }
    p.outdent()
    p.print("]\n")
  }

  /// Generates `init?(rawValue:)` for the enum.
  ///
  /// - Parameter p: The code printer.
  private func generateInitRawValue(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    p.print("\(visibility)init?(rawValue: Int) {\n")
    p.indent()
    p.print("switch rawValue {\n")
    for v in mainEnumValueDescriptorsSorted {
      let dottedName = namer.dottedRelativeName(enumValue: v)
      p.print("case \(v.number): self = \(dottedName)\n")
    }
    if enumDescriptor.hasUnknownPreservingSemantics {
      p.print("default: self = .\(unrecognizedCaseName)(rawValue)\n")
    } else {
      p.print("default: return nil\n")
    }
    p.print("}\n")
    p.outdent()
    p.print("}\n")
  }

  /// Generates the `rawValue` property of the enum.
  ///
  /// - Parameter p: The code printer.
  private func generateRawValueProperty(printer p: inout CodePrinter) {
    let visibility = generatorOptions.visibilitySourceSnippet

    // See https://github.com/apple/swift-protobuf/issues/904 for the full
    // details on why the default has to get added even though the switch
    // is complete.

    // This is a "magic" value, currently picked based on the Swift 5.1
    // compiler, it will need ensure the warning doesn't trigger on all
    // versions of the compiler, meaning if the error starts to show up
    // again, all one can do is lower the limit.
    let maxCasesInSwitch = 500

    let neededCases = mainEnumValueDescriptorsSorted.count +
      (enumDescriptor.hasUnknownPreservingSemantics ? 1 : 0)
    let useMultipleSwitches = neededCases > maxCasesInSwitch

    p.print("\(visibility)var rawValue: Int {\n")
    p.indent()

    if useMultipleSwitches {
      for (i, v) in mainEnumValueDescriptorsSorted.enumerated() {
        if (i % maxCasesInSwitch) == 0 {
          if i > 0 {
            p.print(
              "default: break\n",
              "}\n")
          }
          p.print("switch self {\n")
        }
        let dottedName = namer.dottedRelativeName(enumValue: v)
        p.print("case \(dottedName): return \(v.number)\n")
      }
      if enumDescriptor.hasUnknownPreservingSemantics {
        p.print("case .\(unrecognizedCaseName)(let i): return i\n")
      }
      p.print(
        "default: break\n",
        "}\n",
        "\n",
        "// Can't get here, all the cases are listed in the above switches.\n",
        "// See https://github.com/apple/swift-protobuf/issues/904 for more details.\n",
        "fatalError()\n")
    } else {
      p.print("switch self {\n")
      for v in mainEnumValueDescriptorsSorted {
        let dottedName = namer.dottedRelativeName(enumValue: v)
        p.print("case \(dottedName): return \(v.number)\n")
      }
      if enumDescriptor.hasUnknownPreservingSemantics {
        p.print("case .\(unrecognizedCaseName)(let i): return i\n")
      }
      p.print("}\n")
    }

    p.outdent()
    p.print("}\n")
  }
}
