//
//  MTFontMetrics.m
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
    NSDictionary* consts = (NSDictionary*) [_mathTable objectForKey:kConstants];
    NSNumber* val = (NSNumber*)[consts objectForKey:constName];
    return [self fontUnitsToPt:[val intValue]];
}

- (CGFloat) percentFromTable:(NSString*) percentName
{
    NSDictionary* consts = (NSDictionary*) [_mathTable objectForKey:kConstants];
    NSNumber* val = (NSNumber*)[consts objectForKey:percentName];
    return [val floatValue] / 100;
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


#pragma mark - Variants

static NSString* const kVariants = @"variants";

- (CFArrayRef) copyVerticalVariantsForGlyphWithName:(NSString*) glyphName
{
    NSParameterAssert(glyphName);
    NSDictionary* variants = (NSDictionary*) [_mathTable objectForKey:kVariants];
    CFMutableArrayRef glyphArray = CFArrayCreateMutable(NULL, 0, NULL);
    NSArray* variantGlyphs = (NSArray*) [variants objectForKey:glyphName];
    if (!variantGlyphs) {
        // There are no extra variants, so just add the current glyph to it.
        CGGlyph glyph = [self.font getGlyphWithName:glyphName];
        CFArrayAppendValue(glyphArray, (void*)(uintptr_t)glyph);
        return glyphArray;
    }
    for (NSString* glyphVariantName in variantGlyphs) {
        CGGlyph variantGlyph = [self.font getGlyphWithName:glyphVariantName];
        CFArrayAppendValue(glyphArray, (void*)(uintptr_t)variantGlyph);
    }
    return glyphArray;
}

- (CGGlyph) getLargerGlyph:(CGGlyph) glyph
{
    NSDictionary* variants = (NSDictionary*) [_mathTable objectForKey:kVariants];
    NSString* glyphName = [self.font getGlyphName:glyph];
    NSArray* variantGlyphs = (NSArray*) [variants objectForKey:glyphName];
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

@end
