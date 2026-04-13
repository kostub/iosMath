//
//  ContentView.swift
//  SwiftMathExample
//
//  Mirrors iosMathExample: 22 showcase formulae followed by 48 typesetter
//  test cases, each with the same rendering properties as the ObjC apps.
//
//  MathDemoFormulas() and MathTestFormulas() come from the bridging header
//  which imports MathExamples.h. They return [String].
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI
import iosMath

struct ContentView: View {
    // Heights match the ObjC example apps exactly.
    private static let demoHeights: [CGFloat] = [
        60, 40, 40, 80, 60, 40, 40, 40, 40, 60, 40, 40, 60, 60, 60, 70, 70, 140, 60, 90, 60, 60
    ]
    private static let testHeights: [CGFloat] = [
        40, 40, 40, 40, 40, 60, 60, 60, 90, 30, 40, 90, 40, 60, 60, 60,
        60, 60, 60, 60, 60, 60, 30, 20, 20, 60, 30, 40, 30, 30, 50, 50,
        50, 50, 30, 30, 30, 30, 30, 50, 80, 120, 30, 30, 30, 30, 30, 70
    ]

    // Shared formula strings — sourced from MathExamples.h via bridging header.
    private let demoFormulas: [String] = MathDemoFormulas()
    private let testFormulas: [String] = MathTestFormulas()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                // --- Demo formulae ---
                ForEach(demoFormulas.indices, id: \.self) { i in
                    MathLabel(latex: demoFormulas[i], fontSize: 15)
                        .frame(height: Self.demoHeights[i])
                        .padding(.horizontal, 10)
                }

                Divider().padding(.vertical, 10)

                // --- Test formulae ---
                ForEach(testFormulas.indices, id: \.self) { i in
                    MathLabel(
                        latex: testFormulas[i],
                        fontSize: testFontSize(at: i),
                        mode: testMode(at: i),
                        alignment: testAlignment(at: i),
                        highlighted: [0, 1, 3, 6, 7].contains(i),
                        leftInset: i == 6 ? 20 : 0,
                        rightInset: i == 3 ? 20 : 0
                    )
                    .frame(height: Self.testHeights[i])
                    .padding(.horizontal, 10)
                }
            }
            .padding(.vertical, 10)
        }
        .background(Color.white)
    }

    // MARK: - Per-label rendering properties

    private func testFontSize(at i: Int) -> CGFloat {
        switch i {
        case 8: return 30
        case 9: return 10
        default: return 15
        }
    }

    private func testMode(at i: Int) -> MTMathUILabelMode {
        [5, 7, 17, 18, 26, 28].contains(i) ? .text : .display
    }

    private func testAlignment(at i: Int) -> MTTextAlignment {
        switch i {
        case 1: return .center
        case 3: return .right
        default: return .left
        }
    }
}
