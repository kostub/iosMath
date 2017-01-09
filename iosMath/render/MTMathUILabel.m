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
#import "MTMathListBuilder.h"
#import "MTTypesetter.h"

@implementation MTMathUILabel {
#if TARGET_OS_IPHONE
    UILabel* _errorLabel;
#else
    NSTextField *_errorLabel;
#endif
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
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
    _contentInsets =
#if TARGET_OS_IPHONE
    UIEdgeInsetsZero
#else
    // For backward compatibility, DO NOT use NSEdgeInsetsZero (Available from OS X 10.10).
    NSEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
#endif
    _labelMode = kMTMathUILabelModeDisplay;
    MTFont* font = [MTFontManager fontManager].defaultFont;
    self.font = font;
    _textAlignment = kMTTextAlignmentLeft;
    _displayList = nil;
    _displayErrorInline = true;
    
#if TARGET_OS_IPHONE
    self.backgroundColor = [UIColor clearColor];
    _textColor = [UIColor blackColor];
    _errorLabel = [[UILabel alloc] init];
    _errorLabel.hidden = YES;
    _errorLabel.layer.geometryFlipped = YES;
    _errorLabel.textColor = [UIColor redColor];
#else
    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    [self setWantsLayer:YES];
    _textColor = [NSColor blackColor];
    _errorLabel = [[NSTextField alloc] init];
    _errorLabel.bezeled = NO;
    _errorLabel.drawsBackground = NO;
    _errorLabel.editable = NO;
    _errorLabel.selectable = NO;
    _errorLabel.hidden = YES;
    _errorLabel.layer.geometryFlipped = YES;
    _errorLabel.textColor = [NSColor redColor];
#endif
    
    [self addSubview:_errorLabel];
}

- (void)setFont:(MTFont*)font
{
    NSParameterAssert(font);
    _font = font;
    [self invalidateIntrinsicContentSize];
#if TARGET_OS_IPHONE
    [self setNeedsLayout];
#else
    [self setNeedsLayout:YES];
#endif
}

- (void)setFontSize:(CGFloat)fontSize
{
    _fontSize = fontSize;
    MTFont* font = [_font copyFontWithSize:_fontSize];
    self.font = font;
}

#if TARGET_OS_IPHONE
- (void)setContentInsets:(UIEdgeInsets)contentInsets
#else
- (void)setContentInsets:(NSEdgeInsets)contentInsets
#endif
{
    _contentInsets = contentInsets;
    [self invalidateIntrinsicContentSize];
#if TARGET_OS_IPHONE
    [self setNeedsLayout];
#else
    [self setNeedsLayout:YES];
#endif
}

- (void) setMathList:(MTMathList *)mathList
{
    _mathList = mathList;
    _error = nil;
    _latex = [MTMathListBuilder mathListToString:mathList];
    [self invalidateIntrinsicContentSize];
#if TARGET_OS_IPHONE
    [self setNeedsLayout];
#else
    [self setNeedsLayout:YES];
#endif
}

- (void)setLatex:(NSString *)latex
{
    _latex = latex;
    _error = nil;
    NSError* error = nil;
    _mathList = [MTMathListBuilder buildFromString:latex error:&error];
    if (error) {
        _mathList = nil;
        _error = error;
        
        _errorLabel.
#if TARGET_OS_IPHONE
        text
#else
        stringValue
#endif
        = error.localizedDescription;
        
        _errorLabel.frame = self.bounds;
        _errorLabel.hidden = !self.displayErrorInline;
    } else {
        _errorLabel.hidden = YES;
    }
    [self invalidateIntrinsicContentSize];
#if TARGET_OS_IPHONE
    [self setNeedsLayout];
#else
    [self setNeedsLayout:YES];
#endif
}

- (void)setLabelMode:(MTMathUILabelMode)labelMode
{
    _labelMode = labelMode;
    [self invalidateIntrinsicContentSize];
#if TARGET_OS_IPHONE
    [self setNeedsLayout];
#else
    [self setNeedsLayout:YES];
#endif
}

#if TARGET_OS_IPHONE
- (void)setTextColor:(UIColor *)textColor
#else
- (void)setTextColor:(NSColor *)textColor
#endif
{
    NSParameterAssert(textColor);
    _textColor = textColor;
    _displayList.textColor = textColor;
#if TARGET_OS_IPHONE
    [self setNeedsDisplay];
#else
    [self setNeedsDisplay:YES];
#endif
}

- (void)setTextAlignment:(MTTextAlignment)textAlignment
{
    _textAlignment = textAlignment;
    [self invalidateIntrinsicContentSize];
#if TARGET_OS_IPHONE
    [self setNeedsLayout];
#else
    [self setNeedsLayout:YES];
#endif
}

#if !TARGET_OS_IPHONE
- (BOOL)isFlipped
{
    return NO;
}
#endif

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
#if TARGET_OS_IPHONE
- (void)drawRect:(CGRect)rect
#else
- (void)drawRect:(NSRect)dirtyRect
#endif
{
    [super drawRect:
#if TARGET_OS_IPHONE
     rect
#else
     dirtyRect
#endif
     ];

    if (!_mathList) {
        return;
    }
    
    // Drawing code
#if TARGET_OS_IPHONE
    CGContextRef context = UIGraphicsGetCurrentContext();
#else
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
#endif
    CGContextSaveGState(context);
    
    [_displayList draw:context];
    
    CGContextRestoreGState(context);
}

#if TARGET_OS_IPHONE
- (void) layoutSubviews
#else
- (void)layout
#endif
{
    if (_mathList) {
        _displayList = [MTTypesetter createLineForMathList:_mathList font:_font style:self.currentStyle];
        _displayList.textColor = _textColor;
        
        // Determine x position based on alignment
        CGFloat textX = 0;
        switch (self.textAlignment) {
            case kMTTextAlignmentLeft:
                textX = self.contentInsets.left;
                break;
            case kMTTextAlignmentCenter:
                textX = (self.bounds.size.width - self.contentInsets.left - self.contentInsets.right - _displayList.width) / 2 + self.contentInsets.left;
                break;
            case kMTTextAlignmentRight:
                textX = (self.bounds.size.width - _displayList.width - self.contentInsets.right);
                break;
        }
        
        CGFloat availableHeight = self.bounds.size.height - self.contentInsets.bottom - self.contentInsets.top;
        // center things vertically
        CGFloat height = _displayList.ascent + _displayList.descent;
        if (height < _fontSize/2) {
            // Set the height to the half the size of the font
            height = _fontSize/2;
        }        
        CGFloat textY = (availableHeight - height) / 2 + _displayList.descent + self.contentInsets.bottom;
        _displayList.position = CGPointMake(textX, textY);
    } else {
        _displayList = nil;
    }
    _errorLabel.frame = self.bounds;
#if TARGET_OS_IPHONE
    [self setNeedsDisplay];
#else
    [self setNeedsDisplay:YES];
    
    [super layout];
#endif
}

- (CGSize) sizeThatFits:(CGSize)size
{
    MTMathListDisplay* displayList = nil;
    if (_mathList) {
        displayList = [MTTypesetter createLineForMathList:_mathList font:_font style:self.currentStyle];
    }

    size.width = displayList.width + self.contentInsets.left + self.contentInsets.right;
    size.height = displayList.ascent + displayList.descent + self.contentInsets.top + self.contentInsets.bottom;
    return size;
}

- (CGSize) intrinsicContentSize
{
    return [self sizeThatFits:CGSizeZero];
}

@end
