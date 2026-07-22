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

@end
