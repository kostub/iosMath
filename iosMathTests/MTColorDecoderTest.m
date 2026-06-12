//
//  MTColorDecoderTest.m
//  iosMath
//
//  Tests for UIColor(HexString) / NSColor(HexString) colorFromHexString:.
//  REN-7: 3-digit CSS shorthand #RGB should expand to #RRGGBB before decoding.
//

@import XCTest;

#if TARGET_OS_IPHONE
#import "UIColor+HexString.h"
#define MTTestColor UIColor
#else
#import "NSColor+HexString.h"
#define MTTestColor NSColor
#endif

@interface MTColorDecoderTest : XCTestCase
@end

@implementation MTColorDecoderTest

// Helper: extract red/green/blue components in the 0–255 integer range.
- (void)assertColor:(MTTestColor *)color red:(int)expectedR green:(int)expectedG blue:(int)expectedB msg:(NSString *)msg {
    XCTAssertNotNil(color, @"%@", msg);
    CGFloat r = 0, g = 0, b = 0, a = 0;
#if TARGET_OS_IPHONE
    [color getRed:&r green:&g blue:&b alpha:&a];
#else
    // NSColor is created with colorWithSRGBRed:; retrieve components in sRGB.
    MTTestColor *srgb = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    [srgb getRed:&r green:&g blue:&b alpha:&a];
#endif
    XCTAssertEqual((int)round(r * 255), expectedR, @"red   — %@", msg);
    XCTAssertEqual((int)round(g * 255), expectedG, @"green — %@", msg);
    XCTAssertEqual((int)round(b * 255), expectedB, @"blue  — %@", msg);
}

// REN-7 regression: #f00 must decode to pure red, not near-black green.
- (void)testThreeDigit_red {
    MTTestColor *color = [MTTestColor colorFromHexString:@"#f00"];
    [self assertColor:color red:255 green:0 blue:0 msg:@"#f00 should be pure red"];
}

// Additional 3-digit forms.
- (void)testThreeDigit_green {
    MTTestColor *color = [MTTestColor colorFromHexString:@"#0f0"];
    [self assertColor:color red:0 green:255 blue:0 msg:@"#0f0 should be pure green"];
}

- (void)testThreeDigit_blue {
    MTTestColor *color = [MTTestColor colorFromHexString:@"#00f"];
    [self assertColor:color red:0 green:0 blue:255 msg:@"#00f should be pure blue"];
}

- (void)testThreeDigit_white {
    MTTestColor *color = [MTTestColor colorFromHexString:@"#fff"];
    [self assertColor:color red:255 green:255 blue:255 msg:@"#fff should be white"];
}

- (void)testThreeDigit_black {
    MTTestColor *color = [MTTestColor colorFromHexString:@"#000"];
    [self assertColor:color red:0 green:0 blue:0 msg:@"#000 should be black"];
}

// 6-digit paths must be unaffected (no regression).
- (void)testSixDigit_red {
    MTTestColor *color = [MTTestColor colorFromHexString:@"#ff0000"];
    [self assertColor:color red:255 green:0 blue:0 msg:@"#ff0000 should be pure red"];
}

- (void)testSixDigit_green {
    MTTestColor *color = [MTTestColor colorFromHexString:@"#00ff00"];
    [self assertColor:color red:0 green:255 blue:0 msg:@"#00ff00 should be pure green"];
}

- (void)testSixDigit_blue {
    MTTestColor *color = [MTTestColor colorFromHexString:@"#0000ff"];
    [self assertColor:color red:0 green:0 blue:255 msg:@"#0000ff should be pure blue"];
}

- (void)testSixDigit_arbitrary {
    // #4a9 shorthand → #44aa99; full form #44aa99 should match.
    MTTestColor *color = [MTTestColor colorFromHexString:@"#44aa99"];
    [self assertColor:color red:0x44 green:0xaa blue:0x99 msg:@"#44aa99 arbitrary 6-digit"];
}

@end
