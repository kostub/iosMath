//
//  MTModularArithmeticTest.m
//  iosMath
//
//  Tests for \bmod, \pmod, \mod, \pod.
//  Design: docs/lld/2026-07-13-modular-arithmetic.md
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
#import "MTMacroParameterAtom.h"

@interface MTModularArithmeticTest : XCTestCase
@property (nonatomic) MTFont* font;
@end

// Declared privately in MTMathList.m; redeclared here so the tests can drive
// phase 1 in isolation and observe RAW (unreclassified) output.
@interface MTMathList (MTMacroExpansionTesting)
- (MTMathList *)mathListByExpandingMacros;
@end

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

#pragma mark - MTMacroParameterAtom

- (void)testMacroParameterAtomBasics
{
    MTMacroParameterAtom* p = [[MTMacroParameterAtom alloc] initWithArgumentIndex:3];
    XCTAssertEqual(p.argumentIndex, 3ul);
    // Type stays Ordinary: the placeholder is a sentinel that never survives
    // expansion, so it deliberately adds no value to the public MTMathAtomType enum.
    XCTAssertEqual(p.type, kMTMathAtomOrdinary);
    XCTAssertEqualObjects(p.nucleus, @"#3");
}

- (void)testMacroParameterAtomCopyPreservesIndex
{
    MTMacroParameterAtom* p = [[MTMacroParameterAtom alloc] initWithArgumentIndex:1];
    MTMacroParameterAtom* copy = [p copy];
    XCTAssertTrue([copy isKindOfClass:[MTMacroParameterAtom class]]);
    XCTAssertEqual(copy.argumentIndex, 1ul);
    XCTAssertEqualObjects(copy.nucleus, @"#1");
}

// A template list is deep-copied wholesale during expansion, so the placeholder
// must survive MTMathList's deep copy too (MTMathList.m:216-220 copies items).
- (void)testMacroParameterAtomSurvivesListCopy
{
    MTMathList* list = [MTMathList new];
    [list addAtom:[[MTMacroParameterAtom alloc] initWithArgumentIndex:2]];
    MTMathList* copy = [list copy];
    MTMathAtom* copied = copy.atoms[0];
    XCTAssertTrue([copied isKindOfClass:[MTMacroParameterAtom class]]);
    XCTAssertEqual([(MTMacroParameterAtom*)copied argumentIndex], 2ul);
}

#pragma mark - MTMacroAtom

// Builds the golden template list for \pod: [Space8, Open "(", #1, Close ")"].
// Hand-built so PR 2 is independent of the parser (which lands in PR 3).
static MTMathList* PodTemplate(void)
{
    MTMathList* t = [MTMathList new];
    [t addAtom:[[MTMathSpace alloc] initWithSpace:8]];
    [t addAtom:[MTMathAtom atomWithType:kMTMathAtomOpen value:@"("]];
    [t addAtom:[[MTMacroParameterAtom alloc] initWithArgumentIndex:1]];
    [t addAtom:[MTMathAtom atomWithType:kMTMathAtomClose value:@")"]];
    return t;
}

static MTMacroAtom* PodMacroWithArgument(NSString* latex)
{
    MTMathList* arg = [MTMathListBuilder buildFromString:latex];
    return [[MTMacroAtom alloc] initWithCommand:@"pod"
                                      arguments:@[ arg ]
                                   templateList:PodTemplate()];
}

- (void)testMacroAtomBasics
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    XCTAssertEqual(macro.type, kMTMathAtomMacro);
    XCTAssertEqualObjects(macro.command, @"pod");
    XCTAssertEqual(macro.arguments.count, 1ul);
    XCTAssertEqual(macro.templateList.atoms.count, 4ul);
    // 22 sits just past kMTMathAtomOrdGroup (21), the last script-capable value,
    // so a macro can carry ^/_ at parse time (MTMathList.h:74-78).
    XCTAssertTrue(macro.scriptsAllowed);
}

// NSArray's -copy is shallow. The initializer must deep-copy, or a caller can
// mutate the list it handed in and silently mutate the atom (LLD §3.1).
- (void)testMacroAtomDeepCopiesAtInit
{
    MTMathList* arg = [MTMathListBuilder buildFromString:@"n"];
    MTMathList* templ = PodTemplate();
    MTMacroAtom* macro = [[MTMacroAtom alloc] initWithCommand:@"pod"
                                                    arguments:@[ arg ]
                                                 templateList:templ];
    [arg addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];
    [templ addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];

    XCTAssertEqual([macro.arguments[0] atoms].count, 1ul, @"argument was not deep-copied");
    XCTAssertEqual(macro.templateList.atoms.count, 4ul, @"template was not deep-copied");
}

- (void)testMacroAtomCopyIsDeep
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMacroAtom* copy = [macro copy];

    XCTAssertTrue([copy isKindOfClass:[MTMacroAtom class]]);
    XCTAssertEqualObjects(copy.command, @"pod");
    XCTAssertNotEqual(copy.arguments[0], macro.arguments[0]);
    XCTAssertNotEqual(copy.templateList, macro.templateList);
    XCTAssertEqual(copy.templateList.atoms.count, 4ul);
    XCTAssertNotNil(copy.superScript);

    [macro.arguments[0] addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];
    XCTAssertEqual([copy.arguments[0] atoms].count, 1ul);
}

// A macro atom has no valid zero-argument construction, so the generic
// initializer must fail loud (guard idiom of MTMathColorbox, MTMathList.m:975-983).
- (void)testMacroAtomRejectsGenericInitializer
{
    XCTAssertThrows([[MTMacroAtom alloc] initWithType:kMTMathAtomMacro value:@""]);
    XCTAssertThrows([[MTMacroAtom alloc] initWithType:kMTMathAtomOrdinary value:@"x"]);
}

- (void)testMacroAtomSerializesCommandFaithfully
{
    MTMathList* list = [MTMathList new];
    [list addAtom:PodMacroWithArgument(@"n+1")];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pod{n+1}");
}

- (void)testMacroAtomSerializesWithScripts
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pod{n}^{2}");
}

// The template is not a source of truth for the arguments: mutating a parsed
// argument must show up in serialization (LLD §7.2, blocking issue #2).
- (void)testMacroAtomSerializationTracksArgumentMutation
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pod{n}");

    MTMathList* arg = macro.arguments[0];
    [arg removeAtomAtIndex:0];
    [arg addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"m"]];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pod{m}");
}

- (void)testMacroAtomStringValue
{
    XCTAssertEqualObjects([PodMacroWithArgument(@"n") stringValue], @"\\pod{n}");
}

#pragma mark - Two-phase finalized

// Phase 2 must be the existing loop, unchanged: same Bin/Unary reclassification,
// same number fusion, same index ranges, on lists that contain no macros at all.
- (void)testFinalizedUnchangedForMacroFreeLists
{
    NSArray<NSString*>* inputs = @[ @"17+5", @"-x", @"x+", @"(+3)", @"\\frac{1+2}{3-}",
                                    @"a\\equiv b", @"1\\times 23" ];
    for (NSString* latex in inputs) {
        MTMathList* list = [MTMathListBuilder buildFromString:latex];
        XCTAssertNotNil(list, @"%@", latex);
        MTMathList* finalized = list.finalized;
        // finalized must still be a fresh list, not the receiver.
        XCTAssertNotEqual(finalized, list, @"%@", latex);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:finalized],
                              [MTMathListBuilder mathListToString:list.finalized],
                              @"%@ is not idempotent across calls", latex);
    }
}

- (void)testExpandingMacrosIsIdentityWithoutMacros
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"1+2"];
    MTMathList* expanded = [list mathListByExpandingMacros];
    XCTAssertEqual(expanded.atoms.count, 3ul);
    // A macro-free list needs no rewriting, so phase 1 hands the receiver straight
    // through — phase 2 is what allocates the new list.
    XCTAssertEqual(expanded, list);
}

#pragma mark - Macro expansion (phase 1)

// The \mod template: [Space12, m, o, d (Roman Variables), Space6, #1].
static MTMathList* ModTemplate(void)
{
    MTMathList* t = [MTMathList new];
    [t addAtom:[[MTMathSpace alloc] initWithSpace:12]];
    for (NSString* ch in @[ @"m", @"o", @"d" ]) {
        MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomVariable value:ch];
        atom.fontStyle = kMTFontStyleRoman;
        [t addAtom:atom];
    }
    [t addAtom:[[MTMathSpace alloc] initWithSpace:6]];
    [t addAtom:[[MTMacroParameterAtom alloc] initWithArgumentIndex:1]];
    return t;
}

static MTMacroAtom* ModMacroWithArgument(NSString* latex)
{
    return [[MTMacroAtom alloc] initWithCommand:@"mod"
                                      arguments:@[ [MTMathListBuilder buildFromString:latex] ]
                                   templateList:ModTemplate()];
}

// Phase 1 produces RAW atoms — no reclassification yet. \pod{n} -> 4 atoms with the
// placeholder replaced by a copy of the argument.
- (void)testExpansionSplicesArgumentIntoPlaceholder
{
    MTMathList* list = [MTMathList new];
    [list addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    [list addAtom:PodMacroWithArgument(@"n")];

    MTMathList* expanded = [list mathListByExpandingMacros];
    XCTAssertEqual(expanded.atoms.count, 5ul);
    XCTAssertEqualObjects([expanded.atoms[0] nucleus], @"x");
    XCTAssertEqual([expanded.atoms[1] type], kMTMathAtomSpace);
    XCTAssertEqualWithAccuracy([(MTMathSpace*)expanded.atoms[1] space], 8, 0.001);
    XCTAssertEqual([expanded.atoms[2] type], kMTMathAtomOpen);
    XCTAssertEqualObjects([expanded.atoms[3] nucleus], @"n");
    XCTAssertEqual([expanded.atoms[4] type], kMTMathAtomClose);

    for (MTMathAtom* atom in expanded.atoms) {
        XCTAssertFalse([atom isKindOfClass:[MTMacroParameterAtom class]]);
        XCTAssertNotEqual(atom.type, kMTMathAtomMacro);
    }
}

// A multi-atom argument is spliced inline, not wrapped.
- (void)testExpansionSplicesMultiAtomArgument
{
    MTMathList* list = [MTMathList new];
    [list addAtom:PodMacroWithArgument(@"n+1")];
    MTMathList* expanded = [list mathListByExpandingMacros];
    // Space8, "(", n, +, 1, ")"
    XCTAssertEqual(expanded.atoms.count, 6ul);
    XCTAssertEqual([expanded.atoms[3] type], kMTMathAtomBinaryOperator);
}

// Expansion must not consume the stored template or arguments: finalizing twice
// gives the same answer.
- (void)testExpansionLeavesMacroAtomPristine
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    NSString* first = [MTMathListBuilder mathListToString:list.finalized];
    NSString* second = [MTMathListBuilder mathListToString:list.finalized];
    XCTAssertEqualObjects(first, second);
    XCTAssertEqual(macro.templateList.atoms.count, 4ul);
    XCTAssertTrue([macro.templateList.atoms[2] isKindOfClass:[MTMacroParameterAtom class]]);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:macro.arguments[0]], @"n");
}

// A macro nested inside another macro's argument is expanded by the same pass
// (LLD §7.4): the inner atom is spliced into this list, then re-scanned.
- (void)testExpansionRecursesIntoNestedMacros
{
    MTMacroAtom* inner = PodMacroWithArgument(@"n");
    MTMathList* outerArg = [MTMathList new];
    [outerArg addAtom:inner];
    MTMacroAtom* outer = [[MTMacroAtom alloc] initWithCommand:@"pod"
                                                    arguments:@[ outerArg ]
                                                 templateList:PodTemplate()];
    MTMathList* list = [MTMathList new];
    [list addAtom:outer];

    MTMathList* expanded = [list mathListByExpandingMacros];
    // Space8 ( Space8 ( n ) )
    XCTAssertEqual(expanded.atoms.count, 7ul);
    for (MTMathAtom* atom in expanded.atoms) {
        XCTAssertNotEqual(atom.type, kMTMathAtomMacro);
    }
}

// Phase 1 deliberately does NOT descend into sub-lists. Containers recurse through
// their own -finalized, which re-enters phase 1 + 2 per child list (LLD §3.3).
- (void)testExpansionDoesNotDescendButFinalizedStillExpandsNested
{
    MTFraction* frac = [MTFraction new];
    frac.numerator = [MTMathList new];
    [frac.numerator addAtom:PodMacroWithArgument(@"n")];
    frac.denominator = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:frac];

    // Phase 1 alone leaves the macro sitting in the numerator.
    MTFraction* rawFrac = (MTFraction*)[list mathListByExpandingMacros].atoms[0];
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
        XCTAssertFalse([atom isKindOfClass:[MTMacroParameterAtom class]]);
    }
}

// Mutating a parsed argument must change what renders, not just what serializes
// (LLD §7.2, blocking issue #2). Item 5 covered the serialization half.
// Deviation from the plan's literal test text: PodTemplate() leads with an 8mu
// space (LLD's \pod template is \mkern8mu(#1)), and 8 is not one of the named
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

    MTMathList* arg = macro.arguments[0];
    [arg removeAtomAtIndex:0];
    [arg addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"m"]];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list.finalized], @"\\mkern8.0mu(m)");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\pod{m}");
}

#pragma mark - Script transfer

// \pod{n}^2 -> the ")" carries the superscript.
- (void)testScriptTransfersToLastScriptableAtom
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    MTMathList* expanded = [list mathListByExpandingMacros];
    XCTAssertEqual(expanded.atoms.count, 4ul);
    MTMathAtom* close = expanded.atoms[3];
    XCTAssertEqual(close.type, kMTMathAtomClose);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:close.superScript], @"2");
    XCTAssertNil([expanded.atoms[2] superScript]);
}

- (void)testSubscriptTransfers
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    macro.subScript = [MTMathListBuilder buildFromString:@"k"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];
    MTMathAtom* close = [list mathListByExpandingMacros].atoms[3];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:close.subScript], @"k");
}

// \mod{n\;}^2: the trailing space is not scriptable, so the script skips it and
// lands on n. It is never dropped (LLD §6, §7.3).
- (void)testScriptSkipsTrailingSpace
{
    MTMacroAtom* macro = ModMacroWithArgument(@"n\\;");
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    MTMathList* expanded = [list mathListByExpandingMacros];
    XCTAssertEqual([expanded.atoms.lastObject type], kMTMathAtomSpace);
    XCTAssertNil([expanded.atoms.lastObject superScript]);

    MTMathAtom* n = expanded.atoms[expanded.atoms.count - 2];
    XCTAssertEqualObjects(n.nucleus, @"n");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:n.superScript], @"2");
}

// Collision: n already has ^2, so ^3 goes on an appended empty Ordinary — exactly
// what the builder does for x^2^3 (MTMathListBuilder.m:211-216). \mod{n^2}^3 is
// therefore \mod{n^2}{}^3.
- (void)testSuperscriptCollisionAppendsEmptyOrdinary
{
    MTMacroAtom* macro = ModMacroWithArgument(@"n^2");
    macro.superScript = [MTMathListBuilder buildFromString:@"3"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    MTMathList* expanded = [list mathListByExpandingMacros];
    MTMathAtom* appended = expanded.atoms.lastObject;
    XCTAssertEqual(appended.type, kMTMathAtomOrdinary);
    XCTAssertEqualObjects(appended.nucleus, @"");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:appended.superScript], @"3");

    MTMathAtom* n = expanded.atoms[expanded.atoms.count - 2];
    XCTAssertEqualObjects(n.nucleus, @"n");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:n.superScript], @"2");
}

- (void)testSubscriptCollisionAppendsEmptyOrdinary
{
    MTMacroAtom* macro = ModMacroWithArgument(@"n_1");
    macro.subScript = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    MTMathAtom* appended = [list mathListByExpandingMacros].atoms.lastObject;
    XCTAssertEqual(appended.type, kMTMathAtomOrdinary);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:appended.subScript], @"2");
}

// \mod{n^2}_3 is NOT a collision: the subscript slot on n is free.
- (void)testNonCollidingSubscriptAttachesDirectly
{
    MTMacroAtom* macro = ModMacroWithArgument(@"n^2");
    macro.subScript = [MTMathListBuilder buildFromString:@"3"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    MTMathList* expanded = [list mathListByExpandingMacros];
    MTMathAtom* n = expanded.atoms.lastObject;
    XCTAssertEqualObjects(n.nucleus, @"n", @"no empty Ordinary should have been appended");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:n.superScript], @"2");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:n.subScript], @"3");
}

// Slots are evaluated as a unit: if either needed slot is taken, BOTH scripts move
// to the appended atom, so a ^/_ pair is never split across two atoms.
- (void)testCollidingPairStaysTogether
{
    MTMacroAtom* macro = ModMacroWithArgument(@"n^2");
    macro.superScript = [MTMathListBuilder buildFromString:@"3"];
    macro.subScript = [MTMathListBuilder buildFromString:@"k"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    MTMathList* expanded = [list mathListByExpandingMacros];
    MTMathAtom* appended = expanded.atoms.lastObject;
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:appended.superScript], @"3");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:appended.subScript], @"k");

    MTMathAtom* n = expanded.atoms[expanded.atoms.count - 2];
    XCTAssertNil(n.subScript, @"the pair must not be split across two atoms");
}

// No scriptable atom anywhere in the expansion. Unreachable for the three built-in
// templates (all end in a scriptable atom — see the plan's "Known LLD discrepancy"
// note), but it is the branch LLD §6 asks for and the one \newcommand (§8.2) makes
// reachable, so it is covered here with a spaces-only template.
- (void)testNoScriptableTargetAppendsEmptyOrdinary
{
    MTMathList* spacesOnly = [MTMathList new];
    [spacesOnly addAtom:[[MTMathSpace alloc] initWithSpace:8]];
    [spacesOnly addAtom:[[MTMathSpace alloc] initWithSpace:6]];
    MTMacroAtom* macro = [[MTMacroAtom alloc] initWithCommand:@"spacesonly"
                                                    arguments:@[]
                                                 templateList:spacesOnly];
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    MTMathList* expanded = [list mathListByExpandingMacros];
    XCTAssertEqual(expanded.atoms.count, 3ul);
    MTMathAtom* appended = expanded.atoms.lastObject;
    XCTAssertEqual(appended.type, kMTMathAtomOrdinary);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:appended.superScript], @"2");
}

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

static NSString* ListSignature(MTMathList* list);

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

#pragma mark - One-pass equivalence (model layer)

// Wraps `latex` around a hand-built \mod macro and returns the finalized signature.
- (NSString*)signatureForModMacroWithArgument:(NSString*)arg
                                     prefix:(NSString*)prefix
                                     suffix:(NSString*)suffix
{
    MTMathList* list = [MTMathList new];
    [list append:[MTMathListBuilder buildFromString:prefix]];
    [list addAtom:ModMacroWithArgument(arg)];
    [list append:[MTMathListBuilder buildFromString:suffix]];
    return ListSignature(list.finalized);
}

// The expansion typed out directly, for comparison. \mathrm{mod} is written as
// three Roman Variables to match ModTemplate() exactly.
- (NSString*)signatureForWrittenOutModWithArgument:(NSString*)arg
                                          prefix:(NSString*)prefix
                                          suffix:(NSString*)suffix
{
    NSString* latex = [NSString stringWithFormat:@"%@\\mkern12mu\\mathrm{mod}\\mkern6mu%@%@",
                       prefix, arg, suffix];
    MTMathList* list = [MTMathListBuilder buildFromString:latex];
    XCTAssertNotNil(list, @"%@", latex);
    return ListSignature(list.finalized);
}

// x\mod{n+}y : the + sits between n and y in the flat stream and stays Bin. A
// design that finalized each expansion on its own would demote it to Unary —
// this is exactly the case the r1 design got wrong (LLD §3.4 Flow 3).
- (void)testTrailingBinaryOperatorInArgumentStaysBinary
{
    XCTAssertEqualObjects([self signatureForModMacroWithArgument:@"n+" prefix:@"x" suffix:@"y"],
                          [self signatureForWrittenOutModWithArgument:@"n+" prefix:@"x" suffix:@"y"]);
}

// x\mod{-n}y : the leading - has no left operand inside the flat stream either
// (it follows a Space, whose predecessor is "mod"), so both sides must agree.
- (void)testLeadingUnaryInArgumentAgrees
{
    XCTAssertEqualObjects([self signatureForModMacroWithArgument:@"-n" prefix:@"x" suffix:@"y"],
                          [self signatureForWrittenOutModWithArgument:@"-n" prefix:@"x" suffix:@"y"]);
}

// 1\mod{2}3 : number fusion must see the same neighbours on both sides.
- (void)testNumberFusionAcrossExpansionAgrees
{
    XCTAssertEqualObjects([self signatureForModMacroWithArgument:@"2" prefix:@"1" suffix:@"3"],
                          [self signatureForWrittenOutModWithArgument:@"2" prefix:@"1" suffix:@"3"]);
}

- (void)testPlainExpansionsAgree
{
    for (NSString* arg in @[ @"n", @"n+1", @"2^k" ]) {
        XCTAssertEqualObjects([self signatureForModMacroWithArgument:arg prefix:@"" suffix:@""],
                              [self signatureForWrittenOutModWithArgument:arg prefix:@"" suffix:@""],
                              @"arg %@", arg);
    }
}

- (void)testEquivalenceInsideCongruence
{
    XCTAssertEqualObjects([self signatureForModMacroWithArgument:@"n" prefix:@"a\\equiv b" suffix:@""],
                          [self signatureForWrittenOutModWithArgument:@"n" prefix:@"a\\equiv b" suffix:@""]);
}

@end
