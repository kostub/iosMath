//
//  MTFontManagerTest.m
//  iosMath
//
//  Tests for MTFontManager.fontWithName:size: error handling.
//  FUN-2: fontWithName: should return nil (not crash) for unknown font names.
//

#import <XCTest/XCTest.h>
#import <CoreText/CoreText.h>
#import "MTFontManager.h"
#import "MTFont.h"
#import "MTFont+Internal.h"

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

// LLD §7: every row of the companion table must serve a Latin letter, a digit,
// and a Greek capital — a fallback face cannot silently miss a glyph.
- (void)testMathitCompanionCoverageAndSize
{
    NSArray<NSString*>* names = @[ MTFontNameLatinModern, MTFontNameXITS, MTFontNameTermes,
                                   MTFontNameNewComputerModern, MTFontNamePagella,
                                   MTFontNameSTIXTwo, MTFontNameFiraMath, MTFontNameNotoSansMath ];
    for (NSString* name in names) {
        MTFont* font = [MTFontManager.fontManager fontWithName:name size:20];
        CTFontRef companion = font.mathitCTFont;
        XCTAssertTrue(companion != NULL, @"%@", name);
        XCTAssertEqualWithAccuracy(CTFontGetSize(companion), 20.0, 0.001, @"%@", name);
        unichar chars[3] = { 'f', '1', 0x0393 };
        CGGlyph glyphs[3];
        // Returns false if any character has no glyph in the font.
        XCTAssertTrue(CTFontGetGlyphsForCharacters(companion, chars, glyphs, 3), @"%@", name);
    }
}

- (void)testMathitCompanionIsBundledFaceForLatinModernFamily
{
    for (NSString* name in @[ MTFontNameLatinModern, MTFontNameNewComputerModern ]) {
        MTFont* font = [MTFontManager.fontManager fontWithName:name size:20];
        NSString* ps = CFBridgingRelease(CTFontCopyPostScriptName(font.mathitCTFont));
        XCTAssertEqualObjects(ps, @"LMRoman10-Italic", @"%@", name);
    }
}

- (void)testCopyFontWithSizePreservesMathitCompanion
{
    MTFont* font = [MTFontManager.fontManager fontWithName:MTFontNameXITS size:20];
    MTFont* copy = [font copyFontWithSize:14];
    XCTAssertTrue(copy.mathitCTFont != NULL);
    XCTAssertEqualWithAccuracy(CTFontGetSize(copy.mathitCTFont), 14.0, 0.001);
    // Resizing must keep the same face, not re-resolve it (LLD §6 re-entrancy).
    NSString* original = CFBridgingRelease(CTFontCopyPostScriptName(font.mathitCTFont));
    NSString* copied = CFBridgingRelease(CTFontCopyPostScriptName(copy.mathitCTFont));
    XCTAssertEqualObjects(original, copied);

    // Size 0 means "12pt" to the primary font's constructor but "keep the
    // current size" to the companion's, so the two can only stay in step if
    // the companion is built from the primary's resolved size.
    MTFont* defaulted = [font copyFontWithSize:0];
    XCTAssertEqualWithAccuracy(CTFontGetSize(defaulted.mathitCTFont),
                               CTFontGetSize(defaulted.ctFont), 0.001);
}

// CTFontCreateWithName substitutes silently rather than failing (LLD §2.9);
// this proves the create -> compare -> reject sequence actually rejects.
- (void)testVerifiedFontCreationRejectsSubstitution
{
    // Without this the test would also pass if CTFontCreateWithName started
    // returning NULL, which would mean the compare-and-reject never ran.
    CTFontRef raw = CTFontCreateWithName(CFSTR("MTNoSuchFace-Italic"), 20, NULL);
    XCTAssertTrue(raw != NULL, @"CoreText no longer substitutes for a missing face");
    if (raw) { CFRelease(raw); }

    CTFontRef font = MTCreateVerifiedFontWithPostScriptName(@"MTNoSuchFace-Italic", 20);
    XCTAssertTrue(font == NULL);
    if (font) { CFRelease(font); }
}

@end
