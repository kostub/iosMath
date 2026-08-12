//
//  MTModularArithmeticTest.m
//  iosMath
//
//  Tests for \bmod, \pmod, \mod, \pod.
//

#import <XCTest/XCTest.h>
#import <CoreText/CoreText.h>

#import "MTMathList.h"
#import "MTMathListBuilder.h"
#import "MTMathAtomFactory.h"
#import "MTTypesetter.h"
#import "MTFont+Internal.h"
#import "MTFontManager.h"
#import "MTMathListDisplay.h"
#import "MTMathListDisplayInternal.h"
#import "MTFontMathTable.h"

@interface MTModularArithmeticTest : XCTestCase
@property (nonatomic) MTFont* font;
@end

// Declared privately in MTMathList.m; redeclared here so the tests can drive
// macro expansion in isolation and observe RAW (unreclassified) output.
@interface MTMathList (MTMacroExpansionTesting)
- (MTMathList *)expandMacros;
@end

// Defined under "Equivalence helpers" below.
static NSString* ListSignature(MTMathList* list);

@implementation MTModularArithmeticTest

- (void)setUp
{
    [super setUp];
    self.font = MTFontManager.fontManager.defaultFont;   // Latin Modern Math @ 20pt
}

- (MTMathListDisplay*)displayForLaTeX:(NSString*)latex
{
    MTMathList* list = [MTMathListBuilder buildFromString:latex];
    XCTAssertNotNil(list, @"%@ failed to parse", latex);
    return [MTTypesetter createLineForMathList:list font:self.font style:kMTLineStyleDisplay];
}

// Collects the text of every MTCTLineDisplay in the tree, in traversal order.
- (NSString*)renderedTextForDisplay:(MTDisplay*)display
{
    if ([display isKindOfClass:[MTCTLineDisplay class]]) {
        return [(MTCTLineDisplay*)display attributedString].string;
    }
    if ([display isKindOfClass:[MTMathListDisplay class]]) {
        NSMutableString* out = [NSMutableString string];
        for (MTDisplay* sub in [(MTMathListDisplay*)display subDisplays]) {
            [out appendString:[self renderedTextForDisplay:sub]];
        }
        return out;
    }
    return @"";
}

#pragma mark - \bmod

// 17 \bmod 5 -> [Number "17", Bin "mod", Number "5"] once finalized
// (the 17 is fused by finalize, MTMathList.m:1709-1716).
- (void)testBmodParsesAsBinaryOperator
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"17 \\bmod 5"];
    XCTAssertNotNil(list);
    MTMathList* finalized = list.finalized;
    XCTAssertEqual(finalized.atoms.count, 3ul);

    MTMathAtom* lhs = finalized.atoms[0];
    XCTAssertEqual(lhs.type, kMTMathAtomNumber);
    XCTAssertEqualObjects(lhs.nucleus, @"17");

    MTMathAtom* mod = finalized.atoms[1];
    XCTAssertEqual(mod.type, kMTMathAtomBinaryOperator);
    XCTAssertEqualObjects(mod.nucleus, @"mod");
    // No font style is set: changeFont's italic remap only applies to Variable
    // and Number atoms (MTTypesetter.m:539-545), so a Bin "mod" is already upright.
    XCTAssertEqual(mod.fontStyle, kMTFontStyleDefault);

    MTMathAtom* rhs = finalized.atoms[2];
    XCTAssertEqual(rhs.type, kMTMathAtomNumber);
    XCTAssertEqualObjects(rhs.nucleus, @"5");
}

// The reverse (nucleus, type) map is auto-populated for symbol-table entries
// (MTMathAtomFactory.m:190-239), so serialization round-trips without extra code.
- (void)testBmodSerializes
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"17 \\bmod 5"];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"17\\bmod 5");
}

- (void)testBmodIsDiscoverable
{
    XCTAssertTrue([[MTMathAtomFactory supportedLatexSymbolNames] containsObject:@"bmod"]);
}

#pragma mark - \bmod boundary reclassification

// TeX Rule 5: a Bin with no left operand is not a binary operator.
- (void)testBmodAtBoundariesDemotesToUnary
{
    NSArray<NSString*>* atStart = @[ @"\\bmod 5", @"(\\bmod b", @"a + \\bmod b",
                                     @"a = \\bmod b", @"a , \\bmod b" ];
    for (NSString* latex in atStart) {
        MTMathList* finalized = [MTMathListBuilder buildFromString:latex].finalized;
        MTMathAtom* mod = nil;
        for (MTMathAtom* atom in finalized.atoms) {
            if ([atom.nucleus isEqualToString:@"mod"]) { mod = atom; break; }
        }
        XCTAssertNotNil(mod, @"%@", latex);
        XCTAssertEqual(mod.type, kMTMathAtomUnaryOperator, @"%@", latex);
    }

    // At list end there is no right operand either.
    MTMathList* trailing = [MTMathListBuilder buildFromString:@"5 \\bmod"].finalized;
    XCTAssertEqual([trailing.atoms.lastObject type], kMTMathAtomUnaryOperator);
}

// A leading \bmod must not trip the (Open, Bin) kMTSpaceInvalid assert.
- (void)testBmodAtBoundariesBuildsDisplay
{
    XCTAssertNoThrow([self displayForLaTeX:@"\\bmod 5"]);
    XCTAssertNoThrow([self displayForLaTeX:@"(\\bmod b"]);
    XCTAssertNoThrow([self displayForLaTeX:@"5 \\bmod"]);
}

// Upright ASCII "mod", not the italic mathematical alphanumerics 𝑚𝑜𝑑.
- (void)testBmodRendersUpright
{
    NSString* text = [self renderedTextForDisplay:[self displayForLaTeX:@"17 \\bmod 5"]];
    XCTAssertTrue([text containsString:@"mod"], @"got %@", text);
    XCTAssertFalse([text containsString:@"\U0001D45A"], @"italic m in %@", text);   // 𝑚
}

// A Bin demoted to Unary still serializes back to \bmod: latexSymbolNameForAtom:
// falls back from the Un cell to the Bin cell (MTMathAtomFactory.m:205-212).
- (void)testDemotedBmodSerializes
{
    MTMathList* finalized = [MTMathListBuilder buildFromString:@"\\bmod 5"].finalized;
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:finalized], @"\\bmod 5");
}

#pragma mark - MTMacroAtom

// The two fixed halves of \pod's expansion: [Space8, Open "("] and [Close ")"].
// Hand-built so PR 2 is independent of the parser (which lands in PR 3).
static MTMathList* PodPrefix(void)
{
    MTMathList* t = [MTMathList new];
    [t addAtom:[[MTMathSpace alloc] initWithSpace:8]];
    [t addAtom:[MTMathAtom atomWithType:kMTMathAtomOpen value:@"("]];
    return t;
}

static MTMathList* PodSuffix(void)
{
    MTMathList* t = [MTMathList new];
    [t addAtom:[MTMathAtom atomWithType:kMTMathAtomClose value:@")"]];
    return t;
}

static MTMacroAtom* PodMacroWithArgument(NSString* latex)
{
    MTMathList* arg = [MTMathListBuilder buildFromString:latex];
    return [[MTMacroAtom alloc] initWithCommand:@"pod"
                                      argument:arg
                                         prefix:PodPrefix()
                                         suffix:PodSuffix()];
}

// NSArray's -copy is shallow. The initializer must deep-copy, or a caller can
// mutate the list it handed in and silently mutate the atom.
- (void)testMacroAtomDeepCopiesAtInit
{
    MTMathList* arg = [MTMathListBuilder buildFromString:@"n"];
    MTMathList* prefix = PodPrefix();
    MTMathList* suffix = PodSuffix();
    MTMacroAtom* macro = [[MTMacroAtom alloc] initWithCommand:@"pod"
                                                    argument:arg
                                                       prefix:prefix
                                                       suffix:suffix];
    [arg addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];
    [prefix addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];
    [suffix addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];

    XCTAssertEqual([macro.argument atoms].count, 1ul, @"argument was not deep-copied");
    XCTAssertEqual(macro.prefix.atoms.count, 2ul, @"prefix was not deep-copied");
    XCTAssertEqual(macro.suffix.atoms.count, 1ul, @"suffix was not deep-copied");
}

- (void)testMacroAtomCopyIsDeep
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMacroAtom* copy = [macro copy];

    XCTAssertTrue([copy isKindOfClass:[MTMacroAtom class]]);
    XCTAssertEqualObjects(copy.command, @"pod");
    XCTAssertNotEqual(copy.argument, macro.argument);
    XCTAssertNotEqual(copy.prefix, macro.prefix);
    XCTAssertEqual(copy.prefix.atoms.count, 2ul);
    XCTAssertEqual(copy.suffix.atoms.count, 1ul);
    XCTAssertNotNil(copy.superScript);

    [macro.argument addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];
    XCTAssertEqual([copy.argument atoms].count, 1ul);
}

#pragma mark - Two-phase finalized

// Phase 2 must be the existing loop, unchanged: same Bin/Unary reclassification,
// same number fusion, same index ranges, on lists that contain no macros at all.
// Routing every list through macro expansion must not perturb the reclassifying
// pass. Asserted against literal signatures rather than serialization, because
// latexSymbolNameForAtom: maps Unary back through the Bin cell — the exact
// distinction under test would be invisible in a round-tripped string.
- (void)testFinalizedUnchangedForMacroFreeLists
{
    NSDictionary<NSString*, NSString*>* expected = @{
        // 1 and 7 fuse into one Number; + keeps a left operand so it stays Bin.
        @"17+5": @"[2:17, 5:+, 2:5]",
        // No left operand at all -> Unary.
        @"-x": @"[6:−, 3:x]",
        // Nothing follows -> Unary.
        @"x+": @"[3:x, 6:+]",
        // Follows an Open -> Unary.
        @"(+3)": @"[8:(, 6:+, 2:3, 9:)]",
        // Demotion happens independently inside each sub-list.
        @"\\frac{1+2}{3-}": @"[10:numerator[2:1, 5:+, 2:2]denominator[2:3, 6:−]]",
        @"a\\equiv b": @"[3:a, 7:≡, 3:b]",
        // 2 and 3 fuse; x stays Bin between two Numbers.
        @"1\\times 23": @"[2:1, 5:×, 2:23]",
    };
    for (NSString* latex in expected) {
        MTMathList* list = [MTMathListBuilder buildFromString:latex];
        XCTAssertNotNil(list, @"%@", latex);
        MTMathList* finalized = list.finalized;
        // finalized must still be a fresh list, not the receiver.
        XCTAssertNotEqual(finalized, list, @"%@", latex);
        XCTAssertEqualObjects(ListSignature(finalized), expected[latex], @"%@", latex);
        XCTAssertEqualObjects(ListSignature(list.finalized), expected[latex],
                              @"%@ is not idempotent across calls", latex);
    }
}

#pragma mark - Macro expansion (phase 1)

// \mod's prefix: [Space12, m, o, d (Roman Variables), Space6]. Its suffix is empty.
static MTMathList* ModPrefix(void)
{
    MTMathList* t = [MTMathList new];
    [t addAtom:[[MTMathSpace alloc] initWithSpace:12]];
    for (NSString* ch in @[ @"m", @"o", @"d" ]) {
        MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomVariable value:ch];
        atom.fontStyle = kMTFontStyleRoman;
        [t addAtom:atom];
    }
    [t addAtom:[[MTMathSpace alloc] initWithSpace:6]];
    return t;
}

static MTMacroAtom* ModMacroWithArgument(NSString* latex)
{
    return [[MTMacroAtom alloc] initWithCommand:@"mod"
                                      argument:[MTMathListBuilder buildFromString:latex]
                                         prefix:ModPrefix()
                                         suffix:[MTMathList new]];
}

// Phase 1 produces RAW atoms — no reclassification yet. \pod{n} -> 4 atoms, the
// argument spliced between prefix and suffix.
- (void)testExpansionSplicesArgumentBetweenPrefixAndSuffix
{
    MTMathList* list = [MTMathList new];
    [list addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    [list addAtom:PodMacroWithArgument(@"n")];

    MTMathList* expanded = [list expandMacros];
    XCTAssertEqual(expanded.atoms.count, 5ul);
    XCTAssertEqualObjects([expanded.atoms[0] nucleus], @"x");
    XCTAssertEqual([expanded.atoms[1] type], kMTMathAtomSpace);
    XCTAssertEqualWithAccuracy([(MTMathSpace*)expanded.atoms[1] space], 8, 0.001);
    XCTAssertEqual([expanded.atoms[2] type], kMTMathAtomOpen);
    XCTAssertEqualObjects([expanded.atoms[3] nucleus], @"n");
    XCTAssertEqual([expanded.atoms[4] type], kMTMathAtomClose);

    for (MTMathAtom* atom in expanded.atoms) {
        XCTAssertNotEqual(atom.type, kMTMathAtomMacro);
    }
}

// Expansion must not consume the stored halves or argument: finalizing twice
// gives the same answer.
- (void)testExpansionLeavesMacroAtomPristine
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    NSString* first = [MTMathListBuilder mathListToString:list.finalized];
    NSString* second = [MTMathListBuilder mathListToString:list.finalized];
    XCTAssertEqualObjects(first, second);
    XCTAssertEqual(macro.prefix.atoms.count, 2ul);
    XCTAssertEqual(macro.suffix.atoms.count, 1ul);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:macro.argument], @"n");
}

// A macro nested inside another macro's argument is expanded by the same pass
//: the inner atom is spliced into this list, then re-scanned.
- (void)testExpansionRecursesIntoNestedMacros
{
    MTMacroAtom* inner = PodMacroWithArgument(@"n");
    MTMathList* outerArg = [MTMathList new];
    [outerArg addAtom:inner];
    MTMacroAtom* outer = [[MTMacroAtom alloc] initWithCommand:@"pod"
                                                    argument:outerArg
                                                       prefix:PodPrefix()
                                                       suffix:PodSuffix()];
    MTMathList* list = [MTMathList new];
    [list addAtom:outer];

    MTMathList* expanded = [list expandMacros];
    // Space8 ( Space8 ( n ) )
    XCTAssertEqual(expanded.atoms.count, 7ul);
    for (MTMathAtom* atom in expanded.atoms) {
        XCTAssertNotEqual(atom.type, kMTMathAtomMacro);
    }
}

// Phase 1 deliberately does NOT descend into sub-lists. Containers recurse through
// their own -finalized, which re-enters phase 1 + 2 per child list.
- (void)testExpansionDoesNotDescendButFinalizedStillExpandsNested
{
    MTFraction* frac = [[MTFraction alloc] init];
    frac.numerator = [MTMathList new];
    [frac.numerator addAtom:PodMacroWithArgument(@"n")];
    frac.denominator = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:frac];

    // Phase 1 alone leaves the macro sitting in the numerator.
    MTFraction* rawFrac = (MTFraction*)[list expandMacros].atoms[0];
    XCTAssertEqual([rawFrac.numerator.atoms[0] type], kMTMathAtomMacro);

    // The public -finalized still reaches it, via MTFraction's -finalized.
    MTFraction* finalFrac = (MTFraction*)list.finalized.atoms[0];
    XCTAssertEqual(finalFrac.numerator.atoms.count, 4ul);
    for (MTMathAtom* atom in finalFrac.numerator.atoms) {
        XCTAssertNotEqual(atom.type, kMTMathAtomMacro);
    }
}

// The invariant, stated per list: no macro reaches the reclassifying pass.
- (void)testFinalizedContainsNoMacroAtoms
{
    MTMathList* list = [MTMathList new];
    [list addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    [list addAtom:ModMacroWithArgument(@"n")];
    for (MTMathAtom* atom in list.finalized.atoms) {
        XCTAssertNotEqual(atom.type, kMTMathAtomMacro);
    }
}

// Mutating a parsed argument must change what renders, not just what serializes.
// PodPrefix() leads with an 8mu space, and 8 is not one of the named
// keywords in +[MTMathListBuilder spaceToCommands] (3/4/5/18/36/-3), so
// MTMathSpace correctly serializes it as "\mkern8.0mu" rather than being
// silently dropped. The plan's expected "(n)"/"(m)" omitted that prefix; the
// assertions below reflect the actual, correct serialization.
- (void)testFinalizedTracksArgumentMutation
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list.finalized], @"\\mkern8.0mu(n)");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pod{n}");

    MTMathList* arg = macro.argument;
    [arg removeAtomAtIndex:0];
    [arg addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"m"]];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list.finalized], @"\\mkern8.0mu(m)");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pod{m}");
}

#pragma mark - Script transfer

// Transferring must not mutate the macro atom's own scripts: finalizing twice is
// stable, and serialization still reports \pod{n}^{2}.
- (void)testScriptTransferLeavesMacroAtomPristine
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    NSString* first = [MTMathListBuilder mathListToString:list.finalized];
    NSString* second = [MTMathListBuilder mathListToString:list.finalized];
    XCTAssertEqualObjects(first, second);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pod{n}^{2}");
}

#pragma mark - Equivalence helpers

// A structural fingerprint: type + nucleus + space value + font style + scripts.
// Serialization is not usable for this — latexSymbolNameForAtom: maps Unary back
// through the Bin cell, so "\bmod" and a demoted "\bmod" stringify identically and
// the Bin/Unary distinction (the whole point of these tests) would be invisible.
static NSString* AtomSignature(MTMathAtom* atom)
{
    NSMutableString* sig = [NSMutableString string];
    if (atom.type == kMTMathAtomSpace) {
        [sig appendFormat:@"Space(%g)", [(MTMathSpace*)atom space]];
    } else {
        [sig appendFormat:@"%lu:%@", (unsigned long)atom.type, atom.nucleus];
    }
    if (atom.fontStyle != kMTFontStyleDefault) {
        [sig appendFormat:@"/f%lu", (unsigned long)atom.fontStyle];
    }
    if (atom.superScript) {
        [sig appendFormat:@"^%@", ListSignature(atom.superScript)];
    }
    if (atom.subScript) {
        [sig appendFormat:@"_%@", ListSignature(atom.subScript)];
    }
    // Container sublists, so a divergence inside a fraction/radical/group shows up
    // too. Keyed by name because -innerList is declared on nine unrelated classes
    // with no common protocol.
    for (NSString* key in @[ @"numerator", @"denominator", @"degree", @"radicand", @"innerList" ]) {
        if (![atom respondsToSelector:NSSelectorFromString(key)]) {
            continue;
        }
        MTMathList* sub = [atom valueForKey:key];
        if (sub) {
            [sig appendFormat:@"%@%@", key, ListSignature(sub)];
        }
    }
    return sig;
}

static NSString* ListSignature(MTMathList* list)
{
    NSMutableArray<NSString*>* parts = [NSMutableArray arrayWithCapacity:list.atoms.count];
    for (MTMathAtom* atom in list.atoms) {
        [parts addObject:AtomSignature(atom)];
    }
    return [NSString stringWithFormat:@"[%@]", [parts componentsJoinedByString:@", "]];
}

#pragma mark - Required-argument guard

- (void)testStopCommandInMacroArgumentIsAnErrorNotSilentlyWrongOutput
{
    // Before the stop-command guard these all parsed "successfully" into wrong
    // output: \left(\pmod\right) => \left( \pmod{}\right), x \pmod \\ y =>
    // \pmod{\\ y} (a table nested inside the parens), and the matrix case
    // silently lost a row. Fail loud instead (see the repo's no-silent-degradation
    // rule).
    for (NSString* latex in @[ @"\\left(\\pmod\\right)",
                               @"x \\pmod \\\\ y",
                               @"\\begin{matrix}a\\pmod\\\\b\\end{matrix}",
                               @"\\begin{matrix}a\\mod\\\\b\\end{matrix}",
                               @"\\begin{matrix}a\\pod\\\\b\\end{matrix}" ]) {
        NSError* error = nil;
        XCTAssertNil([MTMathListBuilder buildFromString:latex error:&error], @"%@", latex);
        XCTAssertEqual(error.code, MTParseErrorMissingArgument, @"%@", latex);
    }
}

- (void)testStopCommandAfterAMacroArgumentStillWorks
{
    // Only the argument POSITION is guarded — a stop command after a complete
    // argument keeps its normal meaning, so the matrix still has two rows.
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\begin{matrix}a\\pmod{n}\\\\b\\end{matrix}"
                                                   error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(list.atoms.count, 1ul);
    MTMathTable* table = (MTMathTable*) list.atoms[0];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    XCTAssertEqual(table.numRows, 2);
}

#pragma mark - Expansion halves as parsed

// There is no template syntax, so '#' in user input keeps raising the same error it
// always has.
- (void)testEveryRegisteredMacroParses
{
    // Keeps the registry honest: a malformed half would otherwise only surface as
    // MTParseErrorInternalError at invocation.
    for (NSString* name in @[ @"pmod", @"mod", @"pod" ]) {
        NSError* error = nil;
        NSString* latex = [NSString stringWithFormat:@"\\%@{n}", name];
        XCTAssertNotNil([MTMathListBuilder buildFromString:latex error:&error], @"%@", latex);
        XCTAssertNil(error, @"%@", latex);
        // Macros and symbols stay disjoint surfaces.
        XCTAssertFalse([[MTMathAtomFactory supportedLatexSymbolNames] containsObject:name],
                       @"%@ must not be a symbol too", name);
    }
}

#pragma mark - Parsing the three macros

- (void)testPmodParsesToASingleMacroAtom
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"a \\equiv b \\pmod{n}"];
    XCTAssertNotNil(list);
    // a, ≡, b, macro — the macro is ONE atom in the raw list.
    XCTAssertEqual(list.atoms.count, 4ul);
    MTMathAtom* last = list.atoms[3];
    XCTAssertEqual(last.type, kMTMathAtomMacro);
    MTMacroAtom* macro = (MTMacroAtom*)last;
    XCTAssertEqualObjects(macro.command, @"pmod");
    XCTAssertEqual(macro.argument.atoms.count, 1ul);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:macro.argument], @"n");
    XCTAssertEqual(macro.prefix.atoms.count, 6ul);
    XCTAssertEqual(macro.suffix.atoms.count, 1ul);
}

- (void)testUnbracedArgument
{
    MTMacroAtom* macro = (MTMacroAtom*)[MTMathListBuilder buildFromString:@"\\pmod n"].atoms[0];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:macro.argument], @"n");
}

- (void)testEmptyArgumentIsAllowed
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\pmod{}"];
    XCTAssertNotNil(list);
    MTMacroAtom* macro = (MTMacroAtom*)list.atoms[0];
    XCTAssertEqual([macro.argument atoms].count, 0ul);
}

// Non-macro commands must be untouched: macroAtomForCommand: returns nil without
// setting an error, and dispatch falls through to atomForCommand:.
- (void)testNonMacroCommandsUnaffected
{
    XCTAssertNotNil([MTMathListBuilder buildFromString:@"\\frac{1}{2}"]);
    XCTAssertNotNil([MTMathListBuilder buildFromString:@"\\sqrt{2}"]);
    XCTAssertNotNil([MTMathListBuilder buildFromString:@"17 \\bmod 5"]);
    NSError* error = nil;
    XCTAssertNil([MTMathListBuilder buildFromString:@"\\notacommand" error:&error]);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

#pragma mark - End-to-end equivalence

// The registry's templates, written out by hand. If these drift from
// +builtinMacros the equivalence tests fail — which is the point.
static NSString* WrittenOutExpansion(NSString* command, NSString* arg)
{
    if ([command isEqualToString:@"pmod"]) {
        return [NSString stringWithFormat:@"\\mkern8mu(\\mathrm{mod}\\mkern6mu%@)", arg];
    } else if ([command isEqualToString:@"mod"]) {
        return [NSString stringWithFormat:@"\\mkern12mu\\mathrm{mod}\\mkern6mu%@", arg];
    } else if ([command isEqualToString:@"pod"]) {
        return [NSString stringWithFormat:@"\\mkern8mu(%@)", arg];
    }
    return nil;
}

- (void)assertEquivalentCommand:(NSString*)command
                       argument:(NSString*)arg
                         prefix:(NSString*)prefix
                         suffix:(NSString*)suffix
{
    NSString* macroLatex = [NSString stringWithFormat:@"%@\\%@{%@}%@", prefix, command, arg, suffix];
    NSString* writtenLatex = [NSString stringWithFormat:@"%@%@%@",
                              prefix, WrittenOutExpansion(command, arg), suffix];
    MTMathList* macroList = [MTMathListBuilder buildFromString:macroLatex];
    MTMathList* writtenList = [MTMathListBuilder buildFromString:writtenLatex];
    XCTAssertNotNil(macroList, @"%@", macroLatex);
    XCTAssertNotNil(writtenList, @"%@", writtenLatex);
    XCTAssertEqualObjects(ListSignature(macroList.finalized),
                          ListSignature(writtenList.finalized),
                          @"%@  !=  %@", macroLatex, writtenLatex);
    // And the invariant: no macro survives.
    for (MTMathAtom* atom in macroList.finalized.atoms) {
        XCTAssertNotEqual(atom.type, kMTMathAtomMacro, @"%@", macroLatex);
    }
}

// The boundary-sensitive cases: a trailing Bin in the argument must stay Bin
// because it sees the following y in the flat stream; a leading - must agree; and
// numbers must fuse identically on both sides (LLD §7.1).
- (void)testEquivalenceBoundarySensitive
{
    for (NSString* command in @[ @"pmod", @"mod", @"pod" ]) {
        [self assertEquivalentCommand:command argument:@"n+" prefix:@"x" suffix:@"y"];
        [self assertEquivalentCommand:command argument:@"-n" prefix:@"x" suffix:@"y"];
        [self assertEquivalentCommand:command argument:@"2"  prefix:@"1" suffix:@"3"];
    }
}

- (void)testEquivalencePlain
{
    for (NSString* command in @[ @"pmod", @"mod", @"pod" ]) {
        for (NSString* arg in @[ @"n", @"n+1", @"2^k", @"\\frac{a}{b}", @"" ]) {
            [self assertEquivalentCommand:command argument:arg prefix:@"" suffix:@""];
        }
    }
}

- (void)testEquivalenceInCongruence
{
    [self assertEquivalentCommand:@"pmod" argument:@"n" prefix:@"a\\equiv b" suffix:@""];
}

// Nested: phase 1 flattens both before phase 2, so no expansion is ever finalized
// on its own (LLD §7.4).
- (void)testNestedMacrosEquivalence
{
    MTMathList* nested = [MTMathListBuilder buildFromString:@"\\pmod{\\pmod{n}}"];
    XCTAssertNotNil(nested);
    NSString* inner = WrittenOutExpansion(@"pmod", @"n");
    MTMathList* written = [MTMathListBuilder buildFromString:WrittenOutExpansion(@"pmod", inner)];
    XCTAssertNotNil(written);
    XCTAssertEqualObjects(ListSignature(nested.finalized), ListSignature(written.finalized));
}

#pragma mark - Scripts end to end

- (void)testScriptOnPmodLandsOnClosingParen
{
    MTMathList* finalized = [MTMathListBuilder buildFromString:@"\\pmod{n}^2"].finalized;
    MTMathAtom* last = finalized.atoms.lastObject;
    XCTAssertEqual(last.type, kMTMathAtomClose);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:last.superScript], @"2");
}

- (void)testSubscriptOnPodLandsOnClosingParen
{
    MTMathList* finalized = [MTMathListBuilder buildFromString:@"\\pod{n}_k"].finalized;
    MTMathAtom* last = finalized.atoms.lastObject;
    XCTAssertEqual(last.type, kMTMathAtomClose);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:last.subScript], @"k");
}

- (void)testScriptOnModSkipsTrailingSpace
{
    MTMathList* finalized = [MTMathListBuilder buildFromString:@"\\mod{n\\;}^2"].finalized;
    XCTAssertEqual([finalized.atoms.lastObject type], kMTMathAtomSpace);
    XCTAssertNil([finalized.atoms.lastObject superScript]);
    MTMathAtom* n = finalized.atoms[finalized.atoms.count - 2];
    XCTAssertEqualObjects(n.nucleus, @"n");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:n.superScript], @"2");
}

// \mod{n^2}^3 == \mod{n^2}{}^3 -- the same shape iosMath already produces for
// x^2^3 vs x^2{}^3 (getTestDataSuperScript() in MTMathListBuilderTest.m: both
// "x^2^3" and "{}^2" alone serialize to the same "{}^{...}" text). The two
// sides are NOT byte-identical at the ListSignature level: the collision path
// (MTMathListBuilder.m ^/_ handling) appends a bare kMTMathAtomOrdinary, while
// a literal "{}" in the source always builds an MTMathGroup (kMTMathAtomOrdGroup)
// -- same precedent the codebase already establishes for plain "^2" vs "{}^2".
// mathListToString is what unifies them (both render "{}"), so that -- not
// ListSignature -- is the right equivalence check here.
- (void)testScriptCollisionMatchesExistingEmptyOrdBehavior
{
    MTMathList* collided = [MTMathListBuilder buildFromString:@"\\mod{n^2}^3"];
    MTMathList* explicit = [MTMathListBuilder buildFromString:@"\\mod{n^2}{}^3"];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:collided.finalized],
                          [MTMathListBuilder mathListToString:explicit.finalized]);

    // And the precedent it mirrors.
    MTMathList* precedent = [MTMathListBuilder buildFromString:@"x^2^3"];
    MTMathAtom* precedentLast = precedent.finalized.atoms.lastObject;
    XCTAssertEqual(precedentLast.type, kMTMathAtomOrdinary);
    XCTAssertEqualObjects(precedentLast.nucleus, @"");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:precedentLast.superScript], @"3");
}

// See testScriptCollisionMatchesExistingEmptyOrdBehavior above: same bare-Ordinary-
// vs-OrdGroup distinction, so mathListToString is the equivalence check, not
// ListSignature.
- (void)testSubscriptCollisionMatchesExistingBehavior
{
    XCTAssertEqualObjects(
        [MTMathListBuilder mathListToString:[MTMathListBuilder buildFromString:@"\\mod{n_1}_2"].finalized],
        [MTMathListBuilder mathListToString:[MTMathListBuilder buildFromString:@"\\mod{n_1}{}_2"].finalized]);
}

// \mod{n^2}_3 is NOT a collision: the subscript slot on n is free.
- (void)testNonCollidingSubscriptEndToEnd
{
    MTMathList* finalized = [MTMathListBuilder buildFromString:@"\\mod{n^2}_3"].finalized;
    MTMathAtom* last = finalized.atoms.lastObject;
    XCTAssertEqualObjects(last.nucleus, @"n", @"no empty Ordinary should have been appended");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:last.superScript], @"2");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:last.subScript], @"3");
}

// See the plan's "Known LLD discrepancy" note: LLD §6 lists this as the
// no-scriptable-target case, but the \mod template's own "mod" letters ARE
// scriptable, so ^2 lands on the d. What matters — and what §6 was protecting —
// is that the script is never dropped. The genuine no-target branch is covered by
// -testNoScriptableTargetAppendsEmptyOrdinary (item 8).
- (void)testScriptOnAllSpaceArgumentIsNotDropped
{
    MTMathList* finalized = [MTMathListBuilder buildFromString:@"\\mod{\\;}^2"].finalized;
    MTMathAtom* carrier = nil;
    for (MTMathAtom* atom in finalized.atoms) {
        if (atom.superScript) { carrier = atom; break; }
    }
    XCTAssertNotNil(carrier, @"the superscript was dropped");
    XCTAssertEqualObjects(carrier.nucleus, @"d", @"expected the last letter of \"mod\"");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:carrier.superScript], @"2");
}

// The argument is parsed under the enclosing font style; the parens and spaces come
// from the prefix, which is parsed by a fresh builder at default style (LLD §6).
- (void)testMacroInsideFontStyleGroup
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\mathbf{x \\pmod{n}}"];
    XCTAssertNotNil(list);
    MTMacroAtom* macro = nil;
    for (MTMathAtom* atom in list.atoms) {
        if (atom.type == kMTMathAtomMacro) { macro = (MTMacroAtom*)atom; break; }
    }
    XCTAssertNotNil(macro);
    XCTAssertEqual([macro.argument atoms][0].fontStyle, kMTFontStyleBold);
    // "mod" stays Roman regardless — it comes from \mathrm in the prefix.
    XCTAssertEqual(macro.prefix.atoms[2].fontStyle, kMTFontStyleRoman);
}

#pragma mark - Serialization

- (void)testSerializationRoundTrips
{
    NSDictionary<NSString*, NSString*>* cases = @{
        @"\\pmod{n}":      @"\\pmod{n}",
        @"\\mod{n}":       @"\\mod{n}",
        @"\\pod{n}":       @"\\pod{n}",
        @"\\mod{n+1}":     @"\\mod{n+1}",
        @"\\pmod n":       @"\\pmod{n}",     // unbraced serializes canonically
        @"\\mod{ n }":     @"\\mod{n}",      // whitespace is canonicalized
        @"\\pmod{n}^2":    @"\\pmod{n}^{2}",
        @"\\pod{n}_k":     @"\\pod{n}_{k}",
        @"\\pmod{}":       @"\\pmod{}",
        @"a\\equiv b\\pmod{n}": @"a\\equiv b\\pmod{n}",
    };
    for (NSString* input in cases) {
        MTMathList* list = [MTMathListBuilder buildFromString:input];
        XCTAssertNotNil(list, @"%@", input);
        NSString* out = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(out, cases[input], @"%@", input);

        // And it re-parses to the same thing — the round trip is stable.
        MTMathList* reparsed = [MTMathListBuilder buildFromString:out];
        XCTAssertNotNil(reparsed, @"reparse of %@", out);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:reparsed], out, @"%@", input);
    }
}

// The raw list serializes the COMMAND; only the finalized list shows the expansion.
// This split is the seam the whole design rests on (LLD §2.7).
//
// Deviation from the plan's literal expected string: the plan expected "(n)", but
// the `\pod` template's leading 8mu kern has no named LaTeX command, so it
// serializes via the `\mkern%.1fmu` fallback (per the plan's documented known
// deviation) rather than disappearing. "\mkern8.0mu(n)" is the correct output.
- (void)testRawSerializesCommandFinalizedSerializesExpansion
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\pod{n}"];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pod{n}");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list.finalized], @"\\mkern8.0mu(n)");
}

// Deviation from the plan (see the NOTE next to the parse-error table in
// MTMathListBuilderTest.m): `\pmod{\frac}` is NOT a parse error. The macro
// argument reader (`requiredArgumentWithError:`) uses the same one-token
// `buildInternal:YES` reader that `\frac` itself uses to read its numerator and
// denominator, so `\frac`'s own reads immediately see the closing `}` and each
// come back as an empty argument — exactly like bare top-level `\frac` at EOF.
- (void)testFracWithNoArgumentsIsNotAnErrorInsideMacroArgument
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\pmod{\\frac}"];
    XCTAssertNotNil(list);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pmod{\\frac{}{}}");
    XCTAssertNoThrow([list finalized]);
}

#pragma mark - Rendering

- (void)testPmodRendersUprightMod
{
    NSString* text = [self renderedTextForDisplay:[self displayForLaTeX:@"a \\equiv b \\pmod{n}"]];
    XCTAssertTrue([text containsString:@"mod"], @"got %@", text);
    // \mathrm{mod} must not be remapped to the italic mathematical alphanumerics.
    XCTAssertFalse([text containsString:@"\U0001D45A"], @"italic m in %@", text);   // 𝑚
    XCTAssertFalse([text containsString:@"\U0001D45C"], @"italic o in %@", text);   // 𝑜
    XCTAssertFalse([text containsString:@"\U0001D451"], @"italic d in %@", text);   // 𝑑
}

// Geometry, not substring presence: the macro must lay out exactly like its
// expansion typed out by hand.
- (void)testMacroLayoutMatchesWrittenOutExpansion
{
    NSArray<NSArray<NSString*>*>* cases = @[
        @[ @"pmod", @"n",   @"a\\equiv b", @"" ],
        @[ @"mod",  @"n",   @"x",          @"" ],
        @[ @"pod",  @"n",   @"x",          @"" ],
        @[ @"mod",  @"n+1", @"x",          @"y" ],
    ];
    for (NSArray<NSString*>* c in cases) {
        NSString* macroLatex = [NSString stringWithFormat:@"%@\\%@{%@}%@", c[2], c[0], c[1], c[3]];
        NSString* writtenLatex = [NSString stringWithFormat:@"%@%@%@",
                                  c[2], WrittenOutExpansion(c[0], c[1]), c[3]];
        MTMathListDisplay* macroDisplay = [self displayForLaTeX:macroLatex];
        MTMathListDisplay* writtenDisplay = [self displayForLaTeX:writtenLatex];

        XCTAssertEqualWithAccuracy(macroDisplay.width, writtenDisplay.width, 0.001,
                                   @"width: %@", macroLatex);
        XCTAssertEqualWithAccuracy(macroDisplay.ascent, writtenDisplay.ascent, 0.001,
                                   @"ascent: %@", macroLatex);
        XCTAssertEqualWithAccuracy(macroDisplay.descent, writtenDisplay.descent, 0.001,
                                   @"descent: %@", macroLatex);
        XCTAssertEqualObjects([self renderedTextForDisplay:macroDisplay],
                              [self renderedTextForDisplay:writtenDisplay],
                              @"text: %@", macroLatex);

        XCTAssertEqual(macroDisplay.subDisplays.count, writtenDisplay.subDisplays.count,
                       @"subdisplay count: %@", macroLatex);
        for (NSUInteger i = 0; i < MIN(macroDisplay.subDisplays.count,
                                       writtenDisplay.subDisplays.count); i++) {
            MTDisplay* a = macroDisplay.subDisplays[i];
            MTDisplay* b = writtenDisplay.subDisplays[i];
            XCTAssertEqualWithAccuracy(a.position.x, b.position.x, 0.001,
                                       @"subdisplay %lu x: %@", (unsigned long)i, macroLatex);
            XCTAssertEqualWithAccuracy(a.position.y, b.position.y, 0.001,
                                       @"subdisplay %lu y: %@", (unsigned long)i, macroLatex);
            XCTAssertEqualWithAccuracy(a.width, b.width, 0.001,
                                       @"subdisplay %lu width: %@", (unsigned long)i, macroLatex);
        }
    }
}

@end
