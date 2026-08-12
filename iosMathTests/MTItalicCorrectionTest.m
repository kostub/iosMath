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
    return (MTCTLineDisplay*) display.subDisplays[0];
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
    MTCTLineDisplay* base = (MTCTLineDisplay*) display.subDisplays[0];
    MTDisplay* script = display.subDisplays[1];
    XCTAssertEqualWithAccuracy(script.position.x - (base.position.x + base.width),
                               0.145 * em, 0.001 * em);
}

// The math-font side of the same helper, unchanged from master.
- (void) testSuperscriptShiftOnAMathFontGlyphIsUnchanged
{
    MTMathListDisplay* display = [self displayForLaTeX:@"V^a"];
    MTCTLineDisplay* base = (MTCTLineDisplay*) display.subDisplays[0];
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

// The trailing kern reaches MTCTLineDisplay.width — the measured CoreText
// property the whole flush story rests on. A lone f is also the end-of-list case.
- (void) testTrailingCorrectionReachesLineWidth
{
    MTCTLineDisplay* line = [self lineForLaTeX:@"f"];
    XCTAssertEqualWithAccuracy(line.width,
                               [self mathAdvanceOf:@"\U0001D453"] + [self mathItalicCorrectionOf:@"\U0001D453"],
                               0.001);
}

// ...and every flush site inherits it through the display's width, with no
// pending-advance state anywhere.
- (void) testTrailingCorrectionSurvivesEveryFlushSite
{
    CGFloat expected = [self mathAdvanceOf:@"\U0001D453"] + [self mathItalicCorrectionOf:@"\U0001D453"];
    for (NSString* latex in @[ @"f\\sqrt{x}", @"f\\sum x", @"f\\,x", @"f\\frac{1}{2}",
                               @"f\\left(x\\right)", @"f\\color{#ff0000}{x}" ]) {
        MTMathListDisplay* display = [self displayForLaTeX:latex];
        MTCTLineDisplay* line = (MTCTLineDisplay*) display.subDisplays[0];
        XCTAssertTrue([line isKindOfClass:[MTCTLineDisplay class]], @"%@", latex);
        XCTAssertEqualWithAccuracy(line.width, expected, 0.001, @"%@", latex);
    }

    // Ordinary -> Radical takes no inter-element space, so the next display
    // starts exactly where the corrected line ends.
    MTMathListDisplay* radical = [self displayForLaTeX:@"f\\sqrt{x}"];
    MTCTLineDisplay* line = (MTCTLineDisplay*) radical.subDisplays[0];
    MTDisplay* next = radical.subDisplays[1];
    XCTAssertEqualWithAccuracy(next.position.x, line.position.x + line.width, 0.001);
}

// The final character is corrected by exactly one path, never both, and a
// subscript still blocks the base from advancing.
- (void) testScriptedAndScriptlessGlyphsAgree
{
    CGFloat f = [self mathItalicCorrectionOf:@"\U0001D453"];
    CGFloat advance = [self mathAdvanceOf:@"\U0001D453"];

    // Scriptless: the correction is in the line width.
    XCTAssertEqualWithAccuracy([self lineForLaTeX:@"f"].width, advance + f, 0.001);

    // Superscript: the correction shifts the script instead, and the base line
    // keeps its bare advance — applied once, not twice.
    MTMathListDisplay* sup = [self displayForLaTeX:@"f^a"];
    MTCTLineDisplay* supBase = (MTCTLineDisplay*) sup.subDisplays[0];
    XCTAssertEqualWithAccuracy(supBase.width, advance, 0.001);
    XCTAssertEqualWithAccuracy(sup.subDisplays[1].position.x - supBase.width, f, 0.001);

    // Subscript: the base does not advance by the correction.
    MTMathListDisplay* sub = [self displayForLaTeX:@"f_a"];
    MTCTLineDisplay* subBase = (MTCTLineDisplay*) sub.subDisplays[0];
    XCTAssertEqualWithAccuracy(subBase.width, advance, 0.001);
    XCTAssertEqualWithAccuracy(sub.subDisplays[1].position.x, subBase.width, 0.001);

    // Both scripts: the superscript carries the correction, the subscript does not.
    MTMathListDisplay* both = [self displayForLaTeX:@"f_a^b"];
    MTCTLineDisplay* bothBase = (MTCTLineDisplay*) both.subDisplays[0];
    MTDisplay* superscript = nil;
    MTDisplay* subscript = nil;
    for (MTDisplay* d in both.subDisplays) {
        if (![d isKindOfClass:[MTMathListDisplay class]]) { continue; }
        MTMathListDisplay* script = (MTMathListDisplay*) d;
        if (script.type == kMTLinePositionSuperscript) { superscript = script; }
        if (script.type == kMTLinePositionSubscript) { subscript = script; }
    }
    XCTAssertEqualWithAccuracy(superscript.position.x - subscript.position.x, f, 0.001);
    XCTAssertEqualWithAccuracy(subscript.position.x, bothBase.width, 0.001);
}

// A fused atom whose last character carries the script: the interior is
// corrected here, the last character by the script path.
- (void) testFusedAtomWithAScriptOnItsLastCharacter
{
    MTMathListDisplay* display = [self displayForLaTeX:@"Vt^2"];
    MTCTLineDisplay* line = (MTCTLineDisplay*) display.subDisplays[0];
    // Vt fuses to one atom; V is interior and corrected, t has no correction.
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0],
                               [self mathItalicCorrectionOf:@"\U0001D449"], 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:line atIndex:2], 0, 0.001);
}

// Digits and capital Greek are routable too, so they are measured in the
// companion. \mathit{7} doubles as a face check: the math font's own correction
// for upright 7 is 0.013 em, so reading the wrong face gives a plausible wrong
// number rather than zero.
- (void) testCompanionDigitsAndCapitalGreek
{
    CGFloat em = self.font.fontSize;
    XCTAssertEqualWithAccuracy([self kernOf:[self lineForLaTeX:@"\\mathit{7}"] atIndex:0],
                               0.114 * em, 0.001 * em);
    XCTAssertEqualWithAccuracy([self kernOf:[self lineForLaTeX:@"\\mathit{\\Pi}"] atIndex:0],
                               0.108 * em, 0.001 * em);

    // No ink past the advance: nothing to clear, no kern, and no floor.
    XCTAssertEqualWithAccuracy([self kernOf:[self lineForLaTeX:@"\\mathit{1}"] atIndex:0], 0, 0.001);
    XCTAssertEqualWithAccuracy([self kernOf:[self lineForLaTeX:@"\\mathit{\\Delta}"] atIndex:0], 0, 0.001);
}

// Latin Modern and New CM both fall through to the bundled companion, so their
// values are ours to pin. The other six resolve to OS faces: assert where the
// kern landed and that it is bounded, not what Apple's outlines measure.
- (void) testCompanionCorrectionAcrossAllBundledFonts
{
    NSArray<NSString*>* bundledCompanion = @[ MTFontNameLatinModern, MTFontNameNewComputerModern ];
    NSArray<NSString*>* names = @[ MTFontNameLatinModern, MTFontNameXITS, MTFontNameTermes,
                                   MTFontNameNewComputerModern, MTFontNamePagella,
                                   MTFontNameSTIXTwo, MTFontNameFiraMath, MTFontNameNotoSansMath ];
    for (NSString* name in names) {
        MTFont* font = [MTFontManager.fontManager fontWithName:name size:20];
        MTMathListDisplay* display = [self displayForLaTeX:@"\\mathit{fVf}" withFont:font];
        XCTAssertEqual(display.subDisplays.count, 1, @"%@", name);
        MTCTLineDisplay* line = (MTCTLineDisplay*) display.subDisplays[0];

        // Trailing-only, whatever the face measures.
        XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0], 0, 0.001, @"%@", name);
        XCTAssertEqualWithAccuracy([self kernOf:line atIndex:1], 0, 0.001, @"%@", name);
        CGFloat trailing = [self kernOf:line atIndex:2];
        XCTAssertGreaterThanOrEqual(trailing, 0, @"%@", name);
        XCTAssertLessThanOrEqual(trailing, 0.4 * font.fontSize, @"%@", name);

        if ([bundledCompanion containsObject:name]) {
            XCTAssertEqualWithAccuracy(trailing, 0.145 * font.fontSize, 0.001 * font.fontSize, @"%@", name);
        }
    }
}

// The math-font correction is a font parameter, so the same assertion runs
// across all eight bundled fonts by reading its own expectation.
- (void) testMathFontCorrectionIsFontParameterised
{
    for (NSString* name in @[ MTFontNameLatinModern, MTFontNameXITS, MTFontNameTermes,
                              MTFontNameNewComputerModern, MTFontNamePagella,
                              MTFontNameSTIXTwo, MTFontNameFiraMath, MTFontNameNotoSansMath ]) {
        MTFont* font = [MTFontManager.fontManager fontWithName:name size:20];
        MTMathListDisplay* display = [self displayForLaTeX:@"fVf" withFont:font];
        MTCTLineDisplay* line = (MTCTLineDisplay*) display.subDisplays[0];
        XCTAssertEqualWithAccuracy([self kernOf:line atIndex:0],
                                   [self mathItalicCorrectionOf:@"\U0001D453" inFont:font], 0.001, @"%@", name);
        XCTAssertEqualWithAccuracy([self kernOf:line atIndex:2],
                                   [self mathItalicCorrectionOf:@"\U0001D449" inFont:font], 0.001, @"%@", name);
        XCTAssertEqualWithAccuracy([self kernOf:line atIndex:4],
                                   [self mathItalicCorrectionOf:@"\U0001D453" inFont:font], 0.001, @"%@", name);
    }
}

// New CM is the one bundled font with GPOS pair kerning on math-italic glyphs.
// The correction must stack on the shaped position, not replace it.
- (void) testCorrectionStacksOnNativePairKerning
{
    MTFont* newcm = [MTFontManager.fontManager fontWithName:MTFontNameNewComputerModern size:20];
    MTMathListDisplay* display = [self displayForLaTeX:@"B." withFont:newcm];
    MTCTLineDisplay* line = (MTCTLineDisplay*) display.subDisplays[0];

    NSMutableAttributedString* unkerned = [line.attributedString mutableCopy];
    [unkerned removeAttribute:(NSString*) kCTKernAttributeName range:NSMakeRange(0, unkerned.length)];
    CTLineRef shaped = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef) unkerned);
    CGFloat shapedWidth = CTLineGetTypographicBounds(shaped, NULL, NULL, NULL);
    CFRelease(shaped);

    CGFloat correction = [self mathItalicCorrectionOf:@"\U0001D435" inFont:newcm];
    XCTAssertGreaterThan(correction, 0);
    // shaped + correction, not rawAdvance + correction.
    XCTAssertEqualWithAccuracy(line.width, shapedWidth + correction, 0.001);
}

// f+1 carries both a correction and a binary-operator space on the f. Each is
// isolated by a control that has only one of them.
- (void) testCorrectionAndInterElementSpaceCompose
{
    CGFloat correctionOnly = [self kernOf:[self lineForLaTeX:@"f1"] atIndex:0];
    CGFloat spaceOnly = [self kernOf:[self lineForLaTeX:@"x+1"] atIndex:0];
    CGFloat both = [self kernOf:[self lineForLaTeX:@"f+1"] atIndex:0];
    XCTAssertGreaterThan(correctionOnly, 0);   // x has no correction, f does
    XCTAssertGreaterThan(spaceOnly, 0);
    XCTAssertEqualWithAccuracy(both, correctionOnly + spaceOnly, 0.001);

    CGFloat relationSpace = [self kernOf:[self lineForLaTeX:@"x="] atIndex:0];
    XCTAssertGreaterThan(relationSpace, 0);
    XCTAssertEqualWithAccuracy([self kernOf:[self lineForLaTeX:@"V="] atIndex:0],
                               [self mathItalicCorrectionOf:@"\U0001D449"] + relationSpace, 0.001);
}

// Nothing is attached where the font reports no correction, so these are
// byte-identical to master.
- (void) testZeroCorrectionGlyphsAreUntouched
{
    for (NSString* latex in @[ @"\\mathrm{abc}", @"123" ]) {
        MTCTLineDisplay* line = [self lineForLaTeX:latex];
        [line.attributedString enumerateAttribute:(NSString*) kCTKernAttributeName
                                          inRange:NSMakeRange(0, line.attributedString.length)
                                          options:0
                                       usingBlock:^(NSNumber* kern, NSRange range, BOOL* stop) {
            XCTAssertNil(kern, @"%@ has a kern at %@", latex, NSStringFromRange(range));
        }];
    }
}

// \textit{fVf} renders through MTTextDisplay, which the correction path never
// sees. The property is structural, so one smoke case is enough.
- (void) testTextPathTakesNoCorrection
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\textit{fVf}"];
    XCTAssertEqual(display.subDisplays.count, 1);
    XCTAssertFalse([display.subDisplays[0] isKindOfClass:[MTCTLineDisplay class]]);
}

// Two properties of \math* vs \text* that are already correct and must stay
// that way: math mode discards an interword space, and \text shrinks in scripts.
- (void) testMathAndTextModeDifferencesAreUnchanged
{
    MTCTLineDisplay* math = [self lineForLaTeX:@"\\mathrm{a b}"];
    XCTAssertEqualObjects(math.attributedString.string, @"ab");

    MTMathListDisplay* text = [self displayForLaTeX:@"\\text{a b}"];
    MTTextDisplay* textDisplay = (MTTextDisplay*) text.subDisplays[0];
    XCTAssertEqualObjects(textDisplay.text, @"a b");

    MTMathListDisplay* scripted = [self displayForLaTeX:@"x^{\\text{ab}}"];
    MTMathListDisplay* superscript = (MTMathListDisplay*) scripted.subDisplays[1];
    MTTextDisplay* scriptedText = (MTTextDisplay*) superscript.subDisplays[0];
    XCTAssertLessThan(scriptedText.ascent, textDisplay.ascent);
}

@end
