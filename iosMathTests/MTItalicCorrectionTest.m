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

// Default style is cmmi10 (SPACE = 0), so every character of a fused run is
// corrected, interior included.
- (void) testDefaultStyleCorrectsEveryCharacter
{
    MTCTLineDisplay* line = [self lineForLaTeX:@"fVf"];
    CGFloat f = [self mathItalicCorrectionOf:@"\U0001D453"];
    CGFloat V = [self mathItalicCorrectionOf:@"\U0001D449"];
    XCTAssertGreaterThan(f, 0);
    XCTAssertGreaterThan(V, 0);
    // fVf fuses to one atom of three surrogate pairs.
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0], f, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:2], V, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:4], f, 0.001);
}

// A run whose last glyph has no correction still corrects the interior.
- (void) testDefaultStyleInteriorCorrectionWithZeroTrailing
{
    MTCTLineDisplay* line = [self lineForLaTeX:@"Vx"];
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0],
                               [self mathItalicCorrectionOf:@"\U0001D449"], 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:2], 0, 0.001);
}

// Text-font styles keep only the trailing correction. \mathrm is cmr10 and
// \mathbf is cmbx10, both SPACE != 0.
- (void) testTextFontStylesAreTrailingOnly
{
    MTCTLineDisplay* roman = [self lineForLaTeX:@"\\mathrm{fVf}"];
    XCTAssertEqualWithAccuracy([self kernOf:roman atIndex:0], 0, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:roman atIndex:1], 0, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:roman atIndex:2],
                               [self mathItalicCorrectionOf:@"f"], 0.001);

    MTCTLineDisplay* bold = [self lineForLaTeX:@"\\mathbf{fVf}"];
    XCTAssertEqualWithAccuracy([self kernOf:bold atIndex:0], 0, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:bold atIndex:2], 0, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:bold atIndex:4],
                               [self mathItalicCorrectionOf:@"\U0001D41F"], 0.001);
}

// The two non-default styles that sit on a SPACE = 0 TFM. These fail if the
// gate is ever keyed on "style != default", or if a default: branch swallows
// kMTFontStyleBoldItalic. \mathcal maps lowercase onto the default math-italic
// code points, so \mathcal{ff} and \mathnormal{ff} must agree exactly.
- (void) testMathFontStylesCorrectTheInterior
{
    CGFloat mathItalicF = [self mathItalicCorrectionOf:@"\U0001D453"];
    for (NSString* latex in @[ @"\\mathcal{ff}", @"\\mathnormal{ff}" ]) {
        MTCTLineDisplay* line = [self lineForLaTeX:latex];
        XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0], mathItalicF, 0.001, @"%@", latex);
        XCTAssertEqualWithAccuracy([self kernOf:line atIndex:2], mathItalicF, 0.001, @"%@", latex);
    }

    MTCTLineDisplay* bm = [self lineForLaTeX:@"\\bm{ff}"];
    CGFloat boldItalicF = [self mathItalicCorrectionOf:@"\U0001D487"];
    XCTAssertGreaterThan(boldItalicF, 0);
    XCTAssertEqualWithAccuracy([self kernOf:bm atIndex:0], boldItalicF, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:bm atIndex:2], boldItalicF, 0.001);
}

// A style change ends a run, so the correction survives on the left glyph even
// for a suppressed style — pdfTeX's $V\mathrm{l}$ -> V ·2.22223· l. Fusion
// never merges across styles, so this proves the gate is per-atom.
- (void) testCorrectionAppliesAtAStyleSeam
{
    MTCTLineDisplay* seam = [self lineForLaTeX:@"V\\mathrm{l}"];
    XCTAssertEqualWithAccuracy([self kernOf:seam atIndex:0],
                               [self mathItalicCorrectionOf:@"\U0001D449"], 0.001);

    MTCTLineDisplay* suppressed = [self lineForLaTeX:@"\\mathrm{a}\\mathbf{b}"];
    XCTAssertEqualWithAccuracy([self kernOf:suppressed atIndex:0],
                               [self mathItalicCorrectionOf:@"a"], 0.001);

    MTCTLineDisplay* unGated = [self lineForLaTeX:@"\\mathnormal{f}\\mathrm{x}"];
    XCTAssertEqualWithAccuracy([self kernOf:unGated atIndex:0],
                               [self mathItalicCorrectionOf:@"\U0001D453"], 0.001);
}

// A cross-atom boundary inside one line: the Close atom appends after the
// corrected V.
- (void) testCorrectionAppliesBeforeAClosingDelimiter
{
    MTCTLineDisplay* line = [self lineForLaTeX:@"V]"];
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0],
                               [self mathItalicCorrectionOf:@"\U0001D449"], 0.001);
}

// Companion glyphs are cmti10 (SPACE != 0), so the interior is suppressed and
// only the last f carries the measured overhang. Asserting kern placement
// rather than run width distinguishes "suppressed interior" from "a smaller
// correction everywhere".
- (void) testCompanionRunIsTrailingOnly
{
    CGFloat em = self.font.fontSize;
    MTCTLineDisplay* line = [self lineForLaTeX:@"\\mathit{fVf}"];
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0], 0, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:1], 0, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:2], 0.145 * em, 0.001 * em);
}

// The face seam inside one nucleus: f is drawn by the companion, alpha by the
// math font, so the run ends at f and its correction is applied. The only case
// where an interior companion glyph is corrected, and the only one that fails
// if the seam check is dropped.
- (void) testCorrectionAppliesAtAFaceSeamInsideOneNucleus
{
    CGFloat em = self.font.fontSize;
    MTCTLineDisplay* line = [self lineForLaTeX:@"\\mathit{f\\alpha}"];
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0], 0.145 * em, 0.001 * em);
}

// Neither beta nor gamma is routable, so both stay in the math font and the
// interior is corrected. This is the only test that pins kMTFontStyleItalic in
// the gate's NO branch. Beta, not alpha: alpha has no italic entry in Latin
// Modern, so an alpha-first case would pass whichever branch the style took.
- (void) testMathitInteriorIsCorrectedInTheMathFont
{
    MTCTLineDisplay* line = [self lineForLaTeX:@"\\mathit{\\beta\\gamma}"];
    CGFloat beta = [self mathItalicCorrectionOf:@"\U0001D6FD"];
    XCTAssertGreaterThan(beta, 0);
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0], beta, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:2],
                               [self mathItalicCorrectionOf:@"\U0001D6FE"], 0.001);
}

@end
