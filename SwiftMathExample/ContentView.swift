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

    var body: some View {
        TabView {
            ExamplesTab(font: font)
                .tabItem { Label("Examples", systemImage: "function") }
            PlaygroundTab(font: $font)
                .tabItem { Label("Playground", systemImage: "pencil.and.scribble") }
            GalleryTab(font: font)
                .tabItem { Label("Gallery", systemImage: "square.grid.2x2") }
        }
    }
}

// MARK: - Examples tab

private struct NamedFormula {
    let title: String
    let latex: String
    var mode: MTMathUILabelMode = .display
    var fontSize: CGFloat = 20
    var height: CGFloat = 60
}

/// Curated examples — keep in sync with MathDemoFormulas() in MathExamples.h.
/// LaTeX strings are sourced from MathDemoFormulas() so content stays consistent;
/// titles and per-formula display metadata live here.
private struct NamedFormulaMeta {
    let title: String
    var mode: MTMathUILabelMode = .display
    var fontSize: CGFloat = 20
    var height: CGFloat = 60
}

private let namedExampleMeta: [NamedFormulaMeta] = [
    NamedFormulaMeta(title: "Quadratic formula", height: 80),
    NamedFormulaMeta(title: "Cosine addition formula", height: 60),
    NamedFormulaMeta(title: "Rogers–Ramanujan continued fraction", height: 130),
    NamedFormulaMeta(title: "Standard deviation", height: 80),
    NamedFormulaMeta(title: "De Morgan's law", height: 60),
    NamedFormulaMeta(title: "Change of base", height: 70),
    NamedFormulaMeta(title: "Compound interest limit", height: 70),
    NamedFormulaMeta(title: "Gaussian integral", height: 70),
    NamedFormulaMeta(title: "AM-GM inequality", height: 80),
    NamedFormulaMeta(title: "Cauchy integral formula", height: 80),
    NamedFormulaMeta(title: "Schrödinger's equation", fontSize: 16, height: 80),
    NamedFormulaMeta(title: "Cauchy-Schwarz inequality", height: 80),
    NamedFormulaMeta(title: "Stirling numbers", height: 80),
    NamedFormulaMeta(title: "Fourier transform", height: 70),
    NamedFormulaMeta(title: "Lorenz system", height: 110),
    NamedFormulaMeta(title: "Cross product", fontSize: 16, height: 140),
    NamedFormulaMeta(title: "Maxwell's equations", fontSize: 16, height: 200),
    NamedFormulaMeta(title: "2×2 matrix multiplication", fontSize: 16, height: 90),
    NamedFormulaMeta(title: "EM algorithm Q-function", height: 130),
    NamedFormulaMeta(title: "Piecewise function", height: 100),
]

private let namedExamples: [NamedFormula] = {
    let formulas = MathDemoFormulas()
    precondition(formulas.count == namedExampleMeta.count,
                 "namedExampleMeta (\(namedExampleMeta.count)) must match MathDemoFormulas (\(formulas.count))")
    return zip(namedExampleMeta, formulas).map { meta, latex in
        NamedFormula(title: meta.title, latex: latex, mode: meta.mode, fontSize: meta.fontSize, height: meta.height)
    }
}()

/// Curated, named examples — suitable as a quick-start reference.
private struct ExamplesTab: View {
    let font: MathFont

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(namedExamples.indices, id: \.self) { i in
                        ExampleCard(formula: namedExamples[i], font: font)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formula.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            // Horizontal scroll so a formula wider than the screen (e.g. the
            // Rogers–Ramanujan fraction in Latin Modern) scrolls within its card
            // instead of stretching the whole column and clipping every card's left edge.
            ScrollView(.horizontal, showsIndicators: false) {
                MathLabel(latex: formula.latex, fontSize: formula.fontSize, mode: formula.mode,
                          font: font.font(size: formula.fontSize))
                    .frame(height: formula.height)
            }
        }
        .padding()
        .background(Color(white: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Playground tab

/// Interactive sandbox: type any LaTeX and pick a math font to see it render
/// live. Mirrors the LaTeX text field and font switcher in the ObjC iosMathExample.
private struct PlaygroundTab: View {
    @Binding var font: MathFont
    @State private var latex = #"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#

    private let fontSize: CGFloat = 24

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
                .background(Color(white: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                // Font switcher.
                Picker("Font", selection: $font) {
                    ForEach(MathFont.allCases) { font in
                        Text(font.rawValue).tag(font)
                    }
                }
                .pickerStyle(.segmented)

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

    private static let testHeights: [CGFloat] = [
        40, 40, 40, 40, 40, 60, 60, 60, 90, 30, 40, 90, 40, 60, 60, 60,
        60, 60, 60, 60, 60, 60, 30, 20, 20, 60, 30, 40, 30, 30, 50, 50,
        50, 50, 30, 30, 30, 30, 30, 50, 80, 120, 30, 30, 30, 30, 30, 70,
        40, 40, 50, 60, 50, 40, 70, 40,
        40, 40, 40, 40, 40, 50, 50, 60, 50, 50, 40, 70,
        80, 150, 60, 60, 50, 60, 50,
        40, 60, 60, 70, 60, 60, 70, 60, 60, 60, 60
    ]

    private let testFormulas: [String] = MathTestFormulas()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(testFormulas.indices, id: \.self) { i in
                        MathLabel(
                            latex: testFormulas[i],
                            fontSize: testFontSize(at: i),
                            mode: testMode(at: i),
                            alignment: testAlignment(at: i),
                            highlighted: [0, 1, 3, 6, 7].contains(i),
                            leftInset: i == 6 ? 20 : 0,
                            rightInset: i == 3 ? 20 : 0,
                            font: font.font(size: testFontSize(at: i))
                        )
                        .frame(height: testHeight(at: i))
                        .padding(.horizontal, 10)
                    }
                }
                .padding(.vertical, 10)
            }
            .background(Color.white)
            .navigationTitle("Gallery")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }

    private func testFontSize(at i: Int) -> CGFloat {
        switch i {
        case 8: return 30
        case 9: return 10
        default: return 15
        }
    }

    private func testHeight(at i: Int) -> CGFloat {
        Self.testHeights.indices.contains(i) ? Self.testHeights[i] : 40
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
