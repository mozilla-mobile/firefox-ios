// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Implementation of the `CopyWithChanges` macro.
public struct CopyWithChangesMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro should only be valid on structs
        guard let members = declaration.as(StructDeclSyntax.self)?.memberBlock.members else {
            context.diagnose(Diagnostic(
                node: attribute,
                message: CopyWithChangesDiagnostic.unsupportedTarget
            ))

            return []
        }

        // Get a list of all the properties that should be copied in a struct instance (excludes static properties)
        let variableDecls = members.compactMap { member -> VariableDeclSyntax? in
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                return nil
            }

            let isStatic = variableDecl.modifiers.contains { modifier in
                modifier.name.tokenKind == .keyword(.static)
            }

            return isStatic ? nil : variableDecl
        }

        let bindings = variableDecls.flatMap { $0.bindings }

        // Based on the each property's name and type, construct the copyWith function arguments and internal assignments
        var arguments: [String] = []
        var assignments: [String] = []

        for binding in bindings {
            guard let propertyName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let propertyType = binding.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type else {
                context.diagnose(Diagnostic(
                    node: attribute,
                    message: CopyWithChangesDiagnostic.unsupportedBinding(binding)
                ))

                continue
            }

            if propertyType.is(OptionalTypeSyntax.self) {
                /// Optionals are treated as double optionals (`??`)
                arguments.append("\(propertyName): \(propertyType)? = .some(nil)")

                /// We treat a top-level `nil` argument semantically as setting the property to `nil`, instead of passing
                /// `.some(nil)`, which would feel odd at call sites.
                assignments.append("\(propertyName): \(propertyName).map { $0 ?? self.\(propertyName) } ?? nil")
            } else {
                arguments.append("\(propertyName): \(propertyType)? = nil")
                assignments.append("\(propertyName): \(propertyName) ?? self.\(propertyName)")
            }
        }

        // Construct the return statement with proper syntax
        let copyWithFunction = try FunctionDeclSyntax("public func copyWith(\(raw: arguments.joined(separator: ", "))) -> Self") {
            return """
                return Self(
                \(raw: assignments.joined(separator: ",\n"))
                )
            """
        }

        return [
            DeclSyntax(copyWithFunction),
        ]
    }

    enum CopyWithChangesDiagnostic: DiagnosticMessage {
        case unsupportedTarget
        case unsupportedBinding(PatternBindingSyntax)

        var severity: DiagnosticSeverity {
            switch self {
            case .unsupportedTarget:  .error
            case .unsupportedBinding: .warning
            }
        }

        var message: String {
            switch self {
            case .unsupportedTarget:
                "'@CopyWithChanges' can only be applied to a struct or a class"
            case .unsupportedBinding(let binding):
                "'@CopyWithChanges' cannot copy field '\(binding)'"
            }
        }

        var diagnosticID: MessageID {
            MessageID(domain: "CopyWithChangesMacros", id: String(describing: self))
        }
    }
}

@main
struct CopyWithChangesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CopyWithChangesMacro.self,
    ]
}
