# iosMath Feature Expansion Requirements

## Overview

This document defines the requirements for expanding symbol and shorthand support in `iosMath` to improve LaTeX compatibility with common mathematical notation used in textbooks, research papers, chemistry, logic, and category theory.

The scope is intentionally limited to parser and symbol-table enhancements. No layout engine redesign, font rendering changes, or new atom types are required.

Primary goals:

- Improve compatibility with standard LaTeX and `amssymb`
- Close long-standing missing-symbol issues
- Reduce incorrect rendering reports caused by unsupported syntax
- Maintain backwards compatibility
- Keep implementation lightweight and localized

---

# Functional Requirements

---

# 1. Prime Shorthand Support (`'`)

## Objective

Support apostrophe shorthand notation for primes in math expressions.

Examples:

```latex
f'
y''
f'''(x)
```

should render equivalently to:

```latex
f^\prime
y^{\prime\prime}
f^{\prime\prime\prime}(x)
```

---

## Requirements

### Parsing

- Extend `MTMathListBuilder.buildInternal`
- Detect `'` characters during parsing
- Convert one or more consecutive apostrophes into corresponding `\prime` atoms

### Behavior

| Input | Expected Semantic Output |
|---|---|
| `f'` | `f^\prime` |
| `y''` | `y^{\prime\prime}` |
| `f'''(x)` | `f^{\prime\prime\prime}(x)` |

### Rendering

- Reuse existing `\prime` support
- Use Unicode `U+2032`
- No new atom types
- No font additions

### Constraints

- Must behave identically to explicit `\prime`
- Must integrate correctly with superscript handling
- Consecutive apostrophes should associate together

### Tests Required

- Single prime
- Double prime
- Triple prime
- Prime attached to grouped expressions
- Prime followed by superscripts/subscripts
- Existing explicit `\prime` behavior regression tests

---

# 2. Negated Relation Symbols (`amssymb`)

## Objective

Add support for common negated relation operators from `amssymb`.

---

## Symbols

```latex
\nleq
\ngeq
\nless
\ngtr
\nsubseteq
\nsupseteq
\nmid
\nparallel
\nleftarrow
\nrightarrow
\nLeftarrow
\nRightarrow
\nleftrightarrow
\nLeftrightarrow
\nvdash
\nvDash
\nVdash
\nVDash
```

---

## Requirements

### Symbol Registration

- Add symbol mappings in `MTMathAtomFactory`
- Implementation should be dictionary/data-driven only

### Rendering

- Use existing relation/operator atom categories where appropriate
- Use corresponding Unicode glyphs if already supported by font set

### Constraints

- No parser changes required
- No layout engine changes required
- No synthetic `\not` composition logic required

### Tests Required

- Parsing validation for each symbol
- Correct atom type classification
- Rendering snapshots where test infrastructure exists

---

# 3. Harpoons and Missing Arrow Symbols

## Objective

Add support for commonly used harpoons and extended arrows from `amssymb`.

---

## Symbols

```latex
\rightleftharpoons
\leftrightharpoons
\upharpoonleft
\upharpoonright
\downharpoonleft
\downharpoonright
\rightharpoonup
\leftharpoonup
\rightharpoondown
\leftharpoondown
\hookleftarrow
\hookrightarrow
\twoheadleftarrow
\twoheadrightarrow
\rightarrowtail
\leftarrowtail
```

---

## Requirements

### Symbol Registration

- Add mappings in `MTMathAtomFactory`
- Use existing arrow/relation atom classifications

### Compatibility

- Must parse identically to existing arrow commands
- Should render correctly inside:
  - superscripts
  - subscripts
  - fractions
  - matrices

### Constraints

- No layout engine changes
- No extensible-arrow implementation required
- No stretchy behavior required

### Tests Required

- Symbol parse tests
- Arrow rendering validation
- Mixed-expression integration tests

---

# 4. Missing Common Relations and Ordinaries

## Objective

Fill gaps in commonly used proof, logic, and set-theory notation.

---

## Symbols

```latex
\vdash
\dashv
\Subset
\Supset
\backsim
\backsimeq
\eqsim
\Bumpeq
\bumpeq
\therefore
\because
\multimap
\complement
\Box
\Diamond
\beth
\gimel
\daleth
```

---

## Requirements

### Classification

Symbols must be categorized correctly as:

- relation
- binary operator
- ordinary
- punctuation

depending on TeX semantics.

### Rendering

- Use existing glyph lookup mechanisms
- Ensure spacing follows atom type semantics

### Constraints

- No custom spacing rules
- No new font handling logic

### Tests Required

- Parsing tests
- Atom type validation
- Inline spacing verification where testable

---

# 5. Boxed and Circled Binary Operators

## Objective

Add support for boxed/circled operator symbols commonly used in algebra and category theory.

---

## Symbols

```latex
\boxplus
\boxminus
\boxtimes
\boxdot
\circledast
\circledcirc
\circleddash
\barwedge
\veebar
\triangleleft
\triangleright
```

---

## Requirements

### Classification

- Operators should use binary operator atom type where appropriate

### Rendering

- Reuse existing symbol rendering pipeline

### Constraints

- No operator sizing behavior required
- No custom layout handling

### Tests Required

- Symbol parsing
- Binary operator spacing validation

---

# 6. Alias Support

## Objective

Add lightweight alias mappings for commonly expected LaTeX commands.

---

## Aliases

| Alias | Canonical Mapping |
|---|---|
| `\implies` | `\Longrightarrow` |
| `\impliedby` | `\Longleftarrow` |
| `\restriction` | `\upharpoonright` |
| `\dotsc` | `\ldots` |
| `\dotsb` | `\cdots` |
| `\dotsm` | `\cdots` |
| `\dotsi` | `\ldots` |

---

## Requirements

### Implementation

- Extend alias dictionary/mapping table
- Aliases should resolve during command lookup

### Constraints

- No parser modifications required
- No context-sensitive dots logic required

### Tests Required

- Alias resolution tests
- Regression tests for canonical commands

---

# Non-Functional Requirements

## Backwards Compatibility

- Existing supported LaTeX must continue functioning unchanged
- No behavioral regressions in parser or layout engine

---

## Performance

- No measurable parsing slowdown for normal expressions
- Symbol lookups should remain O(1) dictionary lookups

---

## Scope Constraints

The following are explicitly out of scope:

- New atom types
- Font asset changes
- Stretchy/extensible arrows
- Context-sensitive dots rendering
- General `\not` composition support
- AMS environment support
- Macro expansion engine changes

---

# Expected Implementation Areas

## Likely Files

### Parser

- `MTMathListBuilder`

### Symbol Registration

- `MTMathAtomFactory`

### Tests

- Existing parser/render test suites

---

# Acceptance Criteria

Implementation is considered complete when:

1. All listed symbols parse successfully
2. Prime shorthand behaves identically to TeX expectations
3. Alias commands resolve correctly
4. Existing tests continue passing
5. New tests are added for all newly supported commands
6. No rendering regressions are introduced

---

# Suggested Implementation Order

Recommended rollout sequence:

1. Prime shorthand
2. Aliases
3. Negated relations
4. Missing relations/ordinaries
5. Harpoons/arrows
6. Boxed/circled operators

This ordering minimizes risk and simplifies debugging.
