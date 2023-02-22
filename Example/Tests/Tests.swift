import XCTest
@testable import ReerRouter

class Tests: XCTestCase {
    
    func testOptionalExtension() {
        let int: Int? = 2
        XCTAssertEqual(int.string, "2")

        let empty: Int? = nil
        XCTAssertNil(empty.string)

        let bool: Bool? = false
        XCTAssertEqual(bool.string, "false")

        let bool1: Bool? = true
        XCTAssertEqual(bool1.string, "true")

        let float: Float? = 3.14
        XCTAssertEqual(float.string, "3.14")
    }

    func testURL()  {
        let s1 = "http://hello"
        XCTAssertNotNil(URL.with(urlString: s1))

        let s2 = "http://hello?a=你好"
        XCTAssertNotNil(URL.with(urlString: s2))
    }
    
}
