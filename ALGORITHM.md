# TeX Appendix G → iosMath Implementation Map

This document maps TeX's math typesetting algorithm from Knuth's *The TeXbook* Appendix G ("Generating Boxes from Formulas") onto the iosMath rendering pipeline. It is intended as a reference for maintainers who want to understand, audit, or extend the algorithm.

Unless stated otherwise, file references are relative to the `iosMath/` directory.

---

## 1. Big Picture

### 1.1 Pipeline

```
LaTeX string ──► MTMathListBuilder ──► MTMathList (of MTMathAtoms)
                                            │
                                            ▼
                                   MTMathList.finalized  (Rules 5, 6, 14 pre-bake)
                                            │
                                            ▼
                     MTTypesetter.preprocessMathList  (Rule 14 merge + Number→Ord, Variable→Ord, Unary→Ord)
                                            │
                                            ▼
            MTTypesetter.createDisplayAtoms  (Rules 1–4, 7–13, 15–18, 20, 22; two-pass merged into one)
                                            │
                                            ▼
                                MTMathListDisplay (tree of MTDisplays)
                                            │
                                            ▼
                                     MTDisplay.draw:  (CoreText / CGContext)
```

TeX's conceptual two-pass algorithm (Rules 1–18 first pass, Rule 20 second pass) is collapsed in iosMath into a single left-to-right pass because `MTMathList.finalized` already runs the most important preprocessing (Rules 5, 6, 14) before layout begins.

### 1.2 Key objects

| TeX concept (Appendix G) | iosMath type | File |
|---|---|---|
| Math list | `MTMathList` | `lib/MTMathList.{h,m}` |
| Atom / noad | `MTMathAtom` (and subclasses) | `lib/MTMathList.{h,m}` |
| Horizontal list / translation | `MTMathListDisplay` (a tree of `MTDisplay`s) | `render/MTMathListDisplay.{h,m}` |
| Style (D, T, S, SS, and their primed variants) | `MTLineStyle` | `lib/MTMathList.h` |
| Font parameters σ₁…σ₂₂ (family 2) and ξ₁…ξ₁₃ (family 3) | `MTFontMathTable` (OpenType MATH table) | `render/internal/MTFontMathTable.{h,m}` |
| Typesetter | `MTTypesetter` | `render/internal/MTTypesetter.{h,m}` |

**Important deviation.** TeX uses σ (symbol-font) and ξ (extension-font) parameters. iosMath uses the **OpenType MATH table** via `MTFontMathTable`, which is a superset. This means many TeX parameters map to OpenType constants that are roughly equivalent but not identical. See §6 for the mapping.

### 1.3 Primed/cramped styles

TeX has eight styles D, D′, T, T′, S, S′, SS, SS′. iosMath only has four `MTLineStyle` values (Display, Text, Script, ScriptScript) but tracks the *cramped* bit separately as the `_cramped` BOOL on `MTTypesetter`. This is functionally equivalent (`C′` means the cramped variant of `C`).

- `subscriptCramped` → always `YES` (TeX: subscript always uses C″ which is the cramped C^sub).
- `superScriptCramped` → inherits `_cramped` (TeX: superscript uses C^sup which has the same primed-ness as C).
- Radicand (`makeRadical`), overline innerList, accent innerList, fraction denominator → passed `cramped:YES`.

---

## 2. Atom Types and TeX Noad Correspondence

Defined in `MTMathList.h` as `MTMathAtomType`.

| `MTMathAtomType` | TeX noad | Notes |
|---|---|---|
| `kMTMathAtomOrdinary` | Ord | Plain symbol. |
| `kMTMathAtomNumber` | — | Not in TeX. Collapsed to Ord by `preprocessMathList`. Fusing of adjacent numbers is handled in `MTMathList.finalized`. |
| `kMTMathAtomVariable` | — | Not in TeX. Collapsed to Ord by `preprocessMathList`, after applying `fontStyle` via `changeFont`. |
| `kMTMathAtomLargeOperator` | Op | Handled by Rule 13. |
| `kMTMathAtomBinaryOperator` | Bin | Handled by Rule 5 (reclassified to Ord when context demands). |
| `kMTMathAtomUnaryOperator` | — | Not in TeX. Produced by `MTMathList.finalized` when a Bin has no left-operand or follows Bin/Rel/Open/Punct/Op (this IS TeX Rule 5). Collapsed back to Ord by `preprocessMathList`. |
| `kMTMathAtomRelation` | Rel | Rule 6. |
| `kMTMathAtomOpen` | Open | Rule 7. |
| `kMTMathAtomClose` | Close | Rule 6 partial (kills preceding Bin). |
| `kMTMathAtomFraction` | "generalized fraction" | Rule 15. |
| `kMTMathAtomRadical` | Rad | Rule 11. |
| `kMTMathAtomPunctuation` | Punct | Rule 6 partial. |
| `kMTMathAtomPlaceholder` | — | Not in TeX. Renders as a blue `□`. Treated as Ord for spacing. |
| `kMTMathAtomInner` | Inner | Rule 7; also produced by Rule 15e and `\left…\right`. |
| `kMTMathAtomUnderline` | Under | Rule 10. |
| `kMTMathAtomOverline` | Over | Rule 9. |
| `kMTMathAtomAccent` | Acc | Rule 12. |
| `kMTMathAtomBoundary` | (for \left, \right) | Cannot appear in a `MTMathList` directly; only on `MTInner.leftBoundary` / `.rightBoundary`. Rule 19 analogue is in `MTTypesetter.makeInner:atIndex:`. |
| `kMTMathAtomSpace` | glue/kern | Rule 2. |
| `kMTMathAtomStyle` | style item | Rule 3. |
| `kMTMathAtomColor` / `kMTMathAtomColorbox` | — | iosMath extension. Renders inner list and applies fg/bg color. |
| `kMTMathAtomTable` | — | iosMath extension (equivalent to TeX `\halign` for matrices, aligned, cases, etc.). |

**Missing noad types** (vs. TeX):
- **Vcent atom (Rule 8).** `\vcenter` is not supported. The corresponding atom type does not exist.
- **Rule (horizontal rule) item**, **discretionary**, **whatsit**, **penalty**, **boundary (top-level)** — none exist at the `MTMathAtom` level. Rule 1 is therefore a no-op in iosMath.
- **Four-way choice (Rule 4).** `\mathchoice` is not implemented.

---

## 3. Rule-by-Rule Mapping

Throughout: "first pass" = `MTTypesetter.createDisplayAtoms:`. "Finalize" = `MTMathList.finalized` in `lib/MTMathList.m`.

### Rule 1 — Rule / discretionary / penalty / whatsit / boundary items are passed through unchanged

**Status: N/A.** None of these item types exist in iosMath's math list model. Line-breaking penalties for inline math (the purpose of whatsit/penalty here) are delegated entirely to the higher-level text layout; math lists are always laid out monolithically.

### Rule 2 — Glue or kern; convert mu → pt via σ₆; handle `\nonscript`

**Status: Partially implemented.**

In `MTTypesetter.createDisplayAtoms:` the `kMTMathAtomSpace` branch does:

```objc
_currentPosition.x += space.space * _styleFont.mathTable.muUnit;
```

- `muUnit` is `_fontSize / 18` (i.e. 1 em / 18). This is the OpenType-era equivalent of `σ₆ / 18`, and it is indeed taken from the *current style's* scaled font (`_styleFont`). ✓
- **`\nonscript` is NOT implemented.** There is no mechanism to cancel the following glue/kern when `C ≤ S` (script or smaller). Rule 20's note that some inter-element spacing is `\nonscript` is therefore also only partially honored — see Rule 20.
- `\mskip` / `\mkern` are both represented as `MTMathSpace` with an mu amount; there is no separate finite-vs-infinite glue distinction, which is fine because math lists do not need stretchable glue.

### Rule 3 — Style change

**Status: Implemented** in `MTTypesetter.createDisplayAtoms:`, `kMTMathAtomStyle` branch:

```objc
MTMathStyle* style = (MTMathStyle*) atom;
self.style = style.style;
continue;
```

The `setStyle:` setter also re-creates `_styleFont` via `copyFontWithSize:` with the appropriate script-scale-down. The `continue` preserves `prevNode`, matching TeX's rule that style items are deleted but don't reset the inter-atom spacing context.

### Rule 4 — Four-way choice (`\mathchoice`)

**Status: NOT IMPLEMENTED.** `\mathchoice` is not recognized by `MTMathListBuilder`. There is no corresponding `MTMathAtom` subclass. This is a real gap — packages that use `\mathchoice` for style-dependent symbol selection (e.g. some AMS macros) will not work.

### Rule 5 — Bin→Ord reclassification based on context

> If the current Bin is first in the list, or follows Bin/Op/Rel/Open/Punct, change it to Ord.

**Status: Implemented** but in the finalize phase, not the first pass.

`MTMathList.finalized` walks the list and uses `isNotBinaryOperator(prevNode)`:

```objc
if (prevNode.type == BinaryOperator || Relation || Open || Punctuation || LargeOperator) return true;
```

When true, the current Bin is retyped to `kMTMathAtomUnaryOperator`. (It stays a distinct type so that the LaTeX round-tripper can tell them apart.) Later, `MTTypesetter.preprocessMathList` collapses `UnaryOperator` to `Ordinary` before layout.

**Deviation:** TeX's rule 5 would change it directly to Ord. iosMath uses a two-step Bin→UnaryOp→Ord path. Functionally equivalent for spacing because `getInterElementSpaceArrayIndexForType` treats Ordinary and Unary the same (unary never reaches the spacing table; it's converted first).

### Rule 6 — Rel/Close/Punct after a Bin converts that Bin to Ord

**Status: Implemented** in `MTMathList.finalized`:

```objc
case kMTMathAtomRelation:
case kMTMathAtomPunctuation:
case kMTMathAtomClose:
    if (prevNode && prevNode.type == kMTMathAtomBinaryOperator) {
        prevNode.type = kMTMathAtomUnaryOperator;
    }
```

Same as Rule 5: Bin is retyped to UnaryOp, which later becomes Ord.

The tail-of-list case from the end of Rule 18 ("after all Rules 1–18 … change its type from Bin to Ord") is also handled here:

```objc
if (prevNode && prevNode.type == kMTMathAtomBinaryOperator) {
    prevNode.type = kMTMathAtomUnaryOperator;   // trailing Bin → unary
}
```

### Rule 7 — Open or Inner: go directly to Rule 17

**Status: Implemented implicitly.** Open and Inner atoms are handled by the generic "render nucleus and attach scripts" path in the ordinary-atoms branch of `createDisplayAtoms:` (for Open/Close/Punct) or the `kMTMathAtomInner` branch (for Inner). No special preprocessing is done, which matches the rule.

### Rule 8 — Vcent (`\vcenter`)

**Status: NOT IMPLEMENTED.** There is no `Vcent` atom type, no `\vcenter` command in the parser, and no axis-centering of arbitrary vboxes. This is a real gap.

### Rule 9 — Over (`\overline`)

**Status: Implemented** in `MTTypesetter.makeOverline:` called from the `kMTMathAtomOverline` branch.

- Sets cramped=YES when laying out the inner list ✓ (matches TeX's `C′` for overline).
- The clearance, rule thickness, and extra ascender are read from the OpenType MATH table:
  - `overbarVerticalGap` ← `OverbarVerticalGap` (TeX 3ξ₈)
  - `overbarRuleThickness` ← `OverbarRuleThickness` (TeX ξ₈)
  - `overbarExtraAscender` ← `OverbarExtraAscender` (TeX ξ₈)

**Deviation:** TeX's rule says "kern ξ, hrule of height ξ, kern 3ξ, and box x, from top to bottom." iosMath uses three separate OpenType parameters instead of all being ξ₈. On TeX-compatible fonts these three values are all equal so this is consistent in practice.

After processing, `kMTMathAtomOverline` is retyped to `kMTMathAtomOrdinary` for inter-element-space purposes, matching Rule 16.

### Rule 10 — Under (`\underline`)

**Status: Implemented** in `MTTypesetter.makeUnderline:`.

- Inner list is laid out with `cramped:_cramped` (**deviation**: TeX's rule 10 says "in style C", i.e. *not* cramped; our use of `_cramped` inherits the current cramping rather than forcing non-cramped, which is actually more faithful to TeX's style inheritance than Rule 10 reads at face value — Rule 10 says C, and C might already be primed).
- Uses `underbarVerticalGap`, `underbarRuleThickness`, `underbarExtraDescender`.

Same retype-to-Ord after processing as Rule 9 (Rule 16).

### Rule 11 — Radical (`\sqrt`)

**Status: Implemented** in `MTTypesetter.makeRadical:range:` and `getRadicalGlyphWithHeight:`.

TeX's rule involves:
1. Typeset radicand in style C′ (cramped). ✓ — `createLineForMathList:… cramped:YES`
2. Compute `φ = σ₅` (x-height) if C>T else `φ = ξ₈` (default rule thickness), and `ψ = ξ₈ + ¼|φ|`.
3. Find a radical glyph of height ≥ h(x)+d(x)+ψ+ξ.
4. Let ξ ← h(y) (thickness taken from the radical glyph's ascent).
5. If the glyph is bigger than needed, increase ψ to center the radicand.
6. Build vbox: kern ξ, hrule ξ, kern ψ, box x.
7. Then attach a degree (if any), shifted and kerned per Rule 16's preamble (handled below).

**How iosMath does it:**

- `clearance = radicalVerticalGap` (uses `RadicalDisplayStyleVerticalGap` in display, `RadicalVerticalGap` otherwise). This corresponds to `ψ` in TeX and already bundles the ξ₈+¼σ₅ computation into a single OpenType constant. ✓
- `radicalRuleThickness = RadicalRuleThickness`, which corresponds to `ξ` in step 4.
- The radical glyph is found by `findGlyph:withHeight:…` which walks the vertical variants; if no pre-built variant is tall enough, `constructGlyph:withHeight:` builds one from an OpenType glyph assembly (extenders + connectors). This is the OpenType equivalent of TeX's extensible-character search. ✓
- The delta-based centering (Rule 11: "If d(y) > h(x)+d(x)+ψ, increase ψ by half the excess") is implemented as:
  ```objc
  CGFloat delta = (glyph.descent + glyph.ascent) - (innerDisplay.ascent + innerDisplay.descent + clearance + radicalRuleThickness);
  if (delta > 0) clearance += delta/2;
  ```
  This is slightly different from TeX (which uses only `d(y) - h(x) - d(x) - ψ`) because OpenType doesn't assume `glyphAscent == thickness` the way TeX's font metrics do. The code comment explicitly calls this out. Still correct.
- Extra ascender at the top: `radicalExtraAscender` ← `RadicalExtraAscender` (TeX ξ₈).

**Degree (index) placement** — `setDegree:fontMetrics:` in `MTMathListDisplay.m`:

- Degree is laid out in `kMTLineStyleScriptScript`. ✓ matches TeX's style rule.
- `kernBefore = radicalKernBeforeDegree`, `kernAfter = radicalKernAfterDegree` (TeX-defined as 5mu and −10mu).
- `raise = radicalDegreeBottomRaisePercent * (ascent - descent)` corresponds to TeX's 60%.
- If kernBefore+degree.width+kernAfter < 0, kernBefore is bumped up so the shift is non-negative. This is a sanity guard not explicitly in Rule 11 but sound.

### Rule 12 — Accent (`\mathaccent`)

**Status: Implemented (mostly)** in `MTTypesetter.makeAccent:`.

What's implemented:
- "If accent doesn't exist in current size, skip" — `if (accent.nucleus.length == 0) return accentee;` ✓
- Inner list typeset in C′ (cramped). ✓
- **Successor walking for wider accents**: `findVariantGlyph:withMaxWidth:` walks OpenType horizontal variants to find the widest accent glyph whose width ≤ accentee width. ✓ This is TeX's "If the accent character has a successor in its font whose width is ≤ u, change it to the successor and repeat."
- `delta = MIN(accenteeAdjustment, accentBaseHeight)` — corresponds to TeX `δ = min(h(x), φ)` where φ is x-height in the accent font. iosMath uses `AccentBaseHeight` from the MATH table, which is the OpenType equivalent.
- **Skew computation** uses OpenType top-accent attachment points rather than TeX's `\skewchar`+kern mechanism:
  ```objc
  skew = (accenteeTopAccentAdjustment - accentTopAccentAdjustment)
  ```
  This is `getTopAccentAdjustment:` for both glyphs. Strictly better than TeX (`\skewchar`).
- **Single-char accentee subscript/superscript promotion** (TeX Rule 12: "If the nucleus is a single character, replace box x by a box containing the nucleus together with the superscript and subscript of the Acc atom, in style C, and make the sub/superscripts of the Acc atom empty"). Implemented:
  ```objc
  if ([self isSingleCharAccentee:accent] && (accent.subScript || accent.superScript)) {
      innerAtom.superScript = accent.superScript;
      innerAtom.subScript = accent.subScript;
      accent.superScript = nil;
      accent.subScript = nil;
      accentee = [MTTypesetter createLineForMathList:accent.innerList …];
  }
  ```

**Deviations / gaps:**
- TeX rule 12 includes "If h(z) < h(x), add a kern of h(x) − h(z) above box y and set h(z) ← h(x)." The iosMath code does `display.ascent = MAX(accentee.ascent, ascent)` which preserves the max height, but the extra kern is not materialized. For accentees that are taller than the default accent-base height this is essentially correct; the ascent field reflects the taller value.
- TeX's comment that δ should be adjusted if the accent character is walked (`δ ← δ + Δh(x)` in its phrasing) is not explicitly done because `δ = MIN(h(x), AccentBaseHeight)` is computed once from the original accentee, and the accentee is only re-laid-out for the sub/superscript promotion, not for accent-width changes.

### Rule 13 — Large operator (Op)

**Status: Implemented** in `MTTypesetter.makeLargeOp:` and `addLimitsToDisplay:forOperator:delta:`.

- **Limits decision** (`\limits` / `\nolimits` / `\displaylimits`): iosMath stores a BOOLEAN `limits` on `MTLargeOperator` set at parse time by `\limits`/`\nolimits`. The default `limits:YES` is assigned to large-operator symbols like `\sum`, `\prod`, and `NO` to `\int`, `\oint`, `\log`, etc. in the symbol table. This is richer than TeX's `\displaylimits` (tri-state) because the default-for-style behavior is baked in at table-creation time. The test `bool limits = (op.limits && _style == kMTLineStyleDisplay);` matches TeX's "if marked with \limits, or if marked with \displaylimits and C ≥ T" only for display style — **there is no explicit `\displaylimits` state**.
- **Successor walk** (TeX: "if C ≥ T and the nucleus symbol has a successor in its font, move to the successor"): implemented via `getLargerGlyph:` which returns the first distinct vertical variant. Only done if `_style == kMTLineStyleDisplay` (TeX allows both D and T; iosMath is slightly more restrictive here — arguably a minor deviation).
- **Italic correction**: `delta = getItalicCorrection:`. If there is a subscript and `!limits`, delta is subtracted from the visible width so the subscript can nestle under the italic overhang. ✓
- **Vertical centering on axis**: `shiftDown = 0.5*(ascent − descent) − axisHeight` ✓ matches TeX's `½(h − d) − a` where `a = σ₂₂`.
- **Rule 13a (limits attached above/below)**: `addLimitsToDisplay:forOperator:delta:` creates an `MTLargeOpLimitsDisplay` with:
  - Upper limit in style C^up (script style of the current style), cramped per `superScriptCramped`. ✓
  - Lower limit in style C^down, always cramped (`subscriptCramped = YES`). ✓
  - `upperLimitGap = max(UpperLimitGapMin, UpperLimitBaselineRiseMin − superScript.descent)` — corresponds to TeX `max(ξ₉, ξ₁₁ − d(x))`. ✓
  - `lowerLimitGap = max(LowerLimitGapMin, LowerLimitBaselineDropMin − subScript.ascent)` — corresponds to TeX `max(ξ₁₀, ξ₁₂ − h(z))`. ✓
  - `limitShift = delta/2` — half of the italic correction applied to the upper limit (TeX: shift x right by ½ε). ✓
  - `extraPadding = 0` — TeX's ξ₁₃ kern above upper and below lower. **This is explicitly set to 0** and `limitExtraAscenderDescender` returns 0 with the comment "not present in OpenType fonts." This is a minor deviation from TeX that is unavoidable with OpenType MATH.
- **Nucleus rebox to max width** (TeX: "Rebox all three of these boxes to width max(w(x), w(y), w(z))"): `MTLargeOpLimitsDisplay`'s position updates center each of nucleus, upper, and lower at `(self.width − their.width)/2`. ✓

**Sub/superscript-when-no-limits** branch: when `!limits`, the code falls through to `makeScripts:` which is the general Rule 18 mechanism. ✓

### Rule 14 — Ordinary atom ligatures and kerns

**Status: Partially implemented.**

- **Merging of adjacent Ord symbols** is done in two places:
  - `MTMathList.finalized` merges adjacent `Number` atoms (so `42` fuses into one atom of length 2). This is pre-Rule-14 because Number is an iosMath-specific concept.
  - `MTTypesetter.preprocessMathList` merges adjacent `Ordinary` atoms (with no sub/superscripts). This is TeX Rule 14's "combine ordinary characters."
- **Ligature lookup** (e.g. `ff` → ﬀ): **NOT implemented.** No OpenType GSUB ligature table is consulted during math typesetting.
- **Kern lookup between adjacent Ord symbols**: **NOT implemented.** There is no insertion of kern items between fused ordinary atoms.
- The italic correction that Rule 14 implicitly enables for the last character of a fused text-symbol run IS partially handled by Rule 17's italic-correction insertion (see Rule 17).

**Gap.** If a math font ships with math ligatures or math kerns (rare but supported by the OpenType MATH table via the MathKernInfo table), iosMath will not honor them.

### Rule 15 — Generalized fraction

**Status: Implemented (without delim sizes from TeX, with `\above` missing).**

`MTTypesetter.makeFraction:` and `addDelimitersToFractionDisplay:forFraction:`:

- **Bar thickness** (Rule 15 preamble): `frac.hasRule ? fractionRuleThickness : 0`.
  - `\over`, `\frac` → `hasRule=YES` → thickness = `FractionRuleThickness` (TeX ξ₈). ✓
  - `\atop`, `\binom`, `\choose`, `\brack`, `\brace` → `hasRule=NO` → thickness = 0. ✓
  - **`\above`, `\abovewithdelims`, `\overwithdelims`, `\atopwithdelims` with explicit thickness: NOT implemented.** The parser does not recognize `\above` or its `*withdelims` cousins.
- **Left/right delimiters**: `frac.leftDelimiter`, `frac.rightDelimiter`. Set by `\binom` etc., or left nil. When present, the fraction is wrapped in an extra `MTMathListDisplay` with left/right glyphs of height `fractionDelimiterHeight` (≈ `2.39·fontSize` in display, `1.01·fontSize` otherwise). These are non-OpenType constants chosen to match LuaTeX/KaTeX behavior — comment in `MTFontMathTable.m` explains this.

**Rule 15a** (numerator/denominator typesetting style):
- Numerator: `fractionStyle = self.fractionStyle` → `_style+1` (so D→T, T→S, S→SS, SS→SS). Cramped = NO.
- Denominator: same style, cramped = YES (TeX: T′ if C > T, else C″).
- Rebox to common width: handled by `MTFractionDisplay.updateNumeratorPosition` / `updateDenominatorPosition` which center at `(width − their.width)/2`. ✓

**Rule 15b** (numerator up, denominator down — baseline shifts):

```objc
- numeratorShiftUp:(BOOL) hasRule  →  fractionNumeratorDisplayStyleShiftUp (D) or fractionNumeratorShiftUp (T)
                                    stackTopDisplayStyleShiftUp (D, atop) or stackTopShiftUp (T, atop)
- denominatorShiftDown:(BOOL) hasRule → mirror
```

Corresponds to TeX σ₈/σ₉/σ₁₀/σ₁₁/σ₁₂ selections. ✓ (OpenType splits stack vs fraction into separate constants; these map cleanly.)

**Rule 15c** (`\atop` clearance): handled by `self.stackGapMin` which returns `stackDisplayStyleGapMin` (D: TeX 7ξ₈) or `stackGapMin` (T: TeX 3ξ₈). When actual clearance falls short, half the deficit is added to both shifts. ✓

**Rule 15d** (`\over` clearance around the bar): handled with separate numerator and denominator gaps (`numeratorGapMin`, `denominatorGapMin` — OpenType constants). The bar is centered at `axisHeight`. ✓

**Rule 15e** (delimiters for `\overwithdelims` etc.): not reached because these commands aren't parsed. However the *equivalent* for `\binom`/`\choose`/etc. is implemented via `addDelimitersToFractionDisplay:forFraction:` which picks a glyph of `fractionDelimiterDisplayStyleSize` (D) or `fractionDelimiterSize` (T), corresponding to σ₂₀ and σ₂₁. ✓ (for the subset that exists). The result is wrapped in a `MTMathListDisplay` rather than explicitly retyped to Inner, but spacing is unaffected because the wrapper stands in for an Inner atom at the next level.

### Rule 16 — Change the current item to Ord then continue with Rule 17

**Status: Implemented** implicitly. After each of `makeRadical:`, `makeOverline:`, `makeUnderline:`, `makeAccent:`, and the fraction path, the code sets `atom.type = kMTMathAtomOrdinary` before (or logically before) the Rule 17 nucleus-processing. Specifically, in the over/under/accent/table branches of `createDisplayAtoms:`:

```objc
atom.type = kMTMathAtomOrdinary;  // or kMTMathAtomInner for table
```

The spacing call `addInterElementSpace:currentType:kMTMathAtomOrdinary` also uses Ord explicitly. ✓

### Rule 17 — Nucleus-to-horizontal-list conversion and text-symbol italic-correction kern

**Status: Implemented (mostly)** in the ordinary-atoms block of `createDisplayAtoms:` (for Ord, Bin, Rel, Open, Close, Placeholder, Punct).

- **Nucleus is a math list**: handled by the various `make*:` functions which recurse via `MTTypesetter.createLineForMathList:…` for sub-lists (numerator, denominator, radicand, degree, accentee, overline/underline inner, inner-list for `\left…\right`, table cells, color box, superscript, subscript).
- **Nucleus is a symbol**: added to `_currentLine` (an `NSMutableAttributedString`) so adjacent symbols share a CTLine, which is rendered as an `MTCTLineDisplay`. The font is attached in `addDisplayLine:`.
- **Italic correction for text-symbols** (TeX: "If the symbol was not marked by Rule 14 above as a text symbol, or if \fontdimen parameter number 2 of its font is zero, set ε to the italic correction; otherwise set ε to zero. If ε is nonzero and if the subscript field of the current atom is empty, insert a kern of width ε after the character box"):

  iosMath does NOT consult the "text-symbol" mark from Rule 14 (because Rule 14's ligature/kern expansion isn't done), so italic correction is applied on the *last character* of the nucleus only when the atom has a sub or superscript:

  ```objc
  if (atom.subScript || atom.superScript) {
      [self addDisplayLine];
      CGGlyph glyph = [self findGlyphForCharacterAtIndex:atom.nucleus.length-1 inString:atom.nucleus];
      delta = [_styleFont.mathTable getItalicCorrection:glyph];
      if (delta > 0 && !atom.subScript) {
          _currentPosition.x += delta;   // italic-correction kern
      }
      [self makeScripts:atom display:line index:NSMaxRange(atom.indexRange)-1 delta:delta];
  }
  ```

  So the kern is applied when there's a superscript without a subscript (matching TeX's "if subscript is empty" condition). The delta is also passed into `makeScripts:` for superscript horizontal positioning.

  **Deviation:** TeX's unconditional italic-correction kern between adjacent text symbols (without sub/super) — i.e. the "letter `f` followed by `y`" italic-correction kern — is NOT applied in iosMath. This is the same gap as Rule 14's kern gap.

### Rule 18 — Attach subscript and superscript

**Status: Implemented (mostly)** in `MTTypesetter.makeScripts:display:index:delta:`.

- **18a**: initial `u` and `v`. iosMath uses `superScriptShiftUp` (the TeX σ₁₃/σ₁₄/σ₁₅ set, selected by cramping) and `subscriptShiftDown` (σ₁₆/σ₁₇), rather than the `h − q` / `d + r` formula based on sub/super drop constants. HOWEVER, when the nucleus is **not** a simple CTLine (i.e. it's a composite like a fraction, radical, etc.), the code *does* apply the TeX formula:

  ```objc
  if (![display isKindOfClass:[MTCTLineDisplay class]]) {
      superScriptShiftUp = display.ascent - scriptFontMetrics.superscriptBaselineDropMax;
      subscriptShiftDown = display.descent + scriptFontMetrics.subscriptBaselineDropMin;
  }
  ```

  This is TeX's `u = h − q`, `v = d + r` (with q = σ₁₈ in script font, r = σ₁₉ in script font). Note the code reads these from the **script font** — slightly different from TeX's reading. Used only for composite nuclei. ✓
  Then for character-box nuclei they stay 0 and the max-with constants fires in 18c.

- **18b** (subscript only): `fmax(v, σ₁₆, h(x) − 4/5|σ₅|)`:

  ```objc
  subscriptShiftDown = fmax(subscriptShiftDown, subscriptShiftDown);
  subscriptShiftDown = fmax(subscriptShiftDown, subscript.ascent - subscriptTopMax);
  ```

  where `subscriptTopMax` = OpenType `SubscriptTopMax` ≈ `4/5 σ₅`. ✓

  **`\scriptspace` padding** (TeX 18b: "add \scriptspace to w(x)"): not applied as a padding. Instead `spaceAfterScript` from the MATH table is added to `_currentPosition.x` after the script is positioned:

  ```objc
  _currentPosition.x += subscript.width + _styleFont.mathTable.spaceAfterScript;
  ```

  This is the OpenType analog and serves the same purpose (preventing the next character from touching the script).

- **18c** (superscript tentative position):
  ```objc
  superScriptShiftUp = fmax(superScriptShiftUp, self.superScriptShiftUp);   // σ₁₃ or σ₁₅
  superScriptShiftUp = fmax(superScriptShiftUp, superScript.descent + superscriptBottomMin);
  ```
  where `superScriptShiftUp` returns `superscriptShiftUpCramped` when cramped (TeX σ₁₅ vs σ₁₃/σ₁₄). `superscriptBottomMin` ≈ `¼σ₅`. ✓

- **18d / 18e** (joint sub+super positioning — avoid collision):
  ```objc
  CGFloat subSuperScriptGap = (superScriptShiftUp - superScript.descent) + (subscriptShiftDown - subscript.ascent);
  if (subSuperScriptGap < subSuperscriptGapMin) {
      subscriptShiftDown += subSuperscriptGapMin - subSuperScriptGap;
      CGFloat superscriptBottomDelta = superscriptBottomMaxWithSubscript - (superScriptShiftUp - superScript.descent);
      if (superscriptBottomDelta > 0) {
          superScriptShiftUp += superscriptBottomDelta;
          subscriptShiftDown -= superscriptBottomDelta;
      }
  }
  ```
  Corresponds to TeX's "4ξ₈ min gap" rule and the `4/5|σ₅|` superscript-bottom rule (encoded as `superscriptBottomMaxWithSubscript`). ✓

- **18f** (horizontal `ε` offset between sub and super due to italic correction): The `delta` passed in is used as `superScript.position.x = _currentPosition.x + delta`, and the subscript is at `_currentPosition.x`. Final advance is `MAX(superScript.width + delta, subscript.width) + spaceAfterScript`. This corresponds to TeX's "box x shifted right by ε, followed by an appropriate kern, followed by box y" in the vbox. ✓

### Rule 19 — `\left…\right` boundary delimiters

**Status: Implemented** in `MTTypesetter.makeInner:atIndex:`.

- `delta = MAX(inner.ascent − axisHeight, inner.descent + axisHeight)` — TeX's ψ.
- Two candidate sizes:
  - `d1 = (delta / 500) * kDelimiterFactor` with `kDelimiterFactor = 901` — TeX's `⌊ψf/500⌋` where `f = \delimiterfactor`. ✓
  - `d2 = 2*delta - kDelimiterShortfallPoints` with `kDelimiterShortfallPoints = 5` — TeX's `2ψ − l` where `l = \delimitershortfall`. ✓
- `glyphHeight = max(d1, d2)` — matches TeX "height plus depth is at least max(⌊ψf/500⌋, 2ψ − l)". ✓
- Delimiter selection via `findGlyphForBoundary:withHeight:` which tries vertical variants then constructs via glyph assembly. Delimiters are centered on the axis via `shiftDown = 0.5*(ascent - descent) - axisHeight`. ✓
- Left is retyped to Open and right to Close via inter-element spacing: the outer `createDisplayAtoms:` treats the whole Inner atom with `kMTMathAtomInner` spacing, so the "change left boundary to Open, right to Close" re-typing from Rule 19 is short-circuited. In practice this is fine because Inner's spacing relation to its neighbors already matches.

**Deviation:** The user-tunable `\delimiterfactor` and `\delimitershortfall` are baked in as hard-coded constants (901 and 5). TeX allows these to be changed.

### Rule 20 — Second pass: inter-element spacing

**Status: Implemented as part of the first pass.**

`MTTypesetter.getInterElementSpace:right:` does a lookup in the 9×8 table `getInterElementSpaces()` (ordinary/operator/binary/relation/open/close/punct/fraction × same with a radical row). The table returns one of `{none, thin, NSthin, NSmedium, NSthick}` (NS = "not script"), and `getSpacingInMu:` converts that into mu, respecting the current style:

```objc
case kMTSpaceNSThin:    return (_style < kMTLineStyleScript) ? 3 : 0;
case kMTSpaceNSMedium:  return (_style < kMTLineStyleScript) ? 4 : 0;
case kMTSpaceNSThick:   return (_style < kMTLineStyleScript) ? 5 : 0;
```

This is the TeX chart from chapter 18. ✓

The spacing is inserted at `addInterElementSpace:currentType:` or, for consecutive ordinary-type atoms that share a CTLine, as a `kCTKernAttribute` on the previous character (to stay within a single run). ✓

**Deviations:**
- `\thinmuskip`, `\medmuskip`, `\thickmuskip` parameters are hard-coded as 3/4/5 mu and cannot be changed by the user.
- Radical appears only as a *row* in the table, not a column (iosMath comment: "Radicals have inter element spaces only when on the left side … They have the same spacing as ordinary except with ordinary. … Treat radical as ordinary on the right."). TeX also treats radical this way in practice (it becomes Ord after Rule 11+16), so this is a faithful optimization.

### Rule 21 — Line-break penalties after Bin and Rel in paragraphs

**Status: NOT IMPLEMENTED.** There is no concept of `\binoppenalty` or `\relpenalty` — math lists are always laid out atomically and never participate in line breaking. Any line breaking of surrounding prose is entirely the caller's responsibility.

### Rule 22 — Math-on / math-off items and `\mathsurround`

**Status: NOT IMPLEMENTED at the list level.** `MTMathUILabel` is a standalone view; there is no host text stream to embed math-on/off markers into. Inline math is expected to be positioned by the caller. `\mathsurround` has no analog.

---

## 4. What's Missing — Summary

Feature gaps against TeX Appendix G:

1. **Rule 1 items (rule/discretionary/whatsit/penalty/boundary at list level)** — absent from the noad model. Low priority except for penalty.
2. **Rule 2 `\nonscript`** — not implemented. Would need a one-bit flag on `MTMathSpace` plus a check in the `kMTMathAtomSpace` branch to swallow the following glue/kern when `_style ≥ Script`.
3. **Rule 4 `\mathchoice`** — not parsed. Would need a new atom type holding four `MTMathList`s and a selection in `createDisplayAtoms:`.
4. **Rule 8 `\vcenter`** — no noad type, no parser support.
5. **Rule 14 ligatures and kerns between Ord symbols** — no GSUB/math-kern lookup. In practice Latin Modern Math has few math ligatures, so the visible impact is small, but kerning between `f` and `y` etc. is lost.
6. **Rule 14's "text symbol" mark** — not tracked; Rule 17's italic-correction decision uses a cruder heuristic (only when there is a sub/superscript). This can cause italic collisions when e.g. a trailing italic letter is followed by an upright symbol.
7. **Rule 15: `\above`, `\above­withdelims`, `\overwithdelims`, `\atopwithdelims`** — not parsed.
8. **Rule 13: `\displaylimits` tri-state** — reduced to a two-state `limits` BOOL with style-dependent default in the symbol table. Cannot be changed at runtime with a `\displaylimits` modifier (only `\limits`/`\nolimits` are).
9. **Rule 19 user-tunable `\delimiterfactor` and `\delimitershortfall`** — hard-coded constants.
10. **Rule 20 user-tunable `\thinmuskip`, `\medmuskip`, `\thickmuskip`** — hard-coded.
11. **Rule 21 penalties** — not inserted.
12. **Rule 22 math-on/math-off + `\mathsurround`** — not applicable to the standalone label use case.
13. **Non-OpenType `ξ₁₃`** — always 0 (no extra padding above/below limits). Cannot be changed.

---

## 5. Helpful Implementation Notes for Future Work

### 5.1 Two-pass vs one-pass

TeX's algorithm is explicitly two-pass (Rules 1–18 then 20–21). iosMath folds the first pass into `createDisplayAtoms:`. This works because:
- All atom retyping that Rule 20 depends on (Bin→Ord per Rules 5/6) is done before `createDisplayAtoms:` in `MTMathList.finalized` / `preprocessMathList`.
- Style items are processed in the same pass as layout, and they don't change atom types.
- Inter-element spacing is computed on the fly between `prevNode.type` and `atom.type`, which have already been finalized.

If Rules 14's ligatures/kerns were added, they'd need to run *before* `createDisplayAtoms:` (they are Rule 14, not Rule 20) — probably in `preprocessMathList`, which already has the right shape.

### 5.2 Style flow

`MTTypesetter` tracks `_style` and `_cramped` as mutable state. The key propagation points are:
- Numerator: `fractionStyle` (one step smaller, not cramped).
- Denominator: `fractionStyle` + cramped.
- Radicand: same style + cramped.
- Degree: ScriptScript + default cramping.
- Overline inner: same style + cramped.
- Underline inner: same style + current cramping (`_cramped`) — see Rule 10 note above.
- Accentee: same style + cramped.
- Sub/superscripts: `self.scriptStyle` + `subscriptCramped`/`superScriptCramped`.
- Upper/lower limits of Op: `scriptStyle` + same cramping rules as sub/super.
- Left/right of `\left…\right`: same style + current cramping.
- Color, colorbox, table cell: same style, not cramped (note: table cell uses `cramped:NO` explicitly — a potential deviation from TeX).

### 5.3 Font-parameter index (external names)

OpenType MATH table names mapped to TeX names (the Appendix G table at the bottom of the reference, plus some extras):

| TeX | OpenType (MTFontMathTable property) | Used in |
|---|---|---|
| σ₂ (space) | (CoreText advance width) | Rule 17 italic-correction gate — iosMath doesn't gate on this, so σ₂=0 has no effect |
| σ₅ (x-height) | `accentBaseHeight` (approximates) | Rule 12 |
| σ₆ (quad) | `muUnit * 18` = fontSize | Rules 2, 20 |
| σ₈ (num1) | `fractionNumeratorDisplayStyleShiftUp` | Rule 15b |
| σ₉ (num2) | `fractionNumeratorShiftUp` | Rule 15b |
| σ₁₀ (num3) | `stackTopShiftUp` | Rule 15b |
| σ₁₁ (denom1) | `fractionDenominatorDisplayStyleShiftDown` | Rule 15b |
| σ₁₂ (denom2) | `fractionDenominatorShiftDown` | Rule 15b |
| σ₁₃ (sup1) | `superscriptShiftUp` (D) | Rule 18c |
| σ₁₄ (sup2) | `superscriptShiftUp` (T) — same constant | Rule 18c |
| σ₁₅ (sup3) | `superscriptShiftUpCramped` | Rule 18c |
| σ₁₆ (sub1) | `subscriptShiftDown` | Rule 18b |
| σ₁₇ (sub2) | `subscriptShiftDown` — same | Rule 18d |
| σ₁₈ (sup drop) | `superscriptBaselineDropMax` | Rule 18a (composite nucleus) |
| σ₁₉ (sub drop) | `subscriptBaselineDropMin` | Rule 18a |
| σ₂₀ (delim1) | `fractionDelimiterDisplayStyleSize` (2.39·em) | Rule 15e |
| σ₂₁ (delim2) | `fractionDelimiterSize` (1.01·em) | Rule 15e |
| σ₂₂ (axis height) | `axisHeight` | Rules 8, 13, 15d, 19 |
| ξ₈ (default rule thickness) | `fractionRuleThickness`, `radicalRuleThickness`, `overbarRuleThickness`, `underbarRuleThickness`, etc. (split across constants) | Rules 9, 10, 11, 15, 18e |
| ξ₉ (big op spacing 1) | `upperLimitGapMin` | Rule 13a |
| ξ₁₀ (big op spacing 2) | `lowerLimitGapMin` | Rule 13a |
| ξ₁₁ (big op spacing 3) | `upperLimitBaselineRiseMin` | Rule 13a |
| ξ₁₂ (big op spacing 4) | `lowerLimitBaselineDropMin` | Rule 13a |
| ξ₁₃ (big op spacing 5) | `limitExtraAscenderDescender` (returns 0) | Rule 13a — **always 0** |

### 5.4 Where to add a new rule

- **New atom type** — add to `MTMathAtomType` enum, subclass `MTMathAtom` with any extra fields, update `typeToText`, `atomWithType:value:`, and (if fusable) `fuse:`. Add a case in `MTMathList.finalized` and `preprocessMathList`. Add a branch in the `MTMathListBuilder.atomForCommand:` switch.
- **New rendering branch** — add a case in `MTTypesetter.createDisplayAtoms:` and a `makeX:` helper that returns an `MTDisplay` subclass. The display must set its `ascent`/`descent`/`width` and respond to `setPosition:` to reposition children.
- **New inter-element-space entry** — update `getInterElementSpaces()` matrix and `getInterElementSpaceArrayIndexForType`.
- **New font metric** — expose on `MTFontMathTable` by adding a property that reads from `_mathTable[@"..."]` via `constantFromTable:` (for lengths) or `percentFromTable:` (for percentages).

### 5.5 Finalize / preprocess split

`MTMathList.finalized` is also called on nested lists recursively (see `MTFraction.finalized`, etc.) so preprocessing is applied everywhere. `MTTypesetter.preprocessMathList` is called only on the top-level list passed to `createLineForMathList:`; recursive calls into `createLineForMathList:` (for numerators, radicands, etc.) run `preprocessMathList` again — so Rule 14 merging of Ordinaries happens at every nesting level. Both are idempotent.

### 5.6 Display tree model

An `MTMathListDisplay` holds an array of `MTDisplay`s whose positions are **relative to the parent**. When draw is called, the parent translates the context to its own position and then asks each child to draw (which again translates to the child's position). Sub/superscripts are regular children in this tree, not nested inside the parent atom's display, which keeps positioning math simple.

Special displays: `MTFractionDisplay` draws the bar, `MTRadicalDisplay` draws the surd glyph plus the horizontal top-bar, `MTLineDisplay` draws over/underline bars, `MTAccentDisplay` and `MTLargeOpLimitsDisplay` position auxiliary displays around the nucleus, `MTInnerDisplay` holds left/right delimiter glyphs. Each exposes computed `ascent`, `descent`, `width`.

---

## 6. Quick Audit Checklist

Use this to re-verify the implementation after changes:

- [ ] Each call to `createLineForMathList:` in `MTTypesetter.m` has the correct `style:` and `cramped:` arguments. Grep: `createLineForMathList:`
- [ ] Every `make*:` helper sets `ascent`, `descent`, `width` on its returned `MTDisplay` before it reaches the caller.
- [ ] `_currentPosition.x` is incremented by exactly the display width after each atom, with any needed inter-element space added *before*.
- [ ] `atom.type = kMTMathAtomOrdinary` (or Inner for tables) is set before Rule 20 spacing lookups for any Rule-16 atom.
- [ ] Super/subscript positioning is always guarded by `if (atom.subScript || atom.superScript)` and uses the index range end, not start.
- [ ] `spaceAfterScript` is applied exactly once after a sub/super pair, not twice.
- [ ] `axisHeight` is pulled from `_styleFont` (not `_font`) in all centering computations — the axis scales with the current style.
