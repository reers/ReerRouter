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
	
