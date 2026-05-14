# New Symbol & Shorthand Support — Low-Level Design

## 1. Summary / Goals

Expand iosMath's LaTeX compatibility surface to cover the symbol set defined in
[iosMath_feature_requirements.md](../../iosMath_feature_requirements.md) and the
codebase findings collected in
[new-symbols-research.md](../../new-symbols-research.md). The work decomposes
into seven orthogonal pieces:

1. Prime shorthand (`'`) in the parser.
2. ~30 negated-relation symbols from `amssymb`.
3. ~16 harpoon and extended-arrow symbols.
4. ~25 missing relations / ordinaries (logic, set theory, Hebrew letters, the
   triangle and lozenge / suit families) plus the `\Box ↔ \square` cleanup.
5. ~11 boxed and circled binary operators.
6. ~9 lightweight aliases.
7. Round-trip type preservation: re-key the reverse symbol map by
   `(nucleus, type)` so the U+25B3 / U+25BD pairs introduced by §4 + §5 do not
   regress.

**Non-goals:** new atom types, new fonts, stretchy/extensible arrows,
context-sensitive `\dotsb` / `\dotsi` selection, generic `\not` composition,
AMS environment support, or macro-expansion machinery. The requirements doc
explicitly excludes all of these.

The LLD ends at the design boundary; implementation is left to the plan that
follows.

---

## 2. Current Code-base Findings

### 2.1 Symbol registration

`+supportedLatexSymbols` is a single static dictionary built lazily inside
`MTMathAtomFactory` and returned mutable `[verified: iosMath/lib/MTMathAtomFactory.m:439]`.
It maps a command name (no leading `\`) to a prototype `MTMathAtom`; lookups
go through `+atomForLatexSymbolName:` which consults aliases first
`[verified: iosMath/lib/MTMathAtomFactory.m:164]`. The runtime escape hatch
`+addLatexSymbol:value:` updates both forward and reverse maps and is not the
right home for built-in symbols `[verified: iosMath/lib/MTMathAtomFactory.m:193]`.

`\prime` is already registered as Ord at U+2032, so prime shorthand can reuse
the existing prototype `[verified: iosMath/lib/MTMathAtomFactory.m:666]`.

`\square` is currently mapped to a placeholder atom (`kMTMathAtomPlaceholder`,
nucleus `MTSymbolWhiteSquare = "□"`)
`[verified: iosMath/lib/MTMathAtomFactory.m:444]`,
`[verified: iosMath/lib/MTMathAtomFactory.m:65]`,
`[verified: iosMath/lib/MTMathAtomFactory.m:18]`. Per the inline comment at
`MTMathList.h:51` the placeholder type "does not exist in TeX"
`[verified: iosMath/lib/MTMathList.h:51]` — wiring it to a LaTeX command is a
layering accident.

### 2.2 Aliases

`+aliases` holds 13 entries today; resolution happens in
`+atomForLatexSymbolName:` *before* the symbol lookup, by string indirection
into `supportedLatexSymbols`
`[verified: iosMath/lib/MTMathAtomFactory.m:709]`,
`[verified: iosMath/lib/MTMathAtomFactory.m:164]`. There is no chained alias
support and no cycle detection.

### 2.3 Reverse map (round-trip serialization)

`+textToLatexSymbolNames` is keyed by **nucleus alone**
`[verified: iosMath/lib/MTMathAtomFactory.m:732]`. Its build loop iterates
`supportedLatexSymbols`; on collision the tie-break is "shorter command wins,
then alphabetical-ascending"
`[verified: iosMath/lib/MTMathAtomFactory.m:744-758]`. Aliases are *not*
inserted, so `\le` round-trips as `\leq`, `\to` as `\rightarrow`, etc.
`+latexSymbolNameForAtom:` consults this map with `atom.nucleus`
`[verified: iosMath/lib/MTMathAtomFactory.m:184]` and is called from the base
`-appendLaTeXToString:` `[verified: iosMath/lib/MTMathList.m:281-299]` which is
in turn driven by `+mathListToString:`
`[verified: iosMath/lib/MTMathListBuilder.m:798]`.

The map is type-blind. Any two `supportedLatexSymbols` entries that share a
nucleus collapse to a single canonical regardless of their `MTMathAtomType`. No
current entry triggers this, but Features 4 and 5 introduce two collisions
(U+25B3 Ord/Bin, U+25BD Ord/Bin) — see §3.4 / §5.

### 2.4 Parser dispatch

`-buildInternal:stopChar:` is a `unichar`-by-`unichar` scanner
`[verified: iosMath/lib/MTMathListBuilder.m:106-255]`. The relevant branches:

- `^` (line 131): if the previous atom already has a superscript, allocates a
  fresh empty Ord and treats the new `^` as that Ord's superscript
  `[verified: iosMath/lib/MTMathListBuilder.m:131-143]`.
- `\` (line 174): reads a command and dispatches via `stopCommand`,
  `applyModifier`, `fontStyleWithName`, `atomForCommand`
  `[verified: iosMath/lib/MTMathListBuilder.m:174-213]`.
- catch-all (line 228): `+atomForCharacter:`. If it returns nil the character
  is silently dropped `[verified: iosMath/lib/MTMathListBuilder.m:228-232]`.

`+atomForCharacter:` explicitly rejects `'` along with the other LaTeX control
characters `[verified: iosMath/lib/MTMathAtomFactory.m:112]`. Consequently
`f'` parses today as `f` with no error and no warning. `mathListForCharacters:`
also goes through this rejection list
`[verified: iosMath/lib/MTMathAtomFactory.m:148-162]`, which is why we must
not relax it (it would change `fractionWithNumeratorStr:`).

The `^` branch is the model for prime handling: same "no prevAtom or already
has script → allocate empty Ord" preface, then attach the parsed group as a
superscript list.

### 2.5 finalize() — Bin/Un reclassification

`-[MTMathList finalized]` walks the list and reclassifies a `Bin` to `Un` when
the previous atom is `Bin/Rel/Open/Punct/LargeOp` or absent
`[verified: iosMath/lib/MTMathList.m:1344-1393]`,
`[verified: iosMath/lib/MTMathList.m:17-25]`. It also fuses adjacent Number
atoms and converts a trailing Bin to Un. This means new `Bin` symbols
(`\boxplus`, `\veebar`, `\triangleleft`, ...) automatically get TeX-correct
behavior at the start of a list or after a Rel.

### 2.6 Layout pipeline

`MTTypesetter` dispatches on `atom.type` and renders Ord/Bin/Rel/Open/Close/
Punct/Placeholder through a single "ordinary glyph atom" branch — no
per-symbol layout code exists. Spacing is driven entirely by the rule-16
matrix in `getInterElementSpaces()` indexed via
`getInterElementSpaceArrayIndexForType` `[inferred: research doc §5.1; not
re-verified line-by-line because this LLD does not change layout]`. None of the
new symbols touch this layer.

### 2.7 Test surfaces

- `testLatexSymbols` iterates every entry returned by
  `+supportedLatexSymbolNames` and asserts the rendered display has the
  expected glyph plus non-zero width and (for non-spaces) non-zero
  ascent+descent `[verified: iosMathTests/MTTypesetterTest.m:1292-1350]`. It
  runs only against `self.font`, which is set to `defaultFont` in `setUp`
  `[verified: iosMathTests/MTTypesetterTest.m:29]`. `defaultFont` returns
  Latin Modern Math `[verified: iosMath/render/MTFontManager.m:72-75]`. XITS
  Math and TeX Gyre Termes Math have factory methods on `MTFontManager` but
  are not exercised by the sweep
  `[verified: iosMath/render/MTFontManager.m:57-69]`.
- Parser tests are data-table style; the pattern is "list of triples (input,
  expected atom-types, expected round-trip string)" and the helper
  `checkAtomTypes:types:desc:` iterates the type list
  `[verified: iosMathTests/MTMathListBuilderTest.m:23-31]`,
  `[verified: iosMathTests/MTMathListBuilderTest.m:47-92]`. The existing data
  table already covers an alias round-trip (`\ne` → `\neq`)
  `[verified: iosMathTests/MTMathListBuilderTest.m:67]`.

---

## 3. Proposed Design

### 3.1 Data model changes

N/A — no new `MTMathAtomType`, no new atom subclass, no new persistent state.
The reverse-map shape changes (§3.3) but it is a private, lazily-built cache.

### 3.2 API contract

No public-API additions. The set of LaTeX commands the parser accepts grows;
`mathListToString:` round-trip output changes for two pre-existing
nucleus-shared cases (`\bigtriangleup` and `\bigtriangledown`, neither
currently registered) and for `\square` (today `\square` produces a
placeholder atom and round-trips trivially; after this change it produces an
Ord and round-trips as `\Box`).

The `+placeholder` factory (`MTMathAtomFactory.m:65`) is preserved verbatim —
editor clients that need a placeholder atom continue to call it directly. Only
the LaTeX command `\square` is unwired from it.

### 3.3 Class / module changes

#### iosMath/lib/MTMathAtomFactory.m `[verified]`

##### `+supportedLatexSymbols` (line 439) — modify

- **Remove** the `@"square" : [MTMathAtomFactory placeholder]` row at line 444
  `[verified: iosMath/lib/MTMathAtomFactory.m:444]`. The `+placeholder` method
  itself is unchanged.
- **Add** the rows below. Each row follows the existing pattern
  `@"<cmd>" : [MTMathAtom atomWithType:<type> value:@"\u<hex>"]` (matching the
  formatting used at lines 506–589). Group them into the existing visual
  sections (Arrows, Relations, operators, Other symbols).

  **Negated relations (Rel)** — Feature 2:
  `\nleq` U+2270, `\ngeq` U+2271, `\nless` U+226E, `\ngtr` U+226F,
  `\nsubseteq` U+2288, `\nsupseteq` U+2289, `\nmid` U+2224,
  `\nparallel` U+2226, `\nleftarrow` U+219A, `\nrightarrow` U+219B,
  `\nLeftarrow` U+21CD, `\nRightarrow` U+21CF, `\nleftrightarrow` U+21AE,
  `\nLeftrightarrow` U+21CE, `\nvdash` U+22AC, `\nvDash` U+22AD,
  `\nVdash` U+22AE, `\nVDash` U+22AF, `\ntriangleleft` U+22EA,
  `\ntriangleright` U+22EB, `\ntrianglelefteq` U+22EC,
  `\ntrianglerighteq` U+22ED, `\nsim` U+2241, `\ncong` U+2247,
  `\nequiv` U+2262, `\nsubset` U+2284, `\nsupset` U+2285, `\nsucc` U+2281,
  `\nprec` U+2280, `\nsucceq` U+2AB1, `\npreceq` U+2AB0.

  **Harpoons / extended arrows (Rel)** — Feature 3:
  `\rightleftharpoons` U+21CC, `\leftrightharpoons` U+21CB,
  `\upharpoonleft` U+21BF, `\upharpoonright` U+21BE,
  `\downharpoonleft` U+21C3, `\downharpoonright` U+21C2,
  `\rightharpoonup` U+21C0, `\leftharpoonup` U+21BC,
  `\rightharpoondown` U+21C1, `\leftharpoondown` U+21BD,
  `\hookleftarrow` U+21A9, `\hookrightarrow` U+21AA,
  `\twoheadleftarrow` U+219E, `\twoheadrightarrow` U+21A0,
  `\rightarrowtail` U+21A3, `\leftarrowtail` U+21A2.

  **Missing relations / ordinaries** — Feature 4:
  `\vdash` U+22A2 Rel, `\dashv` U+22A3 Rel, `\Subset` U+22D0 Rel,
  `\Supset` U+22D1 Rel, `\backsim` U+223D Rel, `\backsimeq` U+22CD Rel,
  `\eqsim` U+2242 Rel, `\Bumpeq` U+224E Rel, `\bumpeq` U+224F Rel,
  `\therefore` U+2234 Rel, `\because` U+2235 Rel, `\multimap` U+22B8 Rel,
  `\complement` U+2201 Ord, `\Box` U+25A1 Ord, `\Diamond` U+25C7 Ord,
  `\lozenge` U+25CA Ord, `\blacklozenge` U+29EB Ord,
  `\diamondsuit` U+2662 Ord, `\heartsuit` U+2661 Ord,
  `\spadesuit` U+2660 Ord, `\clubsuit` U+2663 Ord, `\beth` U+2136 Ord,
  `\gimel` U+2137 Ord, `\daleth` U+2138 Ord, `\triangledown` U+25BD Ord,
  `\vartriangleleft` U+22B2 Rel, `\vartriangleright` U+22B3 Rel,
  `\trianglelefteq` U+22B4 Rel, `\trianglerighteq` U+22B5 Rel,
  `\triangleq` U+225C Rel, `\blacktriangle` U+25B2 Ord,
  `\blacktriangledown` U+25BC Ord, `\blacktriangleleft` U+25C0 Ord,
  `\blacktriangleright` U+25B6 Ord.

  **Boxed / circled binary operators (Bin)** — Feature 5:
  `\boxplus` U+229E, `\boxminus` U+229F, `\boxtimes` U+22A0,
  `\boxdot` U+22A1, `\circledast` U+229B, `\circledcirc` U+229A,
  `\circleddash` U+229D, `\barwedge` U+22BC, `\veebar` U+22BB,
  `\triangleleft` U+25C1, `\triangleright` U+25B7.

  Total: 31 + 16 + 25 + 11 = **83 new entries**, plus the `\Box` entry that
  replaces `\square`.

##### `+aliases` (line 709) — modify

Add to the static dictionary (existing format
`@"alias" : @"canonical"`)
`[verified: iosMath/lib/MTMathAtomFactory.m:709-730]`:

- `\implies` → `Longrightarrow`
- `\impliedby` → `Longleftarrow`
- `\restriction` → `upharpoonright`  *(requires Feature 3 entry)*
- `\dotsc` → `ldots`
- `\dotsb` → `cdots`
- `\dotsm` → `cdots`
- `\dotsi` → `ldots`
- `\square` → `Box`               *(requires Feature 4 entry; replaces removed
  `square → placeholder` row)*
- `\vartriangle` → `triangle`     *(same Ord/U+25B3 — true synonym)*

##### `+textToLatexSymbolNames` (line 732) — re-key by `(nucleus, type)`

- Inner dict `NSDictionary<NSString*, NSDictionary<NSNumber*, NSString*>>`
  (nucleus → boxed `MTMathAtomType` → command name). Build loop iterates
  `+supportedLatexSymbols` once, locates (or creates) the inner dict for
  `prototype.nucleus`, then applies the existing shorter-then-alphabetical
  tie-break against `inner[@(prototype.type)]`
  `[verified: iosMath/lib/MTMathAtomFactory.m:744-758]`. Only the inner
  comparison changes; the predicate is identical.
- `dispatch_once`-equivalent (`if (!textToCommands)`) is preserved
  `[verified: iosMath/lib/MTMathAtomFactory.m:734-736]`.
- **Decision (recommended) — nested dict.** The flat composite-key form
  (`"<nucleus>|<type>"`) is functionally equivalent. The nested shape is
  picked because it is easier to inspect in a debugger and keeps the existing
  per-nucleus iteration intuition. The composite form would save one
  allocation per nucleus; that is irrelevant given ~270 entries lazily built
  once.

##### `+latexSymbolNameForAtom:` (line 184) — modify

One-line change: instead of `dict[atom.nucleus]`, look up
`dict[atom.nucleus][@(atom.type)]`
`[verified: iosMath/lib/MTMathAtomFactory.m:184-191]`. Return `nil` when
either lookup misses (preserves current "fall back to literal nucleus"
behavior at `MTMathList.m:296`).

##### `+addLatexSymbol:value:` (line 193) — modify

Same one-line change to keep the runtime escape hatch consistent with the
re-keyed map: `dict[atom.nucleus][@(atom.type)] = name`, allocating the inner
mutable dict on first use
`[verified: iosMath/lib/MTMathAtomFactory.m:193-203]`. Without this, an atom
registered via `+addLatexSymbol:value:` would not survive round-trip after the
re-keying.

##### `+atomForCharacter:` (line 103) — leave intact

The `'` rejection at line 112 stays
`[verified: iosMath/lib/MTMathAtomFactory.m:112]`. Prime handling is added in
the parser (§3.3 `MTMathListBuilder.m`). Reason: this method is shared with
`+mathListForCharacters:` `[verified: iosMath/lib/MTMathAtomFactory.m:148-162]`
which is documented as "no LaTeX conversion" and is used by
`+fractionWithNumeratorStr:denominatorStr:`
`[verified: iosMath/lib/MTMathAtomFactory.m:299-304]`. Programmatic callers
should not get a `\prime` atom out of a literal `'` character.

#### iosMath/lib/MTMathListBuilder.m `[verified]`

##### `-buildInternal:stopChar:` (line 106) — add `'` branch

Insert a new `else if (ch == '\'')` branch in the per-character loop, before
the catch-all `+atomForCharacter:` fallback at line 228. Behavior:

1. **`oneCharOnly` slot guard.** If the recursion was entered with
   `oneCharOnly == YES` (i.e. inside a `^` or `_` or `fontStyleWithName`
   one-char slot — see lines 118–124), build a single `\prime` atom
   (`+atomForLatexSymbolName:@"prime"`), append it to `list` as the slot's
   one Ord, set `prevAtom = atom`, `[list addAtom:atom]`, then return `list`
   per the existing oneCharOnly contract at line 239–242. This makes
   `f^'` produce `f^{\prime}`.

2. **Allocate an empty Ord if needed.** If `prevAtom == nil ||
   prevAtom.superScript || !prevAtom.scriptsAllowed`, allocate
   `MTMathAtom atomWithType:kMTMathAtomOrdinary value:@""` and append it,
   matching the `^` branch at lines 134–138
   `[verified: iosMath/lib/MTMathListBuilder.m:134-138]`. This handles `'2`
   (no prevAtom) and `f^2'` (prevAtom already has a superscript).

3. **Greedy prime collection.** Build a fresh `MTMathList* primes` and
   append `+atomForLatexSymbolName:@"prime"` once for the consumed `'`.
   Then while the next character is `'`, consume it via
   `getNextCharacter` and append another prime. (Spaces between primes are
   already filtered at line 224 — the `_spacesAllowed` branch only emits a
   space inside `\text`, otherwise the space is silently dropped by the
   catch-all branch. So `f' '` reads as `f''` already.)
   `[verified: iosMath/lib/MTMathListBuilder.m:224-232]`

4. **TeX `\futurelet` merge with trailing `^`.** Peek at the next
   character via `getNextCharacter` / `unlookCharacter`
   `[verified: iosMath/lib/MTMathListBuilder.m:75-85]`. If it is `'`,
   continue the loop in step 3 (already covered). If it is `^`:
   consume it, then call `[self buildInternal:YES]` (mirrors the `^`
   handler at line 142). The returned `MTMathList`'s atoms are appended
   onto `primes`. This produces `f'^2 → primes = [\prime, 2]`.
   `[verified: iosMath/lib/MTMathListBuilder.m:142]`

5. **Attach.** Set `prevAtom.superScript = primes`. Do **not** modify
   `prevAtom`'s subScript or replace `prevAtom` in `list` — a following
   `_n` should attach via the existing `_` branch to the same prevAtom.
   `continue` to the next loop iteration.

The change is local to one new branch (~25 lines) plus its early return for
the oneCharOnly case. The existing `^` branch is untouched.

##### Other methods — unchanged

`-build` (line 87), `-readCommand` (line 340), `-stopCommand:` (line 537),
`-applyModifier:` (line 613), `-atomForCommand:` (line 423) — none of these
need changes for any feature in this LLD.

#### iosMathTests/MTTypesetterTest.m `[verified]`

##### `testLatexSymbols` (line 1292) — extend to three-font sweep

Refactor the body into a helper `-runSymbolSweepWithFont:(MTFont*)font`
containing the existing per-symbol assertions (lines 1296–1349 verbatim, with
`self.font` replaced by the parameter)
`[verified: iosMathTests/MTTypesetterTest.m:1296-1349]`. Add three test
methods:

```
- (void) testLatexSymbols_LatinModern
- (void) testLatexSymbols_XITS
- (void) testLatexSymbols_Termes
```

Each builds its `MTFont*` via the corresponding `MTFontManager` factory at
`MTFontManager.m:57/62/67` `[verified: iosMath/render/MTFontManager.m:57-69]`
and calls the helper. Three sibling methods (rather than one combined test)
give clearer failure messages — Xcode reports which font failed.

The existing single-font `testLatexSymbols` is preserved as
`testLatexSymbols_LatinModern` (or removed; either is fine — the
`_LatinModern` sweep dominates it).

#### iosMathTests/MTMathListBuilderTest.m `[verified]`

Add new test methods using the established data-table pattern
(`getTestData`, `checkAtomTypes:types:desc:` at lines 23–31, 47–92):

- `testPrimes` — bespoke (single, double, triple, no-prevAtom, inside-braces,
  prime+`^` merge, prime+`_`, double-superscript fallback). See §7.
- `testNegatedRelations` — parameterized over the 31 Feature-2 entries.
- `testHarpoons` — parameterized over the 16 Feature-3 entries.
- `testMissingRelationsAndOrdinaries` — parameterized over the 25 Feature-4
  entries (including `\Box`).
- `testBoxedCircledOperators` — parameterized over the 11 Feature-5 entries.
  Includes one row that asserts a leading `\boxplus` is reclassified to
  `kMTMathAtomUnaryOperator` after `finalized` (mirrors existing Bin behavior
  via `MTMathList.finalized` at `MTMathList.m:1358-1364`).
- `testNewAliases` — parameterized over the 9 Feature-6 entries; verifies
  parse-time canonicalization and that round-trip emits the canonical form
  (matches the existing `\ne → \neq` precedent at line 67).
- `testSquareBoxParity` — bespoke (§7.4 of research): parse `\square` and
  `\Box`, both produce Ord/U+25A1; round-trip both emits `\Box` (only canonical
  in the (U+25A1, Ord) cell after Feature 7); placeholder constructed via
  `+placeholder` still has type `kMTMathAtomPlaceholder`.
- `testRoundTripTypePreservation` — bespoke (Feature 7): parse
  `\bigtriangleup`, round-trip is `\bigtriangleup `; parse `\triangle`,
  round-trip is `\triangle `; same pair at U+25BD. Plus a render-side
  check: `\bigtriangleup a` and `\triangle a` lay out with different
  inter-element spacing (Bin vs Ord with an Ord neighbor).

### 3.4 Logic flow

#### Parsing `f'^2`

1. `+buildFromString:` → `-build` → `-buildInternal:NO stopChar:0`
   `[verified: iosMath/lib/MTMathListBuilder.m:763-779, 87, 101-103]`.
2. `f` → `+atomForCharacter:` returns Variable atom; appended to `list`,
   `prevAtom = f`.
3. `'` → enters new prime branch.
   - `prevAtom = f`, `f.superScript == nil`, `f.scriptsAllowed == YES`. No
     empty-Ord allocation.
   - `primes = [\prime]`. Peek: next char is `^`.
   - Consume `^`. Call `-buildInternal:YES`. This recursive call sees `2`,
     returns a list `[2]`. Append `2` onto `primes` → `primes = [\prime, 2]`.
   - `f.superScript = primes`. Continue.
4. End of input. `list = [f]` with `f.superScript = [\prime, 2]`.
5. `-finalized`: `\prime` is Ord, `2` is Number — no rule-5/6 reclassification
   inside the superscript list.

#### Parsing `\nleq` (representative of Features 2/3/4/5)

1. `\` → `-readCommand` returns `"nleq"`
   `[verified: iosMath/lib/MTMathListBuilder.m:340-360]`.
2. `-stopCommand:`/`-applyModifier:`/`+fontStyleWithName:` return
   nil/NO/`NSNotFound`
   `[verified: iosMath/lib/MTMathListBuilder.m:177-188]`.
3. `-atomForCommand:@"nleq"` calls `+atomForLatexSymbolName:@"nleq"`
   `[verified: iosMath/lib/MTMathListBuilder.m:423]`,
   `[verified: iosMath/lib/MTMathAtomFactory.m:164-181]`.
4. Aliases miss; `commands[@"nleq"]` returns the new Rel/U+2270 prototype;
   `[atom copy]` returned.
5. Atom appended; `prevAtom` updated.

#### Parsing `\implies` (representative of Feature 6)

1. `-readCommand` returns `"implies"`.
2. `+atomForLatexSymbolName:@"implies"` resolves alias to `"Longrightarrow"`
   `[verified: iosMath/lib/MTMathAtomFactory.m:167-173]`.
3. `commands[@"Longrightarrow"]` returns the existing Rel/U+27F9 prototype
   `[verified: iosMath/lib/MTMathAtomFactory.m:527]`. Copy returned.

#### Round-tripping `\bigtriangleup a` (Feature 7)

1. Parse → `[Bin/U+25B3, Variable a]`.
2. `-finalized`: leading Bin → Un (`MTMathList.m:1359-1363`); now
   `[Un/U+25B3, Variable a]`.
   - **Subtlety.** `Un` (kMTMathAtomUnaryOperator) is the post-finalize type.
     `+latexSymbolNameForAtom:` will look up `(U+25B3, Un)` and miss because
     `+supportedLatexSymbols` registers the prototype as `Bin`. The lookup
     falls back to the literal nucleus path at `MTMathList.m:294-296`,
     emitting the raw character "△" instead of the command. **This breaks
     round-trip.**
   - **Mitigation.** `+latexSymbolNameForAtom:` is the right place to fix
     this: when `atom.type == kMTMathAtomUnaryOperator`, search both
     `(nucleus, Un)` and `(nucleus, Bin)` cells, since Un is finalize's
     transformation of Bin. (`MTMathList.m:1358-1364` is the only producer of
     `Un`.) Implementation: try `(nucleus, type)` first, then if `type ==
     kMTMathAtomUnaryOperator`, retry with `kMTMathAtomBinaryOperator`. This
     keeps the (nucleus, type) discrimination for the cases that need it
     (Ord vs Bin at U+25B3) while preserving the Bin → Un transformation.
3. With the mitigation in place, `\bigtriangleup` is found in the (U+25B3,
   Bin) cell and emitted; `a` falls through to literal output. Result:
   `\bigtriangleup a` `[verified: iosMath/lib/MTMathList.m:281-299, 1344-1393]`.

This Un/Bin lookup quirk is a minor addition to the design beyond the research
doc's three-line sketch — flagged here so the implementation does not miss it.

---

## 4. Open Questions

1. **Sequencing.** Land Feature 7 alone first as a small de-risk PR, then
   Feature 1 (prime) as its own PR, then bundle Features 3 + 6 (so
   `\restriction` isn't a temporarily-broken alias) and Feature 4 + 6's
   `\square` together, then Features 2 and 5 in any order? Or one big PR?
   Project policy. **Assumption:** small PRs preferred — repo's recent
   history shows feature-per-PR cadence (see PRs #193–#199 in `git log`).

2. **Sparse-glyph symbols.** If the three-font `testLatexSymbols` sweep flags
   `\blacklozenge` (U+29EB), `\npreceq`/`\nsucceq` (U+2AB0/2AB1), or
   `\triangleq` (U+225C) as zero-width in XITS or Termes, do we (a) drop the
   symbol, (b) keep the symbol and skip those fonts in the sweep, or (c) keep
   and accept the test failure for that font? **Recommendation:** keep
   registered (LaTeX compatibility wins), expected-fail per missing font with
   a documented exception list inside the sweep helper. Confirms with the
   user once empirical font-coverage data is in.

3. **Round-trip serialization of `\square`.** After Feature 4, `\square`
   round-trips as `\Box`. The placeholder type's serialization changes from
   "the literal U+25A1 character" (today, since
   `+latexSymbolNameForAtom:` returns `nil` for placeholders constructed via
   `+placeholder` — they're not in `supportedLatexSymbols` after the change)
   to … the same literal U+25A1 character, since after Feature 7 the
   `(U+25A1, Placeholder)` cell is still empty. **No regression**, but
   confirm we are happy with the placeholder atom *not* round-tripping as
   any LaTeX command. (The research doc already accepted this in §7.4.)

4. **Prime-inside-superscript ergonomics.** `f^{2'}` produces
   `f^{2^{\prime}}` per the algorithm in §3.4 — `'` inside the inner
   recursion sees `prevAtom = 2` and attaches as a superscript on the `2`.
   This matches TeX. The requirements doc does not pin this case; assumption
   is the TeX-canonical behavior is wanted. Confirm.

5. **Does the `\square → \Box` removal need a deprecation period?** No
   external client of iosMath should depend on `\square` producing a
   placeholder atom — the placeholder is documented as "does not exist in
   TeX" `[verified: iosMath/lib/MTMathList.h:51]`. Assumption: no
   deprecation needed; ship the cleaner semantics in the same PR.

---

## 5. Risks / Trade-offs

- **Feature 7 introduces a Bin/Un asymmetry in the lookup** (§3.4 Round-trip
  flow). Fix is the explicit Un→Bin retry described in the same section. If a
  reviewer prefers a different shape — e.g. always store under
  `kMTMathAtomBinaryOperator` and never under `Un` — that works too but
  hard-codes the assumption that `Un` only appears via `Bin` reclassification.
  The retry is more transparent.
- **Sequencing dependencies are fragile.** `\restriction → \upharpoonright`
  and `\square → \Box` cannot land before their canonicals exist. A merged
  PR that mis-sequences will produce `MTParseErrorInvalidCommand` for users
  who try the alias on a transient build. Mitigation: bundle Features 3+6
  (or 4+6) in a single commit, or land Feature 6 last.
- **Font coverage is empirical.** The three-font sweep is a safety net, but
  bundle fonts may skip a symbol. The fallback (drop the symbol) reduces
  LaTeX coverage; the alternative (per-font expected-fail) increases test
  noise. Open Question 2.
- **The reverse map's tie-break is now per-cell.** Previously two Bin
  symbols at the same nucleus would tie-break against each other; now they
  share a single (nucleus, Bin) cell and still tie-break — but two
  type-distinct entries at the same nucleus no longer fight. This is the
  desired behavior, but the LLD should note that any existing
  same-nucleus-same-type pair (none in the current table per the research
  doc, §8.7 last bullet) would still resolve via the within-cell tie-break,
  not become an explicit alias.
- **No layout regression risk for the symbol additions.** Each new symbol
  flows through the existing uniform "ordinary glyph atom" branch. The
  spacing matrix is unchanged. The only layout-adjacent test surface is the
  three-font `testLatexSymbols` sweep.
- **Prime parser change is the one piece with non-trivial behavior.** It
  has six edge cases (§3.4 + §7) that need tests. The risk is a corner case
  we haven't enumerated; the test list is the mitigation.

**Trade-offs taken.**

- **Nested dict over composite key for the reverse map.** Slightly more
  allocations, but better debug ergonomics. Negligible at this scale.
- **`'` handled in `buildInternal:`, not `+atomForCharacter:`.** Keeps the
  programmatic-construction path (`mathListForCharacters:`) untouched at the
  cost of one new branch in the parser loop. The alternative — promote `'`
  to a Ord/U+2032 atom in `+atomForCharacter:` — would silently change the
  semantics of `+fractionWithNumeratorStr:` and is rejected.
- **Three sibling test methods per font, not one parameterized loop.**
  Better failure messages from Xcode. Three instead of one.

---

## 6. Edge cases / Error handling

| Case | Planned response |
|---|---|
| `'` with no preceding atom (`'2`) | Allocate empty Ord, set its `superScript = [\prime]`, then continue parsing — mirrors `^2` at lines 134–138. |
| `f'` at end of input | `f.superScript = [\prime]`, no merge needed. |
| `f''''` (4+ primes) | Greedy collection — `superScript = [\prime, \prime, \prime, \prime]`. No upper bound. |
| `f'^2` | `f.superScript = [\prime, 2]` per §3.4. |
| `f^2'` | `f.superScript = [2]` already; double-superscript path allocates an empty Ord and sets `emptyOrd.superScript = [\prime]` — matches the existing `^` "already has superscript" branch. |
| `f^{2'}` | Inner recursion: `2.superScript = [\prime]`. Outer: `f.superScript = [2 with prime]`. Matches TeX. |
| `f^'2` | Inside `oneCharOnly == YES`. The new branch's step 1 (oneCharOnly slot guard) returns a single-element list `[\prime]`. The outer `^` handler attaches it as `f.superScript = [\prime]`. The `2` is then parsed as the next top-level atom. |
| `'` inside `\text{...}` | `_spacesAllowed == YES` only affects spaces. The new `'` branch fires regardless and the prime attaches to the previous atom inside the text scope. (Not strictly TeX — but consistent and not regressing anything; document.) |
| `\square` in legacy code that expected a placeholder atom | After Feature 4, `\square` produces an Ord. Programmatic clients constructing placeholders should use `+placeholder` directly (as the existing tests already do — `MTMathListTest.m`). The class comment at `MTMathList.h:51` is the documented contract. |
| Alias resolves to a missing canonical (e.g. partial PR with `\restriction` but no `\upharpoonright`) | `+atomForLatexSymbolName:` returns nil; `-atomForCommand:` returns nil; the parser raises `MTParseErrorInvalidCommand`. **Mitigation:** sequence the PRs or bundle Features 3+6. |
| Round-trip of an atom whose `(nucleus, type)` cell is empty | Falls through to `else { [str appendString:self.nucleus]; }` at `MTMathList.m:296` — unchanged from today. |
| Glyph missing in one of the three bundled fonts | Three-font `testLatexSymbols` sweep fails with the symbol name and font name in the message. Triage per Open Question 2. |

---

## 7. Testing Strategy

### Unit tests (parser + factory)

`MTMathListBuilderTest.m`:

- `testPrimes` — bespoke. Cases:
  - `f'` → `[Variable f]` with `f.superScript = [Ord U+2032]`.
  - `y''` → `[Variable y]` with `y.superScript = [Ord, Ord]`.
  - `f'''(x)` → atoms `[f, (, x, )]` with `f.superScript.atoms.count == 3`.
  - `'2` → atoms `[Ord(empty), Number 2]`. (Not quite — re-check: empty Ord
    gets `superScript = [\prime]`, `2` is the next top-level atom after
    `continue`.) Confirm with `checkAtomTypes:`.
  - `{f'}^2` → outer atom is `f` (the brace's last atom) with
    `superScript` pre-set to `[\prime]`, then outer `^2` falls into the
    "already has a superscript" branch and creates a new empty Ord with
    `superScript = [2]`. Verify atom count and shapes.
  - `f'^2` → `f.superScript = [\prime, Number 2]`.
  - `f'''^{2x}` → `f.superScript = [\prime, \prime, \prime, Number 2,
    Variable x]`.
  - `f'_n` → `f.superScript = [\prime]`, `f.subScript = [Variable n]`.
  - `f^\prime` (regression) — explicit `\prime` still parses unchanged.
  - Round-trip every input; expected output uses the existing `\prime ` form
    inside `^{...}`.

- `testNegatedRelations` — data-table over 31 Feature-2 entries. Each row:
  `(LaTeX, [type], roundTrip)`. Run `testBuilder`-style: build, check types,
  round-trip equality.
- `testHarpoons` — same shape, 16 entries.
- `testMissingRelationsAndOrdinaries` — 25 entries.
- `testBoxedCircledOperators` — 11 entries. Plus one row asserting
  `\boxplus a` finalizes to `[Un/U+229E, Variable a]` (rule-5 reclassification
  via `MTMathList.finalized`).
- `testNewAliases` — 9 entries: parse alias, assert atom matches the
  canonical's prototype; round-trip emits the canonical string.
- `testSquareBoxParity` — bespoke per §7.4 of research:
  - Parse `\square` → Ord/U+25A1.
  - Parse `\Box` → Ord/U+25A1.
  - Round-trip both — both emit `\Box `.
  - `[MTMathAtomFactory placeholder]` returns
    `kMTMathAtomPlaceholder`/U+25A1 unchanged.
- `testRoundTripTypePreservation` — bespoke per Feature 7:
  - `\bigtriangleup` → round-trips as `\bigtriangleup `.
  - `\triangle` → round-trips as `\triangle `.
  - Same pair at U+25BD.
  - `\bigtriangleup` after a leading `a` (so finalize keeps Bin, not Un) —
    confirm Bin/Un round-trip both emit `\bigtriangleup`.

### Integration tests (typesetter)

`MTTypesetterTest.m`:

- `testLatexSymbols_LatinModern`, `testLatexSymbols_XITS`,
  `testLatexSymbols_Termes` — three sibling methods backed by a shared helper
  (§3.3). Each iterates `+supportedLatexSymbolNames` and asserts non-zero
  width plus expected ascent+descent for non-space glyphs. **This is the only
  per-font font-coverage check** and the only safety net for "registered but
  no glyph in this font."
- The existing `testSpacing` covers rule-16 spacing class-by-class — no
  per-symbol spacing test is needed.

### Edge cases that need explicit coverage (from §6)

- `f^2'` (double-superscript fallback) — covered by `testPrimes` above.
- Alias-canonical-missing — *not* a runnable test (would require breaking
  the build). Mitigation is sequencing, captured in §5 as a process risk.
- Glyph missing in one of the three bundled fonts — surfaces from the
  per-font `testLatexSymbols_*` sweeps. No bespoke regression test
  (re-running the suite is the regression).

---

*End of LLD.*
