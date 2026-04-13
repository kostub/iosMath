// iosMathSwiftAPITests.swift
// Swift XCTest coverage of the iosMath public API surface.
// Each test exercises a distinct public type so that Swift-breaking regressions
// (e.g. nullability changes, NS_SWIFT_NAME renames, module surface changes)
// are caught before they ship.

import XCTest
import iosMath

final class MTMathUILabelTests: XCTestCase {
    func testCreateLabel() {
        let label = MTMathUILabel()
        XCTAssertNotNil(label)
    }

    func testSetLatexPopulatesMathList() {
        let label = MTMathUILabel()
        label.latex = #"x^2 + y^2 = z^2"#
        XCTAssertNotNil(label.mathList)
        XCTAssertNil(label.error)
    }

    func testInvalidLatexSetsError() {
        let label = MTMathUILabel()
        label.latex = #"\invalidcommand"#
        XCTAssertNotNil(label.error)
    }

    func testLabelModeDefaultIsDisplay() {
        let label = MTMathUILabel()
        XCTAssertEqual(label.labelMode, .display)
    }

    func testSetLabelModeText() {
        let label = MTMathUILabel()
        label.labelMode = .text
        XCTAssertEqual(label.labelMode, .text)
    }
}

final class MTFontManagerTests: XCTestCase {
    func testFontManagerInit() {
        let mgr = MTFontManager()
        XCTAssertNotNil(mgr)
    }

    func testDefaultFont() {
        let font = MTFontManager().defaultFont()
        XCTAssertNotNil(font)
    }

    func testLatinModernFont() {
        let font = MTFontManager().latinModernFont(withSize: 18)
        XCTAssertNotNil(font)
    }

    func testXitsFont() {
        let font = MTFontManager().xitsFont(withSize: 16)
        XCTAssertNotNil(font)
    }

    func testTermesFont() {
        let font = MTFontManager().termesFont(withSize: 16)
        XCTAssertNotNil(font)
    }
}

final class MTMathListBuilderTests: XCTestCase {
    func testBuildFromStringClass() {
        let list = MTMathListBuilder.build(from: #"e^{i\pi} + 1 = 0"#)
        XCTAssertNotNil(list)
    }

    func testBuildFromStringReturnsNilOnError() {
        let list = MTMathListBuilder.build(from: #"\badcommand"#)
        XCTAssertNil(list)
    }

    func testInstanceBuild() {
        let builder = MTMathListBuilder(string: #"\frac{1}{2}"#)
        let list = builder.build()
        XCTAssertNotNil(list)
        XCTAssertNil(builder.error)
    }

    func testInstanceBuildInvalidSetsError() {
        let builder = MTMathListBuilder(string: #"\notacommand"#)
        let list = builder.build()
        XCTAssertNil(list)
        XCTAssertNotNil(builder.error)
    }

    func testMathListToString() {
        let list = MTMathListBuilder.build(from: #"a + b"#)!
        let latex = MTMathListBuilder.mathList(toString: list)
        XCTAssertFalse(latex.isEmpty)
    }
}

final class MTMathAtomFactoryTests: XCTestCase {
    func testTimes() {
        let atom = MTMathAtomFactory.times()
        XCTAssertNotNil(atom)
    }

    func testDivide() {
        let atom = MTMathAtomFactory.divide()
        XCTAssertNotNil(atom)
    }

    func testPlaceholder() {
        let atom = MTMathAtomFactory.placeholder()
        XCTAssertNotNil(atom)
    }

    func testPlaceholderFraction() {
        let frac = MTMathAtomFactory.placeholderFraction()
        XCTAssertNotNil(frac)
    }

    func testPlaceholderSquareRoot() {
        let rad = MTMathAtomFactory.placeholderSquareRoot()
        XCTAssertNotNil(rad)
    }

    func testAtomForLatexSymbolName() {
        let atom = MTMathAtomFactory.atom(forLatexSymbolName: "alpha")
        XCTAssertNotNil(atom)
    }

    func testAtomForLatexSymbolNameUnknown() {
        let atom = MTMathAtomFactory.atom(forLatexSymbolName: "notasymbol")
        XCTAssertNil(atom)
    }

    func testLatexSymbolNameForAtom() {
        let atom = MTMathAtomFactory.atom(forLatexSymbolName: "beta")!
        let name = MTMathAtomFactory.latexSymbolName(for: atom)
        XCTAssertEqual(name, "beta")
    }

    func testFractionWithLists() {
        let num = MTMathListBuilder.build(from: "1")!
        let denom = MTMathListBuilder.build(from: "2")!
        let frac = MTMathAtomFactory.fraction(withNumerator: num, denominator: denom)
        XCTAssertNotNil(frac)
    }

    func testFractionWithStrings() {
        let frac = MTMathAtomFactory.fraction(withNumeratorStr: "3", denominatorStr: "4")
        XCTAssertNotNil(frac)
    }

    func testOperatorWithName() {
        let op = MTMathAtomFactory.operator(withName: "lim", limits: true)
        XCTAssertNotNil(op)
    }

    func testSupportedLatexSymbolNames() {
        let names = MTMathAtomFactory.supportedLatexSymbolNames()
        XCTAssertFalse(names.isEmpty)
    }

    func testBoundaryAtomForDelimiterName() {
        let atom = MTMathAtomFactory.boundaryAtom(forDelimiterName: "(")
        XCTAssertNotNil(atom)
    }
}

final class MTMathListIndexTests: XCTestCase {
    func testLevel0Index() {
        let idx = MTMathListIndex.level0Index(3)
        XCTAssertEqual(idx.atomIndex, 3)
        XCTAssertNil(idx.sub)
        XCTAssertEqual(idx.subIndexType, .subIndexTypeNone)
    }

    func testIndexAtLocationWithSubIndex() {
        let sub = MTMathListIndex.level0Index(1)
        let idx = MTMathListIndex(atLocation: 2, withSubIndex: sub, type: .subIndexTypeSuperscript)
        XCTAssertEqual(idx.atomIndex, 2)
        XCTAssertEqual(idx.subIndexType, .subIndexTypeSuperscript)
        XCTAssertNotNil(idx.sub)
    }

    func testIndexAtLocationNilSubIndex() {
        let idx = MTMathListIndex(atLocation: 0, withSubIndex: nil, type: .subIndexTypeNone)
        XCTAssertEqual(idx.atomIndex, 0)
        XCTAssertNil(idx.sub)
    }

    func testLevelUp() {
        let base = MTMathListIndex.level0Index(0)
        let sub = MTMathListIndex.level0Index(1)
        let up = base.levelUp(withSubIndex: sub, type: .subIndexTypeNumerator)
        XCTAssertEqual(up.subIndexType, .subIndexTypeNumerator)
    }

    func testLevelDown() {
        let sub = MTMathListIndex.level0Index(1)
        let idx = MTMathListIndex(atLocation: 0, withSubIndex: sub, type: .subIndexTypeDenominator)
        let down = idx.levelDown()
        XCTAssertNotNil(down)
        XCTAssertEqual(down?.atomIndex, 0)
    }

    func testNext() {
        let idx = MTMathListIndex.level0Index(4)
        let next = idx.next()
        XCTAssertEqual(next.atomIndex, 5)
    }

    func testIsAtBeginningOfLine() {
        let idx = MTMathListIndex.level0Index(0)
        XCTAssertTrue(idx.isAtBeginningOfLine())
        let other = MTMathListIndex.level0Index(2)
        XCTAssertFalse(other.isAtBeginningOfLine())
    }

    func testEquality() {
        let a = MTMathListIndex.level0Index(5)
        let b = MTMathListIndex.level0Index(5)
        XCTAssertEqual(a, b)
    }

    func testSubIndexTypes() {
        // Verify that all sub-index type enum cases are accessible from Swift.
        let types: [MTMathListSubIndexType] = [
            .subIndexTypeNone,
            .subIndexTypeNucleus,
            .subIndexTypeSuperscript,
            .subIndexTypeSubscript,
            .subIndexTypeNumerator,
            .subIndexTypeDenominator,
            .subIndexTypeRadicand,
            .subIndexTypeDegree,
            .subIndexTypeInner,
        ]
        XCTAssertEqual(types.count, 9)
    }
}
