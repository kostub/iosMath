#import <XCTest/XCTest.h>
#import "MTMathUILabel.h"
#import "MTMathUILabelInternal.h"
#import "MTMathListDisplay.h"
#import "MTFont+Internal.h"
#import "MTMathListDisplayInternal.h"
#import "MTTypesetter.h"
#import "MTFontManager.h"
#import "MTMathListBuilder.h"

@interface MTMathUILabelSizingTest : XCTestCase
@end

@implementation MTMathUILabelSizingTest

- (MTMathUILabel*)labelFor:(NSString*)latex {
    MTMathUILabel* label = [[MTMathUILabel alloc] init];
    label.latex = latex;
    return label;
}

// Reported width covers the ink extent and lands on the device-pixel grid.
- (void)testSizeThatFitsInkAndGrid {
    for (NSString* latex in @[@"P", @"V", @"\\frac{1}{2}", @"\\int_0^1", @"x"]) {
        MTMathUILabel* label = [self labelFor:latex];
        CGFloat scale = [label screenScale];
        MTMathListDisplay* d =
            [MTTypesetter createLineForMathList:[MTMathListBuilder buildFromString:latex]
                                           font:label.font style:label.labelMode == kMTMathUILabelModeDisplay ? kMTLineStyleDisplay : kMTLineStyleText];
        CGSize size = [label sizeThatFits:CGSizeZero];
        // (a) covers the ink (insets are >= 0, so >= inkWidth alone).
        XCTAssertGreaterThanOrEqual(size.width, d.inkWidth - 0.001, @"%@", latex);
        // (b) both axes are whole device pixels.
        XCTAssertEqualWithAccuracy(size.width * scale,  round(size.width * scale),  0.001, @"%@", latex);
        XCTAssertEqualWithAccuracy(size.height * scale, round(size.height * scale), 0.001, @"%@", latex);
    }
}

- (void)testIntrinsicMatchesSizeThatFits {
    MTMathUILabel* label = [self labelFor:@"\\frac{1}{2}"];
    XCTAssertTrue(CGSizeEqualToSize(label.intrinsicContentSize, [label sizeThatFits:CGSizeZero]));
}

// Nil latex → insets only, still pixel-rounded.
- (void)testNilLatexReportsRoundedInsets {
    MTMathUILabel* label = [[MTMathUILabel alloc] init];
    label.latex = nil;
    CGFloat scale = [label screenScale];
    CGSize size = [label sizeThatFits:CGSizeZero];
    CGFloat lr = label.contentInsets.left + label.contentInsets.right;
    CGFloat tb = label.contentInsets.top + label.contentInsets.bottom;
    XCTAssertEqualWithAccuracy(size.width,  ceil(lr * scale) / scale, 0.001);
    XCTAssertEqualWithAccuracy(size.height, ceil(tb * scale) / scale, 0.001);
}

@end
