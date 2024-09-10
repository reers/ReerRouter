//
//  ReerRouterMacros.swift
//  ReerRouter
//
//  Created by phoenix on 2024/9/6.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct WriteRouteActionToSectionMacro: DeclarationMacro {
    
    public static func expansion(
        of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let argumentList = node.argumentList
        var key: String = ""
        var functionBody: String = ""
        var signature: String?
        
        for argument in argumentList {
            switch argument.label?.text {
            case "key":
                // Route.Key type
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    key = memberAccess.declName.baseName.text
                }
                // String type
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let hostValue = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text {
                    key = hostValue
                }
            case "action":
                if let closureExpr = argument.expression.as(ClosureExprSyntax.self) {
                    functionBody = closureExpr.statements.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let sig = closureExpr.signature {
                        signature = sig.description
                    }
                }
            default:
                break
            }
        }
        let isGlobal = context.lexicalContext.isEmpty
        let staticString = isGlobal ? "" : "static "
        let infoName = "\(context.makeUniqueName("rhea"))"
        
        let declarationString = """
            @_used 
            @_section("__DATA,__rerouter_ac")
            \(staticString)let \(infoName): (StaticString, Route.Action) = (
                "\(key)",
                { \(signature ?? "param in")
                    \(functionBody)
                }
            )
            """
        return [DeclSyntax(stringLiteral: declarationString)]
    }
}


@main
struct RheaRouterPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WriteRouteActionToSectionMacro.self
    ]
}
