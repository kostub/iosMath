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

@end
