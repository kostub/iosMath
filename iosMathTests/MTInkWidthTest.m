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

@end
