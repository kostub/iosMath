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

@end
