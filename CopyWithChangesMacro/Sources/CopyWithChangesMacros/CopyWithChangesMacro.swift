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
        guard let members = (declaration.as(StructDeclSyntax.self)?.memberBlock.members
                             ?? declaration.as(ClassDeclSyntax.self)?.memberBlock.members) else {
            context.diagnose(Diagnostic(
                node: attribute,
                message: CopyWithChangesDiagnostic.unsupportedTarget
            ))

            return []
        }

        let variableDecls = members.compactMap { member -> VariableDeclSyntax? in
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
                return nil
            }

            // Check if the 'static' modifier is present; we don't want these properties copied into the generated copyWith
            // method.
            let isStatic = variableDecl.modifiers.contains { modifier in
                modifier.name.tokenKind == .keyword(.static)
            }

            return isStatic ? nil : variableDecl
        }

        let bindings = variableDecls.flatMap { $0.bindings }

        let with = try {
            var arguments: [String] = []
            var assignments: [String] = []

            for binding in bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                      let type = binding.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type else {
                    context.diagnose(Diagnostic(
                        node: attribute,
                        message: CopyWithChangesDiagnostic.unsupportedBinding(binding)
                    ))

                    continue
                }

                if type.is(OptionalTypeSyntax.self) {
                    arguments.append("\(pattern): \(type)? = .some(nil)")
                    assignments.append("\(pattern): \(pattern) == .none ? nil : self.\(pattern)")
                } else {
                    arguments.append("\(pattern): \(type)? = nil")
                    assignments.append("\(pattern): \(pattern) ?? self.\(pattern)")
                }
            }

            return try FunctionDeclSyntax("public func copyWith(\(raw: arguments.joined(separator: ", "))) -> Self") {
                return """
                    return Self(
                    \(raw: assignments.joined(separator: ",\n"))
                    )
                """
            }
        }()

        return [
            DeclSyntax(with),
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
