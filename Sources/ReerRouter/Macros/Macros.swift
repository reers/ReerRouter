//
//  Macros.swift
//  ReerRouter
//
//  Created by phoenix on 2024/9/6.
//

#if canImport(UIKit)
/// Defines a route action with a specified key.
///
/// This macro generates code to register a route in the router's section data.
/// It can be used at both global and type scope, supporting nested declarations.
///
/// - Parameters:
///   - key: A `Route.Key` value that uniquely identifies this route.
///          This parameter also supports direct static string input, which will be
///          processed by the framework as an event identifier.
///          ⚠️⚠️⚠️ When extending this struct with static constants, ensure that
///          the constant name exactly matches the string literal value. This practice
///          maintains consistency and prevents confusion.
///   - action: A closure of type `Route.Action` that will be executed when this route is triggered.
///             The closure takes a `params` argument which can contain route-specific data.
///
/// - Note: This macro is processed at compile-time and generates the necessary code for route registration.
///
/// - Important: Ensure that the `Route.Key` used is unique within your routing system to avoid conflicts.
///
/// Example usage:
/// ```
/// // Global scope
/// #route(key: .testKey, action: { params in
///     print("Global route triggered")
/// })
///
/// class MyClass {
///     // Nested within a class
///     #route(key: .nestedKey, action: { params in
///         print("Nested route triggered")
///     })
/// }
/// ```
@freestanding(declaration)
public macro route(
    key: Route.Key,
    action: Route.Action
) = #externalMacro(module: "ReerRouterMacros", type: "WriteRouteActionToSectionMacro")

/// Defines a routable view controller.
///
/// This macro is used to automatically conform a view controller to the `Routable` protocol
/// and register it with the routing system. It generates the necessary code for route registration
/// and conformance to the `Routable` protocol.
///
/// - Parameters:
///   - key: A `Route.Key` value that uniquely identifies this routable view controller.
///          This parameter also supports direct static string input, which will be processed
///          by the framework as a route identifier.
///          ⚠️ When using string literals, ensure they match any corresponding static
///          constants in `Route.Key` for consistency.
///
/// - Note: This macro is processed at compile-time and should be applied to view controller classes.
///
/// - Important:
///   - The view controller must implement `init?(param: Route.Param)` initializer.
///   - Ensure that the `Route.Key` used is unique within your routing system to avoid conflicts.
///
/// Example usage:
/// ```swift
/// extension Route.Key {
///     static let chat: Route.Key = "chat"
/// }
///
/// @Routable(.chat)
/// class ChatViewController: UIViewController {
///     required init?(param: Route.Param) {
///         super.init(nibName: nil, bundle: nil)
///     }
///
///     // ... other methods ...
/// }
///
/// @Routable("setting")
/// class SettingViewController: UIViewController {
///     required init?(param: Route.Param) {
///         super.init(nibName: nil, bundle: nil)
///     }
///
///     // ... other methods ...
/// }
/// ```
///
/// - SeeAlso: `Routable` protocol, `Route.Key`
@attached(extension, conformances: Routable, names: arbitrary)
public macro Routable(_ key: Route.Key) = #externalMacro(module: "ReerRouterMacros", type: "WriteRouteVCToSectionMacro")
#endif
