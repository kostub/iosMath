//
//  MTFontMathTable.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTFontMathTable.h"
#import "MTFont.h"
#import "MTFont+Internal.h"


@interface MTGlyphPart ()

@property (nonatomic) CGGlyph glyph;
@property (nonatomic) CGFloat fullAdvance;
@property (nonatomic) CGFloat startConnectorLength;
@property (nonatomic) CGFloat endConnectorLength;
@property (nonatomic) BOOL isExtender;

@end

@implementation MTGlyphPart

@end

@interface MTFontMathTable ()

// The font for this math table.
@property (nonatomic, readonly, weak) MTFont* font;

@end

@implementation MTFontMathTable {
    NSUInteger _unitsPerEm;
    CGFloat _fontSize;
    NSDictionary* _Nonnull _mathTable;
}

- (instancetype)initWithFont:(nonnull MTFont*) font mathTable:(nonnull NSDictionary*) mathTable
{
    self = [super init];
    if (self) {
        NSParameterAssert(font);
        NSParameterAssert(font.ctFont);
        _font = font;
        // do domething with font
        _unitsPerEm = CTFontGetUnitsPerEm(font.ctFont);
        _fontSize = font.fontSize;
        _mathTable = mathTable;
        if (![@"1.3" isEqualToString:_mathTable[@"version"]]) {
            // Invalid version
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"Invalid version of math table plist: %@", _mathTable[@"version"]]
                                         userInfo:nil];
        }
    }
    return self;
}

- (CGFloat) fontUnitsToPt:(int) fontUnits
{
    return fontUnits * _fontSize / _unitsPerEm;
}

- (CGFloat)muUnit
{
    return _fontSize/18;
}

static NSString* const kConstants = @"constants";

- (CGFloat) constantFromTable:(NSString*) constName
{
    NSDictionary* consts = (NSDictionary*) _mathTable[kConstants];
    NSNumber* val = (NSNumber*)consts[constName];
    return [self fontUnitsToPt:val.intValue];
}

- (CGFloat) percentFromTable:(NSString*) percentName
{
    NSDictionary* consts = (NSDictionary*) _mathTable[kConstants];
    NSNumber* val = (NSNumber*)consts[percentName];
    return val.floatValue / 100;
}

#pragma mark - Fractions
- (CGFloat)fractionNumeratorDisplayStyleShiftUp
{
    return [self constantFromTable:@"FractionNumeratorDisplayStyleShiftUp"];
}

- (CGFloat)fractionNumeratorShiftUp
{
    return [self constantFromTable:@"FractionNumeratorShiftUp"];
}

- (CGFloat)fractionDenominatorDisplayStyleShiftDown
{
    return [self constantFromTable:@"FractionDenominatorDisplayStyleShiftDown"];
}

- (CGFloat)fractionDenominatorShiftDown
{
    return [self constantFromTable:@"FractionDenominatorShiftDown"];
}

- (CGFloat)fractionNumeratorDisplayStyleGapMin
{
    return [self constantFromTable:@"FractionNumDisplayStyleGapMin"];
}

- (CGFloat)fractionNumeratorGapMin
{
    return [self constantFromTable:@"FractionNumeratorGapMin"];
}

- (CGFloat)fractionDenominatorDisplayStyleGapMin
{
    return [self constantFromTable:@"FractionDenomDisplayStyleGapMin"];
}

- (CGFloat)fractionDenominatorGapMin
{
    return [self constantFromTable:@"FractionDenominatorGapMin"];
}

- (CGFloat)fractionRuleThickness
{
    return [self constantFromTable:@"FractionRuleThickness"];
}

- (CGFloat) skewedFractionHorizontalGap
{
    return [self constantFromTable:@"SkewedFractionHorizontalGap"];
}

- (CGFloat) skewedFractionVerticalGap
{
    return [self constantFromTable:@"SkewedFractionVerticalGap"];
}

#pragma mark Non-standard

// FractionDelimiterSize and FractionDelimiterDisplayStyleSize are not constants
// specified in the OpenType Math specification. Rather these are proposed LuaTeX extensions
// for the TeX parameters \sigma_20 (delim1) and \sigma_21 (delim2). Since these do not
// exist in the fonts that we have, we use the same approach as LuaTeX and use the fontSize
// to determine these values. The constants used are the same as LuaTeX and KaTeX and match the
// metrics values of the original TeX fonts.
// Note: An alternative approach is to use DelimitedSubFormulaMinHeight for \sigma21 and use a factor
// of 2 to get \sigma 20 as proposed in Vieth paper.
// The XeTeX implementation sets \sigma21 = fontSize and \sigma20 = DelimitedSubFormulaMinHeight which
// will produce smaller delimiters.
// Of all the approaches we've implemented LuaTeX's approach since it mimics LaTeX most accurately.
- (CGFloat) fractionDelimiterSize
{
    return 1.01 * _fontSize;
}

- (CGFloat) fractionDelimiterDisplayStyleSize
{
    // Modified constant from 2.4 to 2.39, it matches KaTeX and looks better.
    return 2.39 * _fontSize;
}

#pragma mark - Sub/Superscripts

- (CGFloat)superscriptShiftUp
{
    return [self constantFromTable:@"SuperscriptShiftUp"];
}

- (CGFloat)superscriptShiftUpCramped
{
    return [self constantFromTable:@"SuperscriptShiftUpCramped"];
}

- (CGFloat)subscriptShiftDown
{
    return [self constantFromTable:@"SubscriptShiftDown"];
}

- (CGFloat)superscriptBaselineDropMax
{
    return [self constantFromTable:@"SuperscriptBaselineDropMax"];
}

- (CGFloat)subscriptBaselineDropMin
{
    return [self constantFromTable:@"SubscriptBaselineDropMin"];
}

- (CGFloat)superscriptBottomMin
{
    return [self constantFromTable:@"SuperscriptBottomMin"];
}

- (CGFloat)subscriptTopMax
{
    return [self constantFromTable:@"SubscriptTopMax"];
}

- (CGFloat)subSuperscriptGapMin
{
    return [self constantFromTable:@"SubSuperscriptGapMin"];
}

- (CGFloat)superscriptBottomMaxWithSubscript
{
    return [self constantFromTable:@"SuperscriptBottomMaxWithSubscript"];
}

- (CGFloat) spaceAfterScript
{
    return [self constantFromTable:@"SpaceAfterScript"];
}

#pragma mark - Radicals

- (CGFloat)radicalRuleThickness
{
    return [self constantFromTable:@"RadicalRuleThickness"];
}

- (CGFloat)radicalExtraAscender
{
    return [self constantFromTable:@"RadicalExtraAscender"];
}

- (CGFloat)radicalVerticalGap
{
    return [self constantFromTable:@"RadicalVerticalGap"];
}

- (CGFloat)radicalDisplayStyleVerticalGap
{
    return [self constantFromTable:@"RadicalDisplayStyleVerticalGap"];
}

- (CGFloat)radicalKernBeforeDegree
{
    return [self constantFromTable:@"RadicalKernBeforeDegree"];
}

- (CGFloat)radicalKernAfterDegree
{
    return [self constantFromTable:@"RadicalKernAfterDegree"];
}

- (CGFloat)radicalDegreeBottomRaisePercent
{
    return [self percentFromTable:@"RadicalDegreeBottomRaisePercent"];
}

#pragma mark - Limits

- (CGFloat)upperLimitGapMin
{
    return [self constantFromTable:@"UpperLimitGapMin"];
}

- (CGFloat)upperLimitBaselineRiseMin
{
    return [self constantFromTable:@"UpperLimitBaselineRiseMin"];
}

- (CGFloat)lowerLimitGapMin
{
    return [self constantFromTable:@"LowerLimitGapMin"];
}

- (CGFloat)lowerLimitBaselineDropMin
{
    return [self constantFromTable:@"LowerLimitBaselineDropMin"];
}

- (CGFloat)limitExtraAscenderDescender
{
    // not present in OpenType fonts.
    return 0;
}

#pragma mark - Constants

-(CGFloat)axisHeight
{
    return [self constantFromTable:@"AxisHeight"];
}

- (CGFloat)scriptScaleDown
{
    return [self percentFromTable:@"ScriptPercentScaleDown"];
}

- (CGFloat)scriptScriptScaleDown
{
    return [self percentFromTable:@"ScriptScriptPercentScaleDown"];
}

- (CGFloat) mathLeading
{
    return [self constantFromTable:@"MathLeading"];
}

- (CGFloat) delimitedSubFormulaMinHeight
{
    return [self constantFromTable:@"DelimitedSubFormulaMinHeight"];
}

#pragma mark - Accents

- (CGFloat) accentBaseHeight
{
    return [self constantFromTable:@"AccentBaseHeight"];
}

- (CGFloat) flattenedAccentBaseHeight
{
    return [self constantFromTable:@"FlattenedAccentBaseHeight"];
}

#pragma mark - Large Operators

- (CGFloat) displayOperatorMinHeight
{
    return [self constantFromTable:@"DisplayOperatorMinHeight"];
}

#pragma mark - Over and Underbar

- (CGFloat) overbarExtraAscender
{
    return [self constantFromTable:@"OverbarExtraAscender"];
}

- (CGFloat) overbarRuleThickness
{
    return [self constantFromTable:@"OverbarRuleThickness"];
}

- (CGFloat) overbarVerticalGap
{
    return [self constantFromTable:@"OverbarVerticalGap"];
}

- (CGFloat) underbarExtraDescender
{
    return [self constantFromTable:@"UnderbarExtraDescender"];
}

- (CGFloat) underbarRuleThickness
{
    return [self constantFromTable:@"UnderbarRuleThickness"];
}

- (CGFloat) underbarVerticalGap
{
    return [self constantFromTable:@"UnderbarVerticalGap"];
}

#pragma mark - Stacks

-(CGFloat) stackBottomDisplayStyleShiftDown {
    return [self constantFromTable:@"StackBottomDisplayStyleShiftDown"];
}

- (CGFloat) stackBottomShiftDown {
    return [self constantFromTable:@"StackBottomShiftDown"];
}
            
- (CGFloat) stackDisplayStyleGapMin {
    return [self constantFromTable:@"StackDisplayStyleGapMin"];
}
            
- (CGFloat) stackGapMin {
    return [self constantFromTable:@"StackGapMin"];
}

- (CGFloat) stackTopDisplayStyleShiftUp {
    return [self constantFromTable:@"StackTopDisplayStyleShiftUp"];
}

- (CGFloat) stackTopShiftUp {
    return [self constantFromTable:@"StackTopShiftUp"];
}

- (CGFloat) stretchStackBottomShiftDown {
    return [self constantFromTable:@"StretchStackBottomShiftDown"];
}

- (CGFloat) stretchStackGapAboveMin {
    return [self constantFromTable:@"StretchStackGapAboveMin"];
}

- (CGFloat) stretchStackGapBelowMin {
    return [self constantFromTable:@"StretchStackGapBelowMin"];
}

- (CGFloat) stretchStackTopShiftUp {
    return [self constantFromTable:@"StretchStackTopShiftUp"];
}

#pragma mark - Variants

static NSString* const kVertVariants = @"v_variants";
static NSString* const kHorizVariants = @"h_variants";

- (NSArray<NSNumber*>*) getVerticalVariantsForGlyph:(CGGlyph) glyph
{
    NSDictionary* variants = (NSDictionary*) _mathTable[kVertVariants];
    return [self getVariantsForGlyph:glyph inDictionary:variants];
}

- (NSArray<NSNumber*>*) getHorizontalVariantsForGlyph:(CGGlyph) glyph
{
    NSDictionary* variants = (NSDictionary*) _mathTable[kHorizVariants];
    return [self getVariantsForGlyph:glyph inDictionary:variants];
}

- (NSArray<NSNumber*>*) getVariantsForGlyph:(CGGlyph) glyph inDictionary:(NSDictionary*) variants
{
    NSString* glyphName = [self.font getGlyphName:glyph];
    NSArray* variantGlyphs = (NSArray*) variants[glyphName];
    NSMutableArray* glyphArray = [NSMutableArray arrayWithCapacity:variantGlyphs.count];
    if (!variantGlyphs) {
        // There are no extra variants, so just add the current glyph to it.
        CGGlyph glyph = [self.font getGlyphWithName:glyphName];
        [glyphArray addObject:@(glyph)];
        return glyphArray;
    }
    for (NSString* glyphVariantName in variantGlyphs) {
        CGGlyph variantGlyph = [self.font getGlyphWithName:glyphVariantName];
        [glyphArray addObject:@(variantGlyph)];
    }
    return glyphArray;
}

- (CGGlyph) getLargerGlyph:(CGGlyph) glyph
{
    NSDictionary* variants = (NSDictionary*) _mathTable[kVertVariants];
    NSString* glyphName = [self.font getGlyphName:glyph];
    NSArray* variantGlyphs = (NSArray*) variants[glyphName];
    if (!variantGlyphs) {
        // There are no extra variants, so just returnt the current glyph.
        return glyph;
    }
    // Find the first variant with a different name.
    for (NSString* glyphVariantName in variantGlyphs) {
        if (![glyphVariantName isEqualToString:glyphName]) {
            CGGlyph variantGlyph = [self.font getGlyphWithName:glyphVariantName];
            return variantGlyph;
        }
    }
    // We did not find any variants of this glyph so return it.
    return glyph;
}

#pragma mark - Italic Correction

static NSString* const kItalic = @"italic";

- (CGFloat)getItalicCorrection:(CGGlyph)glyph
{
    NSDictionary* italics = (NSDictionary*) _mathTable[kItalic];
    NSString* glyphName = [self.font getGlyphName:glyph];
    NSNumber* val = (NSNumber*) italics[glyphName];
    // if val is nil, this returns 0.
    return [self fontUnitsToPt:val.intValue];
}

#pragma mark - Top Accent Adjustment

static NSString* const kAccents = @"accents";
- (CGFloat) getTopAccentAdjustment:(CGGlyph) glyph
{
    NSDictionary* accents = (NSDictionary*) _mathTable[kAccents];
    NSString* glyphName = [self.font getGlyphName:glyph];
    NSNumber* val = (NSNumber*) accents[glyphName];
    if (val) {
        return [self fontUnitsToPt:val.intValue];
    } else {
        // If no top accent is defined then it is the center of the advance width.
        CGSize advances;
        CTFontGetAdvancesForGlyphs(self.font.ctFont, kCTFontHorizontalOrientation, &glyph, &advances, 1);
        return advances.width/2;
    }
}

#pragma mark - Glyph Assembly

- (CGFloat)minConnectorOverlap
{
    return [self constantFromTable:@"MinConnectorOverlap"];
}

static NSString* const kVertAssembly = @"v_assembly";
static NSString* const kAssemblyParts = @"parts";

- (NSArray<MTGlyphPart *> *)getVerticalGlyphAssemblyForGlyph:(CGGlyph)glyph
{
    NSDictionary* assemblyTable = (NSDictionary*) _mathTable[kVertAssembly];
    NSString* glyphName = [self.font getGlyphName:glyph];
    NSDictionary* assemblyInfo = (NSDictionary*) assemblyTable[glyphName];
    if (!assemblyInfo) {
        // No vertical assembly defined for glyph
        return nil;
    }
    NSArray* parts = (NSArray*) assemblyInfo[kAssemblyParts];
    if (!parts) {
        // parts should always have been defined, but if it isn't return nil
        return nil;
    }
    NSMutableArray<MTGlyphPart*>* rv = [NSMutableArray array];
    for (NSDictionary* partInfo in parts) {
        MTGlyphPart* part = [[MTGlyphPart alloc] init];
        NSNumber* adv = (NSNumber*) partInfo[@"advance"];
        part.fullAdvance = [self fontUnitsToPt:adv.intValue];
        NSNumber* end = (NSNumber*) partInfo[@"endConnector"];
        part.endConnectorLength = [self fontUnitsToPt:end.intValue];
        NSNumber* start = (NSNumber*) partInfo[@"startConnector"];
        part.startConnectorLength = [self fontUnitsToPt:start.intValue];
        NSNumber* ext = (NSNumber*) partInfo[@"extender"];
        part.isExtender = ext.boolValue;
        NSString* glyphName = (NSString*) partInfo[@"glyph"];
        part.glyph = [self.font getGlyphWithName:glyphName];
        
        [rv addObject:part];
    }
    return rv;
}

@end
