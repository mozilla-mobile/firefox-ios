// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Implementation of the `CopyWithUpdates` macro.
public struct CopyWithUpdatesMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let members = (declaration.as(StructDeclSyntax.self)?.memberBlock.members
                             ?? declaration.as(ClassDeclSyntax.self)?.memberBlock.members) else {
            context.diagnose(Diagnostic(
                node: attribute,
                message: CopyWithUpdatesDiagnostic.unsupportedTarget
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

        // Based on the each property's name and type, construct the copyWith function arguments and internal assignments
        var arguments: [String] = []
        var assignments: [String] = []

        for binding in bindings {
            guard let propertyName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let propertyType = binding.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type else {
                context.diagnose(Diagnostic(
                    node: attribute,
                    message: CopyWithUpdatesDiagnostic.unsupportedBinding(binding)
                ))

                continue
            }

            // Strip comments after the property definition
            let propertyTypeString = stripCommentsFromTypeDefinition(ofProperty: propertyType.description)

            if propertyType.is(OptionalTypeSyntax.self) {
                /// Optionals are treated as double optionals (`??`)
                arguments.append("\(propertyName): \(propertyTypeString)? = .some(nil)")

                /// We treat a top-level `nil` argument semantically as setting the property to `nil`, instead of passing
                /// `.some(nil)`, which would feel odd at call sites.
                assignments.append("\(propertyName): \(propertyName).map { $0 ?? self.\(propertyName) } ?? nil")
            } else {
                arguments.append("\(propertyName): \(propertyTypeString)? = nil")
                assignments.append("\(propertyName): \(propertyName) ?? self.\(propertyName)")
            }
        }

        // Construct the return statement with proper syntax
        let copyWithFunction = try FunctionDeclSyntax("public func copyWithUpdates(\(raw: arguments.joined(separator: ", "))) -> Self") {
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

    enum CopyWithUpdatesDiagnostic: DiagnosticMessage {
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
                "'@CopyWithUpdates' can only be applied to a struct or a class"
            case .unsupportedBinding(let binding):
                "'@CopyWithUpdates' cannot copy field '\(binding)'"
            }
        }

        var diagnosticID: MessageID {
            MessageID(domain: "CopyWithUpdatesMacros", id: String(describing: self))
        }
    }
}

// MARK: - Helpers
public func stripCommentsFromTypeDefinition(ofProperty property: String) -> String {
    var stringToClean = property

    // Remove `// ...` or `/// ...` trailing comments
    if let commentType1Position = stringToClean.range(of: "//")?.lowerBound {
        stringToClean = String(stringToClean.prefix(upTo: commentType1Position))

        // Recursively repeat in case there are other comment types on this line
        return stripCommentsFromTypeDefinition(ofProperty: stringToClean)
    }

    // Remove `/* ... */` comments
    if let commentType2PositionLower = stringToClean.range(of: "/*")?.lowerBound,
       let commentType2PositionUpper = stringToClean.range(of: "*/")?.upperBound {
        // Remove the `/* ... */` comment as if it's in the middle of the definition
        let firstPart = stringToClean.prefix(upTo: commentType2PositionLower)
        let secondPart = stringToClean.suffix(from: commentType2PositionUpper)
        stringToClean = String(firstPart + secondPart)

        // Recursively repeat this in case there are other `/* ... */` on the line
        return stripCommentsFromTypeDefinition(ofProperty: stringToClean)
    } else if let commentType2PositionLower = stringToClean.range(of: "/*")?.lowerBound {
        // Remove the `/* ... ` which starts on this line and terminates on another line
        stringToClean = String(stringToClean.prefix(upTo: commentType2PositionLower))

        // Recursively repeat in case there are other comment types on this line
        return stripCommentsFromTypeDefinition(ofProperty: stringToClean)
    }

    // Trim any lingering whitespace at the end of the property definition
    return stringToClean.trimmingCharacters(in: .whitespaces)
}

@main
struct CopyWithUpdatesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CopyWithUpdatesMacro.self,
    ]
}
