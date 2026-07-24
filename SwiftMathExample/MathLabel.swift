//
//  MathLabel.swift
//  SwiftMathExample
//
//  SwiftUI wrapper for MTMathUILabel, cross-platform (iOS + macOS).
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI
import iosMath

/// A SwiftUI view that renders a LaTeX math formula using MTMathUILabel.
struct MathLabel: View {
    let latex: String
    var fontSize: CGFloat = 15
    var mode: MTMathUILabelMode = .display
    var alignment: MTTextAlignment = .left
    /// Applies a light yellow background, mirroring the ObjC test example highlights.
    var highlighted: Bool = false
    var leftInset: CGFloat = 0
    var rightInset: CGFloat = 0
    /// Math font face. When nil, MTMathUILabel keeps its default (Latin Modern Math).
    var font: MTFont? = nil

    var body: some View {
        _MathLabelRepresentable(
            latex: latex,
            fontSize: fontSize,
            mode: mode,
            alignment: alignment,
            highlighted: highlighted,
            leftInset: leftInset,
            rightInset: rightInset,
            font: font
        )
    }
}

/// The math fonts bundled with iosMath, exposed for the font switcher.
enum MathFont: String, CaseIterable, Identifiable {
    case latinModern = "Latin Modern"
    case termes = "TeX Gyre Termes"
    case xits = "XITS"
    case newComputerModern = "New Computer Modern"
    case pagella = "TeX Gyre Pagella"
    case stixTwo = "STIX Two"
    case firaMath = "Fira Math"
    case notoSansMath = "Noto Sans Math"

    var id: String { rawValue }

    var fontName: String {
        switch self {
        case .latinModern:      return MTFontNameLatinModern
        case .termes:           return MTFontNameTermes
        case .xits:             return MTFontNameXITS
        case .newComputerModern: return MTFontNameNewComputerModern
        case .pagella:          return MTFontNamePagella
        case .stixTwo:          return MTFontNameSTIXTwo
        case .firaMath:         return MTFontNameFiraMath
        case .notoSansMath:     return MTFontNameNotoSansMath
        }
    }

    func font(size: CGFloat) -> MTFont? {
        MTFontManager.fontManager.font(withName: fontName, size: size)
    }
}

// MARK: - Platform representables

#if os(iOS)
import UIKit

private struct _MathLabelRepresentable: UIViewRepresentable {
    let latex: String
    let fontSize: CGFloat
    let mode: MTMathUILabelMode
    let alignment: MTTextAlignment
    let highlighted: Bool
    let leftInset: CGFloat
    let rightInset: CGFloat
    let font: MTFont?

    func makeUIView(context: Context) -> MTMathUILabel {
        MTMathUILabel()
    }

    func updateUIView(_ label: MTMathUILabel, context: Context) {
        label.latex = latex
        if let font = font {
            label.font = font
        }
        label.fontSize = fontSize
        label.mode = mode
        label.textAlignment = alignment
        label.contentInsets = UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        label.backgroundColor = highlighted
            ? UIColor(hue: 0.15, saturation: 0.5, brightness: 1.0, alpha: 0.5)
            : .clear
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MTMathUILabel, context: Context) -> CGSize? {
        mathSizeThatFits(proposal, intrinsic: uiView.intrinsicContentSize)
    }
}

#elseif os(macOS)
import AppKit

private struct _MathLabelRepresentable: NSViewRepresentable {
    let latex: String
    let fontSize: CGFloat
    let mode: MTMathUILabelMode
    let alignment: MTTextAlignment
    let highlighted: Bool
    let leftInset: CGFloat
    let rightInset: CGFloat
    let font: MTFont?

    func makeNSView(context: Context) -> MTMathUILabel {
        MTMathUILabel()
    }

    func updateNSView(_ label: MTMathUILabel, context: Context) {
        label.latex = latex
        if let font = font {
            label.font = font
        }
        label.fontSize = fontSize
        label.mode = mode
        label.textAlignment = alignment
        label.contentInsets = NSEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        label.backgroundColor = highlighted
            ? NSColor(hue: 0.15, saturation: 0.5, brightness: 1.0, alpha: 0.5)
            : .clear
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: MTMathUILabel, context: Context) -> CGSize? {
        mathSizeThatFits(proposal, intrinsic: nsView.intrinsicContentSize)
    }
}
#endif

/// Width policy shared by both platform representables.
///
/// MTMathUILabel's default intrinsic content size is the formula's *natural* width,
/// and its high compression resistance otherwise refuses to be narrower than that.
/// A single formula wider than the viewport (e.g. the Rogers–Ramanujan fraction in
/// Latin Modern, which is wider in that font than in TeX Gyre) would then stretch the
/// whole column and clip every row. Instead: fill exactly the width we're offered when
/// that is finite (so the label still fills its row and `.center`/`.right` alignment
/// works), and only fall back to the natural width when offered unbounded space — e.g.
/// inside a horizontal ScrollView, where the formula is meant to scroll.
private func mathSizeThatFits(_ proposal: ProposedViewSize, intrinsic: CGSize) -> CGSize {
    switch proposal.width {
    case .some(let width) where width != .infinity:
        return CGSize(width: width, height: intrinsic.height)
    default:
        return intrinsic
    }
}
