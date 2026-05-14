# iosMath Symbol Expansion — Research Document

**Phase:** Research (R of RDPI)
**Source requirements:** `iosMath_feature_requirements.md`
**Branch / worktree:** `master` (worktree `.claude/worktrees/new-symbols`)
**Audience:** engineer who will write the LLD and implementation
**Out of scope for this document:** LLD content, implementation code, time estimates

---

## 1. Executive Summary

The seven feature areas decompose into four orthogonal kinds of work:

1. **Pure symbol-table extensions** (Features 2–5) — adding rows to dictionaries in `MTMathAtomFactory`. No parser, layout, or font work is required. The unit-of-work is one Unicode codepoint + one TeX class per symbol.
2. **Parser extensions** (Feature 1: prime shorthand) — a localized change to `MTMathListBuilder buildInternal:`. This requires care because it interacts with the existing `^` superscript handling and a long-standing "silently drop unknown character" path.
3. **Alias-table extensions** (Feature 6) — adding rows to the `aliases` dictionary. Mostly trivial, except `\restriction → \upharpoonright` is dependent on Feature 3, and several aliases interact with reverse-serialization in well-understood ways.
4. **Reverse-map re-keying** (Feature 7: round-trip type preservation) — change `textToLatexSymbolNames` from `nucleus → name` to `(nucleus, type) → name` so type-distinct entries at the same nucleus preserve their type on round-trip. Prerequisite for Features 4 and 5 (which introduce U+25B3 Ord/Bin and U+25BD Ord/Bin pairs).

The **single highest-risk issue** discovered during research is that the existing test `testLatexSymbols` (`iosMathTests/MTTypesetterTest.m:1292`) iterates **every** entry registered in `supportedLatexSymbols`, instantiates an atom, lays it out, and asserts the resulting display has non-zero width and (for non-space glyphs) non-zero ascent+descent. Today this test runs only with the *default* font (Latin Modern). A new symbol whose Unicode codepoint is missing or zero-width in `xits-math.otf` or `texgyretermes-math.otf` would not be caught. **The LLD should extend `testLatexSymbols` to sweep all three bundled fonts** (Latin Modern Math, XITS Math, TeX Gyre Termes Math) — see §9.

The **`\Box` / `\square` situation** is straightforward once the layering is correct: the placeholder atom is an internal editor concept (the inline comment at `MTMathList.h:51` reads *"A placeholder square for future input. Does not exist in TeX"*) and has no business living in the LaTeX command table. Recommendation: remove the existing `@"square" : [MTMathAtomFactory placeholder]` entry, register `\Box` as Ord at U+25A1, and add `\square` to the alias table pointing at `\Box`. The `+placeholder` factory remains the editor's way to construct a placeholder; it never went through LaTeX parsing anyway. No reverse-map special case needed. See §7.4.

The **third issue** is prime semantics around `^`: plain TeX's `'` macro greedily consumes consecutive primes **and** any following `^{...}` group, merging the latter into the same superscript group — `f'^2 → f^{\prime 2}`. The current `^` parser branch in iosMath, however, creates an *empty* ordinary atom when `prevAtom.superScript` is already set (`MTMathListBuilder.m:134`), which means a naive prime implementation that just sets `superScript` would produce `f^{\prime}{}^{2}` for `f'^2`. The TeX-canonical algorithm is well-defined and detailed in §8.1; it is the recommended target.

The **fourth issue** is round-trip lossiness at type-distinct shared nuclei. Today's reverse map (`textToLatexSymbolNames`, `MTMathAtomFactory.m:732`) keys on nucleus alone, so a `\bigtriangleup` (Bin, U+25B3) atom round-trips as `\triangle` (Ord, U+25B3) — same glyph, different rule-16 spacing. Re-parsing the round-trip output produces a visibly different render because the type changed. The fix is to key the reverse map on **(nucleus, type)** so each type-distinct entry preserves its class; the existing shorter-then-alphabetical tie-break still applies within a single (nucleus, type) cell. This is **Feature 7** (§8.7) and must land with or before Features 4 and 5, which introduce the U+25B3 and U+25BD type collisions.

Everything else is mechanical.

---

## 2. Repository Architecture

### 2.1 Top-level layout (relevant subset)

```
iosMath/
  lib/
    MTMathListBuilder.{h,m}   ← LaTeX → MTMathList parser
    MTMathAtomFactory.{h,m}   ← symbol/alias/delimiter/accent/stack tables
    MTMathList.{h,m}          ← atom type definitions, MTMathList, finalize() (Rules 5/6/14)
    MTMathListIndex.{h,m}     ← (cursor model — not relevant)
    MTUnicode.{h,m}           ← (UTF-16 surrogate helpers — not relevant)
  render/
    MTMathListDisplay.{h,m}   ← display tree
    MTFont(Manager).{h,m}     ← CTFont wrapper
    internal/
      MTTypesetter.m          ← layout engine (Appendix-G TeX algorithm)
      MTFontMathTable.{h,m}   ← OpenType MATH table reader (.plist sidecar)
      MTMathListDisplayInternal.h
  fonts/
    latinmodern-math.{otf,plist}
    xits-math.{otf,plist}
    texgyretermes-math.{otf,plist}
iosMathTests/
  MTMathListBuilderTest.m     ← parser tests (~1600 lines)
  MTMathListTest.m            ← atom/list data structure tests
  MTTypesetterTest.m          ← layout output tests; includes testLatexSymbols sweep
ALGORITHM.md                  ← rule-by-rule TeX-algorithm map onto iosMath
CLAUDE.md                     ← project orientation
```

### 2.2 The pipeline (one sentence per stage)

`NSString` → `MTMathListBuilder.build` → `MTMathList` (linked list of `MTMathAtom`) → `MTMathList.finalized` (rules 5/6/14: bin→un reclassification, number fusion) → `MTTypesetter.preprocessMathList` (rule-14 ordinary fusion, type laundering) → `MTTypesetter.createDisplayAtoms` (rule-16 inter-element spacing + glyph layout) → `MTMathListDisplay` → CoreText draw.

For the features in this document, only the first three stages are touched, and only Feature 1 changes the parser at all.

---

## 3. Parsing Pipeline (end-to-end)

### 3.1 Entry points

- `+[MTMathListBuilder buildFromString:]` (`MTMathListBuilder.m:763`)
- `+[MTMathListBuilder buildFromString:error:]` (`MTMathListBuilder.m:769`)

Both delegate to `-build` which calls `-buildInternal:` with `oneCharOnly=NO`.

### 3.2 The single-character / control loop

`-[MTMathListBuilder buildInternal:stopChar:]` (`MTMathListBuilder.m:106`) is a **character-by-character** scanner over a `unichar* _chars` buffer. The control flow per character:

| Char | Branch | Notes |
|---|---|---|
| `^` | line 131 — superscript on `prevAtom`. **If `prevAtom.superScript` is already set, allocates a fresh empty Ord atom.** |
| `_` | line 144 — subscript, mirror of `^` |
| `{` | line 157 — recurse with `stopChar='}'` |
| `}` | line 166 — closing brace; mismatch error if no stopChar |
| `\` | line 174 — `[self readCommand]` then `stopCommand:`/`applyModifier:`/`fontStyleWithName:`/`atomForCommand:` |
| `&` | line 214 — column separator (only inside an env) |
| ` ` | line 224 — preserved only inside `\text{…}` (`_spacesAllowed`) |
| anything else | line 228 — `[MTMathAtomFactory atomForCharacter:ch]`; **if it returns nil, the character is silently skipped** (line 229–232) |

The "silent skip" path is what currently swallows `'`, `~`, `$`, `%`, `#`, `&` (outside env), and any non-ASCII character outside the Cyrillic block. See `+[MTMathAtomFactory atomForCharacter:]` (`MTMathAtomFactory.m:103-146`) for the explicit reject list at line 112.

### 3.3 Command dispatch

After `\` is read, `-readCommand` (`MTMathListBuilder.m:340`) returns a string. That string is dispatched in this order in `buildInternal:`:

1. `-stopCommand:list:stopChar:` (`MTMathListBuilder.m:537`) — handles `\right`, `\over`, `\atop`, `\choose`, `\brack`, `\brace`, `\\`, `\cr`, `\end`. Returns the current list to unwind.
2. `-applyModifier:atom:` (`MTMathListBuilder.m:613`) — handles `\limits`/`\nolimits`.
3. `+[MTMathAtomFactory fontStyleWithName:]` — `\mathbf`, `\mathit`, etc.
4. `-atomForCommand:` (`MTMathListBuilder.m:423`) — the main dispatcher:
   - calls `+[MTMathAtomFactory atomForLatexSymbolName:]` (alias-aware)
   - falls through to `\big`/`\Big`/`\bigl`/…/`\Bigm` family (`largeDelimiterCommands`)
   - falls through to accents (`+[MTMathAtomFactory accentWithName:]`)
   - hard-coded keywords: `\frac`, `\binom`, `\sqrt`, `\left`, `\overline`, `\underline`
   - stack commands: `+[MTMathAtomFactory stackAtomForCommand:]`
   - `\begin` / `\color` / `\colorbox`
   - else → `MTParseErrorInvalidCommand`

The dispatch order matters when adding new commands. **Symbol-table additions (Features 2–5) flow through path 4a (`atomForLatexSymbolName:`) and require zero parser changes.** Aliases also flow through path 4a — `aliases` is consulted *first* inside `atomForLatexSymbolName:`.

### 3.4 finalize() — Rules 5/6/14 in `MTMathList.m`

`-[MTMathList finalized]` (`MTMathList.m:1344`) walks the atom list and:

- Reclassifies a `BinaryOperator` to `UnaryOperator` if `isNotBinaryOperator(prev)` returns true (`MTMathList.m:17`) — i.e. if the preceding atom is `Bin`/`Rel`/`Open`/`Punct`/`LargeOp` or there's no preceding atom. This is **TeX rule 5** for "Bin-not-binary".
- Reclassifies the previous atom from `Bin` to `Un` if the current atom is `Rel`/`Punct`/`Close` (TeX rule 6).
- Fuses adjacent `Number` atoms with no scripts (TeX rule 14, partial).
- Final binary at end-of-list becomes `UnaryOperator`.

This loop is where added Bin-class symbols (`\boxplus`, `\veebar`, etc.) get rule-5/6 treatment automatically.

### 3.5 Reverse direction: `mathListToString:`

`+[MTMathListBuilder mathListToString:]` (`MTMathListBuilder.m:798`) walks the finalized list and calls `-appendLaTeXToString:` on each atom (`MTMathList.m:281` for the base implementation). The base implementation calls `+[MTMathAtomFactory latexSymbolNameForAtom:]` (`MTMathAtomFactory.m:184`), which looks up `textToLatexSymbolNames` — a reverse map keyed by `nucleus` today.

`textToLatexSymbolNames` (`MTMathAtomFactory.m:732`) is built **lazily and once** by iterating `supportedLatexSymbols`. When two symbols share a nucleus, the tie-break is: shorter command wins, then alphabetical-ascending. **Aliases are not in this map.** So an alias like `\le` round-trips as `\leq` (its canonical), and `\implies` would round-trip as `\Longrightarrow`. This matches existing project behavior (see test data at `MTMathListBuilderTest.m:67`).

This document recommends re-keying the reverse map by **(nucleus, type)** rather than nucleus alone — see Feature 7 (§8.7). Under the new keying, the lookup in `latexSymbolNameForAtom:` uses `atom.type` in addition to `atom.nucleus`, and the shorter-then-alphabetical tie-break applies only within a single (nucleus, type) cell.

---

## 4. Symbol Registration System

### 4.1 The five static dictionaries

Owned by `MTMathAtomFactory.m` and lazily-initialized inside `dispatch_once`-equivalent guards:

| Dict | Method | Purpose | Currently houses |
|---|---|---|---|
| `supportedLatexSymbols` | `+supportedLatexSymbols` (line 439) | command name → prototype `MTMathAtom` | ~190 entries: Greek, arrows, relations, operators, large operators, named functions, punctuation, ordinaries, spaces, styles |
| `aliases` | `+aliases` (line 709) | command name → canonical command name | 13 entries (incl. `lnot→neg`, `iff→Longleftrightarrow`) |
| `accents` | `+accents` (line 764) | command name → combining-character nucleus | 11 entries |
| `delimiters` | `+delimiters` (line 814) | delimiter name → glyph for `\left` / `\right` | ~30 entries |
| `fontStyles` | `+fontStyles` (line 885) | command name → `MTFontStyle` enum | 22 entries |

There are also two reverse maps (`textToLatexSymbolNames`, `accentValueToName`, `delimValueToName`) and one stack-command table (`stackCommands`, line 919). These do not need editing for any of the requested features.

### 4.2 Atom prototype shape

Each value in `supportedLatexSymbols` is an `MTMathAtom` (or subclass) instance. `atomForLatexSymbolName:` returns a `[atom copy]` so prototypes are immutable in practice. To register a relation symbol you write:

```objc
@"nleq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≰"]
```

The minimum data per row is:

- **command name** (string key, no leading `\`)
- **`MTMathAtomType`** — drives spacing (§5)
- **`nucleus`** — Unicode code-point string the typesetter renders

For the requested symbols the type values that matter are:

| TeX class | Enum | Used for |
|---|---|---|
| Ord | `kMTMathAtomOrdinary` | hebrew letters, `\complement`, `\Box`, `\Diamond`, prime |
| Rel | `kMTMathAtomRelation` | `\nleq`…, all arrows/harpoons, `\vdash`, `\Subset`, `\therefore`, `\multimap`, etc. |
| Bin | `kMTMathAtomBinaryOperator` | `\boxplus`, `\circledast`, `\veebar`, `\triangleleft`, etc. |

`Number` and `Variable` types are special — they are rewritten by `MTTypesetter.preprocessMathList:` (`MTTypesetter.m:511`) into Ord with font-substituted nucleus. None of the new symbols need them.

### 4.3 The `+addLatexSymbol:value:` runtime escape hatch

`+addLatexSymbol:value:` (`MTMathAtomFactory.m:193`) lets clients register symbols at runtime and updates both the forward and reverse maps. This is exercised in `MTMathListBuilderTest.m:1202 testCustom` and is the project's documented extension API. **Adding to the static `supportedLatexSymbols` dictionary is the right place for the requested built-in symbols** — the runtime API is for client-side custom commands.

### 4.4 Number-of-glyphs caveat

iosMath today registers exactly one Unicode character per symbol (a single `unichar` or, occasionally, a surrogate pair like `\imath` at `U+1D6A4`). The typesetter renders the nucleus via `CTFont` glyph lookup. Multi-character "synthetic" nuclei (e.g. composing `\not` over a base) are not used and are explicitly out of scope per the requirements (§"No synthetic `\not` composition logic required").

This means we **must rely on the bundled fonts already containing single-glyph forms** of every requested symbol at the AMS-canonical codepoint. Per font-coverage rule of thumb, all three bundled fonts (Latin Modern Math, XITS Math, TeX Gyre Termes Math) ship with the AMS extension block (U+22XX, U+229X, U+21XX, U+2210X) — but this is an assumption that **must be smoke-tested** by `testLatexSymbols` after registration (§9).

---

## 5. Rendering / Layout System (the parts that matter)

### 5.1 Inter-element spacing table

`getInterElementSpaces()` (`MTTypesetter.m:28`) is the canonical TeX rule-16 spacing matrix. It indexes by left-class × right-class with the row/column ordering:

```
0 ordinary, 1 large-op, 2 binary, 3 relation,
4 open,     5 close,    6 punct,  7 fraction/inner,
8 radical (left-only)
```

`getInterElementSpaceArrayIndexForType` (`MTTypesetter.m:48`) maps each `MTMathAtomType` to its index. The table is consulted in `-getInterElementSpace:right:` (`MTTypesetter.m:953`) with mu-unit conversion through `_styleFont.mathTable.muUnit`.

For the new symbols, **no edits to this table are needed** — every symbol the requirements add fits one of the existing classes (Ord, Bin, Rel). Rule-16 spacing automatically:

- `Bin Bin = invalid` (boxplus immediately followed by boxplus is not legal TeX — caught by Rule-5/6 reclassification before it reaches the typesetter).
- `Rel Rel = none` (so `a \nleq \nless b` types correctly).
- `Bin × {Rel|Close|Punct|right-side-Close} = invalid` — also handled by Rule-5/6 in finalize.

### 5.2 Atom dispatch

`-createDisplayAtoms:` (`MTTypesetter.m:576`) switches on `atom.type`. The catch-all branch for "ordinary glyph atoms" (line 818) handles **Ordinary, BinaryOperator, Relation, Open, Close, Placeholder, Punctuation** uniformly:

- if not an `MTLargeDelimiter`, append `atom.nucleus` to a CoreText line being built;
- emit kerning equal to `[self getInterElementSpace:left right:right]`;
- attach scripts via `-makeScripts:display:index:delta:` if `atom.subScript || atom.superScript`.

This branch is the universal renderer that all six features ultimately use. **No code changes here are required for any of the six features.**

### 5.3 Glyph lookup

The typesetter does not hard-code per-symbol glyph indices. It calls `CTFontGetGlyphsForCharacters` / italic correction / etc. via `MTFont`/`MTFontMathTable` for each rendered code-point. The implication: **adding a new symbol is equivalent to adding a new code-point to render**. The test of "does it render" is "does the font have a glyph at that code-point with non-zero advance-width" — checked by `testLatexSymbols`.

### 5.4 Scripts on radical/inner/over/under and the placeholder coloring

Not relevant to any feature in this document — listed for completeness only.

---

## 6. Alias Resolution System

### 6.1 Mechanism

`+[MTMathAtomFactory atomForLatexSymbolName:]` (`MTMathAtomFactory.m:164`):

```objc
NSDictionary* aliases = [MTMathAtomFactory aliases];
NSString* canonicalName = aliases[symbolName];
if (canonicalName) {
    symbolName = canonicalName;
}
NSDictionary* commands = [self supportedLatexSymbols];
MTMathAtom* atom = commands[symbolName];
return [atom copy];
```

Aliases are resolved **before** symbol lookup. They are simple string indirections — the alias must point at a key that exists in `supportedLatexSymbols`, otherwise `atomForLatexSymbolName:` returns nil and the parser raises `MTParseErrorInvalidCommand`. There is **no chained alias** support: `aliases[aliases[x]]` is not attempted, and there is no test guarding against alias cycles. (Cycles would loop only if both keys were aliases; today they aren't, but adding many at once raises the risk slightly.)

### 6.2 Reverse direction

The reverse map (`textToLatexSymbolNames`, `MTMathAtomFactory.m:732`) is built **only from `supportedLatexSymbols`** — aliases are excluded. Consequence: `\le` round-trips as `\leq`, `\to` as `\rightarrow`, `\iff` as `\Longleftrightarrow` (covered by the existing parser-test data at `MTMathListBuilderTest.m:67`).

Today the reverse map is keyed by nucleus alone, so two registered entries that share a nucleus collapse to whichever wins the shorter-then-alphabetical tie-break — even if their `MTMathAtomType` differs. This is the Feature 7 problem (§8.7): a `\bigtriangleup` (Bin, U+25B3) atom round-trips as `\triangle` (Ord, U+25B3), changing rule-16 spacing on re-parse. After Feature 7, the map is keyed by (nucleus, type) and each type-distinct entry preserves its own canonical name; same-nucleus-same-type entries still tie-break.

For the new aliases, this implies:

- `\implies` → renders correctly, round-trips as `\Longrightarrow`
- `\impliedby` → renders correctly, round-trips as `\Longleftarrow`
- `\dotsc`, `\dotsi` → render as `\ldots`, round-trip as `\ldots`
- `\dotsb`, `\dotsm` → render as `\cdots`, round-trip as `\cdots`
- `\restriction` → renders as `\upharpoonright` (only after Feature 3 lands), round-trips as `\upharpoonright`

This matches existing project conventions and is acceptable per the requirements (no context-sensitive dots logic required).

### 6.3 When to use an alias vs a separate `supportedLatexSymbols` entry

iosMath's design supports two ways for two LaTeX commands to render the same glyph. Picking the right one is a recurring decision when adding symbols:

| Property | Alias (`+aliases`) | Two entries (`+supportedLatexSymbols`) |
|---|---|---|
| Resolution | Name→name; resolved before prototype lookup | Each name has its own prototype |
| Type-distinct? | **No** — alias inherits canonical's `MTMathAtomType` | **Yes** — each entry has its own type |
| Reverse map | Excluded; round-trip → canonical | Included; each (nucleus, type) cell keeps its own canonical (Feature 7); tie-break (shorter, alphabetical) only applies within a cell |
| Memory | Shares the canonical's atom prototype | Two prototype objects |

**Rule:**

- **Same `MTMathAtomType` AND same nucleus** → use an alias. They are true synonyms.
  *Examples:* `\le → \leq` (Rel/U+2264), `\to → \rightarrow` (Rel/U+2192), `\iff → \Longleftrightarrow` (Rel/U+27FA), `\square → \Box` (Ord/U+25A1), `\vartriangle → \triangle` (Ord/U+25B3).
- **Different `MTMathAtomType`s, same nucleus** → use two separate entries. The alias mechanism cannot change the type.
  *Examples:* `\triangle` (Ord, U+25B3) vs `\bigtriangleup` (Bin, U+25B3); `\triangledown` (Ord, U+25BD) vs `\bigtriangledown` (Bin, U+25BD).

In the two-entries case, after Feature 7 (§8.7) each entry occupies its own (nucleus, type) cell in the reverse map and round-trips to its own canonical name (no type-class loss). The shorter-then-alphabetical tie-break still applies, but only within a single (nucleus, type) cell — and per the rule above, those cases should already have been collapsed into an alias.

The per-feature tables in §8 are written using this rule.

### 6.4 Dependency between Feature 3 and Feature 6

`\restriction → \upharpoonright` requires `\upharpoonright` to exist as a primary entry. Implementing Feature 6 alone without Feature 3 would leave `\restriction` resolving to a missing canonical, causing `MTParseErrorInvalidCommand`. **Feature 6 must be sequenced after Feature 3** (or, if alphabetized into a single PR, both must land together). The requirements doc's suggested implementation order (§"Suggested Implementation Order") puts Aliases before Harpoons, which would cause `\restriction` to be a broken alias temporarily. This is a real ordering issue worth flagging.

---

## 7. What Already Exists (partial coverage check)

Grep results across `MTMathAtomFactory.m`:

- `\prime`: **already registered** (`MTMathAtomFactory.m:666`) as Ord with U+2032. Feature 1 reuses this prototype.
- All of the requested negated relations (Feature 2): **none** present.
- All of the requested harpoons/extended arrows (Feature 3): **none** present.
- All of the requested missing relations/ordinaries (Feature 4): **none** present.
- All of the requested boxed/circled operators (Feature 5): **none** present.
- All of the requested aliases (Feature 6): **none** present.

Adjacent existing entries that are useful reference:

- Existing arrows (`\leftarrow`, `\Longrightarrow`, `\mapsto`, `\nearrow`, etc.) at `MTMathAtomFactory.m:506-528` use `kMTMathAtomRelation`. New harpoons follow this pattern.
- Existing relations like `\leq`, `\subseteq`, `\sqsubseteq`, `\models`, `\perp` at `:532-561` use `kMTMathAtomRelation`. The new negated relations follow this pattern.
- Existing binary operators `\oplus`, `\otimes`, `\odot`, `\sqcap`, `\sqcup`, `\amalg` at `:582-589` use `kMTMathAtomBinaryOperator`. The new boxed/circled operators follow this pattern.
- Existing `\aleph` (U+2135) at `:673` is Ord. The Hebrew letters `\beth`/`\gimel`/`\daleth` (U+2136/2137/2138) follow this.
- `\square : placeholder` (`:444`) is the **only existing AMS-name collision risk** for Feature 4 (`\Box`). See §7.4.

### 7.1 Existing apostrophe handling

`atomForCharacter:` (`:112`) explicitly rejects `'`:

```objc
} else if (ch == '$' || ch == '%' || ch == '#' || ch == '&' || ch == '~' || ch == '\'') {
    // These are latex control characters that have special meanings. We don't support them.
    return nil;
}
```

The parser then silently drops the character (`MTMathListBuilder.m:228-232`). So today `f'` parses as `f` with no error and no warning. Feature 1 must **remove `'` from this rejection list** (or pre-empt it in `buildInternal`) and add explicit handling.

### 7.2 Existing `^` handling and what breaks under primes

`MTMathListBuilder.m:131-143`:

```objc
if (ch == '^') {
    if (!prevAtom || prevAtom.superScript || !prevAtom.scriptsAllowed) {
        // If there is no previous atom, or if it already has a superscript
        // or if scripts are not allowed for it, then add an empty node.
        prevAtom = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@""];
        [list addAtom:prevAtom];
    }
    prevAtom.superScript = [self buildInternal:true];
    continue;
}
```

If primes are implemented by setting `prevAtom.superScript` to a list of `\prime` atoms, then `f'^2` will fall into the "already has a superscript" branch, allocate an empty Ord, and produce `f^{\prime} {}^{2}` — not the TeX-canonical `f^{\prime 2}`. This is a real issue for Feature 1 — discussed in detail in §8.1.

### 7.3 Existing single-char commands

`-readCommand` (`MTMathListBuilder.m:340`) treats certain ASCII symbols as one-character command names:

```objc
NSArray* singleChars = @[ @'{', @'}', @'$', @'#', @'%', @'_', @'|', @' ', @',', @'>', @';', @'!', @'\\' ];
```

So `\$` reads command `"$"`, `\>` reads command `">"`, etc. None of the new commands collide with these.

### 7.4 `\Box` and `\square` — alias resolution

**Background.** Both `\square` and `\Box` are standard AMS LaTeX commands. Both are defined in `amssymb` (and `\Box` also in `latexsym`), and **both are AMS-canonical synonyms for the same glyph U+25A1 WHITE SQUARE**, classified as `mathord`. They are not iosMath inventions.

**iosMath status today.** `@"square" : [MTMathAtomFactory placeholder]` (`MTMathAtomFactory.m:444`) registers `\square` as a **placeholder atom** (type `kMTMathAtomPlaceholder`, nucleus U+25A1). The placeholder concept is editor-internal, not a LaTeX construct — confirmed by the inline comment at `MTMathList.h:51`: *"A placeholder square for future input. Does not exist in TeX."* The fact that it was ever wired to a LaTeX command is a layering accident.

**Plan.**

1. **Remove** `@"square" : [MTMathAtomFactory placeholder]` from `+supportedLatexSymbols`. The `+placeholder` factory method (`MTMathAtomFactory.m:65`) stays untouched — it's the editor's API for constructing placeholders and is exercised by `MTMathListTest.m:134-293`.
2. **Add** `@"Box" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"□"]` to `+supportedLatexSymbols`.
3. **Add** `@"square" : @"Box"` to `+aliases` (in Feature 6's table — see §8.6).

**Effects.**

- Typing `\square` in LaTeX now produces an Ord atom (the AMS-canonical meaning). Typing `\Box` produces the same Ord atom. Both AMS synonyms work and resolve identically.
- The reverse map `textToLatexSymbolNames` gets U+25A1 → `\Box` (the only registered name at that nucleus, since aliases are excluded from the reverse map per §6.2).
- A `kMTMathAtomPlaceholder` atom (created via `+placeholder`) serializing through `latexSymbolNameForAtom:` round-trips as `\Box`. This is acceptable because placeholders "do not exist in TeX" (per the source comment) — clients that care about placeholder semantics should check `atom.type == kMTMathAtomPlaceholder`, not the LaTeX serialization.

**No collisions** with any other registered symbol. Adding the remaining requested symbols introduces no additional collisions because each requested codepoint is unique and not yet used.

### 7.5 The `\Diamond` glyph choice (resolved — AMS canonical)

AMS `amssymb`/`amsfonts` defines `\Diamond` as **U+25C7 (WHITE DIAMOND), `mathord`**. This is the canonical mapping and is what this document recommends. Note: distinct from `\diamond` (`mathbin`, U+22C4 DIAMOND OPERATOR — already not in iosMath, but is the canonical lowercase form), `\diamondsuit` (`mathord`, U+2662 — already not in iosMath, useful relative — see §8.4), `\lozenge` (`mathord`, U+25CA — AMS, see §8.4), and `\blacklozenge` (`mathord`, U+29EB — AMS, see §8.4).

There is no existing collision in iosMath at U+25C7.

### 7.6 The triangle family (AMS canonical)

Per `amssymb.sty`, the canonical mappings for triangle-related symbols are:

| Command | TeX class | Codepoint | Source |
|---|---|---|---|
| `\triangle` *(already registered)* | Ord | U+25B3 △ | plain TeX |
| `\triangleleft` | Bin | U+25C1 ◁ | plain TeX (also AMS-canonical) |
| `\triangleright` | Bin | U+25B7 ▷ | plain TeX (also AMS-canonical) |
| `\bigtriangleup` | Bin | U+25B3 △ | plain TeX |
| `\bigtriangledown` | Bin | U+25BD ▽ | plain TeX |
| `\vartriangle` | Ord | U+25B3 △ | amssymb — **alias to existing `\triangle`** per §6.3 (same type+nucleus) |
| `\triangledown` | Ord | U+25BD ▽ | amssymb |
| `\vartriangleleft` | Rel | U+22B2 ⊲ | amssymb |
| `\vartriangleright` | Rel | U+22B3 ⊳ | amssymb |
| `\trianglelefteq` | Rel | U+22B4 ⊴ | amssymb |
| `\trianglerighteq` | Rel | U+22B5 ⊵ | amssymb |
| `\ntriangleleft` | Rel | U+22EA ⋪ | amssymb (negated; belongs in Feature 2) |
| `\ntriangleright` | Rel | U+22EB ⋫ | amssymb (negated; belongs in Feature 2) |
| `\ntrianglelefteq` | Rel | U+22EC ⋬ | amssymb (negated; belongs in Feature 2) |
| `\ntrianglerighteq` | Rel | U+22ED ⋭ | amssymb (negated; belongs in Feature 2) |
| `\triangleq` | Rel | U+225C ≜ | amssymb |
| `\blacktriangle` | Ord | U+25B2 ▲ | amssymb |
| `\blacktriangledown` | Ord | U+25BC ▼ | amssymb |
| `\blacktriangleleft` | Ord | U+25C0 ◀ | amssymb |
| `\blacktriangleright` | Ord | U+25B6 ▶ | amssymb |

**Codepoint sharing — apply the §6.3 rule.**

- `\vartriangle` (Ord, U+25B3) shares **both type and nucleus** with the existing `\triangle` → **alias** to `\triangle` (Feature 6).
- `\bigtriangleup` (Bin, U+25B3) shares nucleus but has a **different type** (Bin vs Ord) → **separate entry** (Feature 5).
- `\triangledown` (Ord, U+25BD) and `\bigtriangledown` (Bin, U+25BD) share nucleus but differ in type → **two separate entries** (Ord goes in Feature 4, Bin goes in Feature 5).

**Reverse-map consequence at U+25B3 — drives Feature 7.** Today the reverse map keys on nucleus only and tie-breaks "shorter, then alphabetical," so both Ord and Bin atoms at U+25B3 collapse to a single canonical (`\triangle` wins by length over `\bigtriangleup`). A `\bigtriangleup` atom would round-trip as `\triangle` — same glyph, but the type changes from Bin to Ord, which changes rule-16 spacing on re-parse. Same shape at U+25BD with `\triangledown` (Ord) vs `\bigtriangledown` (Bin).

This is a correctness bug, not a stylistic limitation: re-rendering the round-trip output produces visibly different output from the original. **Feature 7 (§8.7) re-keys the reverse map by (nucleus, type)** so each entry occupies its own cell and round-trips to its own canonical name. After Feature 7, `\bigtriangleup` round-trips as `\bigtriangleup`, `\triangle` as `\triangle`, and likewise for the U+25BD pair. Feature 7 must land with or before Features 4 and 5 (which introduce these collisions); landing them without Feature 7 ships the regression.

The negated variants (`\ntriangleleft`, `\ntriangleright`, `\ntrianglelefteq`, `\ntrianglerighteq`) belong in Feature 2 — see §8.2 for the consolidated table.

---

## 8. Feature-by-Feature Research

For each feature: files to edit, parser implications, render implications, spacing implications, risks/regressions, validation strategy.

### 8.1 Feature 1 — Prime Shorthand `'`

**Files to edit**

- `iosMath/lib/MTMathListBuilder.m` — `buildInternal:stopChar:` (the parser loop)
- `iosMath/lib/MTMathAtomFactory.m` — relax the `'` rejection in `atomForCharacter:` (line 112). Strictly, the parser change in `buildInternal` could short-circuit `'` before `atomForCharacter` runs, in which case no edit here is required. The cleaner choice is to handle `'` in `buildInternal` and leave `atomForCharacter` rejecting it (so programmatic callers like `mathListForCharacters:` keep their current safe behavior — `'` should not become an Ord atom there).

**No edits required** in `MTMathAtomFactory.supportedLatexSymbols` (the `\prime` symbol already exists at line 666).

**TeX algorithm reference**

Plain TeX (`plain.tex`, Knuth) makes `'` an active math character whose macro expansion is roughly:

```
\def\'{^\bgroup\prim@s}                                   % open superscript, start collecting
\def\prim@s{\prime\futurelet\next\pr@m@s}                 % insert \prime, peek
\def\pr@m@s{\ifx'\next  \pr@@@s \else
            \ifx^\next  \pr@@@t \else \egroup \fi\fi}
\def\pr@@@s#1{\prim@s}                                    % consume ' and recurse
\def\pr@@@t#1#2{#2\egroup}                                % consume ^{...}, append, close
```

Concretely:

| Input | Expansion |
|---|---|
| `f'`     | `f^{\prime}` |
| `f''`    | `f^{\prime\prime}` |
| `f'''`   | `f^{\prime\prime\prime}` |
| `f'^2`   | `f^{\prime 2}` (the `^` after the primes is **merged** into the same superscript group) |
| `f'^{2x}` | `f^{\prime 2x}` |
| `f^2'`   | "double superscript" error (would re-open `^` after `^2`) |

**The iosMath algorithm should match this.** It is the well-defined, TeX-canonical behavior and is what users expect.

**Parser implications**

The change in `buildInternal:`:

1. Detect `'` in the main `while([self hasCharacters])` loop, before the `atomForCharacter:` fallthrough.
2. **Validate `prevAtom`**: if `prevAtom == nil` or `prevAtom.superScript != nil` or `!prevAtom.scriptsAllowed`, follow the existing `^` convention (allocate an empty Ord atom and add it to the list — `MTMathListBuilder.m:134-137`).
3. **Count primes**: greedily consume consecutive `'` characters from the input, counting them as N. (Whitespace handling: TeX's `\futurelet` skips spaces because `'` is an active char in math mode and spaces are ignored there. Mirror this — skip spaces between consecutive `'`s. iosMath already strips most whitespace at line 224.)
4. Build a fresh `MTMathList` containing N copies of `[atomForLatexSymbolName:@"prime"]`.
5. **Peek for trailing `^`**: examine the next non-space character. If it is `^`, consume it, parse the following super-script group via `[self buildInternal:true]` (one-char-only mode handles both `^x` and `^{...}` cases — see line 137), and **append** every atom from the parsed group to the prime-list.
6. Assign the resulting list to `prevAtom.superScript`.

Step 5 is the merge that gives `f'^2 → f^{\prime 2}`. It supersedes the `^` handler entirely for the case where primes precede the `^`. The `^` handler at line 131 is unchanged for cases without primes. The same logic does **not** apply to a trailing `_` — TeX's prime macro merges only `^`, not `_`. A subscript that follows primes (`f'_n`) should be parsed by the existing `_` handler against the same `prevAtom`, attaching to `prevAtom.subScript`. This works automatically because step 6 leaves `prevAtom` intact (we only set its `superScript`, not replace `prevAtom`).

**Double-superscript error**: if step 2 finds `prevAtom.superScript` already non-nil (e.g., user wrote `f^2'`), the existing `^` branch's "allocate empty Ord" path is the closest analogue — but TeX itself errors here. The requirements doc does not pin behavior; **recommendation**: match the existing `^` convention (allocate empty Ord, attach primes to that). This is non-erroring and consistent with the rest of the parser.

**Render implications**

Zero. `\prime` already lays out correctly as Ord U+2032, and superScript layout already handles a list with multiple atoms. The existing `MTTypesetterTest.m` provides coverage of script positioning.

**Spacing implications**

Zero. The `\prime` atom is Ord and lives inside a superScript list; rule-16 doesn't apply between super/sub script atoms and the parent baseline (only the script-shift constants from the math table).

**Risks / regressions**

- **`atomForCharacter:` callers** — `+[MTMathAtomFactory mathListForCharacters:]` is documented as "no LaTeX conversion or interpretation" and is used by `fractionWithNumeratorStr:denominatorStr:`. If we relax the `'` rejection in `atomForCharacter:`, then `\frac{f'}{g}` constructed via `fractionWithNumeratorStr:` would behave differently. Therefore handle `'` **only inside `buildInternal:`** and leave `atomForCharacter:` rejecting it.
- **Inside braces / scripts**: `f^{x'}` should produce `f^{x'}` → same prime semantics inside the recursive `buildInternal` call. Because the prime handler operates on `prevAtom` within the current invocation's local scope, this works automatically *if* the handler is placed in the main loop and not gated by `oneCharOnly`. Verify with a test.
- **Inside a script `oneCharOnly` slot**: `f^'2` is ambiguous in TeX. Most engines treat the `'` as the (single) one-char super-script content and continue. iosMath's `oneCharOnly` returns to the caller after one atom; the prime would attach to nothing (no prevAtom in the recursion). Easiest behavior: at the start of a oneCharOnly slot, treat `'` as a literal `\prime` ord. This is consistent with how `^2'` would be parsed.
- **Existing `\prime` regression**: `f^\prime` and `f^{\prime\prime}` must continue to work and produce identical lists (they will, since prime handling never touches the explicit `\prime` path).
- **`f^{2'}` — prime inside an existing super-script**: the prime handler runs in the inner recursion; `prevAtom` inside the inner list is `2`, so `'` attaches as `2.superScript = [\prime]`. The result is `f^{2^{\prime}}`, which is the documented TeX behavior and is correct.

**Validation strategy**

In `MTMathListBuilderTest.m`:

- single prime: `f'` → one atom `f` with `superScript = [Ordinary U+2032]`.
- double / triple primes: `y''`, `f'''(x)` — atom count and `superScript.atoms.count`.
- prime with no preceding atom: `'2` — should produce empty Ord atom + superScript with primes (mirror `^2` behavior at `:102`).
- prime inside braces: `{f'}^2` — verify the inner brace produces `f` with prime-superScript, and the outer `^2` takes the brace result.
- **prime followed by `^` (TeX merge)**: `f'^2` should produce one atom `f` with `superScript = [\prime, 2]` (i.e., 2 atoms in the superScript list). Triple primes plus super: `f'''^{2x}` → superScript = `[\prime, \prime, \prime, 2, x]`.
- prime followed by `_`: `f'_n` should produce one atom `f` with `superScript = [\prime]` and `subScript = [n]`.
- regression: explicit `\prime` still parses as Ord U+2032 (untouched path).
- `mathListToString:` round-trip: `f'` should serialize to `f^{\prime }` (because the reverse path emits `\prime ` for the prime atom inside the superscript). The trailing space is a quirk of `appendLaTeXToString:` — see `MTMathList.m:294`. Test should match existing project conventions. The merged form `f^{\prime 2}` should round-trip as such.

In `MTTypesetterTest.m`:

- `testLatexSymbols` already covers `\prime` rendering and continues to.
- No new typesetter test is strictly required; the layout path is unchanged.

### 8.2 Feature 2 — Negated Relations

**Files to edit**

- `iosMath/lib/MTMathAtomFactory.m` — extend `+supportedLatexSymbols` only.

**Symbols and codepoints (Rel class)**

| Command | Codepoint |
|---|---|
| `\nleq` | U+2270 |
| `\ngeq` | U+2271 |
| `\nless` | U+226E |
| `\ngtr` | U+226F |
| `\nsubseteq` | U+2288 |
| `\nsupseteq` | U+2289 |
| `\nmid` | U+2224 |
| `\nparallel` | U+2226 |
| `\nleftarrow` | U+219A |
| `\nrightarrow` | U+219B |
| `\nLeftarrow` | U+21CD |
| `\nRightarrow` | U+21CF |
| `\nleftrightarrow` | U+21AE |
| `\nLeftrightarrow` | U+21CE |
| `\nvdash` | U+22AC |
| `\nvDash` | U+22AD |
| `\nVdash` | U+22AE |
| `\nVDash` | U+22AF |
| `\ntriangleleft` | U+22EA (AMS, see §7.6) |
| `\ntriangleright` | U+22EB (AMS, see §7.6) |
| `\ntrianglelefteq` | U+22EC (AMS, see §7.6) |
| `\ntrianglerighteq` | U+22ED (AMS, see §7.6) |
| `\nsim` | U+2241 (AMS) |
| `\ncong` | U+2247 (AMS) |
| `\nequiv` | U+2262 (AMS) |
| `\nsubset` | U+2284 (AMS) |
| `\nsupset` | U+2285 (AMS) |
| `\nsucc` | U+2281 (AMS) |
| `\nprec` | U+2280 (AMS) |
| `\nsucceq` | U+2AB1 (AMS — note rare in some fonts; see Risks) |
| `\npreceq` | U+2AB0 (AMS — note rare in some fonts; see Risks) |

**Parser implications:** none — flows through `atomForLatexSymbolName:` (§3.3 path 4a).

**Render implications:** none — uniform Ord/Rel/Bin renderer in `MTTypesetter.m:818`. Each codepoint lives in the AMS extension blocks (U+22XX, U+219X-U+21CF) which are present in the bundled OpenType MATH fonts.

**Spacing implications:** Rel-class spacing is already in the rule-16 matrix.

**Risks / regressions**

- **Font-coverage**: missing glyphs in any of the three bundled fonts will make `testLatexSymbols` fail with a zero-width assertion. The U+22XX block is well-supported by all three bundled fonts, but **U+2AB0 / U+2AB1 (`\npreceq` / `\nsucceq`) live in the Supplemental Mathematical Operators block** which has spottier coverage. The LLD must run the (recommended) three-font sweep of `testLatexSymbols` (§9) and, if a glyph is missing in any font, decide whether to drop the symbol or accept partial coverage.
- No nucleus collisions with existing symbols.
- `\nvDash` vs `\nvdash` and `\nVdash` vs `\nVDash` — case matters; the parser is case-sensitive (`readString` at `MTMathListBuilder.m:257` preserves case); no ambiguity.

**Validation strategy**

- Add a parser-test parameterized over the 18 commands: parse `\<cmd>`, assert `list.atoms.count == 1`, type `kMTMathAtomRelation`, nucleus equals expected codepoint.
- Add a round-trip parameterized check: `mathListToString:` round-trips `\nleq` to `\nleq ` (with trailing space — see `MTMathList.m:294`).
- `testLatexSymbols` autoexpands and re-validates rendering.
- A small spacing test like `a \nleq b` should produce three display sub-displays with expected inter-element spacing — but this is not strictly required since rule-16 is already exhaustively tested in `testSpacing`.

### 8.3 Feature 3 — Harpoons and Extended Arrows

**Files to edit**

- `iosMath/lib/MTMathAtomFactory.m` — extend `+supportedLatexSymbols`.

**Symbols and codepoints (Rel class)**

| Command | Codepoint |
|---|---|
| `\rightleftharpoons` | U+21CC |
| `\leftrightharpoons` | U+21CB |
| `\upharpoonleft` | U+21BF |
| `\upharpoonright` | U+21BE |
| `\downharpoonleft` | U+21C3 |
| `\downharpoonright` | U+21C2 |
| `\rightharpoonup` | U+21C0 |
| `\leftharpoonup` | U+21BC |
| `\rightharpoondown` | U+21C1 |
| `\leftharpoondown` | U+21BD |
| `\hookleftarrow` | U+21A9 |
| `\hookrightarrow` | U+21AA |
| `\twoheadleftarrow` | U+219E |
| `\twoheadrightarrow` | U+21A0 |
| `\rightarrowtail` | U+21A3 |
| `\leftarrowtail` | U+21A2 |

All Rel. The naming pattern matches the existing arrow symbols at `MTMathAtomFactory.m:506-528`.

**Parser, render, spacing implications:** identical to Feature 2 — none beyond a dictionary edit.

**Risks / regressions**

- Same font-coverage risk as Feature 2. Same mitigation: rely on `testLatexSymbols` to exercise every glyph.
- Requirements doc explicitly excludes stretchy/extensible arrows. The existing `MTMathStack` machinery can stretch a small set of glyphs (rightarrow, leftarrow, leftrightarrow, brace), but the new harpoons should NOT be added to `stackCommands` — they are bare-arrow symbols only, not "over-arrow" commands.
- No collisions.

**Validation strategy** — identical to Feature 2 (parameterized parser test + round-trip + automatic typesetter sweep).

### 8.4 Feature 4 — Missing Common Relations and Ordinaries

**Files to edit**

- `iosMath/lib/MTMathAtomFactory.m` — `+supportedLatexSymbols` (remove the existing `\square` entry; add the symbols listed below). The existing `\square → placeholder` mapping is replaced by an alias `\square → \Box` in `+aliases` (covered in Feature 6, §8.6).

**Symbols, codepoints, classification (per AMS `amssymb` convention)**

| Command | Codepoint | TeX class | Notes |
|---|---|---|---|
| `\vdash` | U+22A2 | Rel ||
| `\dashv` | U+22A3 | Rel ||
| `\Subset` | U+22D0 | Rel ||
| `\Supset` | U+22D1 | Rel ||
| `\backsim` | U+223D | Rel ||
| `\backsimeq` | U+22CD | Rel ||
| `\eqsim` | U+2242 | Rel ||
| `\Bumpeq` | U+224E | Rel ||
| `\bumpeq` | U+224F | Rel ||
| `\therefore` | U+2234 | Rel ||
| `\because` | U+2235 | Rel ||
| `\multimap` | U+22B8 | Rel ||
| `\complement` | U+2201 | Ord ||
| `\Box` | U+25A1 | Ord | replaces the existing `\square → placeholder` mapping; `\square` becomes an alias to `\Box` (Feature 6). See §7.4 |
| `\Diamond` | U+25C7 | Ord | AMS canonical (§7.5) |
| `\lozenge` | U+25CA | Ord | AMS-related (§7.5) |
| `\blacklozenge` | U+29EB | Ord | AMS-related (§7.5) |
| `\diamondsuit` | U+2662 | Ord | plain TeX, AMS-related |
| `\heartsuit` | U+2661 | Ord | plain TeX, AMS-related |
| `\spadesuit` | U+2660 | Ord | plain TeX, AMS-related |
| `\clubsuit` | U+2663 | Ord | plain TeX, AMS-related |
| `\beth` | U+2136 | Ord ||
| `\gimel` | U+2137 | Ord ||
| `\daleth` | U+2138 | Ord ||
| ~~`\vartriangle`~~ | — | — | **alias** to `\triangle` (same Ord/U+25B3) — see Feature 6, §8.6 |
| `\triangledown` | U+25BD | Ord | AMS-related (§7.6) |
| `\vartriangleleft` | U+22B2 | Rel | AMS-related (§7.6) |
| `\vartriangleright` | U+22B3 | Rel | AMS-related (§7.6) |
| `\trianglelefteq` | U+22B4 | Rel | AMS-related (§7.6) |
| `\trianglerighteq` | U+22B5 | Rel | AMS-related (§7.6) |
| `\triangleq` | U+225C | Rel | AMS-related (§7.6) |
| `\blacktriangle` | U+25B2 | Ord | AMS-related (§7.6) |
| `\blacktriangledown` | U+25BC | Ord | AMS-related (§7.6) |
| `\blacktriangleleft` | U+25C0 | Ord | AMS-related (§7.6) |
| `\blacktriangleright` | U+25B6 | Ord | AMS-related (§7.6) |

**Parser, render implications:** standard — symbol-table addition only.

**Spacing implications**

- Rel-class symbols pick up Rel spacing (`\therefore` and `\because` are listed under "punctuation-like" in some ecosystems; TeXbook puts them as Rel and so does AMS — this matches the Rel choice above). The requirements doc explicitly says "Symbols must be categorized correctly as: relation / binary operator / ordinary / punctuation depending on TeX semantics" — the table above reflects TeX semantics.
- Ord-class symbols pick up Ord spacing.

**Risks / regressions**

- **`\square → placeholder` removal** — see §7.4. Existing test suites use `+placeholder` directly (`MTMathListTest.m:134-293`), not the `\square` LaTeX form, so removing the mapping is safe. The semantic change for any external client that typed `\square` expecting a placeholder atom is intentional: `\square` now produces an AMS-canonical Ord, which is the standard meaning. No code in this repo depends on the old behavior.
- **Triangle nucleus sharing** (§7.6): `\vartriangle` is handled via the alias mechanism (Feature 6) since it shares both type and nucleus with `\triangle`. `\bigtriangleup` (Bin, U+25B3) and `\bigtriangledown` (Bin, U+25BD) are registered as separate entries (Feature 5) because they differ in type from `\triangle` and `\triangledown` respectively. Round-trip behavior at the shared nuclei is documented in §7.6.
- `\vdash` (U+22A2) does **not** collide with `\nvdash` (U+22AC) — different codepoints.
- **Font coverage**: U+29EB (`\blacklozenge`) and U+225C (`\triangleq`) are in less-common blocks. The three-font sweep of `testLatexSymbols` (§9) is the safety net; if a glyph is missing, drop the symbol or accept partial coverage.
- No other collisions.

**Validation strategy**

- Parameterized parser test (one row per symbol): assert type is the expected class and nucleus is the expected codepoint.
- **`\Box` and `\square`**: parse both, assert both produce an Ord atom with nucleus U+25A1 (verifies the alias resolution). Round-trip both: both should serialize to `\Box` (the only canonical for U+25A1; aliases do not survive the reverse map per §6.2).
- **Placeholder regression**: construct `[MTMathAtomFactory placeholder]`, assert `atom.type == kMTMathAtomPlaceholder` and `atom.nucleus == @"□"`. This documents that the editor's placeholder construction path is unchanged.
- **Spacing regression check**: a snippet like `a \therefore b` should produce three atoms with NSThick spacing on either side of the Rel — covered automatically by the existing `testSpacing` machinery if a parameterized rendering test is added.
- `testLatexSymbols` auto-expansion.

### 8.5 Feature 5 — Boxed and Circled Binary Operators

**Files to edit**

- `iosMath/lib/MTMathAtomFactory.m` — `+supportedLatexSymbols`.

**Symbols, codepoints, classification (all Bin)**

| Command | Codepoint |
|---|---|
| `\boxplus` | U+229E |
| `\boxminus` | U+229F |
| `\boxtimes` | U+22A0 |
| `\boxdot` | U+22A1 |
| `\circledast` | U+229B |
| `\circledcirc` | U+229A |
| `\circleddash` | U+229D |
| `\barwedge` | U+22BC |
| `\veebar` | U+22BB |
| `\triangleleft` | U+25C1 (plain TeX & AMS canonical — see §7.6) |
| `\triangleright` | U+25B7 (plain TeX & AMS canonical — see §7.6) |

**Parser, render implications:** none beyond dictionary edit.

**Spacing implications**

- `kMTMathAtomBinaryOperator` is rule-5/6-rewritten in `MTMathList.finalized` — `\boxplus` at the start of an expression (or after a Rel/Open/Punct) becomes Ordinary automatically. This is correct TeX behavior, identical to existing `\oplus`. Verify with a test.

**Risks / regressions**

- Font coverage of U+25C1 / U+25B7 is universal in math fonts. The three-font sweep of `testLatexSymbols` (§9) confirms.
- No nucleus collisions.

**Validation strategy**

- Parameterized parser test (11 entries).
- Specific test for rule-5/6: parse `\boxplus a` and after `finalized` assert the leading `\boxplus` is reclassified to `kMTMathAtomUnaryOperator` (which becomes Ord in preprocessing). Mirrors the established pattern for existing Bin symbols.
- `testLatexSymbols` sweep.

### 8.6 Feature 6 — Aliases

**Files to edit**

- `iosMath/lib/MTMathAtomFactory.m` — extend `+aliases` (line 709) only.

**Aliases**

| Alias | Canonical | Required prerequisite |
|---|---|---|
| `\implies` | `\Longrightarrow` | already present |
| `\impliedby` | `\Longleftarrow` | already present |
| `\restriction` | `\upharpoonright` | **must land with Feature 3 (or after)** |
| `\dotsc` | `\ldots` | already present |
| `\dotsb` | `\cdots` | already present |
| `\dotsm` | `\cdots` | already present |
| `\dotsi` | `\ldots` | already present |
| `\square` | `\Box` | **must land with Feature 4** (which removes the existing `\square → placeholder` entry and adds `\Box`). See §7.4 |
| `\vartriangle` | `\triangle` | already present — same Ord/U+25B3 → alias per §6.3 |

**Parser, render, spacing implications:** none — alias resolution happens in `atomForLatexSymbolName:` before symbol lookup (§6.1).

**Risks / regressions**

- **Sequencing with Feature 3** — see §6.3. Either land Features 3+6 in the same change, or sequence Feature 3 first.
- **Sequencing with Feature 4** — `\square` aliasing requires Feature 4 to register `\Box` and remove the existing `\square → placeholder` entry. Land both in the same PR or sequence Feature 4 first.
- **Round-trip semantics** — aliases do not survive a `mathListToString:` round-trip; they are normalized to the canonical name. See §6.2. This matches existing `\le → \leq`, `\to → \rightarrow`, `\iff → \Longleftrightarrow` behavior, so it is acceptable per project convention. After this PR, `\square` round-trips to `\Box`.
- **No context-sensitive dots** — the requirements explicitly disallow this. `\dotsb` and `\dotsm` both alias to `\cdots` regardless of surrounding context. If a reviewer expects `\dotsb` to render correctly after a binary operator and `\dotsi` correctly after an integral, they should be reminded the requirements specifically scope this out.

**Validation strategy**

- Parameterized parser test: parse `\implies` (and the others), assert atom type and nucleus match the canonical.
- Round-trip test: `\implies` → `\Longrightarrow` (matching existing `\le → \leq` precedent at `MTMathListBuilderTest.m:67`).
- `\restriction` round-trip: produces `\upharpoonright`.
- `\square` round-trip: produces `\Box` (post-Feature-4).

### 8.7 Feature 7 — Round-Trip Type Preservation at Shared Nuclei

**Problem**

The reverse map `textToLatexSymbolNames` (`MTMathAtomFactory.m:732`) is keyed by nucleus only. When two `+supportedLatexSymbols` entries share a nucleus but differ in `MTMathAtomType`, the shorter-then-alphabetical tie-break collapses both into a single canonical, regardless of type. A `\bigtriangleup` (Bin, U+25B3) atom round-trips as `\triangle` (Ord, U+25B3); re-parsing the output gives an Ord atom, so rule-16 spacing changes and the render differs from the original. Same shape at U+25BD (`\bigtriangledown` Bin → `\triangledown` Ord).

This requirement is: **only true aliases (same nucleus AND same type) should canonicalize on round-trip. When two entries share a nucleus but differ in type, round-trip must preserve the type. The shorter-then-alphabetical tie-break only applies as a tie-breaker within a single (nucleus, type) cell.**

The bug is latent today (no current entry has a (nucleus, type) collision in the active table) but surfaces immediately once Features 4 and 5 land — they introduce the U+25B3 Ord/Bin pair (`\triangle` / `\bigtriangleup`) and the U+25BD Ord/Bin pair (`\triangledown` / `\bigtriangledown`).

**Files to edit**

- `iosMath/lib/MTMathAtomFactory.m` — `+textToLatexSymbolNames` (line 732), `+latexSymbolNameForAtom:` (line 184).

**Design**

Re-key the reverse map by `(nucleus, MTMathAtomType)` rather than nucleus alone. Two natural shapes:

1. Nested dict: `NSDictionary<NSString*, NSDictionary<NSNumber*, NSString*>>` (nucleus → type → name).
2. Flat dict with composite key: `NSDictionary<NSString*, NSString*>` keyed by `[NSString stringWithFormat:@"%@|%lu", nucleus, (unsigned long)type]`.

Either works; the nested form is slightly cleaner for debugging and is what this document recommends. The build loop iterates `supportedLatexSymbols` once and inserts into the cell selected by both `prototype.nucleus` and `prototype.type`. The within-cell tie-break (shorter, then alphabetical) is unchanged.

`+latexSymbolNameForAtom:` (`MTMathAtomFactory.m:184`) needs a one-line change: instead of `textToLatexSymbolNames[atom.nucleus]`, look up `textToLatexSymbolNames[atom.nucleus][@(atom.type)]` (nested form) or the composite key (flat form).

**Build-loop change**

Today (paraphrased):
```
for (cmd, prototype) in supportedLatexSymbols:
    existing = output[prototype.nucleus]
    if existing == nil || winsTieBreak(cmd, existing):
        output[prototype.nucleus] = cmd
```

After:
```
for (cmd, prototype) in supportedLatexSymbols:
    cell = output[prototype.nucleus] ?: new mutable inner dict
    existing = cell[@(prototype.type)]
    if existing == nil || winsTieBreak(cmd, existing):
        cell[@(prototype.type)] = cmd
    output[prototype.nucleus] = cell
```

`winsTieBreak(a, b)` is the existing "shorter, then alphabetical-ascending" predicate.

**Effects**

- `\bigtriangleup` (Bin/U+25B3) round-trips as `\bigtriangleup`. `\triangle` (Ord/U+25B3) round-trips as `\triangle`. The two atoms occupy different cells.
- `\bigtriangledown` (Bin/U+25BD) round-trips as `\bigtriangledown`. `\triangledown` (Ord/U+25BD) round-trips as `\triangledown`.
- `\Box` (Ord/U+25A1) is the only entry at that (nucleus, type) cell → still round-trips as `\Box`. The `\square` alias is excluded from the reverse map per §6.2 and is unaffected.
- Every existing single-entry-per-nucleus symbol is unaffected — its (nucleus, type) cell has only one occupant, and the within-cell tie-break is degenerate.
- Aliases (`+aliases`) remain excluded from the reverse map. `\le → \leq`, `\iff → \Longleftrightarrow`, `\implies → \Longrightarrow` round-trip behavior is unchanged.

**Parser, render, spacing implications:** none. The change is purely in the reverse-serialization path.

**Risks / regressions**

- **Pre-existing same-nucleus-same-type collisions.** Per §6.3 the design rule says these should be aliases, not two entries. The LLD should grep `+supportedLatexSymbols` for any nucleus that currently appears twice with the same type and confirm the result is empty (or convert any survivors into aliases). The within-cell tie-break still handles the case correctly if one is found, but architecturally those should be aliases.
- **`MTMathAtomVariable` / `MTMathAtomNumber`.** `MTTypesetter.preprocessMathList:` (`MTTypesetter.m:511`) rewrites these to Ord at layout time — but `mathListToString:` runs against the finalized (not preprocessed) list, so `Variable` and `Number` atoms still carry their original type when they hit the reverse map. None of the current `supportedLatexSymbols` entries use these types, so there is no collision risk; document this in the LLD anyway.
- **Reverse-map memory.** The change adds one inner dict per distinct nucleus. With ~190 current entries plus ~80 new ones, this is negligible.
- **Lazy initialization.** The dispatch-once guard around `+textToLatexSymbolNames` is preserved; the build loop still runs exactly once per process.

**Validation strategy**

Add to `MTMathListBuilderTest.m` a bespoke test (suggested name `testRoundTripTypePreservation` or extend the existing round-trip table):

- Parse `\bigtriangleup`, run through `mathListToString:`, assert output is `\bigtriangleup ` (with trailing space, matching `MTMathList.m:294`). Same for `\triangle` → `\triangle `.
- Parse `\bigtriangledown` and `\triangledown`; assert each round-trips to itself.
- Parse `\bigtriangleup a` and `\triangle a`, lay out both, and assert different inter-element spacing (Bin gets thick-mu spacing before its left neighbor when the left is Ord; Ord-Ord gets none). This anchors the end-to-end behavior — finalize + reverse-map + parse + finalize + layout.
- All existing round-trip tests at `MTMathListBuilderTest.m:67` and the `testLatexSymbols` sweep must continue to pass unchanged.

**Sequencing**

Land Feature 7 with or before Features 4 and 5. Two viable plans:

1. **Feature 7 first, alone** (recommended). It changes only reverse-serialization; behavior on the current symbol table is unchanged because no current entry has a (nucleus, type) collision. The PR is small, easy to review, and de-risks Features 4/5.
2. **Feature 7 bundled with 4+5.** Single PR introduces the collisions and the fix together. Larger PR but no intermediate state.

Landing Features 4 or 5 *without* Feature 7 ships a round-trip regression at U+25B3 and U+25BD. Do not do this.

---

## 9. Test Coverage Gaps and the `testLatexSymbols` Sweep

### 9.1 The auto-sweep is your safety net

`MTTypesetterTest.m:1292 testLatexSymbols` iterates `+[MTMathAtomFactory supportedLatexSymbolNames]` and for each:

- builds an atom via `atomForLatexSymbolName:`
- lays it out in display style
- asserts `display != nil`
- asserts the sub-display is an `MTCTLineDisplay` (or `MTGlyphDisplay` for single-char large operators)
- asserts the rendered string equals the nucleus
- **asserts width > 0 and ascent+descent > 0** for non-space chars

**Every newly-registered symbol auto-flows through this test.** The width/ascent assertions are the practical font-coverage check. If a codepoint is missing or the font assigns it a zero-advance .notdef glyph, the test will fail.

This means:

- The risk of "we registered the symbol but the font doesn't have it" is *caught*, not silent — for the default font.
- It is sufficient to re-run `MTTypesetterTest` after adding entries — no per-symbol smoke test is needed.

**However**, today's `testLatexSymbols` runs only against `MTFontManager.fontManager.defaultFont`, which is Latin Modern Math (`MTFontManager.m:74`). XITS Math and TeX Gyre Termes Math are bundled but never sweep-tested. Several requested symbols live in less-common Unicode blocks (e.g. U+29EB `\blacklozenge`, U+2AB0/2AB1 `\npreceq`/`\nsucceq`, U+225C `\triangleq`) where font coverage may diverge.

**The LLD should extend `testLatexSymbols` to sweep all three bundled fonts.** Concretely: parameterize the existing test loop over an array of three fonts (`latinModernFontWithSize:`, `xitsFontWithSize:`, `termesFontWithSize:` on `MTFontManager`), running the same per-symbol assertions against each. The shape:

```objc
- (void) testLatexSymbols
{
    NSArray<MTFont*>* fonts = @[
        [MTFontManager.fontManager latinModernFontWithSize:kDefaultFontSize],
        [MTFontManager.fontManager xitsFontWithSize:kDefaultFontSize],
        [MTFontManager.fontManager termesFontWithSize:kDefaultFontSize],
    ];
    NSArray<NSString*>* allSymbols = [MTMathAtomFactory supportedLatexSymbolNames];
    for (MTFont* font in fonts) {
        for (NSString* symName in allSymbols) {
            // existing assertions, using `font` instead of `self.font`
        }
    }
}
```

(Or three sibling test methods — `testLatexSymbols_LatinModern`, `testLatexSymbols_XITS`, `testLatexSymbols_Termes` — for clearer failure messages.) This catches the failure mode where a glyph is registered but missing from one of the math fonts (cmap returns `.notdef`, leaving width=0). Same loop, three font instances. Failure messages should include the font name so coverage gaps can be diagnosed quickly.

### 9.2 What `testLatexSymbols` does **not** cover

- Spacing class correctness — the test only checks per-glyph layout, not inter-element spacing. A symbol incorrectly classified as Ord instead of Rel would still pass `testLatexSymbols`. **A spacing test specifically per feature is therefore valuable**, especially for the Rel/Bin distinction in Features 2/4/5.
- Round-trip serialization — covered by parser tests, not the typesetter sweep.
- Aliases — `+supportedLatexSymbolNames` returns only canonical entries. Aliases need separate parser tests.
- The `\Box ↔ \square` collision (§7.4) — neither catches it. **Bespoke regression test required.**

### 9.3 Existing test conventions (worth matching)

- Parser tests use a "data table" pattern (`getTestData()` returning an `NSArray` of triples). Add new tests in this style — see `MTMathListBuilderTest.m:47`, `:94`, `:144`, `:1147`.
- `checkAtomTypes:types:desc:` (`MTMathListBuilderTest.m:23`) is the standard helper.
- Tests roundtrip every input through `mathListToString:` and assert against the expected canonical LaTeX form (`MTMathListBuilderTest.m:88-90` and similar). Match this convention.
- Error tests live in `getTestDataParseErrors` (`MTMathListBuilderTest.m:1147`); add an `'` (apostrophe) entry only if the LLD chooses to error in some cases — Feature 1's current design is "no error, accept all".

### 9.4 Suggested new test scaffolding

Per feature, structure new tests as one parameterized data-table-style test method per category:

- `testNegatedRelations` — 18 rows
- `testHarpoons` — 16 rows
- `testMissingRelationsAndOrdinaries` — 18 rows
- `testBoxedCircledOperators` — 11 rows
- `testNewAliases` — 7 rows
- `testPrimes` — bespoke (single, double, triple, with super, with no prevAtom, inside braces)
- `testBoxSquareCollision` — bespoke regression test for §7.4

This keeps PR-noise low and the tests greppable.

---

## 10. Architectural Constraints to Respect

1. **Single source of truth for command tables.** Aliases, accents, delimiters, fontStyles, and supportedLatexSymbols are each owned by exactly one accessor in `MTMathAtomFactory`. New symbols must go into the corresponding dictionary; do not create parallel lookup paths.

2. **One Unicode codepoint per nucleus.** Every existing symbol nucleus is a single Unicode character (or surrogate pair). The typesetter's glyph-fusion logic (`MTTypesetter.preprocessMathList:` at `:523`) merges adjacent Ord atoms by **string concatenation of nuclei**, then the CoreText-line builder adds them as one line. Multi-character nuclei work for Ord (the merge result is a string), but **don't try to be clever** with synthetic `\not`-overlay nuclei — the requirements explicitly rule this out, and it would interact badly with kerning, italic correction, and the OpenType MATH table.

3. **`MTMathAtomType` discrimination drives spacing.** The mistake to avoid is registering an arrow as Ord because "the user only ever uses it inline". Rule-16 is global; Rel arrows must be Rel.

4. **`finalized` runs after parsing, before layout.** Bin→Un conversion is automatic. Don't try to distinguish Bin and Un at registration time — register everything that's morphologically Bin as Bin, let `finalized` decide.

5. **`atomForCharacter:` is used by both the parser and `mathListForCharacters:`.** Avoid changing its semantics for Feature 1; handle `'` in `buildInternal:` directly.

6. **`textToLatexSymbolNames` should be keyed by (nucleus, type).** Today it is keyed by nucleus alone, which collapses type-distinct entries into a single canonical and breaks round-trip rendering at U+25B3 / U+25BD (Feature 7, §8.7). Type-identical collisions at the same nucleus should be aliases (§6.3), not two entries — the within-cell tie-break (shorter, then alphabetical) is a safety net, not a design choice.

7. **Aliases resolve before symbol lookup, but reverse lookup ignores aliases.** This is by design and consistent across the code base. Don't try to make aliases survive round-trips without a deeper redesign.

8. **`MTMathStack` is for stretchy over/under arrow constructions** — not for the new bare arrows in Feature 3. Don't conflate `\hookrightarrow` (a Rel atom) with `\overrightarrow` (a stack atom that wraps a base).

9. **No font-asset changes** — the requirements forbid this. The implementation must work with the bundled fonts as-shipped.

---

## 11. Recommended Implementation Strategy

The requirements doc's suggested order is:

> 1 Prime → 2 Aliases → 3 Negated relations → 4 Missing relations/ordinaries → 5 Harpoons/arrows → 6 Boxed/circled operators

This document recommends:

> **0 Round-trip type preservation (Feature 7)** → 1 Prime → **2 Harpoons** → **3 Aliases** → 4 Negated relations → 5 Missing relations/ordinaries → 6 Boxed/circled operators

Two reasons for the adjustment:

1. **Feature 7 first.** Re-keying the reverse map by (nucleus, type) is a prerequisite for Features 4 and 5, which introduce the U+25B3 and U+25BD type collisions. Landing Feature 7 alone is a small, low-risk PR with no behavior change on the current table; landing it before symbol additions de-risks every later feature that introduces a shared nucleus.
2. **Harpoons before Aliases.** `\restriction` aliases to `\upharpoonright`, which is part of Harpoons. Landing aliases before harpoons creates a temporarily-broken alias. Bundling Harpoons + Aliases in one PR is an acceptable alternative.

Per-feature implementation guidance:

- **Feature 7 (round-trip type preservation)**: re-key `textToLatexSymbolNames` by (nucleus, type). Update `latexSymbolNameForAtom:` to look up by both. Add the bespoke regression test from §8.7. Land first.
- **Feature 1 (prime)**: implement the TeX-canonical algorithm in §8.1 (greedy `'` consumption + `\futurelet`-style merge of trailing `^`). The `^` merge is the only non-trivial bit; isolate it inside the prime handler so the existing `^` branch stays untouched.
- **Features 2, 3, 4, 5 (symbol tables)**: dictionary additions only. The mechanical work is largely identical for each. Run the three-font `testLatexSymbols` (§9) after each feature lands to catch any font-coverage surprise immediately.
- **Feature 4 + `\Box`**: remove the existing `\square → placeholder` entry from `+supportedLatexSymbols` and register `\Box` (Ord, U+25A1) in the same change. Pair with Feature 6 to add `\square → \Box` as an alias. Add a placeholder regression test (`+placeholder` factory still produces a placeholder atom) and a `\square`/`\Box` parity test in the same PR.
- **Feature 6 (aliases)**: ride the same PR as Feature 3 (for `\restriction`) and Feature 4 (for `\square`), or sequence after both.

The single additional test-infra change is extending `testLatexSymbols` to sweep all three bundled fonts (§9). Everything else ships under existing test infrastructure.

---

## 12. Open Questions

The following items were open in earlier drafts but are now resolved (see referenced sections for the rationale):

- ~~**Prime-then-superscript semantics**~~ → resolved: implement TeX-canonical merge per the algorithm in §8.1. `f'^2 → f^{\prime 2}`.
- ~~**`\Box` glyph choice**~~ → resolved (§7.4): remove the existing `\square → placeholder` entry; register `\Box` at U+25A1 (Ord); add `\square → \Box` to the alias table. The `+placeholder` factory remains the editor's API for placeholders.
- ~~**`\Diamond` glyph choice**~~ → resolved (§7.5): U+25C7 (AMS canonical). Add related `\lozenge`, `\blacklozenge`, `\diamondsuit`, `\heartsuit`, `\spadesuit`, `\clubsuit` as Ord per AMS — see §8.4.
- ~~**`\triangleleft` / `\triangleright` glyph choice**~~ → resolved (§7.6): U+25C1 / U+25B7 (matches both plain TeX and AMS canonical). Add the AMS triangle family — `\vartriangle`, `\triangledown`, `\vartriangleleft`/`\vartriangleright` (Rel), `\trianglelefteq`/`\trianglerighteq` (Rel), `\triangleq` (Rel), `\blacktriangle*` (Ord), and the negated relations `\ntriangleleft*`/`\ntriangleright*` (Rel, in Feature 2).
- ~~**Per-font font-coverage testing**~~ → resolved: extend `testLatexSymbols` to sweep all three bundled fonts. See §9.
- ~~**Error vs silent-skip for `'` in `atomForCharacter:`**~~ → resolved: keep `atomForCharacter:` rejecting `'`; handle primes only in `buildInternal:`.
- ~~**Round-trip lossiness at shared nuclei**~~ → resolved as **Feature 7** (§8.7): re-key the reverse map by (nucleus, type) so type-distinct entries each preserve their own canonical name. Land before or with Features 4 and 5.

Remaining decisions for the LLD author:

1. **Sequencing**: land `Harpoons + Aliases` together to avoid temporary `\restriction` breakage, or land Harpoons in PR #N and Aliases in PR #N+1? (Project-policy question, not codebase-derivable.)

2. **Symbols with sparse font coverage**: if the three-font sweep of `testLatexSymbols` flags missing glyphs in any of the three bundled fonts (most likely candidates: U+29EB `\blacklozenge`, U+2AB0/2AB1 `\npreceq`/`\nsucceq`, U+225C `\triangleq`), should the symbol be dropped from the registration table or kept with the test marked expected-fail for that font? Recommendation: keep registered, document the gap; users can swap to a font that supports it.

3. **Feature 7 packaging**: land Feature 7 as a standalone PR before Features 4/5 (recommended — small, low-risk, no behavior change on the current table) or bundle it with Features 4+5 in one PR? (Project-policy question.)

---

*End of research document.*
