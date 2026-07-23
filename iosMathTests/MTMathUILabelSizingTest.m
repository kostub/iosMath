#import <XCTest/XCTest.h>
#import "MTMathUILabel.h"
#import "MTMathUILabelInternal.h"
#import "MTMathListDisplay.h"
#import "MTFont+Internal.h"
#import "MTMathListDisplayInternal.h"
#import "MTTypesetter.h"
#import "MTFontManager.h"
#import "MTMathListBuilder.h"

@interface MTSpyLabel : MTMathUILabel
@property (nonatomic) NSInteger invalidateCount;
@property (nonatomic) CGFloat forcedScale;   // simulate a known backing scale
@end
@implementation MTSpyLabel
- (CGFloat)screenScale { return self.forcedScale; }
- (void)invalidateIntrinsicContentSize { self.invalidateCount++; [super invalidateIntrinsicContentSize]; }
@end

// Forces a known device-pixel scale so the grid-rounding assertions exercise
// 2x/3x rounding rather than the tautological scale==1 case.
@interface MTScaledLabel : MTMathUILabel
@property (nonatomic) CGFloat forcedScale;
@end
@implementation MTScaledLabel
- (CGFloat)screenScale { return self.forcedScale; }
@end

@interface MTMathUILabelSizingTest : XCTestCase
@end

@implementation MTMathUILabelSizingTest

- (MTMathUILabel*)labelFor:(NSString*)latex {
    MTMathUILabel* label = [[MTMathUILabel alloc] init];
    label.latex = latex;
    return label;
}

// Reported width covers the ink extent and lands on the device-pixel grid.
// Run at 1x/2x/3x so the grid-rounding assertions are exercised where they can
// actually fail, not just the tautological scale==1 case.
- (void)testSizeThatFitsInkAndGrid {
    for (NSNumber* scaleN in @[@1.0, @2.0, @3.0]) {
        CGFloat scale = scaleN.doubleValue;
        for (NSString* latex in @[@"P", @"V", @"\\frac{1}{2}", @"\\int_0^1", @"x"]) {
            MTScaledLabel* label = [[MTScaledLabel alloc] init];
            label.forcedScale = scale;
            label.latex = latex;
            MTMathListDisplay* d =
                [MTTypesetter createLineForMathList:[MTMathListBuilder buildFromString:latex]
                                               font:label.font style:label.labelMode == kMTMathUILabelModeDisplay ? kMTLineStyleDisplay : kMTLineStyleText];
            CGSize size = [label sizeThatFits:CGSizeZero];
            // (a) covers the ink (insets are >= 0, so >= inkWidth alone).
            XCTAssertGreaterThanOrEqual(size.width, d.inkWidth - 0.001, @"%@ @%.0fx", latex, scale);
            // (b) both axes are whole device pixels.
            XCTAssertEqualWithAccuracy(size.width * scale,  round(size.width * scale),  0.001, @"%@ @%.0fx", latex, scale);
            XCTAssertEqualWithAccuracy(size.height * scale, round(size.height * scale), 0.001, @"%@ @%.0fx", latex, scale);
        }
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

- (void)testAlignmentUsesInkWidth {
    NSString* latex = @"V";   // heavy right overhang (advance 11.66, ink 15.38)
    for (NSNumber* alignN in @[@(kMTTextAlignmentLeft), @(kMTTextAlignmentCenter), @(kMTTextAlignmentRight)]) {
        MTMathUILabel* label = [[MTMathUILabel alloc] init];
        label.latex = latex;
        label.textAlignment = (MTTextAlignment)alignN.integerValue;
        CGSize size = [label sizeThatFits:CGSizeZero];
        label.frame = CGRectMake(0, 0, size.width, size.height);
        [label layoutSubviews];

        MTMathListDisplay* d = label.displayList;
        CGFloat inkRight = d.position.x + d.inkWidth;
        CGFloat frameRight = size.width - label.contentInsets.right;
        // Ink right edge must sit within the (inset) frame for every alignment.
        XCTAssertLessThanOrEqual(inkRight, frameRight + 0.01,
            @"alignment %@ clips ink: inkRight %.2f > frameRight %.2f", alignN, inkRight, frameRight);
    }
}

// An actual backing-scale change re-queries the intrinsic size end to end: the
// platform lifecycle hook fires invalidateIntrinsicContentSize, and because
// intrinsicContentSize is uncached (recomputed per query) the next read reflects the
// new scale's device-pixel grid. The hook invalidates unconditionally — it does not
// diff scales (see MTMathUILabel didMoveToWindow / viewDidChangeBackingProperties) —
// so this drives the whole path: 1x size → scale becomes 3x → hook → 3x-grid re-query.
- (void)testScaleLifecycleInvalidates {
    MTSpyLabel* label = [[MTSpyLabel alloc] init];
    label.forcedScale = 1;
    label.latex = @"V";   // ink overhang; its 1x and 3x rounded widths differ
    CGSize sizeAt1x = label.intrinsicContentSize;
    XCTAssertEqualWithAccuracy(sizeAt1x.width, round(sizeAt1x.width), 0.001, @"1x width off grid");

    // Backing scale becomes 3x, then fire the platform lifecycle hook.
    label.forcedScale = 3;
    label.invalidateCount = 0;
#if TARGET_OS_IPHONE
    [label didMoveToWindow];
#else
    [label viewDidChangeBackingProperties];
    [label viewDidMoveToWindow];
#endif
    XCTAssertGreaterThan(label.invalidateCount, 0, @"scale-change lifecycle hook must invalidate intrinsic size");

    // Re-query now lands on the 3x grid and differs from the 1x answer.
    CGSize sizeAt3x = label.intrinsicContentSize;
    XCTAssertEqualWithAccuracy(sizeAt3x.width * 3, round(sizeAt3x.width * 3), 0.001, @"3x width off grid");
    XCTAssertNotEqualWithAccuracy(sizeAt3x.width, sizeAt1x.width, 0.001, @"re-query did not adopt the new scale");
}

@end
