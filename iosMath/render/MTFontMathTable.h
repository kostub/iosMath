//
//  MTFontMetrics.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

@import Foundation;
@import CoreText;

@class MTFont;

/** This class represents the Math table of an open type font.
 
 The math table is documented here: https://www.microsoft.com/typography/otspec/math.htm
 
 How the constants in this class affect the display is documented here:
 http://www.tug.org/TUGboat/tb30-1/tb94vieth.pdf

 @note We don't parse the math table from the open type font. Rather we parse it
 in python and convert it to a .plist file which is easily consumed by this class.
 This approach is preferable to spending an inordinate amount of time figuring out
 how to parse the returned NSData object using the open type rules.
 */
@interface MTFontMathTable : NSObject

- (instancetype) initWithFont:(MTFont*) font mathTable:(NSDictionary*) mathTable;

/** MU unit in points */
@property (nonatomic, readonly) CGFloat muUnit;

// Math Font Metrics from the opentype specification
#pragma mark Fractions
@property (nonatomic, readonly) CGFloat fractionNumeratorDisplayStyleShiftUp;          // \sigma_8 in TeX
@property (nonatomic, readonly) CGFloat fractionNumeratorShiftUp;                      // \sigma_9 in TeX
@property (nonatomic, readonly) CGFloat fractionDenominatorDisplayStyleShiftDown;      // \sigma_11 in TeX
@property (nonatomic, readonly) CGFloat fractionDenominatorShiftDown;                  // \sigma_12 in TeX
@property (nonatomic, readonly) CGFloat fractionNumeratorDisplayStyleGapMin;           // 3 * \xi_8 in TeX
@property (nonatomic, readonly) CGFloat fractionNumeratorGapMin;                       // \xi_8 in TeX
@property (nonatomic, readonly) CGFloat fractionDenominatorDisplayStyleGapMin;         // 3 * \xi_8 in TeX
@property (nonatomic, readonly) CGFloat fractionDenominatorGapMin;                     // \xi_8 in TeX
@property (nonatomic, readonly) CGFloat fractionRuleThickness;                         // \xi_8 in Tex


#pragma mark super/sub scripts

@property (nonatomic, readonly) CGFloat superscriptShiftUp;                            // \sigma_13, \sigma_14 in TeX
@property (nonatomic, readonly) CGFloat superscriptShiftUpCramped;                     // \sigma_15 in TeX
@property (nonatomic, readonly) CGFloat subscriptShiftDown;                            // \sigma_16, \sigma_17 in TeX
@property (nonatomic, readonly) CGFloat superscriptBaselineDropMax;                    // \sigma_18 in TeX
@property (nonatomic, readonly) CGFloat subscriptBaselineDropMin;                      // \sigma_19 in TeX
@property (nonatomic, readonly) CGFloat superscriptBottomMin;                          // 1/4 \sigma_5 in TeX
@property (nonatomic, readonly) CGFloat subscriptTopMax;                               // 4/5 \sigma_5 in TeX
@property (nonatomic, readonly) CGFloat subSuperscriptGapMin;                          // 4 \xi_8 in TeX
@property (nonatomic, readonly) CGFloat superscriptBottomMaxWithSubscript;             // 4/5 \sigma_5 in TeX

@property (nonatomic, readonly) CGFloat spaceAfterScript;

#pragma mark radicals
@property (nonatomic, readonly) CGFloat radicalExtraAscender;                          // \xi_8 in Tex
@property (nonatomic, readonly) CGFloat radicalRuleThickness;                          // \xi_8 in Tex
@property (nonatomic, readonly) CGFloat radicalDisplayStyleVerticalGap;                // \xi_8 + 1/4 \sigma_5 in Tex
@property (nonatomic, readonly) CGFloat radicalVerticalGap;                            // 5/4 \xi_8 in Tex
@property (nonatomic, readonly) CGFloat radicalKernBeforeDegree;                       // 5 mu in Tex
@property (nonatomic, readonly) CGFloat radicalKernAfterDegree;                        // -10 mu in Tex
@property (nonatomic, readonly) CGFloat radicalDegreeBottomRaisePercent;               // 60% in Tex

#pragma mark Limits
@property (nonatomic, readonly) CGFloat upperLimitBaselineRiseMin;                     // \xi_11 in TeX
@property (nonatomic, readonly) CGFloat upperLimitGapMin;                              // \xi_9 in TeX
@property (nonatomic, readonly) CGFloat lowerLimitGapMin;                              // \xi_10 in TeX
@property (nonatomic, readonly) CGFloat lowerLimitBaselineDropMin;                     // \xi_12 in TeX
@property (nonatomic, readonly) CGFloat limitExtraAscenderDescender;                   // \xi_13 in TeX, not present in OpenType so we always set it to 0.

#pragma mark Constants

@property (nonatomic, readonly) CGFloat axisHeight;                                    // \sigma_22 in TeX
@property (nonatomic, readonly) CGFloat scriptScaleDown;
@property (nonatomic, readonly) CGFloat scriptScriptScaleDown;

#pragma mark Variants

/** Returns a CFArray of all the vertical variants of the glyph if any.
 This array needs to be released by the caller. */
- (CFArrayRef) copyVerticalVariantsForGlyphWithName:(NSString*) glyphName;

/** Returns a larger vertical variant of the given glyph if any.
 If there is no larger version, this returns the current glyph.
 */
- (CGGlyph) getLargerGlyph:(CGGlyph) glyph;

#pragma mark Italic Correction

/** Returns the italic correction for the given glyph if any. If there
 isn't any this returns 0. */
- (CGFloat) getItalicCorrection:(CGGlyph) glyph;

@end
