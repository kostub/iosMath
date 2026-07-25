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

@end
