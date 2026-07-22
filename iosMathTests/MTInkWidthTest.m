#import <XCTest/XCTest.h>
#import <CoreText/CoreText.h>
#import "MTTypesetter.h"
#import "MTFont+Internal.h"
#import "MTFontManager.h"
#import "MTMathListDisplay.h"
#import "MTMathListDisplayInternal.h"
#import "MTMathAtomFactory.h"
#import "MTMathListBuilder.h"

@interface MTInkWidthTest : XCTestCase
@property (nonatomic) MTFont* font;
@end

@implementation MTInkWidthTest

- (void)setUp {
    [super setUp];
    self.font = MTFontManager.fontManager.defaultFont; // Latin Modern Math @ 20pt
}

- (MTMathListDisplay*)displayFor:(NSString*)latex {
    MTMathList* list = [MTMathListBuilder buildFromString:latex];
    return [MTTypesetter createLineForMathList:list font:self.font style:kMTLineStyleDisplay];
}

// Base getter: inkWidth == MAX(width, inkMaxX); default inkMaxX is 0.
- (void)testBaseInkWidthGetter {
    MTDisplay* d = [[MTDisplay alloc] init];
    d.width = 10;
    XCTAssertEqual(d.inkMaxX, 0);
    XCTAssertEqualWithAccuracy(d.inkWidth, 10, 0.001);   // inkMaxX 0 < width → width
    d.inkMaxX = 15;
    XCTAssertEqualWithAccuracy(d.inkWidth, 15, 0.001);   // inkMaxX > width → inkMaxX
    d.inkMaxX = 4;
    XCTAssertEqualWithAccuracy(d.inkWidth, 10, 0.001);   // inkMaxX < width → width
}

// The MTCTLineDisplay leaf of an overhang glyph reports ink past its advance.
- (void)testCTLineLeafInk {
    MTMathListDisplay* dP = [self displayFor:@"P"];
    MTCTLineDisplay* lineP = (MTCTLineDisplay*)dP.subDisplays.firstObject;
    XCTAssertTrue([lineP isKindOfClass:[MTCTLineDisplay class]]);
    XCTAssertGreaterThanOrEqual(lineP.inkWidth, 15.08 - 0.01);   // P ink right = 15.08
    XCTAssertGreaterThan(lineP.inkWidth, lineP.width);           // 15.08 > advance 12.84

    // Control: x ink (10.54) < advance (11.44) → inkWidth stays the advance.
    MTMathListDisplay* dx = [self displayFor:@"x"];
    MTCTLineDisplay* lineX = (MTCTLineDisplay*)dx.subDisplays.firstObject;
    XCTAssertEqualWithAccuracy(lineX.inkWidth, 11.44, 0.01);
    XCTAssertEqualWithAccuracy(lineX.width, 11.44, 0.01);
}

// \text{...} produces an MTTextDisplay leaf; its inkMaxX must be populated and
// the invariant inkWidth >= width must hold.
- (void)testTextLeafInk {
    MTMathListDisplay* d = [self displayFor:@"\\text{Wf}"];
    MTTextDisplay* text = nil;
    for (MTDisplay* sub in d.subDisplays) {
        if ([sub isKindOfClass:[MTTextDisplay class]]) { text = (MTTextDisplay*)sub; break; }
    }
    XCTAssertNotNil(text, @"expected an MTTextDisplay");
    XCTAssertGreaterThan(text.inkMaxX, 0);
    XCTAssertGreaterThanOrEqual(text.inkWidth, text.width - 0.01);
}

// A large-op glyph (e.g. \int) renders as an MTGlyphDisplay; its inkMaxX comes
// from the glyph bounding box, independent of the shiftDown y-adjustment.
- (void)testGlyphLeafInk {
    MTMathListDisplay* d = [self displayFor:@"\\int"];
    MTGlyphDisplay* glyph = (MTGlyphDisplay*)[self findDisplayOfClass:[MTGlyphDisplay class] in:d];
    XCTAssertNotNil(glyph, @"expected an MTGlyphDisplay");
    XCTAssertGreaterThan(glyph.inkMaxX, 0);
    XCTAssertGreaterThanOrEqual(glyph.inkWidth, glyph.width - 0.01);
}

// Tall delimiters build an MTGlyphConstructionDisplay (vertical stack, x-offsets 0).
// Deeply nested fractions are needed to exceed the font's largest pre-built
// paren variant and force the multi-part glyph assembly.
- (void)testGlyphConstructionLeafInk {
    MTMathListDisplay* d = [self displayFor:@"\\left(\\frac{1}{\\frac{1}{\\frac{1}{\\frac{1}{2}}}}\\right)"];
    MTGlyphConstructionDisplay* g =
        (MTGlyphConstructionDisplay*)[self findDisplayOfClass:[MTGlyphConstructionDisplay class] in:d];
    XCTAssertNotNil(g, @"expected an MTGlyphConstructionDisplay");
    XCTAssertGreaterThan(g.inkMaxX, 0);
    XCTAssertGreaterThanOrEqual(g.inkWidth, g.width - 0.01);
}

// A wide over-arrow assembles horizontally; ink max-x folds per-part x offsets.
- (void)testHorizontalAssemblyLeafInk {
    MTMathListDisplay* d = [self displayFor:@"\\overleftrightarrow{ABCDEFG}"];
    MTHorizontalGlyphAssemblyDisplay* h =
        (MTHorizontalGlyphAssemblyDisplay*)[self findDisplayOfClass:[MTHorizontalGlyphAssemblyDisplay class] in:d];
    XCTAssertNotNil(h, @"expected an MTHorizontalGlyphAssemblyDisplay");
    XCTAssertGreaterThan(h.inkMaxX, 0);
    XCTAssertGreaterThanOrEqual(h.inkWidth, h.width - 0.01);
}

// Top-level rollup folds trailing-leaf ink AND trailing-script ink, while the
// advance width and script positions stay exactly as before (layout invariance).
- (void)testRollupAndLayoutInvariance {
    // Trailing overhang leaf rolls up to the top.
    MTMathListDisplay* dP = [self displayFor:@"P"];
    XCTAssertGreaterThanOrEqual(dP.inkWidth, 15.08 - 0.01);

    // Control with no overhang: inkWidth stays the advance.
    MTMathListDisplay* dx = [self displayFor:@"x"];
    XCTAssertEqualWithAccuracy(dx.inkWidth, 11.44, 0.01);

    // Scripts append to the top-level displays, so they roll up too.
    MTMathListDisplay* dxsq = [self displayFor:@"x^2"];
    XCTAssertGreaterThanOrEqual(dxsq.inkWidth, dxsq.width - 0.01);
    // Layout invariance: advance width and superscript position unchanged.
    XCTAssertEqualWithAccuracy(dxsq.width, 18.44, 0.01);
    MTMathListDisplay* script = (MTMathListDisplay*)dxsq.subDisplays.lastObject;
    XCTAssertEqualWithAccuracy(script.position.x, 11.44, 0.01);
    XCTAssertEqualWithAccuracy(script.position.y, 7.26, 0.01);
}

- (void)testFractionInk {
    [self assertComposite:[MTFractionDisplay class] bare:@"\\frac{1}{V}" shifted:@"a\\frac{1}{V}"];
}

- (void)testRadicalInk {
    [self assertComposite:[MTRadicalDisplay class] bare:@"\\sqrt{V}" shifted:@"a\\sqrt{V}"];
}

- (void)testOverlineInk {
    [self assertComposite:[MTLineDisplay class] bare:@"\\overline{V}" shifted:@"a\\overline{V}"];
}

- (void)testAccentInk {
    [self assertComposite:[MTAccentDisplay class] bare:@"\\hat{V}" shifted:@"a\\hat{V}"];
}

// \hat{V} above lets the accentee (V) trail, so it passes even if the accent glyph
// is ignored. \vec{f} is the opposite: the skewed arrow glyph overhangs past the
// accentee's ink, so the accent glyph itself must drive inkWidth.
- (void)testAccentGlyphInk {
    MTAccentDisplay* a = (MTAccentDisplay*)[self findDisplayOfClass:[MTAccentDisplay class]
                                                                 in:[self displayFor:@"\\vec{f}"]];
    XCTAssertNotNil(a);
    // True painted ink-right of the accent glyph in the accent display's basis.
    // Use the raw bbox max-x (inkMaxX), not accent.inkWidth, since the accent glyph's
    // advance is ~0 and would otherwise clamp away the real overhang.
    CGFloat accentInkRight  = (a.accent.position.x   - a.position.x) + a.accent.inkMaxX;
    CGFloat accenteeInkRight = (a.accentee.position.x - a.position.x) + a.accentee.inkWidth;
    // The accent glyph is the trailing source: it overhangs the accentee and the advance.
    XCTAssertGreaterThan(accentInkRight, accenteeInkRight);
    XCTAssertGreaterThan(accentInkRight, a.width);
    // The getter must cover the accent glyph's real ink.
    XCTAssertGreaterThanOrEqual(a.inkWidth, accentInkRight - 0.01);
}

- (void)testLargeOpLimitsInk {
    [self assertComposite:[MTLargeOpLimitsDisplay class] bare:@"\\sum^{VVV}" shifted:@"a\\sum^{VVV}"];
}

- (void)testStackInk {
    // \overrightarrow{V} alone doesn't overhang: the target width is the base's
    // *advance* (not ink), so the stretchy-arrow variant step can land wide
    // enough that centering the base within it absorbs the base's ink overhang.
    // A two-character base (VV) has enough advance that the same variant step
    // no longer fully covers the extra ink, restoring a real overhang.
    [self assertComposite:[MTStackDisplay class] bare:@"\\overrightarrow{VV}" shifted:@"a\\overrightarrow{VV}"];
}

- (void)testInnerInk {
    [self assertComposite:[MTInnerDisplay class] bare:@"\\left( V \\right." shifted:@"a\\left( V \\right."];
}

// Depth-first: the first display of the given class, or nil.
- (MTDisplay*)findDisplayOfClass:(Class)cls in:(MTDisplay*)d {
    if ([d isKindOfClass:cls]) return d;
    if ([d respondsToSelector:@selector(subDisplays)]) {
        for (MTDisplay* sub in [(id)d subDisplays]) {
            MTDisplay* hit = [self findDisplayOfClass:cls in:sub];
            if (hit) return hit;
        }
    }
    // Composites hold children outside subDisplays; probe the public accessors.
    for (MTDisplay* child in [self childrenOf:d]) {
        if (!child) continue;
        MTDisplay* hit = [self findDisplayOfClass:cls in:child];
        if (hit) return hit;
    }
    return nil;
}

// Public composite children (nucleus of large-op is private and omitted).
- (NSArray<MTDisplay*>*)childrenOf:(MTDisplay*)d {
    if ([d isKindOfClass:[MTFractionDisplay class]]) {
        MTFractionDisplay* f = (MTFractionDisplay*)d;
        return @[f.numerator, f.denominator];
    } else if ([d isKindOfClass:[MTRadicalDisplay class]]) {
        MTRadicalDisplay* r = (MTRadicalDisplay*)d;
        return r.degree ? @[r.radicand, r.degree] : @[r.radicand];
    } else if ([d isKindOfClass:[MTLargeOpLimitsDisplay class]]) {
        MTLargeOpLimitsDisplay* o = (MTLargeOpLimitsDisplay*)d;
        NSMutableArray* a = [NSMutableArray array];
        if (o.upperLimit) [a addObject:o.upperLimit];
        if (o.lowerLimit) [a addObject:o.lowerLimit];
        return a;
    } else if ([d isKindOfClass:[MTLineDisplay class]]) {
        return @[((MTLineDisplay*)d).inner];
    } else if ([d isKindOfClass:[MTAccentDisplay class]]) {
        MTAccentDisplay* a = (MTAccentDisplay*)d;
        return @[a.accentee, a.accent];
    } else if ([d isKindOfClass:[MTStackDisplay class]]) {
        MTStackDisplay* s = (MTStackDisplay*)d;
        NSMutableArray* a = [NSMutableArray arrayWithObject:s.base];
        if (s.over) [a addObject:s.over];
        if (s.under) [a addObject:s.under];
        return a;
    } else if ([d isKindOfClass:[MTInnerDisplay class]]) {
        MTInnerDisplay* i = (MTInnerDisplay*)d;
        NSMutableArray* a = [NSMutableArray array];
        if (i.leftDelimiter) [a addObject:i.leftDelimiter];
        [a addObject:i.inner];
        if (i.rightDelimiter) [a addObject:i.rightDelimiter];
        return a;
    }
    return @[];
}

// True ink-right of a composite, composed from its public children in the
// composite's own absolute-position basis. This is the guarantee lower bound.
- (CGFloat)composedInkRightOf:(MTDisplay*)d {
    CGFloat r = d.width;
    for (MTDisplay* child in [self childrenOf:d]) {
        if (!child) continue;
        r = MAX(r, (child.position.x - d.position.x) + child.inkWidth);
    }
    return r;
}

// Assert (a) the getter covers the composed child ink (guarantee), (b) it strictly
// exceeds the advance for an overhang child, and (c) the overhang (inkWidth - width)
// is invariant to the composite's absolute x — catching a wrong coordinate basis.
- (void)assertComposite:(Class)cls bare:(NSString*)bare shifted:(NSString*)shifted {
    MTDisplay* b = [self findDisplayOfClass:cls in:[self displayFor:bare]];
    MTDisplay* s = [self findDisplayOfClass:cls in:[self displayFor:shifted]];
    XCTAssertNotNil(b, @"no %@ in %@", NSStringFromClass(cls), bare);
    XCTAssertNotNil(s, @"no %@ in %@", NSStringFromClass(cls), shifted);
    XCTAssertGreaterThanOrEqual(b.inkWidth, [self composedInkRightOf:b] - 0.01);
    XCTAssertGreaterThanOrEqual(s.inkWidth, [self composedInkRightOf:s] - 0.01);
    XCTAssertGreaterThan(b.inkWidth, b.width);            // trailing child overhangs
    XCTAssertGreaterThan(s.position.x, b.position.x);     // shifted variant is further right
    XCTAssertEqualWithAccuracy(s.inkWidth - s.width, b.inkWidth - b.width, 0.02);  // basis-invariant
}

- (void)testPostInitWidthMutationGuard {
    MTMathListDisplay* d = [self displayFor:@"\\left( a+b \\right)"];
    XCTAssertGreaterThanOrEqual(d.inkWidth, d.width - 0.01);
    // Actually mutate width post-init: because inkWidth is a getter (not a value
    // frozen at construction), the invariant must still hold after width grows
    // past the original inkMaxX. A frozen implementation would fail here.
    d.width = d.width * 2;
    XCTAssertGreaterThanOrEqual(d.inkWidth, d.width - 0.01);
    // The mutation absorbs into inkWidth via the getter, not a stale frozen value:
    // walk every sub-display and assert the invariant holds everywhere.
    [self assertInkInvariant:d];
}

- (void)assertInkInvariant:(MTDisplay*)d {
    XCTAssertGreaterThanOrEqual(d.inkWidth, d.width - 0.01,
        @"%@ inkWidth %.2f < width %.2f", NSStringFromClass([d class]), d.inkWidth, d.width);
    if ([d respondsToSelector:@selector(subDisplays)]) {
        for (MTDisplay* sub in [(id)d subDisplays]) { [self assertInkInvariant:sub]; }
    }
    for (MTDisplay* child in [self childrenOf:d]) {
        if (child) [self assertInkInvariant:child];
    }
}

@end
