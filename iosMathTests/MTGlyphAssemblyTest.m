//
//  MTGlyphAssemblyTest.m
//  iosMath
//
//  Tests for the glyph-assembly loop-termination guard introduced in FUN-4.
//  Without the guard, testConstructGlyphWithZeroAdvanceExtenderTerminates hangs
//  indefinitely; with the guard it returns a best-effort assembly promptly.
//

#import <XCTest/XCTest.h>

#import "MTTypesetter.h"
#import "MTTypesetter+Testing.h"
#import "MTFontMathTable.h"
#import "MTGlyphPart+Testing.h"
#import "MTFont.h"
#import "MTFontManager.h"
#import "MTMathList.h"
#import "MTMathListBuilder.h"
#import "MTMathListDisplay.h"
#import "MTMathListDisplayInternal.h"

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build a synthetic MTGlyphPart with caller-supplied field values.
static MTGlyphPart *makePart(CGGlyph glyph,
                              CGFloat fullAdvance,
                              CGFloat startConnector,
                              CGFloat endConnector,
                              BOOL extender)
{
    MTGlyphPart *part = [[MTGlyphPart alloc] init];
    part.glyph               = glyph;
    part.fullAdvance          = fullAdvance;
    part.startConnectorLength = startConnector;
    part.endConnectorLength   = endConnector;
    part.isExtender           = extender;
    return part;
}

// ---------------------------------------------------------------------------

@interface MTGlyphAssemblyTest : XCTestCase
@property (nonatomic) MTFont *font;
@property (nonatomic) MTTypesetter *typesetter;
@end

@implementation MTGlyphAssemblyTest

- (void)setUp {
    [super setUp];
    self.font = MTFontManager.fontManager.defaultFont;
    // Construct a fully initialised MTTypesetter so _styleFont is set.
    // constructGlyphWithParts: reads _styleFont.mathTable.minConnectorOverlap
    // to determine the minimum connector distance; without _styleFont it crashes.
    self.typesetter = [[MTTypesetter alloc] initWithFont:self.font
                                                   style:kMTLineStyleDisplay
                                                 cramped:NO
                                                  spaced:NO];
}

- (void)tearDown {
    [super tearDown];
}

// ---------------------------------------------------------------------------
// RED test: zero-advance extender must not hang (FUN-4)
// ---------------------------------------------------------------------------

/// Regression guard for FUN-4.
///
/// A parts list with two non-extender parts (each fullAdvance = 10 pt) flanking
/// a zero-advance extender simulates malformed font MATH data.  The flanking
/// parts constrain maxDelta (via their connector lengths), so neither normal
/// exit branch ever fires:
///   - minHeight stays flat each time we add more zero-advance extenders.
///   - maxHeight stays flat or shrinks (maxDelta ≤ 0 once extender joints are
///     factored in), so branch B never becomes reachable.
/// Without the no-progress guard the loop spins forever.  With the guard the
/// method returns a best-effort assembly promptly.
///
/// NOTE: XCTest has a default per-test timeout of 60 s (CI kills after ~10 min).
/// Without the fix this test is caught by the timeout and shows as a failure/hang;
/// with the fix it returns in microseconds.
- (void)testConstructGlyphWithZeroAdvanceExtenderTerminates
{
    // Two fixed (non-extender) parts with connector lengths that constrain
    // maxDelta once the extender's joints are added.  connector=5 pt,
    // minConnectorOverlap (from the font) is ~0.4 pt, so maxDelta per joint
    // ≈ 0.  The zero-advance extender contributes nothing to minOffset.
    MTGlyphPart *partLeft = makePart(1, 10.0,  0.0, 5.0, NO);   // endConnector=5
    MTGlyphPart *extender = makePart(2,  0.0,  0.0, 0.0, YES);  // fullAdvance=0 — degenerate
    MTGlyphPart *partRight = makePart(3, 10.0,  5.0, 0.0, NO);   // startConnector=5

    NSArray<MTGlyphPart *> *parts = @[ partLeft, extender, partRight ];

    NSArray<NSNumber *> *glyphs  = nil;
    NSArray<NSNumber *> *offsets = nil;
    CGFloat height = 0;

    // Request a height far beyond what these degenerate parts can ever reach.
    [self.typesetter constructGlyphWithParts:parts
                                      height:1000.0
                                      glyphs:&glyphs
                                     offsets:&offsets
                                      height:&height];

    // The method must return with a usable (non-empty) assembly.
    XCTAssertNotNil(glyphs,  @"glyphs must not be nil after degenerate-extender assembly");
    XCTAssertNotNil(offsets, @"offsets must not be nil after degenerate-extender assembly");
    XCTAssertGreaterThan(glyphs.count, 0u, @"best-effort assembly must contain at least one glyph");
    XCTAssertEqual(glyphs.count, offsets.count, @"glyph/offset arrays must be same length");
    // height is whatever the degenerate font could produce — just verify it's finite and >= 0.
    XCTAssertGreaterThanOrEqual(height, 0.0, @"returned height must be non-negative");
    XCTAssertTrue(isfinite(height), @"returned height must be finite");
}

/// Complementary check: with a positive-advance extender the normal exit branch
/// fires and minHeight >= glyphHeight (branch A) or the spread-delta branch B.
- (void)testConstructGlyphWithPositiveAdvanceExtenderProducesAdequateHeight
{
    // Non-extender: 10 pt base.
    MTGlyphPart *base    = makePart(1, 10.0, 0.0, 0.0, NO);
    // Extender with a real advance (5 pt).  Requesting 100 pt means we need
    // roughly 18+ copies; the loop should terminate normally via branch A.
    MTGlyphPart *extender = makePart(2, 5.0, 0.0, 0.0, YES);

    NSArray<MTGlyphPart *> *parts = @[ base, extender ];

    NSArray<NSNumber *> *glyphs  = nil;
    NSArray<NSNumber *> *offsets = nil;
    CGFloat height = 0;
    CGFloat requestedHeight = 100.0;

    [self.typesetter constructGlyphWithParts:parts
                                      height:requestedHeight
                                      glyphs:&glyphs
                                     offsets:&offsets
                                      height:&height];

    XCTAssertNotNil(glyphs);
    XCTAssertNotNil(offsets);
    XCTAssertGreaterThan(glyphs.count, 0u);
    XCTAssertEqual(glyphs.count, offsets.count);
    // Normal exit: assembled height must reach (or exceed) the requested height.
    XCTAssertGreaterThanOrEqual(height, requestedHeight,
        @"normal exit: assembled height %g must satisfy requested height %g",
        height, requestedHeight);
}

// ---------------------------------------------------------------------------
// Regression guard: bundled-font tall delimiter still renders (no behaviour change)
// ---------------------------------------------------------------------------

/// Renders a tall \left( ... \right) that forces glyph assembly (not just
/// variant selection) and asserts the display has positive dimensions.
/// This proves the no-progress guard does not perturb the common path with
/// well-formed font MATH data.
- (void)testTallDelimiterRendersWithBundledFont
{
    MTFont *font = MTFontManager.fontManager.defaultFont;
    // A fraction tall enough to force glyph assembly for the parentheses.
    NSString *latex = @"\\left( \\frac{\\frac{1}{2}}{\\frac{3}{4}} \\right)";
    MTMathList *list = [MTMathListBuilder buildFromString:latex];
    XCTAssertNotNil(list);

    MTMathListDisplay *display = [MTTypesetter createLineForMathList:list
                                                               font:font
                                                              style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertGreaterThan(display.ascent + display.descent, 0,
        @"tall delimiter display must have positive height");
    XCTAssertGreaterThan(display.width, 0,
        @"tall delimiter display must have positive width");
}

@end
