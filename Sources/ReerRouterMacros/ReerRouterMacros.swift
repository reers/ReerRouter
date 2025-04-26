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
        let argumentList = node.arguments
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
                    functionBody = closureExpr.statements.trimmedDescription
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
            \(staticString)let \(infoName): RouteActionInfo = (
                "\(key)",
                { \(signature ?? "param in")
                    \(functionBody)
                }
            )
            """
        return [DeclSyntax(stringLiteral: declarationString)]
    }
}

public enum ReerRouterMacroError: Error, CustomStringConvertible {
    case notAppliedToClass
    case unableToCreateExtension
    case missingRouteKey
    case unableToInferModule
    
    public var description: String {
        switch self {
        case .notAppliedToClass:
            return "Router can only be applied to a class."
        case .unableToCreateExtension:
            return "Unable to create extension for @Routable."
        case .missingRouteKey:
            return "Router requires a non-empty route key."
        case .unableToInferModule:
            return "Router unable to infer module name."
        }
    }
}

public struct WriteRouteVCToSectionMacro: ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw ReerRouterMacroError.notAppliedToClass
        }
        
        guard let routeKey = parseRouteKey(from: node), !routeKey.isEmpty else {
            throw ReerRouterMacroError.missingRouteKey
        }
        
        let className = classDecl.name.text
        let objcClassName = getObjcClassName(from: classDecl)
        let moduleName = try getModuleName(for: classDecl, in: context)
        
        let realClassName: String
        if let objcName = objcClassName {
            realClassName = objcName
        } else {
            realClassName = "\(moduleName).\(className)"
        }
        
        let extensionDecl: DeclSyntax = """
            extension \(raw: className): Routable {
                @_used
                @_section("__DATA,__rerouter_vc")
                private static let routableRegistration: StaticString = "\(raw: routeKey):\(raw: realClassName)"
            }
            """
        
        guard let extensionDeclSyntax = extensionDecl.as(ExtensionDeclSyntax.self) else {
            throw ReerRouterMacroError.unableToCreateExtension
        }
        
        return [extensionDeclSyntax]
    }
    
    private static func getObjcClassName(from classDecl: ClassDeclSyntax) -> String? {
        for attribute in classDecl.attributes {
            if let objcAttr = attribute.as(AttributeSyntax.self),
               objcAttr.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "objc",
               let arguments = objcAttr.arguments?.as(ObjCSelectorPieceListSyntax.self),
               let firstArgument = arguments.first?.name?.text {
                return firstArgument
            }
        }
        return nil
    }
    
    private static func getModuleName(
        for declaration: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> String {
        guard let location = context.location(
            of: declaration,
            at: .beforeLeadingTrivia,
            filePathMode: .fileID
        ) else {
            throw ReerRouterMacroError.unableToInferModule
        }
        
        guard let stringLiteral = location.file.as(StringLiteralExprSyntax.self),
              let firstSegment = stringLiteral.segments.first,
              case .stringSegment(let content) = firstSegment else {
            throw ReerRouterMacroError.unableToInferModule
        }
        
        let fileIDString = content.content.text
        
        let components = fileIDString.split(separator: "/")
        if let moduleName = components.first {
            return String(moduleName)
        }
        
        throw ReerRouterMacroError.unableToInferModule
    }
    
    private static func parseRouteKey(from attribute: AttributeSyntax) -> String? {
        guard
            let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
            let firstArgument = arguments.first?.expression
        else {
            return nil
        }
        
        if let memberAccess = firstArgument.as(MemberAccessExprSyntax.self) {
            return memberAccess.declName.baseName.text
        } else if let stringLiteral = firstArgument.as(StringLiteralExprSyntax.self),
                  let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
            return segment.content.text
        }
        
        return nil
    }
}

@main
struct RheaRouterPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WriteRouteActionToSectionMacro.self,
        WriteRouteVCToSectionMacro.self
    ]
}
