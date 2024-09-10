//
//  Macros.swift
//  ReerRouter
//
//  Created by phoenix on 2024/9/6.
//

@freestanding(declaration)
public macro route(
    key: Route.Key,
    action: Route.Action
) = #externalMacro(module: "ReerRouterMacros", type: "WriteRouteActionToSectionMacro")
	
@attached(extension, conformances: Routable, names: arbitrary)
public macro Routable(_ key: Route.Key) = #externalMacro(module: "ReerRouterMacros", type: "WriteRouteVCToSectionMacro")
