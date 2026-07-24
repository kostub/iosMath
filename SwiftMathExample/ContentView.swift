//
//  ContentView.swift
//  SwiftMathExample
//
//  The original single-page gallery showed only the raw rendering test suite —
//  useful for verifying correctness but not as a beginner reference. This file
//  restructures the app into three tabs:
//
//   • Examples — named, curated formulae (quadratic formula, Euler's
//     identity, matrices, ...) that mirror the README quick-start snippets.
//     Each formula is displayed in a card with a human-readable title, making
//     the app usable as a first-look reference alongside the documentation.
//
//   • Playground — an interactive sandbox: type any LaTeX and pick a math font
//     to see it render live.
//
//   • Gallery — the full rendering test suite plus visual regression cases
//     for parser and typesetter features.
//
//  The selected font is shared across all three tabs.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI
import iosMath

// MARK: - Top-level tab container

struct ContentView: View {
    /// Selected math font, shared across all tabs — switching it in the
    /// Playground re-renders the Examples and Gallery too, mirroring the ObjC example.
    @State private var font: MathFont = .latinModern
    /// Global font size, shared across all tabs (range 10–40, default 15).
    @State private var fontSize: CGFloat = 15

    var body: some View {
        TabView {
            ExamplesTab(font: font, fontSize: fontSize)
                .tabItem { Label("Examples", systemImage: "function") }
            PlaygroundTab(font: $font, fontSize: $fontSize)
                .tabItem { Label("Playground", systemImage: "pencil.and.scribble") }
            GalleryTab(font: font, fontSize: fontSize)
                .tabItem { Label("Gallery", systemImage: "square.grid.2x2") }
        }
    }
}

// MARK: - Examples tab

private struct NamedFormula {
    let title: String
    let latex: String
    var mode: MTMathUILabelMode = .display
}

/// Curated examples — keep in sync with MathDemoFormulas() in MathExamples.h.
/// LaTeX strings are sourced from MathDemoFormulas() so content stays consistent;
/// titles live here.
private struct NamedFormulaMeta {
    let title: String
    var mode: MTMathUILabelMode = .display
}

private let namedExampleMeta: [NamedFormulaMeta] = [
    NamedFormulaMeta(title: "Quadratic formula"),
    NamedFormulaMeta(title: "Cosine addition formula"),
    NamedFormulaMeta(title: "Rogers–Ramanujan continued fraction"),
    NamedFormulaMeta(title: "Standard deviation"),
    NamedFormulaMeta(title: "De Morgan's law"),
    NamedFormulaMeta(title: "Change of base"),
    NamedFormulaMeta(title: "Compound interest limit"),
    NamedFormulaMeta(title: "Gaussian integral"),
    NamedFormulaMeta(title: "AM-GM inequality"),
    NamedFormulaMeta(title: "Cauchy integral formula"),
    NamedFormulaMeta(title: "Schrödinger's equation"),
    NamedFormulaMeta(title: "Cauchy-Schwarz inequality"),
    NamedFormulaMeta(title: "Stirling numbers"),
    NamedFormulaMeta(title: "Fourier transform"),
    NamedFormulaMeta(title: "Lorenz system"),
    NamedFormulaMeta(title: "Cross product"),
    NamedFormulaMeta(title: "Maxwell's equations"),
    NamedFormulaMeta(title: "2×2 matrix multiplication"),
    NamedFormulaMeta(title: "EM algorithm Q-function"),
    NamedFormulaMeta(title: "Piecewise function"),
    NamedFormulaMeta(title: "Ridge regression"),
    NamedFormulaMeta(title: "Augmented matrix"),
    NamedFormulaMeta(title: "Multiplication table"),
]

private let namedExamples: [NamedFormula] = {
    let formulas = MathDemoFormulas()
    precondition(formulas.count == namedExampleMeta.count,
                 "namedExampleMeta (\(namedExampleMeta.count)) must match MathDemoFormulas (\(formulas.count))")
    return zip(namedExampleMeta, formulas).map { meta, latex in
        NamedFormula(title: meta.title, latex: latex, mode: meta.mode)
    }
}()

/// Curated, named examples — suitable as a quick-start reference.
private struct ExamplesTab: View {
    let font: MathFont
    let fontSize: CGFloat

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(namedExamples.indices, id: \.self) { i in
                        ExampleCard(formula: namedExamples[i], font: font, fontSize: fontSize)
                    }
                }
                .padding()
            }
            .navigationTitle("Examples")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

private struct ExampleCard: View {
    let formula: NamedFormula
    let font: MathFont
    let fontSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formula.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            // Horizontal scroll so a formula wider than the screen (e.g. the
            // Rogers–Ramanujan fraction in Latin Modern) scrolls within its card
            // instead of stretching the whole column and clipping every card's left edge.
            // No fixed height: the label reports its intrinsic content height (see
            // MathLabel.sizeThatFits), so tall formulae aren't vertically clipped at
            // any font size.
            ScrollView(.horizontal, showsIndicators: false) {
                MathLabel(latex: formula.latex, fontSize: fontSize, mode: formula.mode,
                          font: font.font(size: fontSize))
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .primary.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Playground tab

/// Interactive sandbox: type any LaTeX and pick a math font to see it render
/// live. Mirrors the LaTeX text field and font switcher in the ObjC iosMathExample.
private struct PlaygroundTab: View {
    @Binding var font: MathFont
    @Binding var fontSize: CGFloat
    @State private var latex = #"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Live rendering of whatever is in the editor.
                ScrollView(.horizontal, showsIndicators: false) {
                    MathLabel(
                        latex: latex,
                        fontSize: fontSize,
                        mode: .display,
                        alignment: .center,
                        font: font.font(size: fontSize)
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
                    .padding(.horizontal, 12)
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .primary.opacity(0.06), radius: 4, x: 0, y: 2)

                // Font switcher + size stepper. Spacer + fixedSize keep the
                // stepper pinned to the trailing edge so it doesn't shift as the
                // font picker's width changes with the selected font's name.
                HStack {
                    Picker("Font", selection: $font) {
                        ForEach(MathFont.allCases) { font in
                            Text(font.rawValue).tag(font)
                        }
                    }
                    .pickerStyle(.menu)
                    Spacer()
                    Stepper("Size: \(Int(fontSize))", value: $fontSize, in: 10...40)
                        .fixedSize()
                }

                // LaTeX editor.
                Text("LaTeX")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $latex)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled(true)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .frame(minHeight: 80, maxHeight: 160)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

                Spacer()
            }
            .padding()
            .navigationTitle("Playground")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

// MARK: - Gallery tab

/// Full typesetter test suite. Curated real-math formulae live in the Examples tab.
private struct GalleryTab: View {
    let font: MathFont
    let fontSize: CGFloat

    private static let testHeights: [CGFloat] = [
        40, 40, 40, 40, 40, 60, 60, 60, 90, 30, 40, 90, 40, 60, 60, 60,
        60, 60, 60, 60, 60, 60, 30, 20, 20, 60, 30, 40, 30, 30, 50, 50,
        50, 50, 30, 30, 30, 30, 30, 50, 80, 120, 30, 30, 30, 30, 30, 70,
        40, 40, 50, 60, 50, 40, 70, 40,
        40, 40, 40, 40, 40, 50, 50, 60, 50, 50, 40, 70,
        80, 150, 60, 60, 50, 60, 50,
        40, 60, 60, 70, 60, 60, 70, 60, 60, 60, 60,
        70, 40, 40, 50, 40, 50,
        50, 50, 70, 70
    ]

    private static let testFormulas: [String] = {
        let formulas = MathTestFormulas()
        precondition(formulas.count == testHeights.count,
                     "testHeights (\(testHeights.count)) must match MathTestFormulas (\(formulas.count))")
        return formulas
    }()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Self.testFormulas.indices, id: \.self) { i in
                        MathLabel(
                            latex: Self.testFormulas[i],
                            fontSize: fontSize,
                            mode: testMode(at: i),
                            alignment: testAlignment(at: i),
                            highlighted: [0, 1, 3, 6, 7].contains(i),
                            leftInset: i == 6 ? 20 : 0,
                            rightInset: i == 3 ? 20 : 0,
                            font: font.font(size: fontSize)
                        )
                        // Scale the row height with the font, relative to the size
                        // each entry's height was tuned for, so nothing clips.
                        .frame(height: testHeight(at: i) * (fontSize / testBaselineFontSize(at: i)))
                        .padding(.horizontal, 10)
                    }
                }
                .padding(.vertical, 10)
            }
            .background(.background)
            .navigationTitle("Gallery")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }

    private func testHeight(at i: Int) -> CGFloat {
        Self.testHeights.indices.contains(i) ? Self.testHeights[i] : 40
    }

    /// Font size each entry's tuned height assumes, used to scale heights with
    /// the slider. Indices 8 and 9 were originally shown larger/smaller.
    private func testBaselineFontSize(at i: Int) -> CGFloat {
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
