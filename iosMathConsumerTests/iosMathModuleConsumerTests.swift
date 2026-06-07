// iosMathModuleConsumerTests.swift
// Regression test for issue #215: "Clang dependency scanning failure,
// fatal error: MTMathList.h not found."
//
// This target deliberately depends on `iosMath` and imports it *purely as a
// Clang module*, with NO header search paths configured in Package.swift. That
// reproduces exactly how a downstream Swift Package Manager consumer builds the
// module: from `module.modulemap` against the package's public-headers root,
// without iosMath's target-internal `lib`/`render` search paths.
//
// The bug was that public headers in `render/` imported sibling headers in
// `lib/` by bare filename (e.g. `#import "MTMathList.h"`), which only resolves
// when the internal `lib` search path is present. External consumers (and this
// target) lack that path, so building the module failed with
// "'MTMathList.h' file not found".
//
// If that regression returns, this target FAILS TO COMPILE — `import iosMath`
// forces the module (all module-map headers) to build. The assertions below are
// secondary; the real guard is that this file compiles at all. Referencing a
// `render/` type (MTMathUILabel) and a `lib/` type (MTMathList) together keeps
// the cross-directory include in the compiled surface.

import XCTest
import iosMath

final class iosMathModuleConsumerTests: XCTestCase {

    // Exercises the render -> lib cross-directory include path. MTMathUILabel
    // lives in render/ and pulls in MTMathList from lib/.
    @MainActor
    func testModuleBuildsAndRendersCrossDirectoryTypes() {
        let label = MTMathUILabel()
        label.latex = #"\frac{1}{2}"#
        XCTAssertNotNil(label.mathList)
        XCTAssertNil(label.error)

        // Use the lib/ type directly as well so it stays in the consumed surface.
        let list: MTMathList? = label.mathList
        XCTAssertNotNil(list)
    }
}
