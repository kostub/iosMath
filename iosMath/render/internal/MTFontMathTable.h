//
//  MTFontMathTable.h
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

/** MTGlyphPart represents a part of a glyph used for assembling a large vertical or horizontal
 glyph. */
@interface MTGlyphPart : NSObject

/// The glyph that represents this part
@property (nonatomic, readonly) CGGlyph glyph;

/// Full advance width/height for this part, in the direction of the extension in points.
@property (nonatomic, readonly) CGFloat fullAdvance;

/// Advance width/ height of the straight bar connector material at the beginning of the glyph in points.
@property (nonatomic, readonly) CGFloat startConnectorLength;

/// Advance width/ height of the straight bar connector material at the end of the glyph in points.
@property (nonatomic, readonly) CGFloat endConnectorLength;

/// If this part is an extender. If set, the part can be skipped or repeated.
@property (nonatomic, readonly) BOOL isExtender;

@end

/** This class represents the Math table of an open type font.
 
 The math table is documented here: https://www.microsoft.com/typography/otspec/math.htm
 
 How the constants in this class affect the display is documented here:
 http://www.tug.org/TUGboat/tb30-1/tb94vieth.pdf

 @note We don't parse the math table from the open type font. Rather we parse it
 in python and convert it to a .plist file which is easily consumed by this class.
 This approach is preferable to spending an inordinate amount of time figuring out
 how to parse the returned NSData object using the open type rules.
 
 @remark This class is not meant to be used outside of this library.
 */
@interface MTFontMathTable : NSObject

- (nonnull instancetype) initWithFont:(nonnull MTFont*) font mathTable:(nonnull NSDictionary*) mathTable NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype) init NS_UNAVAILABLE;

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
@property (nonatomic, readonly) CGFloat fractionRuleThickness;                         // \xi_8 in TeX
@property (nonatomic, readonly) CGFloat fractionDelimiterDisplayStyleSize;             // \sigma_20 in TeX
@property (nonatomic, readonly) CGFloat fractionDelimiterSize;                         // \sigma_21 in TeX

#pragma mark Stacks
@property (nonatomic, readonly) CGFloat stackTopDisplayStyleShiftUp;                   // \sigma_8 in TeX
@property (nonatomic, readonly) CGFloat stackTopShiftUp;                               // \sigma_10 in TeX
@property (nonatomic, readonly) CGFloat stackDisplayStyleGapMin;                       // 7 \xi_8 in TeX
@property (nonatomic, readonly) CGFloat stackGapMin;                                   // 3 \xi_8 in TeX
@property (nonatomic, readonly) CGFloat stackBottomDisplayStyleShiftDown;              // \sigma_11 in TeX
@property (nonatomic, readonly) CGFloat stackBottomShiftDown;                          // \sigma_12 in TeX

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

#pragma mark Underline
@property (nonatomic, readonly) CGFloat underbarVerticalGap;                           // 3 \xi_8 in TeX
@property (nonatomic, readonly) CGFloat underbarRuleThickness;                         // \xi_8 in TeX
@property (nonatomic, readonly) CGFloat underbarExtraDescender;                        // \xi_8 in TeX

#pragma mark Overline
@property (nonatomic, readonly) CGFloat overbarVerticalGap;                            // 3 \xi_8 in TeX
@property (nonatomic, readonly) CGFloat overbarRuleThickness;                          // \xi_8 in TeX
@property (nonatomic, readonly) CGFloat overbarExtraAscender;                          // \xi_8 in TeX

#pragma mark Constants

@property (nonatomic, readonly) CGFloat axisHeight;                                    // \sigma_22 in TeX
@property (nonatomic, readonly) CGFloat scriptScaleDown;
@property (nonatomic, readonly) CGFloat scriptScriptScaleDown;

#pragma mark Accent

@property (nonatomic, readonly) CGFloat accentBaseHeight;                              // \fontdimen5 in TeX (x-height)

#pragma mark Variants

/** Returns an NSArray of all the vertical variants of the glyph if any. If
 there are no variants for the glyph, the array contains the given glyph. */
- (nonnull NSArray<NSNumber*>*) getVerticalVariantsForGlyph:(CGGlyph) glyph;

/** Returns an NSArray of all the horizontal variants of the glyph if any. If
 there are no variants for the glyph, the array contains the given glyph. */
- (nonnull NSArray<NSNumber*>*) getHorizontalVariantsForGlyph:(CGGlyph) glyph;

/** Returns a larger vertical variant of the given glyph if any.
 If there is no larger version, this returns the current glyph.
 */
- (CGGlyph) getLargerGlyph:(CGGlyph) glyph;

#pragma mark Italic Correction

/** Returns the italic correction for the given glyph if any. If there
 isn't any this returns 0. */
- (CGFloat) getItalicCorrection:(CGGlyph) glyph;

#pragma mark Accents

/** Returns the adjustment to the top accent for the given glyph if any.
 If there isn't any this returns -1. */
- (CGFloat) getTopAccentAdjustment:(CGGlyph) glyph;

#pragma mark Glyph Construction

/** Minimum overlap of connecting glyphs during glyph construction */
@property (nonatomic, readonly) CGFloat minConnectorOverlap;

/** Returns an array of the glyph parts to be used for constructing vertical variants
 of this glyph. If there is no glyph assembly defined, returns nil. */
- (nullable NSArray<MTGlyphPart*>*) getVerticalGlyphAssemblyForGlyph:(CGGlyph) glyph;

@end
