//
//  MathUILabel.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/26/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTMathUILabel.h"
#import "MTMathListDisplay.h"
#import "MTFontManager.h"

@implementation MTMathUILabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (void) initCommon
{
    self.layer.geometryFlipped = YES;  // For ease of interaction with the CoreText coordinate system.
    // default font size
    _fontSize = 20;
    _paddingLeft = 0;
    _paddingRight = 0;
    _paddingTop = 0;
    _paddingBottom = 0;
    _labelMode = kMTMathUILabelModeDisplay;
    MTFont* font = [MTFontManager fontManager].defaultFont;
    self.font = font;
    _textAlignment = kMTTextAlignmentLeft;
    _displayList = nil;
    self.backgroundColor = [UIColor clearColor];
}

- (void)setFont:(MTFont*)font
{
    NSParameterAssert(font);
    _font = font;
    [self setNeedsLayout];
}

- (void)setFontSize:(CGFloat)fontSize
{
    _fontSize = fontSize;
    MTFont* font = [_font copyFontWithSize:_fontSize];
    self.font = font;
}

- (void) setMathList:(MTMathList *)mathList
{
    _mathList = mathList;
    [self setNeedsLayout];
}

- (void)setLabelMode:(MTMathUILabelMode)labelMode
{
    _labelMode = labelMode;
    [self setNeedsLayout];
}

- (void)setTextAlignment:(MTTextAlignment)textAlignment
{
    _textAlignment = textAlignment;
    [self setNeedsLayout];
}

- (MTLineStyle) currentStyle
{
    switch (_labelMode) {
        case kMTMathUILabelModeDisplay:
            return kMTLineStyleDisplay;
        case kMTMathUILabelModeText:
            return kMTLineStyleText;
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (!_mathList) {
        return;
    }
    
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    [_displayList draw:context];
    
    CGContextRestoreGState(context);
}

- (void) layoutSubviews
{
    if (_mathList) {
        _displayList = [MTTypesetter createLineForMathList:_mathList font:_font style:self.currentStyle];
        
        // Determine x position based on alignment
        CGFloat textX = 0;
        switch (self.textAlignment) {
            case kMTTextAlignmentLeft:
                textX = _paddingLeft;
                break;
            case kMTTextAlignmentCenter:
                textX = (self.bounds.size.width - _paddingLeft - _paddingRight - _displayList.width) / 2 + _paddingLeft;
                break;
            case kMTTextAlignmentRight:
                textX = (self.bounds.size.width - _displayList.width -_paddingRight);
                break;
        }
        
        CGFloat availableHeight = self.bounds.size.height - _paddingBottom - _paddingTop;
        // center things vertically
        CGFloat height = _displayList.ascent + _displayList.descent;
        if (height < _fontSize/2) {
            // Set the height to the half the size of the font
            height = _fontSize/2;
        }        
        CGFloat textY = (availableHeight - height) / 2 + _displayList.descent + _paddingBottom;
        _displayList.position = CGPointMake(textX, textY);
    } else {
        _displayList = nil;
    }
    [self setNeedsDisplay];
}

- (CGSize) sizeThatFits:(CGSize)size
{
    MTMathListDisplay* displayList = nil;
    if (_mathList) {
        displayList = [MTTypesetter createLineForMathList:_mathList font:_font style:self.currentStyle];
    }

    size.width = displayList.width + _paddingLeft + _paddingRight;
    size.height = displayList.ascent + displayList.descent + _paddingTop + _paddingBottom;
    return size;
}

@end
