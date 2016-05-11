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

#import "MTFontMetrics.h"

@implementation MTFontMetrics {
    NSUInteger _unitsPerEm;
    CGFloat _fontSize;
}

- (id)initWithFont:(CTFontRef)font
{
    self = [super init];
    if (self) {
        // do domething with font
        _unitsPerEm = CTFontGetUnitsPerEm(font);
        _fontSize = CTFontGetSize(font);
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

// TODO: These are hardcoded for LM Math. Read from the Math table in the font so that other fonts can be used.

#pragma mark - Fractions
- (CGFloat)fractionNumeratorDisplayStyleShiftUp
{
    return [self fontUnitsToPt:677];
}

- (CGFloat)fractionNumeratorShiftUp
{
    return [self fontUnitsToPt:394];
}

- (CGFloat)fractionDenominatorDisplayStyleShiftDown
{
    return [self fontUnitsToPt:686];
}

- (CGFloat)fractionDenominatorShiftDown
{
    return [self fontUnitsToPt:345];
}

- (CGFloat)fractionNumeratorDisplayStyleGapMin
{
    return [self fontUnitsToPt:120];
}

- (CGFloat)fractionNumeratorGapMin
{
    return [self fontUnitsToPt:40];
}

- (CGFloat)fractionDenominatorDisplayStyleGapMin
{
    return [self fontUnitsToPt:120];
}

- (CGFloat)fractionDenominatorGapMin
{
    return [self fontUnitsToPt:40];
}

- (CGFloat)fractionRuleThickness
{
    return [self fontUnitsToPt:40];
}

#pragma mark - Sub/Superscripts

- (CGFloat)superscriptShiftUp
{
    return [self fontUnitsToPt:363];
}

- (CGFloat)superscriptShiftUpCramped
{
    return [self fontUnitsToPt:289];
}

- (CGFloat)subscriptShiftDown
{
    return [self fontUnitsToPt:247];
}

- (CGFloat)superscriptBaselineDropMax
{
    return [self fontUnitsToPt:250];
}

- (CGFloat)subscriptBaselineDropMin
{
    return [self fontUnitsToPt:200];
}

- (CGFloat)superscriptBottomMin
{
    return [self fontUnitsToPt:108];
}

- (CGFloat)subscriptTopMax
{
    return [self fontUnitsToPt:344];
}

- (CGFloat)subSuperscriptGapMin
{
    return [self fontUnitsToPt:160];
}

- (CGFloat)superscriptBottomMaxWithSubscript
{
    return [self fontUnitsToPt:344];
}

- (CGFloat) spaceAfterScript
{
    return [self fontUnitsToPt:56];
}

#pragma mark - Radicals

- (CGFloat)radicalRuleThickness
{
    return [self fontUnitsToPt:40];
}

- (CGFloat)radicalExtraAscender
{
    return [self fontUnitsToPt:40];
}

- (CGFloat)radicalVerticalGap
{
    return [self fontUnitsToPt:50];
}

- (CGFloat)radicalDisplayStyleVerticalGap
{
    return [self fontUnitsToPt:148];
}

- (CGFloat)radicalKernBeforeDegree
{
    return [self fontUnitsToPt:278];
}

- (CGFloat)radicalKernAfterDegree
{
    return [self fontUnitsToPt:-556];
}

- (CGFloat)radicalDegreeBottomRaisePercent
{
    return 0.6;
}

#pragma mark - Constants

-(CGFloat)axisHeight
{
    return [self fontUnitsToPt:250];
}

- (CGFloat)scriptScaleDown
{
    return 0.7;
}

- (CGFloat)scriptScriptScaleDown
{
    return 0.5;
}

@end
