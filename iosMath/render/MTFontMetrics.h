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

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

// Reference for math metrics: http://www.tug.org/TUGboat/tb30-1/tb94vieth.pdf
@interface MTFontMetrics : NSObject

- (id) initWithFont:(CTFontRef) font;

// MU unit in points
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

#pragma mark Constants

@property (nonatomic, readonly) CGFloat axisHeight;                                    // \sigma_22 in TeX
@property (nonatomic, readonly) CGFloat scriptScaleDown;
@property (nonatomic, readonly) CGFloat scriptScriptScaleDown;

@end
