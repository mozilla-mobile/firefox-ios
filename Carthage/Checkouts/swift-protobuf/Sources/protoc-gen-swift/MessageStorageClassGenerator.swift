// Sources/protoc-gen-swift/MessageStorageClassGenerator.swift - Message storage class logic
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Code generation for the private storage class used inside copy-on-write
/// messages.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobufPluginLibrary
import SwiftProtobuf

/// Generates the `_StorageClass` used for messages that employ copy-on-write
/// logic for some of their fields.
class MessageStorageClassGenerator {
  private let fields: [FieldGenerator]

  /// Creates a new `MessageStorageClassGenerator`.
  init(fields: [FieldGenerator]) {
    self.fields = fields
  }

  /// Visibility of the storage within the Message.
  var storageVisibility: String {
    return "fileprivate"
  }

  /// If the storage wants to manually implement equality.
  var storageProvidesEqualTo: Bool { return false }

  /// Generates the full code for the storage class.
  ///
  /// - Parameter p: The code printer.
  func generateTypeDeclaration(printer p: inout CodePrinter) {
    p.print("fileprivate class _StorageClass {\n")
    p.indent()

    generateStoredProperties(printer: &p)

    // Generate a default instance to be used so the heap allocation is
    // delayed until mutation is needed. This is the largest savings when
    // the message is used as a field in another message as it causes
    // returning the default to not require that heap allocation, i.e. -
    // readonly usage never causes the allocation.
    p.print(
        "\n",
        "static let defaultInstance = _StorageClass()\n",
        "\n",
        "private init() {}\n",
        "\n")
    generateClone(printer: &p)

    p.outdent()
    p.print("}\n")
  }

  /// Generated the uniqueStorage() implementation.
  func generateUniqueStorage(printer p: inout CodePrinter) {
    p.print("\(storageVisibility) mutating func _uniqueStorage() -> _StorageClass {\n")
    p.indent()
    p.print("if !isKnownUniquelyReferenced(&_storage) {\n")
    p.indent()
    p.print("_storage = _StorageClass(copying: _storage)\n")
    p.outdent()
    p.print(
      "}\n",
      "return _storage\n")
    p.outdent()
    p.print("}\n")
  }

  func generatePreTraverse(printer p: inout CodePrinter) {
    // Nothing
  }

  /// Generates the stored properties for the storage class.
  ///
  /// - Parameter p: The code printer.
  private func generateStoredProperties(printer p: inout CodePrinter) {
    for f in fields {
      f.generateStorage(printer: &p)
    }
  }

  /// Generates the `init(copying:)` method of the storage class.
  ///
  /// - Parameter p: The code printer.
  private func generateClone(printer p: inout CodePrinter) {
    p.print("init(copying source: _StorageClass) {\n")
    p.indent()
    for f in fields {
      f.generateStorageClassClone(printer: &p)
    }
    p.outdent()
    p.print("}\n")
  }
}

/// Custom generator for storage of an google.protobuf.Any.
class AnyMessageStorageClassGenerator : MessageStorageClassGenerator {
  override var storageVisibility: String { return "internal" }
  override var storageProvidesEqualTo: Bool { return true }

  override func generateTypeDeclaration(printer p: inout CodePrinter) {
    // Just need an alias to the hand coded Storage.
    p.print("typealias _StorageClass = AnyMessageStorage\n")
  }

  override func generatePreTraverse(printer p: inout CodePrinter) {
    p.print("try _storage.preTraverse()\n")
  }
}
