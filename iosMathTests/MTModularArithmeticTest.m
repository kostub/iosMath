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
#import "internal/MTMacroParameterAtom.h"
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

// Declared privately in MTMathListBuilder.m; redeclared here so the required-argument
// guard tests can drive it directly.
@interface MTMathListBuilder (MTRequiredArgumentTesting)
- (nullable MTMathList *)requiredArgumentWithError:(MTParseErrors)error;
@end

@interface MTMathListBuilder (MTTemplateModeTesting)
+ (nullable MTMathList *)buildTemplate:(NSString *)templateString;
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
                                   templateExpression:PodTemplate()];
}

- (void)testMacroAtomBasics
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    XCTAssertEqual(macro.type, kMTMathAtomMacro);
    XCTAssertEqualObjects(macro.command, @"pod");
    XCTAssertEqual(macro.arguments.count, 1ul);
    XCTAssertEqual(macro.templateExpression.atoms.count, 4ul);
    // 22 sits just past kMTMathAtomOrdGroup (21), the last script-capable value,
    // so a macro can carry ^/_ at parse time (MTMathList.h:74-78).
    XCTAssertTrue(macro.scriptsAllowed);
}

// NSArray's -copy is shallow. The initializer must deep-copy, or a caller can
// mutate the list it handed in and silently mutate the atom.
- (void)testMacroAtomDeepCopiesAtInit
{
    MTMathList* arg = [MTMathListBuilder buildFromString:@"n"];
    MTMathList* templ = PodTemplate();
    MTMacroAtom* macro = [[MTMacroAtom alloc] initWithCommand:@"pod"
                                                    arguments:@[ arg ]
                                                 templateExpression:templ];
    [arg addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];
    [templ addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];

    XCTAssertEqual([macro.arguments[0] atoms].count, 1ul, @"argument was not deep-copied");
    XCTAssertEqual(macro.templateExpression.atoms.count, 4ul, @"template was not deep-copied");
}

- (void)testMacroAtomCopyIsDeep
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMacroAtom* copy = [macro copy];

    XCTAssertTrue([copy isKindOfClass:[MTMacroAtom class]]);
    XCTAssertEqualObjects(copy.command, @"pod");
    XCTAssertNotEqual(copy.arguments[0], macro.arguments[0]);
    XCTAssertNotEqual(copy.templateExpression, macro.templateExpression);
    XCTAssertEqual(copy.templateExpression.atoms.count, 4ul);
    XCTAssertNotNil(copy.superScript);

    [macro.arguments[0] addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];
    XCTAssertEqual([copy.arguments[0] atoms].count, 1ul);
}

// A macro atom has no valid zero-argument construction. NS_UNAVAILABLE stops
// statically typed callers at compile time; the runtime guard below is what
// catches an id-typed one, so it is exercised through an id on purpose.
- (void)testMacroAtomRejectsGenericInitializer
{
    id macro = [MTMacroAtom alloc];
    XCTAssertThrows([macro initWithType:kMTMathAtomMacro value:@""]);
    XCTAssertThrows([macro initWithType:kMTMathAtomOrdinary value:@"x"]);
}

// The generic factory has a case for every other structured type, so falling
// through to its default would mint a plain MTMathAtom carrying type 22 — one
// that claims to be a macro but dies on -expansion.
- (void)testAtomFactoryRejectsMacroType
{
    XCTAssertThrows([MTMathAtom atomWithType:kMTMathAtomMacro value:@""]);
}

// +atomWithType: is not the only door: -type is a settable public property, so a
// plain MTMathAtom can be relabelled as a macro after the fact. Expansion dispatches
// on class and carries it through untouched, and the typesetter would silently drop
// it — so -finalized asserts on the way past.
- (void)testFinalizedRejectsNonMacroAtomTypedAsMacro
{
    MTMathAtom* impostor = [MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"];
    impostor.type = kMTMathAtomMacro;
    MTMathList* list = [MTMathList new];
    [list addAtom:impostor];
    XCTAssertThrows([list finalized]);
}

// -expansion substitutes #N only at the top level, so a nested placeholder would
// otherwise reach the finalized list and render as a literal "#1". Caught by an
// assert at construction, which raises in this (assertions-enabled) build.
- (void)testMacroAtomRejectsNestedPlaceholderInTemplate
{
    MTMathGroup* group = [[MTMathGroup alloc] init];
    group.innerList = [MTMathList new];
    [group.innerList addAtom:[[MTMacroParameterAtom alloc] initWithArgumentIndex:1]];
    MTMathList* nested = [MTMathList new];
    [nested addAtom:group];
    XCTAssertThrows([[MTMacroAtom alloc] initWithCommand:@"bad"
                                               arguments:@[ [MTMathListBuilder buildFromString:@"n"] ]
                                      templateExpression:nested]);

    // Also below a script, and below a fraction.
    MTFraction* frac = [[MTFraction alloc] init];
    frac.numerator = [MTMathList new];
    [frac.numerator addAtom:[[MTMacroParameterAtom alloc] initWithArgumentIndex:1]];
    frac.denominator = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* nestedFrac = [MTMathList new];
    [nestedFrac addAtom:frac];
    XCTAssertThrows([[MTMacroAtom alloc] initWithCommand:@"bad"
                                               arguments:@[ [MTMathListBuilder buildFromString:@"n"] ]
                                      templateExpression:nestedFrac]);

    MTMathAtom* scripted = [MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"];
    scripted.superScript = [MTMathList new];
    [scripted.superScript addAtom:[[MTMacroParameterAtom alloc] initWithArgumentIndex:1]];
    MTMathList* nestedScript = [MTMathList new];
    [nestedScript addAtom:scripted];
    XCTAssertThrows([[MTMacroAtom alloc] initWithCommand:@"bad"
                                               arguments:@[ [MTMathListBuilder buildFromString:@"n"] ]
                                      templateExpression:nestedScript]);
}

// A top-level #N is exactly what the initializer must accept.
- (void)testMacroAtomAcceptsTopLevelPlaceholder
{
    XCTAssertNoThrow(PodMacroWithArgument(@"n"));
}

// Nests `depth` \pod macros, each one the sole content of the next one's argument.
static MTMacroAtom* NestedPodChain(NSUInteger depth)
{
    MTMacroAtom* macro = PodMacroWithArgument(@"n");
    for (NSUInteger i = 1; i < depth; i++) {
        MTMathList* arg = [MTMathList new];
        [arg addAtom:macro];
        macro = [[MTMacroAtom alloc] initWithCommand:@"pod"
                                           arguments:@[ arg ]
                                  templateExpression:PodTemplate()];
    }
    return macro;
}

// Expansion recurses once per nesting level, so an absurdly deep chain must fail
// loud rather than run the stack out.
- (void)testRunawayExpansionDepthThrows
{
    MTMathList* deep = [MTMathList new];
    [deep addAtom:NestedPodChain(64)];
    XCTAssertThrows([deep finalized]);

    // Realistic nesting stays well inside the budget.
    MTMathList* shallow = [MTMathList new];
    [shallow addAtom:NestedPodChain(8)];
    XCTAssertNoThrow([shallow finalized]);

    // Pin the boundary itself: the outermost macro expands at depth 0, so a chain of
    // exactly kMTMaxMacroExpansionDepth (32) reaches depth 31 and is allowed, while
    // 33 reaches the limit and fails.
    MTMathList* atLimit = [MTMathList new];
    [atLimit addAtom:NestedPodChain(32)];
    XCTAssertNoThrow([atLimit finalized]);

    MTMathList* pastLimit = [MTMathList new];
    [pastLimit addAtom:NestedPodChain(33)];
    XCTAssertThrows([pastLimit finalized]);
}

// An arity mismatch between template and invocation is a bug in the macro table,
// so it asserts (which raises here, where assertions are enabled). Builds with
// NS_BLOCK_ASSERTIONS keep the placeholder instead, rendering a literal "#2".
- (void)testExpansionRejectsOutOfRangeArgumentIndex
{
    MTMathList* templ = [MTMathList new];
    [templ addAtom:[[MTMacroParameterAtom alloc] initWithArgumentIndex:2]];
    MTMacroAtom* macro = [[MTMacroAtom alloc] initWithCommand:@"arity"
                                                    arguments:@[ [MTMathListBuilder buildFromString:@"n"] ]
                                           templateExpression:templ];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];
    XCTAssertThrows([list finalized]);
}

// \noargs with nothing to terminate the command name would re-parse as \noargsx.
- (void)testZeroArgumentMacroSerializesWithSeparator
{
    MTMathList* templ = [MTMathListBuilder buildFromString:@"1"];
    MTMacroAtom* macro = [[MTMacroAtom alloc] initWithCommand:@"noargs"
                                                    arguments:@[]
                                           templateExpression:templ];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];
    [list addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\noargs x");
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
// argument must show up in serialization.
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
        @"-x": @"[6:\u2212, 3:x]",
        // Nothing follows -> Unary.
        @"x+": @"[3:x, 6:+]",
        // Follows an Open -> Unary.
        @"(+3)": @"[8:(, 6:+, 2:3, 9:)]",
        // Demotion happens independently inside each sub-list.
        @"\\frac{1+2}{3-}": @"[10:numerator[2:1, 5:+, 2:2]denominator[2:3, 6:\u2212]]",
        @"a\\equiv b": @"[3:a, 7:\u2261, 3:b]",
        // 2 and 3 fuse; x stays Bin between two Numbers.
        @"1\\times 23": @"[2:1, 5:\u00d7, 2:23]",
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

- (void)testExpandingMacrosCopiesListWithoutMacros
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"1+2"];
    MTMathList* expanded = [list expandMacros];
    XCTAssertNotEqual(expanded, list);
    XCTAssertEqual(expanded.atoms.count, 3ul);
    // Non-macro atoms are carried over by reference; -finalized is what copies.
    for (NSUInteger i = 0; i < list.atoms.count; i++) {
        XCTAssertEqual(expanded.atoms[i], list.atoms[i]);
    }
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
                                   templateExpression:ModTemplate()];
}

// Phase 1 produces RAW atoms — no reclassification yet. \pod{n} -> 4 atoms with the
// placeholder replaced by a copy of the argument.
- (void)testExpansionSplicesArgumentIntoPlaceholder
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
        XCTAssertFalse([atom isKindOfClass:[MTMacroParameterAtom class]]);
        XCTAssertNotEqual(atom.type, kMTMathAtomMacro);
    }
}

// A multi-atom argument is spliced inline, not wrapped.
- (void)testExpansionSplicesMultiAtomArgument
{
    MTMathList* list = [MTMathList new];
    [list addAtom:PodMacroWithArgument(@"n+1")];
    MTMathList* expanded = [list expandMacros];
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
    XCTAssertEqual(macro.templateExpression.atoms.count, 4ul);
    XCTAssertTrue([macro.templateExpression.atoms[2] isKindOfClass:[MTMacroParameterAtom class]]);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:macro.arguments[0]], @"n");
}

// Re-finalizing an already-finalized list must be a no-op. The typesetter depends
// on it, and it is the invariant that would break if expansion left anything behind
// for a second reclassifying pass to act on.
- (void)testRefinalizingExpandedListIsIdempotent
{
    MTMathList* list = [MTMathList new];
    [list addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    [list addAtom:ModMacroWithArgument(@"n+")];

    MTMathList* once = list.finalized;
    MTMathList* twice = once.finalized;
    XCTAssertNotEqual(twice, once);
    XCTAssertEqualObjects(ListSignature(twice), ListSignature(once));
    // The trailing Bin was already demoted to Unary by the first pass; the second
    // must find nothing left to reclassify.
    XCTAssertEqual(once.atoms.lastObject.type, kMTMathAtomUnaryOperator);
}

// A macro nested inside another macro's argument is expanded by the same pass
//: the inner atom is spliced into this list, then re-scanned.
- (void)testExpansionRecursesIntoNestedMacros
{
    MTMacroAtom* inner = PodMacroWithArgument(@"n");
    MTMathList* outerArg = [MTMathList new];
    [outerArg addAtom:inner];
    MTMacroAtom* outer = [[MTMacroAtom alloc] initWithCommand:@"pod"
                                                    arguments:@[ outerArg ]
                                                 templateExpression:PodTemplate()];
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
        XCTAssertFalse([atom isKindOfClass:[MTMacroParameterAtom class]]);
    }
}

// Mutating a parsed argument must change what renders, not just what serializes.
// PodTemplate() leads with an 8mu space, and 8 is not one of the named
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

    MTMathList* expanded = [list expandMacros];
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
    MTMathAtom* close = [list expandMacros].atoms[3];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:close.subScript], @"k");
}

// \mod{n\;}^2: the trailing space is not scriptable, so the script skips it and
// lands on n. It is never dropped.
- (void)testScriptSkipsTrailingSpace
{
    MTMacroAtom* macro = ModMacroWithArgument(@"n\\;");
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    MTMathList* expanded = [list expandMacros];
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

    MTMathList* expanded = [list expandMacros];
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

    MTMathAtom* appended = [list expandMacros].atoms.lastObject;
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

    MTMathList* expanded = [list expandMacros];
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

    MTMathList* expanded = [list expandMacros];
    MTMathAtom* appended = expanded.atoms.lastObject;
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:appended.superScript], @"3");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:appended.subScript], @"k");

    MTMathAtom* n = expanded.atoms[expanded.atoms.count - 2];
    XCTAssertNil(n.subScript, @"the pair must not be split across two atoms");
}

// No scriptable atom anywhere in the expansion. Unreachable for the three built-in
// templates (all end in a scriptable atom), but a user-defined \newcommand would
// make it reachable, so it is covered here with a spaces-only template.
- (void)testNoScriptableTargetAppendsEmptyOrdinary
{
    MTMathList* spacesOnly = [MTMathList new];
    [spacesOnly addAtom:[[MTMathSpace alloc] initWithSpace:8]];
    [spacesOnly addAtom:[[MTMathSpace alloc] initWithSpace:6]];
    MTMacroAtom* macro = [[MTMacroAtom alloc] initWithCommand:@"spacesonly"
                                                    arguments:@[]
                                                 templateExpression:spacesOnly];
    macro.superScript = [MTMathListBuilder buildFromString:@"2"];
    MTMathList* list = [MTMathList new];
    [list addAtom:macro];

    MTMathList* expanded = [list expandMacros];
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
// design that finalized each expansion on its own would demote it to Unary.
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

#pragma mark - Required-argument guard

- (void)testRequiredArgumentReadsBracedArgument
{
    MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:@"{n+1}"];
    MTMathList* arg = [builder requiredArgumentWithError:MTParseErrorMissingArgument];
    XCTAssertNotNil(arg);
    XCTAssertNil(builder.error);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:arg], @"n+1");
}

- (void)testRequiredArgumentReadsUnbracedToken
{
    MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:@"n"];
    MTMathList* arg = [builder requiredArgumentWithError:MTParseErrorMissingArgument];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:arg], @"n");
}

- (void)testRequiredArgumentAllowsEmptyBraces
{
    // \pmod{} is legal LaTeX and renders "( mod )" (LLD §4.4).
    MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:@"{}"];
    MTMathList* arg = [builder requiredArgumentWithError:MTParseErrorMissingArgument];
    XCTAssertNotNil(arg);
    XCTAssertNil(builder.error);
    XCTAssertEqual(arg.atoms.count, 0ul);
}

- (void)testRequiredArgumentFailsAtEOF
{
    for (NSString* input in @[ @"", @"   " ]) {
        MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:input];
        XCTAssertNil([builder requiredArgumentWithError:MTParseErrorMissingArgument],
                     @"input %@", input);
        XCTAssertEqual(builder.error.code, MTParseErrorMissingArgument, @"input %@", input);
    }
}

- (void)testRequiredArgumentFailsOnDelimiterInArgumentPosition
{
    for (NSString* input in @[ @"}", @"^2", @"_2", @"&x" ]) {
        MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:input];
        XCTAssertNil([builder requiredArgumentWithError:MTParseErrorMissingArgument],
                     @"input %@", input);
        XCTAssertEqual(builder.error.code, MTParseErrorMissingArgument, @"input %@", input);
    }
}

- (void)testRequiredArgumentPropagatesInnerError
{
    MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:@"{\\notacommand}"];
    XCTAssertNil([builder requiredArgumentWithError:MTParseErrorMissingArgument]);
    XCTAssertEqual(builder.error.code, MTParseErrorInvalidCommand);
}

#pragma mark - Template mode

- (void)testBuildTemplateParsesPodExpansion
{
    MTMathList* t = [MTMathListBuilder buildTemplate:@"\\mkern8mu(#1)"];
    XCTAssertNotNil(t);
    XCTAssertEqual(t.atoms.count, 4ul);
    XCTAssertEqual([t.atoms[0] type], kMTMathAtomSpace);
    XCTAssertEqualWithAccuracy([(MTMathSpace*)t.atoms[0] space], 8, 0.001);
    XCTAssertEqual([t.atoms[1] type], kMTMathAtomOpen);
    XCTAssertTrue([t.atoms[2] isKindOfClass:[MTMacroParameterAtom class]]);
    XCTAssertEqual([(MTMacroParameterAtom*)t.atoms[2] argumentIndex], 1ul);
    XCTAssertEqual([t.atoms[3] type], kMTMathAtomClose);
}

- (void)testBuildTemplateParsesPmodExpansion
{
    MTMathList* t = [MTMathListBuilder buildTemplate:@"\\mkern8mu(\\mathrm{mod}\\mkern6mu#1)"];
    XCTAssertNotNil(t);
    // Space8, "(", m, o, d, Space6, #1, ")"
    XCTAssertEqual(t.atoms.count, 8ul);
    XCTAssertEqualWithAccuracy([(MTMathSpace*)t.atoms[0] space], 8, 0.001);
    XCTAssertEqual([t.atoms[1] type], kMTMathAtomOpen);
    for (NSUInteger i = 2; i <= 4; i++) {
        // \mathrm yields Roman-styled atoms; changeFont maps them to upright Latin
        // at layout time (MTTypesetter.m:539-545).
        XCTAssertEqual([t.atoms[i] fontStyle], kMTFontStyleRoman, @"atom %lu", (unsigned long)i);
    }
    XCTAssertEqualObjects([t.atoms[2] nucleus], @"m");
    XCTAssertEqualObjects([t.atoms[3] nucleus], @"o");
    XCTAssertEqualObjects([t.atoms[4] nucleus], @"d");
    XCTAssertEqualWithAccuracy([(MTMathSpace*)t.atoms[5] space], 6, 0.001);
    XCTAssertTrue([t.atoms[6] isKindOfClass:[MTMacroParameterAtom class]]);
    XCTAssertEqual([t.atoms[7] type], kMTMathAtomClose);
}

- (void)testBuildTemplateParsesModExpansion
{
    MTMathList* t = [MTMathListBuilder buildTemplate:@"\\mkern12mu\\mathrm{mod}\\mkern6mu#1"];
    XCTAssertEqual(t.atoms.count, 6ul);
    XCTAssertEqualWithAccuracy([(MTMathSpace*)t.atoms[0] space], 12, 0.001);
    XCTAssertTrue([t.atoms[5] isKindOfClass:[MTMacroParameterAtom class]]);
}

// Template mode is opt-in: '#' in user input keeps raising the same error it
// always has, so no user-facing parsing changes.
- (void)testHashIsStillInvalidInUserInput
{
    NSError* error = nil;
    XCTAssertNil([MTMathListBuilder buildFromString:@"a#1" error:&error]);
    XCTAssertEqual(error.code, MTParseErrorInvalidCharacter);
}

- (void)testBuildTemplateRejectsMalformedPlaceholder
{
    XCTAssertNil([MTMathListBuilder buildTemplate:@"(#x)"]);
    XCTAssertNil([MTMathListBuilder buildTemplate:@"(#0)"]);
    XCTAssertNil([MTMathListBuilder buildTemplate:@"(#"]);
}

#pragma mark - Macro registry

- (void)testSupportedMacroNames
{
    NSArray<NSString*>* names = [MTMathListBuilder supportedMacroNames];
    XCTAssertEqual(names.count, 3ul);
    for (NSString* name in @[ @"pmod", @"mod", @"pod" ]) {
        XCTAssertTrue([names containsObject:name], @"missing %@", name);
    }
    // \bmod is a symbol, not a macro. The two discovery surfaces stay disjoint.
    XCTAssertFalse([names containsObject:@"bmod"]);
    XCTAssertTrue([[MTMathAtomFactory supportedLatexSymbolNames] containsObject:@"bmod"]);
    for (NSString* name in names) {
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
    XCTAssertEqual(macro.arguments.count, 1ul);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:macro.arguments[0]], @"n");
    XCTAssertEqual(macro.templateExpression.atoms.count, 8ul);
}

- (void)testAllThreeMacrosParse
{
    NSDictionary<NSString*, NSNumber*>* expectedTemplateLengths = @{
        @"pmod": @8,   // Space8 ( m o d Space6 #1 )
        @"mod":  @6,   // Space12 m o d Space6 #1
        @"pod":  @4,   // Space8 ( #1 )
    };
    for (NSString* command in expectedTemplateLengths) {
        NSString* latex = [NSString stringWithFormat:@"x \\%@{n}", command];
        MTMathList* list = [MTMathListBuilder buildFromString:latex];
        XCTAssertNotNil(list, @"%@", latex);
        XCTAssertEqual(list.atoms.count, 2ul, @"%@", latex);
        MTMacroAtom* macro = (MTMacroAtom*)list.atoms[1];
        XCTAssertEqual(macro.type, kMTMathAtomMacro, @"%@", latex);
        XCTAssertEqualObjects(macro.command, command);
        XCTAssertEqual(macro.templateExpression.atoms.count,
                       expectedTemplateLengths[command].unsignedIntegerValue, @"%@", latex);
    }
}

// The shared dispatch tail attaches ^/_ to whatever single atom the chain yields —
// no new script logic needed for macros (LLD §2.6).
- (void)testMacroCarriesScriptsFromSharedTail
{
    MTMacroAtom* macro = (MTMacroAtom*)[MTMathListBuilder buildFromString:@"\\pmod{n}^2"].atoms[0];
    XCTAssertEqual(macro.type, kMTMathAtomMacro);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:macro.superScript], @"2");
}

- (void)testUnbracedArgument
{
    MTMacroAtom* macro = (MTMacroAtom*)[MTMathListBuilder buildFromString:@"\\pmod n"].atoms[0];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:macro.arguments[0]], @"n");
}

- (void)testEmptyArgumentIsAllowed
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\pmod{}"];
    XCTAssertNotNil(list);
    MTMacroAtom* macro = (MTMacroAtom*)list.atoms[0];
    XCTAssertEqual([macro.arguments[0] atoms].count, 0ul);
}

- (void)testMissingArgumentIsAnError
{
    for (NSString* latex in @[ @"\\pmod", @"\\mod", @"\\pod", @"a \\pmod ",
                               @"{\\pmod}", @"\\pmod^2" ]) {
        NSError* error = nil;
        XCTAssertNil([MTMathListBuilder buildFromString:latex error:&error], @"%@", latex);
        XCTAssertEqual(error.code, MTParseErrorMissingArgument, @"%@", latex);
    }
}

- (void)testMalformedArgumentPropagates
{
    NSError* error = nil;
    XCTAssertNil([MTMathListBuilder buildFromString:@"\\pmod{\\notacommand}" error:&error]);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
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

// Degenerate but benign: one atom means oneCharOnly makes the whole macro the
// superscript. TeX errors here; iosMath renders it (documented divergence, LLD §6).
- (void)testMacroAsSuperscriptRendersBenignly
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"x^\\pmod{n}"];
    XCTAssertNotNil(list);
    XCTAssertEqual([list.atoms[0] superScript].atoms.count, 1ul);
    XCTAssertEqual([[list.atoms[0] superScript].atoms[0] type], kMTMathAtomMacro);
    XCTAssertNoThrow([list finalized]);
}

// The argument is parsed under the enclosing font style; the parens and spaces come
// from the template, which is parsed by a fresh builder at default style (LLD §6).
- (void)testMacroInsideFontStyleGroup
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\mathbf{x \\pmod{n}}"];
    XCTAssertNotNil(list);
    MTMacroAtom* macro = nil;
    for (MTMathAtom* atom in list.atoms) {
        if (atom.type == kMTMathAtomMacro) { macro = (MTMacroAtom*)atom; break; }
    }
    XCTAssertNotNil(macro);
    XCTAssertEqual([macro.arguments[0] atoms][0].fontStyle, kMTFontStyleBold);
    // "mod" stays Roman regardless — it comes from \mathrm in the template.
    XCTAssertEqual(macro.templateExpression.atoms[2].fontStyle, kMTFontStyleRoman);
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

// The leading gap really is 8mu / 12mu wider than the same expression with no gap.
- (void)testLeadingGapWidths
{
    CGFloat muUnit = self.font.mathTable.muUnit;
    MTMathListDisplay* bare = [self displayForLaTeX:@"x(\\mathrm{mod}\\mkern6mu n)"];
    MTMathListDisplay* pmod = [self displayForLaTeX:@"x\\pmod{n}"];
    XCTAssertEqualWithAccuracy(pmod.width - bare.width, 8 * muUnit, 0.01);

    MTMathListDisplay* bareMod = [self displayForLaTeX:@"x\\mathrm{mod}\\mkern6mu n"];
    MTMathListDisplay* mod = [self displayForLaTeX:@"x\\mod{n}"];
    XCTAssertEqualWithAccuracy(mod.width - bareMod.width, 12 * muUnit, 0.01);
}

- (void)testMacrosBuildWithoutAsserting
{
    for (NSString* latex in @[ @"\\pmod{n}", @"\\mod{n}", @"\\pod{n}",
                               @"a \\equiv b \\pmod{n}", @"(\\pmod{n}",
                               @"\\pmod{n}^2", @"\\pmod{\\pmod{n}}", @"\\pmod{}" ]) {
        XCTAssertNoThrow([self displayForLaTeX:latex], @"%@", latex);
    }
}

@end
