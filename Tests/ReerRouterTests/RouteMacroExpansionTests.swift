import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ReerRouterMacros)
import ReerRouterMacros

private let testMacros: [String: Macro.Type] = [
    "route": WriteRouteActionToSectionMacro.self,
]
#endif

final class RouteMacroExpansionTests: XCTestCase {

    func testLabeledActionClosure() throws {
        #if canImport(ReerRouterMacros)
        assertMacroExpansion(
            """
            #route(key: "haha", action: { params in
                print(123333333)
            })
            """,
            expandedSource: """
            @used
            @section("__DATA,__rerouter_ac")
            let __macro_local_4rheafMu_: RouteActionInfo = (
                0x2e25cdcc7406360d,
                { params in
                print(123333333)
                }
            )
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testTrailingClosure() throws {
        #if canImport(ReerRouterMacros)
        assertMacroExpansion(
            """
            #route(key: "haha") { params in
                print(6666666)
            }
            """,
            expandedSource: """
            @used
            @section("__DATA,__rerouter_ac")
            let __macro_local_4rheafMu_: RouteActionInfo = (
                0x2e25cdcc7406360d,
                { params in
                print(6666666)
                }
            )
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
