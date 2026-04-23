//
//  MathView.swift
//  iosMathSwiftUIExample
//
//  SwiftUI wrapper around MTMathUILabel from the iosMath Objective-C library.
//

import SwiftUI
import UIKit
import iosMath

enum MathFontFace: String, CaseIterable, Identifiable {
    case latinModern = "Latin Modern Math"
    case termes = "TeX Gyre Termes"
    case xits = "XITS Math"

    var id: String { rawValue }

    func font(size: CGFloat) -> MTFont {
        let manager = MTFontManager.sharedInstance()
        switch self {
        case .latinModern: return manager.latinModernFont(withSize: size)
        case .termes:      return manager.termesFont(withSize: size)
        case .xits:        return manager.xitsFont(withSize: size)
        }
    }
}

enum MathAlignment: CaseIterable {
    case left, center, right

    var mtAlignment: MTTextAlignment {
        switch self {
        case .left:   return .left
        case .center: return .center
        case .right:  return .right
        }
    }
}

enum MathMode: CaseIterable {
    case display, text

    var mtMode: MTMathUILabelMode {
        switch self {
        case .display: return .display
        case .text:    return .text
        }
    }
}

struct MathView: UIViewRepresentable {
    var latex: String
    var fontFace: MathFontFace = .latinModern
    var fontSize: CGFloat = 20
    var textColor: UIColor = .label
    var backgroundColor: UIColor = .clear
    var alignment: MathAlignment = .left
    var mode: MathMode = .display
    var contentInsets: UIEdgeInsets = .zero

    func makeUIView(context: Context) -> MTMathUILabel {
        let label = MTMathUILabel()
        apply(to: label)
        return label
    }

    func updateUIView(_ uiView: MTMathUILabel, context: Context) {
        apply(to: uiView)
    }

    private func apply(to label: MTMathUILabel) {
        label.latex = latex
        label.font = fontFace.font(size: fontSize)
        label.fontSize = fontSize
        label.textColor = textColor
        label.backgroundColor = backgroundColor
        label.textAlignment = alignment.mtAlignment
        label.labelMode = mode.mtMode
        label.contentInsets = contentInsets
    }
}
