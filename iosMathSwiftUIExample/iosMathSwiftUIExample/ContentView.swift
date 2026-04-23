//
//  ContentView.swift
//  iosMathSwiftUIExample
//
//  SwiftUI port of iosMathExample's ViewController.
//

import SwiftUI
import UIKit

struct NamedColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let uiColor: UIColor
}

private let palette: [NamedColor] = [
    NamedColor(name: "Black", color: .black, uiColor: .black),
    NamedColor(name: "Blue",  color: .blue,  uiColor: .blue),
    NamedColor(name: "Red",   color: .red,   uiColor: .red),
    NamedColor(name: "Green", color: .green, uiColor: .green),
]

struct ContentView: View {
    @State private var fontFace: MathFontFace = .latinModern
    @State private var selectedColor: NamedColor = palette[0]
    @State private var latexInput: String = #"x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}"#
    @State private var renderedLatex: String = #"x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}"#

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    controlsSection
                    liveEditorSection
                    sectionHeader("Demo formulae")
                    ForEach(Formulae.demoFormulae) { item in
                        formulaRow(item)
                    }
                    sectionHeader("Test formulae")
                    ForEach(Formulae.testFormulae) { item in
                        formulaRow(item)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("iosMath SwiftUI")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Font").frame(width: 60, alignment: .leading)
                Picker("Font", selection: $fontFace) {
                    ForEach(MathFontFace.allCases) { face in
                        Text(face.rawValue).tag(face)
                    }
                }
                .pickerStyle(.menu)
            }
            HStack {
                Text("Color").frame(width: 60, alignment: .leading)
                Picker("Color", selection: $selectedColor) {
                    ForEach(palette) { entry in
                        Text(entry.name).tag(entry)
                    }
                }
                .pickerStyle(.menu)
                Spacer()
                Circle()
                    .fill(selectedColor.color)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.gray.opacity(0.3)))
            }
        }
        .padding(.top, 8)
    }

    private var liveEditorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Live LaTeX")
            MathView(
                latex: renderedLatex,
                fontFace: fontFace,
                fontSize: 20,
                textColor: selectedColor.uiColor
            )
            .frame(height: 80)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)

            TextField("Enter LaTeX", text: $latexInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .lineLimit(1...4)
                .onSubmit { renderedLatex = latexInput }

            Button("Render") { renderedLatex = latexInput }
                .buttonStyle(.borderedProminent)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.top, 8)
    }

    private func formulaRow(_ item: FormulaItem) -> some View {
        MathView(
            latex: item.latex,
            fontFace: fontFace,
            fontSize: item.fontSize,
            textColor: selectedColor.uiColor,
            backgroundColor: item.backgroundColor,
            alignment: item.alignment,
            mode: item.mode,
            contentInsets: item.contentInsets
        )
        .frame(height: item.height)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
}
