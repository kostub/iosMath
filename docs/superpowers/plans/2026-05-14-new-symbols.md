# New Symbol & Shorthand Support — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand iosMath's LaTeX compatibility by registering 92 additional symbols from `amssymb` and adjacent vocabularies (31 negated relations + 16 harpoons/arrows + 34 logic/set-theory/suit/Hebrew/triangle entries + 11 boxed/circled operators), add `'` prime shorthand, add 9 aliases, and re-key the reverse symbol map by `(nucleus, type)` so future and existing Bin/Ord collisions round-trip cleanly. The existing `\square → placeholder` mis-wiring is removed (net +91 new symbol-table entries).

**Architecture:** Pure data-table and parser changes localised to `MTMathAtomFactory.m` and `MTMathListBuilder.m`. No new atom types, no new layout code, no font assets. The reverse map (`+textToLatexSymbolNames`) becomes a two-level dict keyed first by nucleus, then by boxed `MTMathAtomType`; the lookup retries `(nucleus, Bin)` when `(nucleus, Un)` misses so `MTMathList.finalized`'s Bin→Un reclassification doesn't break round-trips. The `'` parser branch mirrors the existing `^` branch and supports greedy collection plus `\futurelet`-style merge with a trailing `^`.

**Tech Stack:** Objective-C, XCTest, three bundled OpenType math fonts (Latin Modern, XITS, TeX Gyre Termes). Source LLD: `docs/lld/2026-05-10-new-symbols.md`. Source requirements: `iosMath_feature_requirements.md`.

---

## PR Sequencing

Six PRs, ordered to keep each diff small and dependency-clean:

| PR | Scope | Why this order |
|----|-------|----------------|
| 1 | Feature 7 — re-key reverse map by `(nucleus, type)` + Un/Bin retry | De-risk infrastructure. Required by every later PR that adds collision-prone symbols. Must include the Un/Bin retry or existing Bin symbols (`\pm`, `\cdot`, …) regress at the start of a list. |
| 2 | Feature 1 — `'` prime shorthand | Parser change in `buildInternal:`. Reuses already-registered `\prime`. Independent of all symbol-table work. |
| 3 | Feature 2 — 31 negated relations | Symbol-table only. Independent. |
| 4 | Feature 5 — 11 boxed/circled binary operators | Symbol-table only. Independent. Exercises PR 1's Un/Bin retry. |
| 5 | Feature 3 + `\restriction` alias (subset of Feature 6) | Bundle so `\restriction → \upharpoonright` lands together with its canonical. |
| 6 | Feature 4 (34 entries) + remaining Feature 6 aliases + `\square` cleanup | Bundle so `\square → \Box` and `\vartriangle → \triangle` land with their canonicals. Removes the placeholder mis-wiring of `\square`. |

PRs 3 and 4 are commutative; either order is fine. PRs 5 and 6 must each land in a single commit per their bundling rationale.

---

## File Structure

All changes live in three existing files plus two existing test files:

| File | Responsibility | PRs that touch it |
|------|----------------|-------------------|
| `iosMath/lib/MTMathAtomFactory.m` | Symbol table, alias table, reverse map | 1, 3, 4, 5, 6 |
| `iosMath/lib/MTMathListBuilder.m` | LaTeX parser; gets `'` branch | 2 |
| `iosMathTests/MTMathListBuilderTest.m` | Parser + factory tests | 1, 2, 3, 4, 5, 6 |
| `iosMathTests/MTTypesetterTest.m` | Per-font symbol sweep | (deferred — see "Font sweep" note below) |

**Font sweep deferral.** The LLD §3.3 calls for refactoring `testLatexSymbols` to sweep all three bundled fonts (Latin Modern, XITS, Termes). That refactor is empirical work (Open Question 2: which symbols are missing in which fonts?) and is not on the critical path for any single PR. The existing single-font `testLatexSymbols` continues to cover every new symbol as it lands. Do the three-font refactor as a follow-up PR once all six PRs in this plan are merged, in scope outside this plan.

---

## PR 1 — Re-key reverse map by (nucleus, type)

**Goal:** Change `+textToLatexSymbolNames` from `nucleus → command` to `nucleus → (type → command)` and update `+latexSymbolNameForAtom:` / `+addLatexSymbol:value:` to match, with a Bin/Un retry in the lookup. No new symbols.

**Files:**
- Modify: `iosMath/lib/MTMathAtomFactory.m:184-203, 732-762`
- Test: `iosMathTests/MTMathListBuilderTest.m` (new method)

### Task 1.1: Write the regression test for `\pm` at start of list

This test must FAIL today (before the change) only if we had already broken the map, but it must PASS after the re-keying. It pins the behavior we are about to refactor under, so it doubles as a regression guard.

- [ ] **Step 1: Add the test method**

Append to `iosMathTests/MTMathListBuilderTest.m`, after the existing `testSymbols` method (~line 270):

```objc
- (void) testReverseMapTypeKeyedRoundTrip
{
    // Regression guard for Feature 7: re-keying the reverse map by
    // (nucleus, type) must not break round-tripping of Bin symbols that
    // become Un at the start of a list via -[MTMathList finalized].
    NSArray<NSArray*>* cases = @[
        @[ @"\\pm a",   @"\\pm a" ],
        @[ @"a\\pm b",  @"a\\pm b" ],
        @[ @"\\pm",     @"\\pm " ],
        @[ @"\\cdot a", @"\\cdot a" ],
        @[ @"a\\cdot b",@"a\\cdot b" ],
        @[ @"\\leq",    @"\\leq " ],
        @[ @"\\alpha",  @"\\alpha " ],
        @[ @"\\to",     @"\\rightarrow " ],   // alias resolves to canonical
    ];
    for (NSArray* c in cases) {
        NSString* input = c[0];
        NSString* expected = c[1];
        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"Parse error for %@", input);
        XCTAssertNotNil(list, @"Nil list for %@", input);
        MTMathList* final = [list finalized];
        NSString* roundTrip = [MTMathListBuilder mathListToString:final];
        XCTAssertEqualObjects(roundTrip, expected, @"Round-trip mismatch for %@", input);
    }
}
```

- [ ] **Step 2: Run the test against the current code**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testReverseMapTypeKeyedRoundTrip
```

Expected: PASS. The test pins current behavior so we have a baseline to refactor under. If it fails today, stop and investigate before refactoring.

### Task 1.2: Re-key `+textToLatexSymbolNames` to nested dict

- [ ] **Step 1: Replace the method body**

Edit `iosMath/lib/MTMathAtomFactory.m` around line 732. Replace:

```objc
+ (NSMutableDictionary<NSString*, NSString*>*) textToLatexSymbolNames
{
    static NSMutableDictionary<NSString*, NSString*>* textToCommands = nil;
    if (!textToCommands) {
        NSDictionary* commands = [self supportedLatexSymbols];
        textToCommands = [NSMutableDictionary dictionaryWithCapacity:commands.count];
        for (NSString* command in commands) {
            MTMathAtom* atom = commands[command];
            if (atom.nucleus.length == 0) {
                continue;
            }

            NSString* existingCommand = textToCommands[atom.nucleus];
            if (existingCommand) {
                // If there are 2 commands for the same symbol, choose one deterministically.
                if (command.length > existingCommand.length) {
                    // Keep the shorter command
                    continue;
                } else if (command.length == existingCommand.length) {
                    // If the length is the same, keep the alphabetically first
                    if ([command compare:existingCommand] == NSOrderedDescending) {
                        continue;
                    }
                }
            }
            // In other cases replace the command.
            textToCommands[atom.nucleus] = command;
        }
    }
    return textToCommands;
}
```

With:

```objc
+ (NSMutableDictionary<NSString*, NSMutableDictionary<NSNumber*, NSString*>*>*) textToLatexSymbolNames
{
    static NSMutableDictionary<NSString*, NSMutableDictionary<NSNumber*, NSString*>*>* textToCommands = nil;
    if (!textToCommands) {
        NSDictionary* commands = [self supportedLatexSymbols];
        textToCommands = [NSMutableDictionary dictionaryWithCapacity:commands.count];
        for (NSString* command in commands) {
            MTMathAtom* atom = commands[command];
            if (atom.nucleus.length == 0) {
                continue;
            }
            NSNumber* typeKey = @(atom.type);

            NSMutableDictionary<NSNumber*, NSString*>* inner = textToCommands[atom.nucleus];
            if (!inner) {
                inner = [NSMutableDictionary dictionaryWithCapacity:1];
                textToCommands[atom.nucleus] = inner;
            }

            NSString* existingCommand = inner[typeKey];
            if (existingCommand) {
                // If there are 2 commands for the same (nucleus, type), choose
                // one deterministically: shorter wins, alphabetical ascending breaks ties.
                if (command.length > existingCommand.length) {
                    continue;
                } else if (command.length == existingCommand.length) {
                    if ([command compare:existingCommand] == NSOrderedDescending) {
                        continue;
                    }
                }
            }
            inner[typeKey] = command;
        }
    }
    return textToCommands;
}
```

### Task 1.3: Update `+latexSymbolNameForAtom:` with Bin/Un retry

- [ ] **Step 1: Replace the method body**

Edit `iosMath/lib/MTMathAtomFactory.m` around line 184. Replace:

```objc
+ (nullable NSString*) latexSymbolNameForAtom:(MTMathAtom*) atom
{
    if (atom.nucleus.length == 0) {
        return nil;
    }
    NSDictionary* dict = [MTMathAtomFactory textToLatexSymbolNames];
    return dict[atom.nucleus];
}
```

With:

```objc
+ (nullable NSString*) latexSymbolNameForAtom:(MTMathAtom*) atom
{
    if (atom.nucleus.length == 0) {
        return nil;
    }
    NSDictionary<NSString*, NSDictionary<NSNumber*, NSString*>*>* dict = [MTMathAtomFactory textToLatexSymbolNames];
    NSDictionary<NSNumber*, NSString*>* inner = dict[atom.nucleus];
    if (!inner) {
        return nil;
    }
    NSString* name = inner[@(atom.type)];
    if (name) {
        return name;
    }
    // -[MTMathList finalized] reclassifies a leading/orphan Bin to Un. The
    // forward table only ever registers atoms as Bin, so a (nucleus, Un)
    // lookup must fall back to the Bin cell to recover the canonical name.
    if (atom.type == kMTMathAtomUnaryOperator) {
        return inner[@(kMTMathAtomBinaryOperator)];
    }
    return nil;
}
```

### Task 1.4: Update `+addLatexSymbol:value:` to write nested dict

- [ ] **Step 1: Replace the method body**

Edit `iosMath/lib/MTMathAtomFactory.m` around line 193. Replace:

```objc
+ (void)addLatexSymbol:(NSString *)name value:(MTMathAtom *)atom
{
    NSParameterAssert(name);
    NSParameterAssert(atom);
    NSMutableDictionary<NSString*, MTMathAtom*>* commands = [self supportedLatexSymbols];
    commands[name] = atom;
    if (atom.nucleus.length != 0) {
        NSMutableDictionary<NSString*, NSString*>* dict = [self textToLatexSymbolNames];
        dict[atom.nucleus] = name;
    }
}
```

With:

```objc
+ (void)addLatexSymbol:(NSString *)name value:(MTMathAtom *)atom
{
    NSParameterAssert(name);
    NSParameterAssert(atom);
    NSMutableDictionary<NSString*, MTMathAtom*>* commands = [self supportedLatexSymbols];
    commands[name] = atom;
    if (atom.nucleus.length != 0) {
        NSMutableDictionary<NSString*, NSMutableDictionary<NSNumber*, NSString*>*>* dict = [self textToLatexSymbolNames];
        NSMutableDictionary<NSNumber*, NSString*>* inner = dict[atom.nucleus];
        if (!inner) {
            inner = [NSMutableDictionary dictionaryWithCapacity:1];
            dict[atom.nucleus] = inner;
        }
        inner[@(atom.type)] = name;
    }
}
```

### Task 1.5: Run the regression test and full suite

- [ ] **Step 1: Run the targeted test**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testReverseMapTypeKeyedRoundTrip
```

Expected: PASS.

- [ ] **Step 2: Run the entire iosMath test suite (Xcode iOS)**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: all tests PASS. The full suite is needed because the reverse map is consulted by every round-trip assertion (`testBuilder`, `testSuperScript`, every `testSymbols`-flavored test). If anything fails, the Un/Bin retry or the keying logic is wrong — do not proceed.

- [ ] **Step 3: Run the SPM test suite**

```
swift test
```

Expected: PASS.

### Task 1.6: Commit

- [ ] **Step 1: Stage and commit**

```
git add iosMath/lib/MTMathAtomFactory.m iosMathTests/MTMathListBuilderTest.m
git commit -m "$(cat <<'EOF'
Re-key reverse symbol map by (nucleus, type)

textToLatexSymbolNames is now a two-level dict keyed by nucleus and then
boxed MTMathAtomType. latexSymbolNameForAtom: retries the (nucleus, Bin)
cell when (nucleus, Un) misses, since MTMathList.finalized reclassifies
leading Bin atoms to Un. This unblocks future PRs that register
type-distinct symbols at the same nucleus.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

### Task 1.7: Open PR

- [ ] **Step 1: Push and open PR**

```
git push -u origin HEAD
gh pr create --title "Re-key reverse symbol map by (nucleus, type)" --body "$(cat <<'EOF'
## Summary
- Re-keys `+textToLatexSymbolNames` from `nucleus → command` to `nucleus → (type → command)`
- Adds a Bin/Un retry in `+latexSymbolNameForAtom:` so `MTMathList.finalized`'s leading-Bin → Un reclassification doesn't break round-trip
- Updates `+addLatexSymbol:value:` to write to the nested dict
- Adds `testReverseMapTypeKeyedRoundTrip` covering `\\pm`, `\\cdot`, `\\leq`, `\\to`, `\\alpha` and confirms behavior with and without finalize-induced Bin → Un transitions

No new symbols and no public API changes. De-risks PRs that will add type-distinct entries at shared nuclei (triangle family, future `\\bigtriangleup`).

## Test plan
- [x] Existing iosMath tests still pass
- [x] SPM `swift test` still passes
- [x] New `testReverseMapTypeKeyedRoundTrip` covers Bin atoms at start-of-list and mid-list

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## PR 2 — Prime shorthand `'`

**Goal:** Make `f'`, `y''`, `f'''(x)` parse identically to `f^{\prime}`, `y^{\prime\prime}`, `f^{\prime\prime\prime}(x)`. Greedy consume consecutive primes; merge with a trailing `^` (TeX `\futurelet` behavior); allocate an empty Ord when there's no atom to attach to.

**Files:**
- Modify: `iosMath/lib/MTMathListBuilder.m:106-243` (`-buildInternal:stopChar:`)
- Test: `iosMathTests/MTMathListBuilderTest.m` (new method `testPrimes`)

Do not touch `+atomForCharacter:` — the `'` rejection at `MTMathAtomFactory.m:112` stays so `+mathListForCharacters:` (used by `+fractionWithNumeratorStr:`) continues to drop `'` rather than promote it to a prime atom.

### Task 2.1: Write the failing tests

- [ ] **Step 1: Add a parameterised `testPrimes` method**

Append to `iosMathTests/MTMathListBuilderTest.m`:

```objc
- (void) testPrimes
{
    // Per-case shape: @[ input,
    //                    expected top-level atom types,
    //                    index-into-top-level of the atom whose superscript holds the primes,
    //                    expected superscript atom types of that atom,
    //                    expected round-trip ]
    NSArray* cases = @[
        @[ @"f'",
           @[@(kMTMathAtomVariable)],
           @0, @[@(kMTMathAtomOrdinary)],
           @"f^{\\prime }" ],
        @[ @"y''",
           @[@(kMTMathAtomVariable)],
           @0, @[@(kMTMathAtomOrdinary), @(kMTMathAtomOrdinary)],
           @"y^{\\prime \\prime }" ],
        @[ @"f'''(x)",
           @[@(kMTMathAtomVariable), @(kMTMathAtomOpen),
             @(kMTMathAtomVariable), @(kMTMathAtomClose)],
           @0,
           @[@(kMTMathAtomOrdinary), @(kMTMathAtomOrdinary), @(kMTMathAtomOrdinary)],
           @"f^{\\prime \\prime \\prime }(x)" ],
        @[ @"'2",
           @[@(kMTMathAtomOrdinary), @(kMTMathAtomNumber)],
           @0, @[@(kMTMathAtomOrdinary)],
           @"{}^{\\prime }2" ],
        @[ @"f'^2",
           @[@(kMTMathAtomVariable)],
           @0,
           @[@(kMTMathAtomOrdinary), @(kMTMathAtomNumber)],
           @"f^{\\prime 2}" ],
        @[ @"f'_n",
           @[@(kMTMathAtomVariable)],
           @0, @[@(kMTMathAtomOrdinary)],
           @"f^{\\prime }_{n}" ],
        @[ @"f^\\prime",
           @[@(kMTMathAtomVariable)],
           @0, @[@(kMTMathAtomOrdinary)],
           @"f^{\\prime }" ],
    ];
    for (NSArray* c in cases) {
        NSString* input = c[0];
        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"Parse error for %@", input);
        XCTAssertNotNil(list, @"Nil list for %@", input);
        [self checkAtomTypes:list types:c[1] desc:input];

        NSUInteger idx = [c[2] unsignedIntegerValue];
        MTMathAtom* hostAtom = list.atoms[idx];
        XCTAssertNotNil(hostAtom.superScript, @"Missing superscript for %@", input);
        [self checkAtomTypes:hostAtom.superScript types:c[3] desc:input];

        // Each Ord atom in the superscript that has nucleus length 1 must be
        // a prime (U+2032). Number / Variable atoms in the merge case
        // (f'^2 → [\prime, 2]) are allowed and skipped.
        for (MTMathAtom* a in hostAtom.superScript.atoms) {
            if (a.type == kMTMathAtomOrdinary && a.nucleus.length == 1) {
                XCTAssertEqualObjects(a.nucleus, @"′", @"%@ prime nucleus", input);
            }
        }

        NSString* roundTrip = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(roundTrip, c[4], @"Round-trip mismatch for %@", input);
    }
}

- (void) testPrimesDoubleSuperscript
{
    // f^2'  →  f has superscript [2]; the ' triggers double-superscript path,
    // which mirrors the existing ^^ handling: allocate an empty Ord whose
    // superscript is the prime list.
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"f^2'" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(list.atoms.count, (NSUInteger)2);
    MTMathAtom* f = list.atoms[0];
    XCTAssertEqual(f.type, kMTMathAtomVariable);
    XCTAssertEqualObjects(f.nucleus, @"f");
    XCTAssertNotNil(f.superScript);
    XCTAssertEqual(f.superScript.atoms.count, (NSUInteger)1);

    MTMathAtom* empty = list.atoms[1];
    XCTAssertEqual(empty.type, kMTMathAtomOrdinary);
    XCTAssertEqualObjects(empty.nucleus, @"");
    XCTAssertNotNil(empty.superScript);
    XCTAssertEqual(empty.superScript.atoms.count, (NSUInteger)1);
    MTMathAtom* prime = empty.superScript.atoms[0];
    XCTAssertEqualObjects(prime.nucleus, @"′");

    NSString* rt = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(rt, @"f^{2}{}^{\\prime }");
}

- (void) testPrimesInsideBraces
{
    // f^{2'}  →  f has superscript [2]; the inner ' attaches to the inner 2.
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"f^{2'}" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTMathAtom* f = list.atoms[0];
    XCTAssertNotNil(f.superScript);
    XCTAssertEqual(f.superScript.atoms.count, (NSUInteger)1);
    MTMathAtom* two = f.superScript.atoms[0];
    XCTAssertEqual(two.type, kMTMathAtomNumber);
    XCTAssertEqualObjects(two.nucleus, @"2");
    XCTAssertNotNil(two.superScript);
    XCTAssertEqual(two.superScript.atoms.count, (NSUInteger)1);
    XCTAssertEqualObjects(two.superScript.atoms[0].nucleus, @"′");

    NSString* rt = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(rt, @"f^{2^{\\prime }}");
}
```

- [ ] **Step 2: Run the new tests; they must FAIL**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testPrimes \
  -only-testing:iosMathTests/MTMathListBuilderTest/testPrimesDoubleSuperscript \
  -only-testing:iosMathTests/MTMathListBuilderTest/testPrimesInsideBraces
```

Expected: all three FAIL. The `'` character is currently dropped silently (`+atomForCharacter:` returns nil → catch-all branch in `-buildInternal:` ignores it), so `f'` parses to just `[Variable f]` with no superscript. The assertions on `superScript.atoms.count` will fail.

### Task 2.2: Add the `'` branch in `-buildInternal:stopChar:`

- [ ] **Step 1: Insert the new branch**

Edit `iosMath/lib/MTMathListBuilder.m`. Locate the catch-all section starting at line 224:

```objc
        } else if (_spacesAllowed && ch == ' ') {
            // If spaces are allowed then spaces do not need escaping with a \ before being used.
            atom = [MTMathAtomFactory atomForLatexSymbolName:@" "];
        } else {
            atom = [MTMathAtomFactory atomForCharacter:ch];
            if (!atom) {
                // Not a recognized character
                continue;
            }
        }
```

Replace it with (note the new `else if (ch == '\'')` block inserted **before** the `_spacesAllowed` clause):

```objc
        } else if (ch == '\'') {
            // Prime shorthand. Mirrors the ^ branch: builds a list of \prime
            // atoms and attaches them as a superscript on prevAtom.
            if (oneCharOnly) {
                // We're filling a single-char slot (^X / _X / \fontStyle{X}).
                // Emit one \prime atom and let the caller consume it.
                MTMathAtom* primeAtom = [MTMathAtomFactory atomForLatexSymbolName:@"prime"];
                NSAssert(primeAtom != nil, @"\\prime must be registered");
                primeAtom.fontStyle = _currentFontStyle;
                [list addAtom:primeAtom];
                return list;
            }
            if (!prevAtom || prevAtom.superScript || !prevAtom.scriptsAllowed) {
                // No host atom, host already has a superscript, or host
                // forbids scripts: allocate an empty Ord to hang primes on.
                // Same pattern as the ^ branch above.
                prevAtom = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@""];
                [list addAtom:prevAtom];
            }
            MTMathList* primes = [MTMathList new];
            MTMathAtom* primeAtom = [MTMathAtomFactory atomForLatexSymbolName:@"prime"];
            NSAssert(primeAtom != nil, @"\\prime must be registered");
            [primes addAtom:primeAtom];
            // Greedy collect more consecutive primes.
            while ([self hasCharacters]) {
                unichar peek = [self getNextCharacter];
                if (peek == '\'') {
                    MTMathAtom* extra = [MTMathAtomFactory atomForLatexSymbolName:@"prime"];
                    [primes addAtom:extra];
                } else {
                    [self unlookCharacter];
                    break;
                }
            }
            // \futurelet merge with trailing ^: f'^2  →  superscript = [\prime, 2]
            if ([self hasCharacters]) {
                unichar peek = [self getNextCharacter];
                if (peek == '^') {
                    MTMathList* tail = [self buildInternal:true];
                    [primes append:tail];
                } else {
                    [self unlookCharacter];
                }
            }
            prevAtom.superScript = primes;
            continue;
        } else if (_spacesAllowed && ch == ' ') {
            // If spaces are allowed then spaces do not need escaping with a \ before being used.
            atom = [MTMathAtomFactory atomForLatexSymbolName:@" "];
        } else {
            atom = [MTMathAtomFactory atomForCharacter:ch];
            if (!atom) {
                // Not a recognized character
                continue;
            }
        }
```

Verify that `MTMathList` exposes an `-append:` method (it does — used at line 161 already).

- [ ] **Step 2: Run the new tests; they must PASS**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testPrimes \
  -only-testing:iosMathTests/MTMathListBuilderTest/testPrimesDoubleSuperscript \
  -only-testing:iosMathTests/MTMathListBuilderTest/testPrimesInsideBraces
```

Expected: all PASS.

- [ ] **Step 3: Run the full iosMath test suite**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: all tests PASS. In particular `testFrac` etc. (which use `+fractionWithNumeratorStr:`) must still work since we did not touch `+atomForCharacter:` / `+mathListForCharacters:`.

- [ ] **Step 4: Run SPM tests**

```
swift test
```

Expected: PASS.

### Task 2.3: Commit and open PR

- [ ] **Step 1: Stage, commit, push, open PR**

```
git add iosMath/lib/MTMathListBuilder.m iosMathTests/MTMathListBuilderTest.m
git commit -m "$(cat <<'EOF'
Add ' prime shorthand to the LaTeX parser

f' parses as f^{\prime}, y'' as y^{\prime\prime}, etc. Mirrors the
existing ^ branch in -buildInternal:stopChar:: allocates an empty Ord
when there is no host atom or the host already has a superscript,
greedily collects consecutive primes, and merges with a trailing ^
(TeX \futurelet behavior). +atomForCharacter:'s rejection of '
is preserved so +mathListForCharacters: (used by
+fractionWithNumeratorStr:) keeps its no-LaTeX semantics.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
git push -u origin HEAD
gh pr create --title "Add ' prime shorthand to parser" --body "$(cat <<'EOF'
## Summary
- Adds a `'` branch to `-buildInternal:stopChar:` mirroring the existing `^` branch
- Greedy consumes consecutive primes and merges with a trailing `^` per TeX `\\futurelet` semantics
- Reuses the already-registered `\\prime` symbol (U+2032 Ord); no symbol-table changes
- `+atomForCharacter:` / `+mathListForCharacters:` are intentionally left alone so `+fractionWithNumeratorStr:` keeps its no-LaTeX semantics

## Test plan
- [x] `testPrimes` covers f', y'', f'''(x), '2, f'^2, f'_n, and the f^\\prime regression case
- [x] `testPrimesDoubleSuperscript` covers f^2' (the empty-Ord allocation path)
- [x] `testPrimesInsideBraces` covers f^{2'} (prime inside an inner one-char slot)
- [x] Full iosMath + SPM suites pass

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## PR 3 — 31 negated relation symbols

**Goal:** Register every command in Feature 2 of the LLD as `kMTMathAtomRelation`. Symbol-table only.

**Files:**
- Modify: `iosMath/lib/MTMathAtomFactory.m:439` (extend `+supportedLatexSymbols`)
- Test: `iosMathTests/MTMathListBuilderTest.m` (new method `testNegatedRelations`)

### Task 3.1: Write the failing data-table test

- [ ] **Step 1: Add the test method**

Append to `iosMathTests/MTMathListBuilderTest.m`:

```objc
- (void) testNegatedRelations
{
    // Each row: @[ command (no leading \), expected nucleus codepoint NSNumber ]
    NSArray* rows = @[
        @[ @"nleq",            @0x2270 ],
        @[ @"ngeq",            @0x2271 ],
        @[ @"nless",           @0x226E ],
        @[ @"ngtr",            @0x226F ],
        @[ @"nsubseteq",       @0x2288 ],
        @[ @"nsupseteq",       @0x2289 ],
        @[ @"nmid",            @0x2224 ],
        @[ @"nparallel",       @0x2226 ],
        @[ @"nleftarrow",      @0x219A ],
        @[ @"nrightarrow",     @0x219B ],
        @[ @"nLeftarrow",      @0x21CD ],
        @[ @"nRightarrow",     @0x21CF ],
        @[ @"nleftrightarrow", @0x21AE ],
        @[ @"nLeftrightarrow", @0x21CE ],
        @[ @"nvdash",          @0x22AC ],
        @[ @"nvDash",          @0x22AD ],
        @[ @"nVdash",          @0x22AE ],
        @[ @"nVDash",          @0x22AF ],
        @[ @"ntriangleleft",   @0x22EA ],
        @[ @"ntriangleright",  @0x22EB ],
        @[ @"ntrianglelefteq", @0x22EC ],
        @[ @"ntrianglerighteq",@0x22ED ],
        @[ @"nsim",            @0x2241 ],
        @[ @"ncong",           @0x2247 ],
        @[ @"nequiv",          @0x2262 ],
        @[ @"nsubset",         @0x2284 ],
        @[ @"nsupset",         @0x2285 ],
        @[ @"nsucc",           @0x2281 ],
        @[ @"nprec",           @0x2280 ],
        @[ @"nsucceq",         @0x2AB1 ],
        @[ @"npreceq",         @0x2AB0 ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)31);
    for (NSArray* r in rows) {
        NSString* cmd = r[0];
        unichar expectedNuc = (unichar)[r[1] unsignedIntegerValue];
        NSString* input = [@"\\" stringByAppendingString:cmd];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"Parse error for %@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1, @"%@", input);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqual(atom.type, kMTMathAtomRelation, @"%@ type", input);
        XCTAssertEqual(atom.nucleus.length, (NSUInteger)1, @"%@ nucleus length", input);
        XCTAssertEqual([atom.nucleus characterAtIndex:0], expectedNuc, @"%@ nucleus", input);

        // Round-trip: relation surrounded by variables to keep finalize stable.
        NSString* probe = [NSString stringWithFormat:@"a%@ b", input];
        MTMathList* probeList = [MTMathListBuilder buildFromString:probe error:&error];
        XCTAssertNil(error);
        NSString* expectedRT = [NSString stringWithFormat:@"a%@ b", input];
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:probeList], expectedRT, @"round-trip %@", input);
    }
}
```

- [ ] **Step 2: Run the test; it must FAIL**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testNegatedRelations
```

Expected: FAIL with parse errors (`MTParseErrorInvalidCommand` for each `\n…`).

### Task 3.2: Register the 31 symbols

- [ ] **Step 1: Add a Feature-2 block to `+supportedLatexSymbols`**

Edit `iosMath/lib/MTMathAtomFactory.m`. Find the existing "Relations" section that ends around line 561 with `@"perp" : ...`. Add a new visually distinct block immediately after that closing `@"perp"` entry, before the comment `// operators`:

```objc
                     // Negated relations (amssymb)
                     @"nleq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≰"],
                     @"ngeq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≱"],
                     @"nless" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≮"],
                     @"ngtr" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≯"],
                     @"nsubseteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊈"],
                     @"nsupseteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊉"],
                     @"nmid" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"∤"],
                     @"nparallel" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"∦"],
                     @"nleftarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↚"],
                     @"nrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↛"],
                     @"nLeftarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⇍"],
                     @"nRightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⇏"],
                     @"nleftrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↮"],
                     @"nLeftrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⇎"],
                     @"nvdash" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊬"],
                     @"nvDash" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊭"],
                     @"nVdash" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊮"],
                     @"nVDash" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊯"],
                     @"ntriangleleft" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⋪"],
                     @"ntriangleright" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⋫"],
                     @"ntrianglelefteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⋬"],
                     @"ntrianglerighteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⋭"],
                     @"nsim" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≁"],
                     @"ncong" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≇"],
                     @"nequiv" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≢"],
                     @"nsubset" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊄"],
                     @"nsupset" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊅"],
                     @"nsucc" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊁"],
                     @"nprec" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊀"],
                     @"nsucceq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⪱"],
                     @"npreceq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⪰"],

```

- [ ] **Step 2: Run the test; it must PASS**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testNegatedRelations
```

Expected: PASS.

- [ ] **Step 3: Run the full suite and `testLatexSymbols` glyph sweep**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: all tests PASS. `testLatexSymbols` in `MTTypesetterTest.m` iterates every registered symbol against the default font (Latin Modern Math) and asserts non-zero width + ascent/descent — this is the safety net that flags missing glyphs. If any of the 31 new entries renders as zero-width in Latin Modern, the test fails with the symbol name in the assertion message; remove that entry, file a follow-up issue, and re-run.

### Task 3.3: Commit and open PR

- [ ] **Step 1: Stage, commit, push, open PR**

```
git add iosMath/lib/MTMathAtomFactory.m iosMathTests/MTMathListBuilderTest.m
git commit -m "$(cat <<'EOF'
Add 31 negated relation symbols from amssymb

Registers \\nleq, \\ngeq, \\nless, \\ngtr, \\nsubseteq, \\nsupseteq,
\\nmid, \\nparallel and 23 more negated-arrow / negated-relation
symbols as kMTMathAtomRelation. Symbol-table only; no parser or
layout changes.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
git push -u origin HEAD
gh pr create --title "Add 31 negated relation symbols" --body "$(cat <<'EOF'
## Summary
- Registers 31 \\n*-style symbols (negated relations, negated arrows) as `kMTMathAtomRelation`
- Symbol-table only — `+supportedLatexSymbols`
- New `testNegatedRelations` covers parse type, nucleus codepoint, and round-trip

## Test plan
- [x] `testNegatedRelations` parameterised over all 31 entries
- [x] Existing `testLatexSymbols` glyph sweep (Latin Modern Math) verifies non-zero render width

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## PR 4 — 11 boxed and circled binary operators

**Goal:** Register Feature 5 entries as `kMTMathAtomBinaryOperator`. This PR exercises the PR 1 Un/Bin retry path because every entry is Bin and can appear at the start of a list.

**Files:**
- Modify: `iosMath/lib/MTMathAtomFactory.m:439`
- Test: `iosMathTests/MTMathListBuilderTest.m` (new method `testBoxedCircledOperators`)

### Task 4.1: Write the failing test

- [ ] **Step 1: Add the test method**

Append to `iosMathTests/MTMathListBuilderTest.m`:

```objc
- (void) testBoxedCircledOperators
{
    NSArray* rows = @[
        @[ @"boxplus",       @0x229E ],
        @[ @"boxminus",      @0x229F ],
        @[ @"boxtimes",      @0x22A0 ],
        @[ @"boxdot",        @0x22A1 ],
        @[ @"circledast",    @0x229B ],
        @[ @"circledcirc",   @0x229A ],
        @[ @"circleddash",   @0x229D ],
        @[ @"barwedge",      @0x22BC ],
        @[ @"veebar",        @0x22BB ],
        @[ @"triangleleft",  @0x25C1 ],
        @[ @"triangleright", @0x25B7 ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)11);
    for (NSArray* r in rows) {
        NSString* cmd = r[0];
        unichar expectedNuc = (unichar)[r[1] unsignedIntegerValue];
        NSString* input = [@"\\" stringByAppendingString:cmd];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"%@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqual(atom.type, kMTMathAtomBinaryOperator, @"%@ pre-finalize type", input);
        XCTAssertEqual([atom.nucleus characterAtIndex:0], expectedNuc, @"%@ nucleus", input);

        // Between variables: stays Bin.
        NSString* middle = [NSString stringWithFormat:@"a%@ b", input];
        MTMathList* middleList = [MTMathListBuilder buildFromString:middle error:&error];
        XCTAssertNil(error);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:middleList],
                              ([NSString stringWithFormat:@"a%@ b", input]),
                              @"round-trip Bin in middle %@", input);

        // At start of list: finalize reclassifies Bin → Un. Round-trip must
        // still recover the command name via the Un/Bin retry (PR 1).
        NSString* start = [NSString stringWithFormat:@"%@ a", input];
        MTMathList* startList = [MTMathListBuilder buildFromString:start error:&error];
        XCTAssertNil(error);
        MTMathList* startFinal = [startList finalized];
        XCTAssertEqual([startFinal.atoms[0] type], kMTMathAtomUnaryOperator,
                       @"%@ should finalize to Un at start of list", input);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:startFinal],
                              ([NSString stringWithFormat:@"%@ a", input]),
                              @"round-trip Bin→Un at start %@", input);
    }
}
```

- [ ] **Step 2: Run; it must FAIL**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testBoxedCircledOperators
```

Expected: FAIL with parse errors for every entry.

### Task 4.2: Register the 11 symbols

- [ ] **Step 1: Append to `+supportedLatexSymbols`**

Edit `iosMath/lib/MTMathAtomFactory.m`. Find the existing "operators" block (starts at the comment `// operators` near line 563, ends at the `@"amalg"` entry around line 589). Add this block immediately after `@"amalg"`, before `// No limit operators`:

```objc
                     // Boxed / circled binary operators (amssymb)
                     @"boxplus" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"⊞"],
                     @"boxminus" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"⊟"],
                     @"boxtimes" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"⊠"],
                     @"boxdot" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"⊡"],
                     @"circledast" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"⊛"],
                     @"circledcirc" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"⊚"],
                     @"circleddash" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"⊝"],
                     @"barwedge" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"⊼"],
                     @"veebar" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"⊻"],
                     @"triangleleft" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"◁"],
                     @"triangleright" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"▷"],

```

- [ ] **Step 2: Run the test; it must PASS**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testBoxedCircledOperators
```

Expected: PASS. The "round-trip Bin→Un at start" assertions specifically exercise the PR 1 retry — if PR 1 is missing or wrong, these fail with output like `⊞ a` instead of `\\boxplus a`.

- [ ] **Step 3: Run full suite**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
swift test
```

Expected: all PASS.

### Task 4.3: Commit and open PR

- [ ] **Step 1: Stage, commit, push, open PR**

```
git add iosMath/lib/MTMathAtomFactory.m iosMathTests/MTMathListBuilderTest.m
git commit -m "$(cat <<'EOF'
Add 11 boxed and circled binary operators

\\boxplus, \\boxminus, \\boxtimes, \\boxdot, \\circledast,
\\circledcirc, \\circleddash, \\barwedge, \\veebar, \\triangleleft,
\\triangleright. All registered as kMTMathAtomBinaryOperator.
Round-trip tests verify the Bin → Un retry in
+latexSymbolNameForAtom: handles the start-of-list case.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
git push -u origin HEAD
gh pr create --title "Add 11 boxed/circled binary operators" --body "$(cat <<'EOF'
## Summary
- Registers \\boxplus, \\boxminus, \\boxtimes, \\boxdot, \\circledast, \\circledcirc, \\circleddash, \\barwedge, \\veebar, \\triangleleft, \\triangleright as `kMTMathAtomBinaryOperator`
- Symbol-table only

## Test plan
- [x] `testBoxedCircledOperators` parameterised over all 11 entries
- [x] Covers both Bin (middle of list) and Un (start of list, finalize-reclassified) round-trip paths
- [x] `testLatexSymbols` glyph sweep passes for all 11 entries

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## PR 5 — 16 harpoons / extended arrows + `\restriction` alias

**Goal:** Register Feature 3 entries as `kMTMathAtomRelation` and add the single Feature-6 alias that depends on this PR (`\restriction → \upharpoonright`). Bundling ensures the alias never resolves to a missing canonical.

**Files:**
- Modify: `iosMath/lib/MTMathAtomFactory.m:439, 709-730`
- Test: `iosMathTests/MTMathListBuilderTest.m` (new methods `testHarpoonsAndExtendedArrows`, `testRestrictionAlias`)

### Task 5.1: Write the failing tests

- [ ] **Step 1: Add the test methods**

Append to `iosMathTests/MTMathListBuilderTest.m`:

```objc
- (void) testHarpoonsAndExtendedArrows
{
    NSArray* rows = @[
        @[ @"rightleftharpoons", @0x21CC ],
        @[ @"leftrightharpoons", @0x21CB ],
        @[ @"upharpoonleft",     @0x21BF ],
        @[ @"upharpoonright",    @0x21BE ],
        @[ @"downharpoonleft",   @0x21C3 ],
        @[ @"downharpoonright",  @0x21C2 ],
        @[ @"rightharpoonup",    @0x21C0 ],
        @[ @"leftharpoonup",     @0x21BC ],
        @[ @"rightharpoondown",  @0x21C1 ],
        @[ @"leftharpoondown",   @0x21BD ],
        @[ @"hookleftarrow",     @0x21A9 ],
        @[ @"hookrightarrow",    @0x21AA ],
        @[ @"twoheadleftarrow",  @0x219E ],
        @[ @"twoheadrightarrow", @0x21A0 ],
        @[ @"rightarrowtail",    @0x21A3 ],
        @[ @"leftarrowtail",     @0x21A2 ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)16);
    for (NSArray* r in rows) {
        NSString* cmd = r[0];
        unichar expectedNuc = (unichar)[r[1] unsignedIntegerValue];
        NSString* input = [@"\\" stringByAppendingString:cmd];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"%@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqual(atom.type, kMTMathAtomRelation, @"%@ type", input);
        XCTAssertEqual([atom.nucleus characterAtIndex:0], expectedNuc, @"%@ nucleus", input);

        NSString* probe = [NSString stringWithFormat:@"a%@ b", input];
        MTMathList* probeList = [MTMathListBuilder buildFromString:probe error:&error];
        XCTAssertNil(error);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:probeList],
                              ([NSString stringWithFormat:@"a%@ b", input]),
                              @"round-trip %@", input);
    }
}

- (void) testRestrictionAlias
{
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\restriction" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomRelation);
    XCTAssertEqualObjects(atom.nucleus, @"↾", @"\\restriction should resolve to \\upharpoonright (U+21BE)");

    // Round-trip emits canonical.
    MTMathList* probe = [MTMathListBuilder buildFromString:@"a\\restriction b" error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:probe], @"a\\upharpoonright b");
}
```

- [ ] **Step 2: Run; both must FAIL**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testHarpoonsAndExtendedArrows \
  -only-testing:iosMathTests/MTMathListBuilderTest/testRestrictionAlias
```

Expected: FAIL.

### Task 5.2: Register the 16 symbols + `\restriction` alias in a single commit

This must be one commit so `\restriction → upharpoonright` is never broken on a transient build.

- [ ] **Step 1: Add Feature-3 block to `+supportedLatexSymbols`**

Edit `iosMath/lib/MTMathAtomFactory.m`. Find the existing "Arrows" block ending at `@"Longleftrightarrow"` around line 528. Add immediately after:

```objc
                     // Harpoons and extended arrows (amssymb)
                     @"rightleftharpoons" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⇌"],
                     @"leftrightharpoons" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⇋"],
                     @"upharpoonleft" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↿"],
                     @"upharpoonright" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↾"],
                     @"downharpoonleft" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⇃"],
                     @"downharpoonright" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⇂"],
                     @"rightharpoonup" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⇀"],
                     @"leftharpoonup" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↼"],
                     @"rightharpoondown" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⇁"],
                     @"leftharpoondown" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↽"],
                     @"hookleftarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↩"],
                     @"hookrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↪"],
                     @"twoheadleftarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↞"],
                     @"twoheadrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↠"],
                     @"rightarrowtail" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↣"],
                     @"leftarrowtail" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"↢"],

```

- [ ] **Step 2: Add the `\restriction` alias**

Edit `iosMath/lib/MTMathAtomFactory.m` around line 713. Find the `+aliases` literal:

```objc
        aliases = @{
                    @"lnot" : @"neg",
                    @"land" : @"wedge",
                    @"lor" : @"vee",
                    @"ne" : @"neq",
                    @"le" : @"leq",
                    @"ge" : @"geq",
                    @"lbrace" : @"{",
                    @"rbrace" : @"}",
                    @"Vert" : @"|",
                    @"gets" : @"leftarrow",
                    @"to" : @"rightarrow",
                    @"iff" : @"Longleftrightarrow",
                    @"AA" : @"angstrom",
                    };
```

Replace with:

```objc
        aliases = @{
                    @"lnot" : @"neg",
                    @"land" : @"wedge",
                    @"lor" : @"vee",
                    @"ne" : @"neq",
                    @"le" : @"leq",
                    @"ge" : @"geq",
                    @"lbrace" : @"{",
                    @"rbrace" : @"}",
                    @"Vert" : @"|",
                    @"gets" : @"leftarrow",
                    @"to" : @"rightarrow",
                    @"iff" : @"Longleftrightarrow",
                    @"AA" : @"angstrom",
                    @"restriction" : @"upharpoonright",
                    };
```

- [ ] **Step 3: Run both tests; they must PASS**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testHarpoonsAndExtendedArrows \
  -only-testing:iosMathTests/MTMathListBuilderTest/testRestrictionAlias
```

Expected: PASS.

- [ ] **Step 4: Run the full suite**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
swift test
```

Expected: all PASS.

### Task 5.3: Commit and open PR

- [ ] **Step 1: Single commit covering symbols and alias**

```
git add iosMath/lib/MTMathAtomFactory.m iosMathTests/MTMathListBuilderTest.m
git commit -m "$(cat <<'EOF'
Add 16 harpoon / extended-arrow symbols + \\restriction alias

\\rightleftharpoons, \\leftrightharpoons, \\upharpoonleft,
\\upharpoonright, \\downharpoonleft, \\downharpoonright,
\\rightharpoonup, \\leftharpoonup, \\rightharpoondown,
\\leftharpoondown, \\hookleftarrow, \\hookrightarrow,
\\twoheadleftarrow, \\twoheadrightarrow, \\rightarrowtail,
\\leftarrowtail registered as kMTMathAtomRelation.

\\restriction registered as an alias for \\upharpoonright.
Bundled in one commit so the alias is never broken on a transient
build.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
git push -u origin HEAD
gh pr create --title "Add harpoons, extended arrows + \\restriction alias" --body "$(cat <<'EOF'
## Summary
- Registers 16 harpoon and extended-arrow symbols as `kMTMathAtomRelation`
- Adds `\\restriction` alias resolving to `\\upharpoonright` (bundled in same commit so the alias is never broken on a transient build)

## Test plan
- [x] `testHarpoonsAndExtendedArrows` parameterised over all 16 entries
- [x] `testRestrictionAlias` verifies the alias resolves to U+21BE and round-trips as `\\upharpoonright`
- [x] `testLatexSymbols` glyph sweep passes for all 16 entries

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## PR 6 — 34 missing relations/ordinaries + Feature 6 aliases + `\square` cleanup

**Goal:** Land Feature 4's symbols (17 Rel + 17 Ord = 34 entries; the LLD's §1 summary undercounts at "~25" but its §3.3 listing enumerates all 34), replace `\square`'s placeholder mis-wiring with a real Ord/U+25A1 entry registered under `\Box`, and add the eight remaining Feature 6 aliases. Must be a single commit so dependent aliases (`\square → \Box`, `\vartriangle → \triangle`) never resolve to a missing canonical.

**Files:**
- Modify: `iosMath/lib/MTMathAtomFactory.m:439, 709-730` (remove `@"square"` row, add 34 new entries, add 8 aliases)
- Test: `iosMathTests/MTMathListBuilderTest.m` (new methods `testMissingRelationsAndOrdinaries`, `testNewAliases`, `testSquareBoxParity`)

`+placeholder` (line 65) is **not** changed. Programmatic clients that want a placeholder atom continue to call `+placeholder` directly. Only the LaTeX command `\square` is unwired from it.

### Task 6.1: Write the failing tests

- [ ] **Step 1: Add three test methods**

Append to `iosMathTests/MTMathListBuilderTest.m`:

```objc
- (void) testMissingRelationsAndOrdinaries
{
    // Each row: @[ command, expected nucleus codepoint NSNumber, expected pre-finalize type ]
    NSArray* rows = @[
        // Relations
        @[ @"vdash",            @0x22A2, @(kMTMathAtomRelation) ],
        @[ @"dashv",            @0x22A3, @(kMTMathAtomRelation) ],
        @[ @"Subset",           @0x22D0, @(kMTMathAtomRelation) ],
        @[ @"Supset",           @0x22D1, @(kMTMathAtomRelation) ],
        @[ @"backsim",          @0x223D, @(kMTMathAtomRelation) ],
        @[ @"backsimeq",        @0x22CD, @(kMTMathAtomRelation) ],
        @[ @"eqsim",            @0x2242, @(kMTMathAtomRelation) ],
        @[ @"Bumpeq",           @0x224E, @(kMTMathAtomRelation) ],
        @[ @"bumpeq",           @0x224F, @(kMTMathAtomRelation) ],
        @[ @"therefore",        @0x2234, @(kMTMathAtomRelation) ],
        @[ @"because",          @0x2235, @(kMTMathAtomRelation) ],
        @[ @"multimap",         @0x22B8, @(kMTMathAtomRelation) ],
        @[ @"vartriangleleft",  @0x22B2, @(kMTMathAtomRelation) ],
        @[ @"vartriangleright", @0x22B3, @(kMTMathAtomRelation) ],
        @[ @"trianglelefteq",   @0x22B4, @(kMTMathAtomRelation) ],
        @[ @"trianglerighteq",  @0x22B5, @(kMTMathAtomRelation) ],
        @[ @"triangleq",        @0x225C, @(kMTMathAtomRelation) ],
        // Ordinaries
        @[ @"complement",       @0x2201, @(kMTMathAtomOrdinary) ],
        @[ @"Box",              @0x25A1, @(kMTMathAtomOrdinary) ],
        @[ @"Diamond",          @0x25C7, @(kMTMathAtomOrdinary) ],
        @[ @"lozenge",          @0x25CA, @(kMTMathAtomOrdinary) ],
        @[ @"blacklozenge",     @0x29EB, @(kMTMathAtomOrdinary) ],
        @[ @"diamondsuit",      @0x2662, @(kMTMathAtomOrdinary) ],
        @[ @"heartsuit",        @0x2661, @(kMTMathAtomOrdinary) ],
        @[ @"spadesuit",        @0x2660, @(kMTMathAtomOrdinary) ],
        @[ @"clubsuit",         @0x2663, @(kMTMathAtomOrdinary) ],
        @[ @"beth",             @0x2136, @(kMTMathAtomOrdinary) ],
        @[ @"gimel",            @0x2137, @(kMTMathAtomOrdinary) ],
        @[ @"daleth",           @0x2138, @(kMTMathAtomOrdinary) ],
        @[ @"triangledown",     @0x25BD, @(kMTMathAtomOrdinary) ],
        @[ @"blacktriangle",    @0x25B2, @(kMTMathAtomOrdinary) ],
        @[ @"blacktriangledown",@0x25BC, @(kMTMathAtomOrdinary) ],
        @[ @"blacktriangleleft",@0x25C0, @(kMTMathAtomOrdinary) ],
        @[ @"blacktriangleright",@0x25B6, @(kMTMathAtomOrdinary) ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)34); // 17 Rel + 17 Ord. LLD §1 reads
        // "~25" but §3.3 enumerates 34 distinct commands; the listing is the
        // source of truth.
    for (NSArray* r in rows) {
        NSString* cmd = r[0];
        unichar expectedNuc = (unichar)[r[1] unsignedIntegerValue];
        MTMathAtomType expectedType = (MTMathAtomType)[r[2] unsignedIntegerValue];
        NSString* input = [@"\\" stringByAppendingString:cmd];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"%@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1, @"%@", input);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqual(atom.type, expectedType, @"%@ pre-finalize type", input);
        XCTAssertEqual([atom.nucleus characterAtIndex:0], expectedNuc, @"%@ nucleus", input);
    }
}

- (void) testNewAliases
{
    // alias → @[ canonical command, canonical nucleus, expected round-trip of "\\alias" ]
    NSArray* rows = @[
        @[ @"implies",      @"Longrightarrow", @"⟹", @"\\Longrightarrow " ],
        @[ @"impliedby",    @"Longleftarrow",  @"⟸", @"\\Longleftarrow " ],
        @[ @"dotsc",        @"ldots",          @"…", @"\\ldots " ],
        @[ @"dotsb",        @"cdots",          @"⋯", @"\\cdots " ],
        @[ @"dotsm",        @"cdots",          @"⋯", @"\\cdots " ],
        @[ @"dotsi",        @"ldots",          @"…", @"\\ldots " ],
        @[ @"square",       @"Box",            @"□", @"\\Box " ],
        @[ @"vartriangle",  @"triangle",       @"△", @"\\triangle " ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)8);
    for (NSArray* r in rows) {
        NSString* alias = r[0];
        NSString* expectedNucleus = r[2];
        NSString* expectedRT = r[3];
        NSString* input = [@"\\" stringByAppendingString:alias];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"%@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqualObjects(atom.nucleus, expectedNucleus, @"%@ nucleus", input);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], expectedRT,
                              @"%@ round-trip", input);
    }
}

- (void) testSquareBoxParity
{
    // Parse "\\square" and "\\Box" — both must produce an Ord at U+25A1.
    NSError* error = nil;
    MTMathList* a = [MTMathListBuilder buildFromString:@"\\square" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(a.atoms.count, (NSUInteger)1);
    XCTAssertEqual([a.atoms[0] type], kMTMathAtomOrdinary);
    XCTAssertEqualObjects([a.atoms[0] nucleus], @"□");

    MTMathList* b = [MTMathListBuilder buildFromString:@"\\Box" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(b.atoms.count, (NSUInteger)1);
    XCTAssertEqual([b.atoms[0] type], kMTMathAtomOrdinary);
    XCTAssertEqualObjects([b.atoms[0] nucleus], @"□");

    // Round-trip both: only \\Box is canonical at (U+25A1, Ord), so both emit \\Box .
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:a], @"\\Box ");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:b], @"\\Box ");

    // +placeholder is untouched: still produces a kMTMathAtomPlaceholder atom.
    MTMathAtom* p = [MTMathAtomFactory placeholder];
    XCTAssertEqual(p.type, kMTMathAtomPlaceholder);
    XCTAssertEqualObjects(p.nucleus, @"□");
}
```

- [ ] **Step 2: Run; all three must FAIL**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testMissingRelationsAndOrdinaries \
  -only-testing:iosMathTests/MTMathListBuilderTest/testNewAliases \
  -only-testing:iosMathTests/MTMathListBuilderTest/testSquareBoxParity
```

Expected: FAIL. In particular `testSquareBoxParity` currently produces a `kMTMathAtomPlaceholder` for `\square` (line 444 of `MTMathAtomFactory.m`).

### Task 6.2: Update the factory in a single commit

The three edits below must all land in one commit because the new aliases (`\square → Box`, `\vartriangle → triangle`) depend on the new symbol-table entries.

- [ ] **Step 1: Remove the `\square → placeholder` row**

Edit `iosMath/lib/MTMathAtomFactory.m` around line 444. Delete this line:

```objc
                     @"square" : [MTMathAtomFactory placeholder],
                     
```

- [ ] **Step 2: Add the 17 new Relations and 17 new Ordinaries**

Append after the negated-relations block added in PR 3 (or any other consistent location inside `+supportedLatexSymbols`). The two sub-groups can be placed adjacent to the existing "Relations" and "Other symbols" blocks respectively:

```objc
                     // Missing relations (proof / set theory / amssymb)
                     @"vdash" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊢"],
                     @"dashv" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊣"],
                     @"Subset" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⋐"],
                     @"Supset" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⋑"],
                     @"backsim" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"∽"],
                     @"backsimeq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⋍"],
                     @"eqsim" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≂"],
                     @"Bumpeq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≎"],
                     @"bumpeq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≏"],
                     @"therefore" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"∴"],
                     @"because" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"∵"],
                     @"multimap" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊸"],
                     @"vartriangleleft" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊲"],
                     @"vartriangleright" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊳"],
                     @"trianglelefteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊴"],
                     @"trianglerighteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"⊵"],
                     @"triangleq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"≜"],

                     // Missing ordinaries (logic / suits / Hebrew letters / amssymb)
                     @"complement" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"∁"],
                     @"Box" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"□"],
                     @"Diamond" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"◇"],
                     @"lozenge" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"◊"],
                     @"blacklozenge" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"⧫"],
                     @"diamondsuit" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"♢"],
                     @"heartsuit" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"♡"],
                     @"spadesuit" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"♠"],
                     @"clubsuit" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"♣"],
                     @"beth" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"ℶ"],
                     @"gimel" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"ℷ"],
                     @"daleth" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"ℸ"],
                     @"triangledown" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"▽"],
                     @"blacktriangle" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"▲"],
                     @"blacktriangledown" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"▼"],
                     @"blacktriangleleft" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"◀"],
                     @"blacktriangleright" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"▶"],

```

- [ ] **Step 3: Add the 8 remaining aliases**

Edit the `+aliases` literal (already extended in PR 5 to include `\restriction`):

```objc
        aliases = @{
                    @"lnot" : @"neg",
                    @"land" : @"wedge",
                    @"lor" : @"vee",
                    @"ne" : @"neq",
                    @"le" : @"leq",
                    @"ge" : @"geq",
                    @"lbrace" : @"{",
                    @"rbrace" : @"}",
                    @"Vert" : @"|",
                    @"gets" : @"leftarrow",
                    @"to" : @"rightarrow",
                    @"iff" : @"Longleftrightarrow",
                    @"AA" : @"angstrom",
                    @"restriction" : @"upharpoonright",
                    @"implies" : @"Longrightarrow",
                    @"impliedby" : @"Longleftarrow",
                    @"dotsc" : @"ldots",
                    @"dotsb" : @"cdots",
                    @"dotsm" : @"cdots",
                    @"dotsi" : @"ldots",
                    @"square" : @"Box",
                    @"vartriangle" : @"triangle",
                    };
```

- [ ] **Step 4: Run the new tests; all must PASS**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iosMathTests/MTMathListBuilderTest/testMissingRelationsAndOrdinaries \
  -only-testing:iosMathTests/MTMathListBuilderTest/testNewAliases \
  -only-testing:iosMathTests/MTMathListBuilderTest/testSquareBoxParity
```

Expected: PASS. Particularly verify `testSquareBoxParity`: both `\square` and `\Box` parse to Ord/U+25A1, and both round-trip as `\Box ` (only `Box` lives in the `(U+25A1, Ord)` cell of the reverse map because `square` is an alias and aliases are not registered in the reverse map by the build loop).

- [ ] **Step 5: Run the full suite**

```
xcodebuild test -project iosMath.xcodeproj -scheme iosMath -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
swift test
```

Expected: all PASS. In particular `testLatexSymbols` is still the safety net for glyph coverage in Latin Modern Math; if `\blacklozenge` (U+29EB) or another sparse symbol fails there, drop it from the registration (file an issue) and re-run.

### Task 6.3: Commit and open PR

- [ ] **Step 1: Single commit**

```
git add iosMath/lib/MTMathAtomFactory.m iosMathTests/MTMathListBuilderTest.m
git commit -m "$(cat <<'EOF'
Add 34 logic/set-theory/suit symbols, 8 aliases, and clean up \\square

Adds 17 missing relations (\\vdash, \\dashv, \\Subset, \\Supset,
\\backsim, \\backsimeq, \\eqsim, \\Bumpeq, \\bumpeq, \\therefore,
\\because, \\multimap, \\vartriangleleft, \\vartriangleright,
\\trianglelefteq, \\trianglerighteq, \\triangleq) and 17 missing
ordinaries (\\complement, \\Box, \\Diamond, \\lozenge,
\\blacklozenge, the four card suits, the Hebrew letters, and the
triangle family).

Removes the \\square → +placeholder mis-wiring and registers
\\Box as the canonical Ord/U+25A1 entry. \\square now resolves
via an alias to \\Box. +placeholder is unchanged.

Adds the remaining Feature-6 aliases: \\implies, \\impliedby,
\\dotsc, \\dotsb, \\dotsm, \\dotsi, \\square, \\vartriangle.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
git push -u origin HEAD
gh pr create --title "Add missing relations/ordinaries, aliases, \\square cleanup" --body "$(cat <<'EOF'
## Summary
- Registers 17 missing relations and 17 missing ordinaries (34 entries total — logic, set theory, suits, Hebrew, triangle family) — Feature 4 from the LLD
- Removes the `\\square → +placeholder` mis-wiring (the placeholder type "does not exist in TeX"; see `MTMathList.h:51`). `+placeholder` itself is unchanged
- Adds 8 aliases: `\\implies`, `\\impliedby`, `\\dotsc`, `\\dotsb`, `\\dotsm`, `\\dotsi`, `\\square`, `\\vartriangle`
- Bundled in one commit so aliases never resolve to a missing canonical

## Test plan
- [x] `testMissingRelationsAndOrdinaries` parameterised over all 34 entries
- [x] `testNewAliases` covers all 8 aliases including round-trip
- [x] `testSquareBoxParity` verifies `\\square` and `\\Box` both produce Ord/U+25A1 and both round-trip as `\\Box`; `+placeholder` still produces kMTMathAtomPlaceholder
- [x] `testLatexSymbols` glyph sweep passes in Latin Modern Math

## Note for reviewers
The `\\square` round-trip output changes from the literal U+25A1 character (today's behavior, because the placeholder atom is not in the reverse map) to `\\Box ` (after this PR). This is a deliberate cleanup and not considered a backwards-compatibility break since `\\square`-as-placeholder was a layering accident.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Verification Across All PRs

After each PR is merged, the cumulative state should be:

- Every command listed in `iosMath_feature_requirements.md` Sections 1–6 parses without error
- `+supportedLatexSymbolNames` count grows by exactly 91 net entries: PR 3 +31, PR 4 +11, PR 5 +16, PR 6 +34 − 1 (the `\square` placeholder row is removed). The LLD §1 says "~25" for Feature 4 but its §3.3 listing enumerates all 34 commands; this plan implements the listing.
- `+aliases` count grows from 13 to 22 (PR 5 +1 for `\restriction`, PR 6 +8 for `\implies`, `\impliedby`, `\dotsc`, `\dotsb`, `\dotsm`, `\dotsi`, `\square`, `\vartriangle`)
- `MTMathListBuilder` has one new `else if (ch == '\'')` branch in `-buildInternal:stopChar:`
- `+placeholder` is unchanged
- `testLatexSymbols` passes against Latin Modern Math for every new entry
- All existing tests pass

Open Question 1 from the LLD (sequencing) is resolved by the 6-PR plan above. Open Question 2 (sparse-glyph triage for XITS/Termes) is deferred — the three-font sweep refactor is a follow-up. Open Questions 3, 4, and 5 are confirmed: `\square` round-trips as `\Box`, prime inside `^{2'}` produces TeX-canonical `2^{\prime}`, and no `\square` deprecation period is needed.

---

*End of plan.*
