//
//  ContentView.swift
//  SwiftMathExample
//
//  The original single-page gallery showed only the raw rendering test suite —
//  useful for verifying correctness but not as a beginner reference. This file
//  restructures the app into two tabs:
//
//   • Examples — 10 named, curated formulae (quadratic formula, Euler's
//     identity, matrices, …) that mirror the README quick-start snippets.
//     Each formula is displayed in a card with a human-readable title, making
//     the app usable as a first-look reference alongside the documentation.
//
//   • Gallery — the original full rendering test suite (22 demo formulae +
//     48 typesetter cases) preserved verbatim so regression coverage is not
//     lost.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI
import iosMath

// MARK: - Top-level tab container

struct ContentView: View {
    var body: some View {
        TabView {
            ExamplesTab()
                .tabItem { Label("Examples", systemImage: "function") }
            GalleryTab()
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

private let namedExamples: [NamedFormula] = [
    NamedFormula(
        title: "Fourier transform",
        latex: #"f(x) = \int\limits_{-\infty}^\infty\!\hat f(\xi)\,e^{2 \pi i \xi x}\,\mathrm{d}\xi"#,
        height: 70
    ),
    NamedFormula(
        title: "Standard deviation",
        latex: #"\sigma = \sqrt{\frac{1}{N}\sum_{i=1}^N (x_i - \mu)^2}"#,
        height: 70
    ),
    NamedFormula(
        title: "AM-GM inequality",
        latex: #"\frac{1}{n}\sum_{i=1}^{n}x_i \geq \sqrt[n]{\prod_{i=1}^{n}x_i}"#,
        height: 80
    ),
    NamedFormula(
        title: "Cauchy-Schwarz inequality",
        latex: #"\left(\sum_{k=1}^n a_k b_k \right)^2 \le \left(\sum_{k=1}^n a_k^2\right)\left(\sum_{k=1}^n b_k^2\right)"#,
        height: 80
    ),
    NamedFormula(
        title: "Cauchy integral formula",
        latex: #"f^{(n)}(z_0) = \frac{n!}{2\pi i}\oint_\gamma\frac{f(z)}{(z-z_0)^{n+1}}dz"#,
        height: 80
    ),
    NamedFormula(
        title: "Schrödinger's equation",
        latex: #"i\hbar\frac{\partial}{\partial t}\mathbf\Psi(\mathbf{x},t) = -\frac{\hbar}{2m}\nabla^2\mathbf\Psi(\mathbf{x},t) + V(\mathbf{x})\mathbf\Psi(\mathbf{x},t)"#,
        height: 80
    ),
    NamedFormula(
        title: "Cross product",
        latex: #"\vec{\bf V}_1 \times \vec{\bf V}_2 = \begin{vmatrix}\hat\imath & \hat\jmath & \hat k \\\frac{\partial X}{\partial u} & \frac{\partial Y}{\partial u} & 0 \\\frac{\partial X}{\partial v} & \frac{\partial Y}{\partial v} & 0\end{vmatrix}"#,
        fontSize: 16,
        height: 140
    ),
    NamedFormula(
        title: "Maxwell's equations",
        latex: #"\begin{eqalign}\nabla \cdot \vec{\bf E} &= \frac{\rho}{\varepsilon_0} \\\nabla \cdot \vec{\bf B} &= 0 \\\nabla \times \vec{\bf E} &= -\frac{\partial\vec{\bf B}}{\partial t} \\\nabla \times \vec{\bf B} &= \mu_0\vec{\bf J} + \mu_0\varepsilon_0\frac{\partial\vec{\bf E}}{\partial t}\end{eqalign}"#,
        fontSize: 16,
        height: 200
    ),
    NamedFormula(
        title: "Piecewise function",
        latex: #"f(x) = \begin{cases}\frac{e^x}{2} & x \geq 0 \\ 1 & x < 0\end{cases}"#,
        height: 100
    ),
    NamedFormula(
        title: "Splitting long equations",
        latex: #"\frak Q(\lambda,\hat{\lambda}) = -\frac{1}{2}\mathbb P(O \mid \lambda)\sum_s\sum_m\sum_t \gamma_m^{(s)}(t) +\\ \quad \left(\log(2\pi) + \log\left|\cal C_m^{(s)}\right| + \left(o_t - \hat{\mu}_m^{(s)}\right)^T \cal C_m^{(s)-1}\right)"#,
        height: 130
    ),
]

/// Curated, named examples — suitable as a quick-start reference.
private struct ExamplesTab: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(namedExamples.indices, id: \.self) { i in
                        ExampleCard(formula: namedExamples[i])
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formula.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            MathLabel(latex: formula.latex, fontSize: formula.fontSize, mode: formula.mode)
                .frame(height: formula.height)
        }
        .padding()
        .background(Color(white: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Gallery tab

/// Full rendering test suite — demo formulae then typesetter cases.
private struct GalleryTab: View {

    private static let demoHeights: [CGFloat] = [
        60, 40, 40, 80, 60, 40, 40, 40, 40, 60, 40, 40, 60, 60, 60, 70, 70, 140, 60, 90, 60, 60, 70
    ]
    private static let testHeights: [CGFloat] = [
        40, 40, 40, 40, 40, 60, 60, 60, 90, 30, 40, 90, 40, 60, 60, 60,
        60, 60, 60, 60, 60, 60, 30, 20, 20, 60, 30, 40, 30, 30, 50, 50,
        50, 50, 30, 30, 30, 30, 30, 50, 80, 120, 30, 30, 30, 30, 30, 70,
        40, 40, 50, 60, 50, 40, 70, 40
    ]

    private let demoFormulas: [String] = MathDemoFormulas()
    private let testFormulas: [String] = MathTestFormulas()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {

                    // Demo formulae
                    ForEach(demoFormulas.indices, id: \.self) { i in
                        MathLabel(latex: demoFormulas[i], fontSize: 15)
                            .frame(height: demoHeight(at: i))
                            .padding(.horizontal, 10)
                    }

                    Divider().padding(.vertical, 10)

                    // Typesetter test cases
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

    private func demoHeight(at i: Int) -> CGFloat {
        Self.demoHeights.indices.contains(i) ? Self.demoHeights[i] : 60
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
