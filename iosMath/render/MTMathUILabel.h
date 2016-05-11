//
//  MathUILabel.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/26/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#import "MTMathList.h"
#import "MTMathListDisplay.h"

// The only significant difference between the two modes is how fractions are displayed.
typedef enum {
    kMTMathUILabelModeDisplay,          // equivalent to $$ in TeX
    kMTMathUILabelModeText              // equivalent to $ in TeX
} MTMathUILabelMode;

typedef enum {
    kMTTextAlignmentLeft,
    kMTTextAlignmentCenter,
    kMTTextAlignmentRight,
} MTTextAlignment;


@interface MTMathUILabel : UIView

@property (nonatomic) CGFloat paddingLeft;
@property (nonatomic) CGFloat paddingRight;
@property (nonatomic) CGFloat paddingTop;
@property (nonatomic) CGFloat paddingBottom;

@property (nonatomic) MTMathList* mathList;
// This should be a math font
// TODO remove from header file
@property (nonatomic) CTFontRef font;
// Resizes the display using the new font size.
@property (nonatomic) CGFloat fontSize;

// The default mode is Display
@property (nonatomic) MTMathUILabelMode labelMode;

// The default is align left.
@property (nonatomic) MTTextAlignment textAlignment;

@property (nonatomic, readonly) MTMathListDisplay* displayList;

// UIView methods overriden
- (CGSize)sizeThatFits:(CGSize)size;
- (void)layoutSubviews;
- (void)drawRect:(CGRect)rect;

@end
