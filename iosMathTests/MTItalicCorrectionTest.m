//
//  MTItalicCorrectionTest.m
//  iosMath
//

#import <XCTest/XCTest.h>
#import <CoreText/CoreText.h>

#import "MTTypesetter.h"
#import "MTFont+Internal.h"
#import "MTFontMathTable.h"
#import "MTFontManager.h"
#import "MTMathListDisplay.h"
#import "MTMathListDisplayInternal.h"
#import "MTMathListBuilder.h"

@interface MTItalicCorrectionTest : XCTestCase

@property (nonatomic) MTFont* font;

@end

@implementation MTItalicCorrectionTest

- (void) setUp
{
    [super setUp];
    self.font = [MTFontManager.fontManager fontWithName:MTFontNameLatinModern size:20];
}

- (MTMathListDisplay*) displayForLaTeX:(NSString*) latex withFont:(MTFont*) font
{
    MTMathList* list = [MTMathListBuilder buildFromString:latex];
    XCTAssertNotNil(list, @"%@", latex);
    return [MTTypesetter createLineForMathList:list font:font style:kMTLineStyleDisplay];
}

- (MTMathListDisplay*) displayForLaTeX:(NSString*) latex
{
    return [self displayForLaTeX:latex withFont:self.font];
}

// The one CTLine of an expression expected to typeset as a single run.
- (MTCTLineDisplay*) lineForLaTeX:(NSString*) latex
{
    MTMathListDisplay* display = [self displayForLaTeX:latex];
    XCTAssertEqual(display.subDisplays.count, 1, @"%@", latex);
    XCTAssertTrue([display.subDisplays[0] isKindOfClass:[MTCTLineDisplay class]], @"%@", latex);
    return display.subDisplays[0];
}

// The kern attached to the character at `index`, 0 when there is none.
- (CGFloat) kernOf:(MTCTLineDisplay*) line atIndex:(NSUInteger) index
{
    NSNumber* kern = [line.attributedString attribute:(NSString*) kCTKernAttributeName
                                              atIndex:index
                                       effectiveRange:NULL];
    return kern.floatValue;
}

// The math font's own correction for the first character of `str`, read the
// way the typesetter reads it, so the expectation is font-parameterised.
- (CGFloat) mathItalicCorrectionOf:(NSString*) str inFont:(MTFont*) font
{
    unichar chars[str.length];
    [str getCharacters:chars range:NSMakeRange(0, str.length)];
    CGGlyph glyphs[str.length];
    XCTAssertTrue(CTFontGetGlyphsForCharacters(font.ctFont, chars, glyphs, str.length), @"%@", str);
    return [font.mathTable getItalicCorrection:glyphs[0]];
}

- (CGFloat) mathItalicCorrectionOf:(NSString*) str
{
    return [self mathItalicCorrectionOf:str inFont:self.font];
}

- (CGFloat) mathAdvanceOf:(NSString*) str
{
    unichar chars[str.length];
    [str getCharacters:chars range:NSMakeRange(0, str.length)];
    CGGlyph glyphs[str.length];
    XCTAssertTrue(CTFontGetGlyphsForCharacters(self.font.ctFont, chars, glyphs, str.length), @"%@", str);
    CGSize advance;
    CTFontGetAdvancesForGlyphs(self.font.ctFont, kCTFontOrientationDefault, glyphs, &advance, 1);
    return advance.width;
}

// master read the MATH table's upright f (0.079 em) while the companion drew
// the glyph, leaving 0.066 em of its ink under the superscript.
- (void) testSuperscriptShiftReadsTheFaceThatDrewTheGlyph
{
    CGFloat em = self.font.fontSize;
    MTMathListDisplay* display = [self displayForLaTeX:@"\\mathit{f}^2"];
    XCTAssertEqual(display.subDisplays.count, 2);
    MTCTLineDisplay* base = display.subDisplays[0];
    MTDisplay* script = display.subDisplays[1];
    XCTAssertEqualWithAccuracy(script.position.x - (base.position.x + base.width),
                               0.145 * em, 0.001 * em);
}

// The math-font side of the same helper, unchanged from master.
- (void) testSuperscriptShiftOnAMathFontGlyphIsUnchanged
{
    MTMathListDisplay* display = [self displayForLaTeX:@"V^a"];
    MTCTLineDisplay* base = display.subDisplays[0];
    MTDisplay* script = display.subDisplays[1];
    XCTAssertEqualWithAccuracy(script.position.x - (base.position.x + base.width),
                               [self mathItalicCorrectionOf:@"\U0001D449"], 0.001);
}

@end
