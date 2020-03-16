// Sources/SwiftProtobufPluginLibrary/ProtoPathModuleMappings.swift - Helpers for module mappings option
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper handling proto file to module mappings.
///
// -----------------------------------------------------------------------------

import Foundation

/// Handles the mapping of proto files to the modules they will be compiled into.
public struct ProtoFileToModuleMappings {

  /// Errors raised from parsing mappings
  public enum LoadError: Error {
    /// Raised if the path wasn't found.
    case failToOpen(path: String)
    /// Raised if an mapping entry in the protobuf doesn't have a module name.
    /// mappingIndex is the index (0-N) of the mapping.
    case entryMissingModuleName(mappingIndex: Int)
    /// Raised if an mapping entry in the protobuf doesn't have any proto files listed.
    /// mappingIndex is the index (0-N) of the mapping.
    case entryHasNoProtoPaths(mappingIndex: Int)
    /// The given proto path was listed for both modules.
    case duplicateProtoPathMapping(path: String, firstModule: String, secondModule: String)
  }

  /// Proto file name to module name.
  /// This is really `private` to this type, it is just `internal` so the tests can
  /// access it to verify things.
  let mappings: [String:String]

  /// Loads and parses the given module mapping from disk.  Raises LoadError
  /// or TextFormatDecodingError.
  public init(path: String) throws {
    let content: String
    do {
      content = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
    } catch {
      throw LoadError.failToOpen(path: path)
    }

    let mappingsProto = try SwiftProtobuf_GenSwift_ModuleMappings(textFormatString: content)
    try self.init(moduleMappingsProto: mappingsProto)
  }

  /// Parses the given module mapping.  Raises LoadError.
  public init(moduleMappingsProto mappings: SwiftProtobuf_GenSwift_ModuleMappings) throws {
    var builder = wktMappings
    for (idx, mapping) in mappings.mapping.lazy.enumerated() {
      if mapping.moduleName.isEmpty {
        throw LoadError.entryMissingModuleName(mappingIndex: idx)
      }
      if mapping.protoFilePath.isEmpty {
        throw LoadError.entryHasNoProtoPaths(mappingIndex: idx)
      }
      for path in mapping.protoFilePath {
        if let existing = builder[path] {
          if existing != mapping.moduleName {
            throw LoadError.duplicateProtoPathMapping(path: path,
                                                      firstModule: existing,
                                                      secondModule: mapping.moduleName)
          }
          // Was a repeat, just allow it.
        } else {
          builder[path] = mapping.moduleName
        }
      }
    }
    self.mappings = builder
  }

  public init() {
    mappings = wktMappings
  }

  /// Looks up the module a given file is in.
  public func moduleName(forFile file: FileDescriptor) -> String? {
    return mappings[file.name]
  }

  /// Returns the list of modules that need to be imported for a given file based on
  /// the dependencies it has.
  public func neededModules(forFile file: FileDescriptor) -> [String]? {
    if file.dependencies.isEmpty {
      return nil
    }

    var collector = Set<String>()

    for dependency in file.dependencies {
      if let depModule = mappings[dependency.name] {
        collector.insert(depModule)
      }
    }

    // Protocol Buffers has the concept of "public imports", these are imports
    // into a file that expose everything from within the file to the new
    // context. From the docs -
    // https://developers.google.com/protocol-buffers/docs/proto#importing-definitions
    //   `import public` dependencies can be transitively relied upon by anyone
    //    importing the proto containing the import public statement.
    // To properly expose the types for use, it means in each file, the public imports
    // from the dependencies have to be hoisted and also imported.
    var visited = Set<String>()
    var toScan = file.dependencies
    while let dep = toScan.popLast() {
      for pubDep in dep.publicDependencies {
        let pubDepName = pubDep.name
        if visited.contains(pubDepName) { continue }
        visited.insert(pubDepName)
        toScan.append(pubDep)
        if let pubDepModule = mappings[pubDepName] {
          collector.insert(pubDepModule)
        }
      }
    }

    if let moduleForThisFile = mappings[file.name] {
      collector.remove(moduleForThisFile)
    }

    // The library itself (happens if the import one of the WKTs).
    collector.remove(SwiftProtobufInfo.name)

    if collector.isEmpty {
      return nil
    }

    return collector.sorted()
  }
}

// Used to seed the mappings, the wkt are all part of the main library.
private let wktMappings: [String:String] = {
  var result = [String:String]()
  for x in SwiftProtobufInfo.bundledProtoFiles {
    result[x] = SwiftProtobufInfo.name
  }
  return result
}()
