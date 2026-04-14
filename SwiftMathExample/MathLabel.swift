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

    var body: some View {
        _MathLabelRepresentable(
            latex: latex,
            fontSize: fontSize,
            mode: mode,
            alignment: alignment,
            highlighted: highlighted,
            leftInset: leftInset,
            rightInset: rightInset
        )
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

    func makeUIView(context: Context) -> MTMathUILabel {
        MTMathUILabel()
    }

    func updateUIView(_ label: MTMathUILabel, context: Context) {
        label.latex = latex
        label.fontSize = fontSize
        label.mode = mode
        label.textAlignment = alignment
        label.contentInsets = UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        label.backgroundColor = highlighted
            ? UIColor(hue: 0.15, saturation: 0.2, brightness: 1.0, alpha: 1.0)
            : .clear
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

    func makeNSView(context: Context) -> MTMathUILabel {
        MTMathUILabel()
    }

    func updateNSView(_ label: MTMathUILabel, context: Context) {
        label.latex = latex
        label.fontSize = fontSize
        label.mode = mode
        label.textAlignment = alignment
        label.contentInsets = NSEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        label.backgroundColor = highlighted
            ? NSColor(hue: 0.15, saturation: 0.2, brightness: 1.0, alpha: 1.0)
            : .clear
    }
}
#endif
