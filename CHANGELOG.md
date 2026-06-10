## Changelog

### v2.3.2 (2026-06-10)
* Fix: `MTFontManager fontWithName:size:` now returns `nil` for unknown or unloadable font names instead of crashing (`CFRelease(NULL)`) or throwing. The Swift signature is now correctly `MTFont?` (#223).

### v2.3.1 (2026-06-07)
* Fix SPM consumer build: public headers in `render/` used bare `#import` of siblings in `lib/`, which only resolved via target-internal header search paths and failed when downstream packages built the `iosMath` Clang module. Qualify the cross-directory imports so the module builds in consumer projects (#215).
* Lower deployment targets from iOS 18+ / macOS 15+ back down to **iOS 13+ / macOS 10.15+**. The earlier raise was a toolchain-cleanup pass, not driven by any actual API requirement (#214).

### v2.3.0 (2026-05-31)
* **Breaking:** Removed `latinModernFontWithSize:`, `xitsFontWithSize:`, and `termesFontWithSize:` from `MTFontManager`. Use `fontWithName:size:` with the new `MTFontName*` constants instead (`defaultFont` is unchanged — Latin Modern Math at 20pt).
* Add five new OpenType MATH fonts: New Computer Modern Math, TeX Gyre Pagella Math, STIX Two Math, Fira Math, and Noto Sans Math; update XITS Math to v1.302.
* Add AMSMath fraction commands: `\dfrac`, `\tfrac`, `\cfrac` (with optional `[l|c|r]` numerator alignment), `\dbinom`, and `\tbinom`.
* Add multi-integral operators: `\iint`, `\iiint`, `\iiiint`, `\oiint`, `\oiiint`, `\fint`, `\varointclockwise`, and `\ointctrclockwise`.

### v2.2.0 (2026-05-16)
* Add `\text{}`, `\textrm{}`, `\textbf{}`, `\textit{}`, `\textsf{}`, `\texttt{}` for rendering non-Latin text alongside math — supports CJK, Devanagari, Arabic, Hebrew, Cyrillic, and any other script handled by CoreText system-font cascade.
* Add prime shorthand: `f'` parses as `f^{\prime}`, `f''` as `f^{\prime\prime}`, etc.
* Add ~100 new symbols from amssymb: negated relations (`\nleq`, `\ngeq`, `\nmid`, `\nparallel`, …), harpoon and extended arrows (`\rightleftharpoons`, `\upharpoonright`, `\hookleftarrow`, `\twoheadrightarrow`, …), boxed/circled operators (`\boxplus`, `\circledast`, `\barwedge`, …), and logic/set-theory/suit symbols (`\vdash`, `\therefore`, `\because`, `\lozenge`, `\complement`, …).
* Add aliases: `\implies`, `\impliedby`, `\dotsc`, `\dotsb`, `\dotsm`, `\dotsi`, `\square`, `\vartriangle`, `\restriction`.

### v2.1.0 (2026-05-10)
* Add support for explicit-size big delimiters: `\bigl`, `\bigr`, `\Bigl`, `\Bigr`, `\biggl`, `\biggr`, `\Biggl`, `\Biggr`.
* Add over/under accent commands: `\overrightarrow`, `\overleftarrow`, `\overbrace`, `\underbrace`, and relatives, backed by a new generic `MTMathStack` atom.

### v2.0.0 (2026-04-14)
* Raise deployment targets to iOS 18+ and macOS 15+.
* Remove CocoaPods support; distribute via Swift Package Manager only.
* Add explicit `module.modulemap` controlling the public API surface.
* Add GitHub Actions CI.
* Add Swift example app (`SwiftMathExample`) with Examples and Gallery tabs.

### v0.9.5 (2019-06-03)
* Add colorbox command (#121)
* Cyrillic support (#108)
* When there is only one element in row, an array error is reported. (#111)
* Fix: on macOS 10.13, NSSegmentItemImageView returns nil for layer.backgroundColor. Need to check for this and return a default color (clear)
* Added textrm (#61)

### v0.9.4 (2017-05-07)
* Support for color (\\textcolor) (Thanks to Markus)
* Fix issue with cramped style in tables (Thanks to Jacob)

### v0.9.3 (2017-01-22)
* Support for changing font styles: (\\mathrm, \\mathcal, \\mathbf etc.)
* Support for the \\text command.
* Fix issue with \\$ not being rendered correctly.
* Support for \\limits and \\nolimits

### v0.9.2 (2017-01-11)
* Support for MacOS (Thanks to AnZhg)
* Better AutoLayout support (Thanks to zhubofei)
* Support for custom defined commands.
* Bug fixes for error label.
* Removing error logging (Thanks to saagarjha)
* API changes:
  * Replace `padding` fields with `contentInsets` in `MTMathUILabel`.

### v0.9.1 (2016-10-17)
* Support for constructing arbitrarily tall delimiters and radicals.
* Fix placement of limits on large operators for the XITS font.
* Allow MTMathUILabel to be used in the interface builder.

### v0.9.0 (2016-08-29)
* Added support for matrix environments (matrix, pmatrix, bmatrix,
  Bmatrix, vmatrix, Vmatrix)
* Added support for equation alignment (eqalign, displaylines, gather,
  split, aligned, eqnarray)
* Added support for the \\\\ command to split long equations
* Added support for math accents (e.g. \\hat, \\tilde etc.)
* Added support for `cases` environment.
* Added support for style commands (e.g. \\displaystyle etc.)
* Improve rendering of square roots and large symbols
* API changes:
  * Updated API for `MTMathAtomFactory`.
  * Rename `MTLargeGlyphDisplay` to `MTGlyphDisplay`

### v0.8.4 (2016-08-10)
* Fix crash for \\epsilon and \\varrho
* Add commands: \\mho, \\angstrom and \\AA

### v0.8.3 (2016-07-31)
* Add `textColor` field to `MTMathUILabel` to set the color of the
  rendered equation.
* Fixed issue with height of tall radicals set incorrectly.

### v0.8.2 (2016-07-23)
* Support for \\overline and \\underline
* Includes math spacing: \\, \\; \\> \\! \\quad \\qquad \\' '

### v0.8.1 (2016-07-17)
* Added support for binomials
* New commands supported: \\over, \\atop, \\choose, \\brack, \\brace,
  \\binom.

### v0.8.0 (2016-07-09)
* Added support for \\left and \\right
* New API for constructing `MTMathList`
* Improved LaTeX error reporting
* Made internal rendering functions and APIs private
* Nullability annotations for using with Swift
* Improved documentation
* Tests for rendering

### v0.7.3 (2016-05-28)
* Moved all font-related files into their own bundle.

### v0.7.2 (2016-05-27)
* Added `MTMathListIndex`

### v0.7.1 (2016-05-25)
* Improved documentation.
* Added `latex` property to set the latex directly on MTMathUILabel.
* Improved error handling.

### v0.7.0 (2016-05-24)

* Support for multiple fonts.
* Includes large operators (\\sum, \\prod)
* Includes arrow symbols
* Includes showing limits (\\lim etc.)
* Includes integrals
* Added italic correction

#### API Changes:
The `MTFontManager` API has been rewritten.
Introduce `MTFont` class to represent a font for the label.

This release contains backwards incompatible API changes.

### v0.6.3 (2016-05-15)
* Include `MTFontManager` in public API.

### v0.6.2 (2016-05-13)
* Fix issues with Greek letters being incorrect.
* Many common math symbols added.
* Improved example program.
* Minor rendering fixes.

### v0.6.1 (2016-05-12)
* Fix the bundle to work correctly with Cocoapods.

### v0.6.0 (2016-05-12)
* Inital public release.

