//
//  MTFontManagerTest.m
//  iosMath
//
//  Tests for MTFontManager.fontWithName:size: error handling.
//  FUN-2: fontWithName: should return nil (not crash) for unknown font names.
//

#import <XCTest/XCTest.h>
#import "MTFontManager.h"
#import "MTFont.h"

@interface MTFontManagerTest : XCTestCase
@end

@implementation MTFontManagerTest

// Test 1: Unknown font returns nil, no crash.
// Before the fix this crashes via CFRelease(NULL); after, it returns nil.
- (void)testUnknownFontNameReturnsNil
{
    MTFont *font = [MTFontManager.fontManager fontWithName:@"does-not-exist" size:20];
    XCTAssertNil(font, @"Unknown font name should return nil, not crash");
}

// Test 2: Unknown font does not poison the cache.
// After a nil return for an unknown name, a known font must still load correctly.
- (void)testUnknownFontNameDoesNotPoisonCache
{
    // First: unknown name -> nil
    MTFont *bad = [MTFontManager.fontManager fontWithName:@"no-such-font" size:18];
    XCTAssertNil(bad, @"Unknown font should return nil");

    // Then: known font must still load
    MTFont *good = [MTFontManager.fontManager fontWithName:MTFontNameLatinModern size:18];
    XCTAssertNotNil(good, @"Known font should load after an unknown-name miss");
    XCTAssertEqualWithAccuracy(good.fontSize, 18.0, 0.001,
                               @"Known font should have the requested size");
}

// Test 3: A nil font name returns nil instead of throwing.
// Without the guard, self.nameToFontMap[name] raises NSInvalidArgumentException
// (NSDictionary keys cannot be nil).
- (void)testNilFontNameReturnsNil
{
    NSString *nilName = nil;
    MTFont *font = [MTFontManager.fontManager fontWithName:nilName size:20];
    XCTAssertNil(font, @"Nil font name should return nil, not throw");
}

// Test 4: All 8 declared font constants load successfully (regression guard).
- (void)testAllDeclaredFontConstantsLoadNonNil
{
    NSArray<NSString *> *fontNames = @[
        MTFontNameLatinModern,
        MTFontNameXITS,
        MTFontNameTermes,
        MTFontNameNewComputerModern,
        MTFontNamePagella,
        MTFontNameSTIXTwo,
        MTFontNameFiraMath,
        MTFontNameNotoSansMath,
    ];
    for (NSString *name in fontNames) {
        MTFont *font = [MTFontManager.fontManager fontWithName:name size:20];
        XCTAssertNotNil(font, @"Bundled font '%@' should load non-nil", name);
        XCTAssertEqualWithAccuracy(font.fontSize, 20.0, 0.001,
                                   @"Font '%@' should have the requested size", name);
    }
}

// Test 5: Size-variant path still works.
// Load a known font at a non-default size; exercises the copyFontWithSize: branch
// with the nil-guard in place.
- (void)testSizeVariantPathReturnsCorrectSize
{
    CGFloat requestedSize = 36.0;
    MTFont *font = [MTFontManager.fontManager fontWithName:MTFontNameLatinModern
                                                      size:requestedSize];
    XCTAssertNotNil(font, @"Font should load at a non-default size");
    XCTAssertEqualWithAccuracy(font.fontSize, requestedSize, 0.001,
                               @"Returned font should have the requested size");
}

@end
