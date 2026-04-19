//
//  AppDelegate.m
//  MacOSMath
//
//  Created by 安志钢 on 17-01-08.
//  Copyright © 2017年 安志钢. All rights reserved.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "AppDelegate.h"
#import "MTMathUILabel.h"
#import "../MathExamples.h"

// Flipped NSView so Auto Layout stacks subviews top-to-bottom.
@interface MTFlippedView : NSView
@end
@implementation MTFlippedView
- (BOOL)isFlipped { return YES; }
@end

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, strong) NSMutableArray<MTMathUILabel*>* demoLabels;
@property (nonatomic, strong) NSMutableArray<MTMathUILabel*>* labels;
@end

@implementation AppDelegate

static CGFloat HeightAtIndex(const CGFloat *heights, NSUInteger count, NSUInteger index, CGFloat fallback)
{
    return (index < count) ? heights[index] : fallback;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.demoLabels = [[NSMutableArray alloc] init];
    self.labels = [[NSMutableArray alloc] init];

    NSView* mainView = self.window.contentView;

    // Scroll view fills the window.
    NSScrollView* scrollView = [[NSScrollView alloc] initWithFrame:mainView.bounds];
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    scrollView.backgroundColor = NSColor.whiteColor;
    scrollView.drawsBackground = YES;
    [mainView addSubview:scrollView];

    // Flipped document view for top-down layout with white background.
    CGFloat docWidth = scrollView.contentSize.width;
    MTFlippedView* contentView = [[MTFlippedView alloc] initWithFrame:NSMakeRect(0, 0, docWidth, 100)];
    contentView.autoresizingMask = NSViewWidthSizable;
    contentView.backgroundColor = NSColor.whiteColor;
    scrollView.documentView = contentView;

    // --- Demo formulae — LaTeX strings from MathExamples.h ---
    static const CGFloat demoHeights[] = {
        60, 40, 40, 80, 60, 40, 40, 40, 40, 60, 40, 40, 60, 60, 60, 70, 70, 140, 60, 90, 60, 60, 70
    };
    NSArray<NSString*>* demoFormulas = MathDemoFormulas();
    for (NSUInteger i = 0; i < demoFormulas.count; i++) {
        CGFloat height = HeightAtIndex(demoHeights, sizeof(demoHeights)/sizeof(CGFloat), i, 60);
        MTMathUILabel* label = [self createMathLabel:demoFormulas[i] withHeight:height];
        label.fontSize = 15;
        [self.demoLabels addObject:label];
    }

    [self addLabelAsSubview:self.demoLabels[0] to:contentView];
    // Pin first label 10pt from top.
    [NSLayoutConstraint constraintWithItem:self.demoLabels[0]
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:contentView
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0 constant:10.0].active = YES;
    for (NSUInteger i = 1; i < self.demoLabels.count; i++) {
        [self addLabelWithIndex:i inArray:self.demoLabels toView:contentView];
    }

    MTMathUILabel* lastDemoLabel = self.demoLabels[self.demoLabels.count - 1];

    // --- Test formulae — LaTeX strings from MathExamples.h ---
    static const CGFloat testHeights[] = {
        40, 40, 40, 40, 40, 60, 60, 60, 90, 30, 40, 90, 40, 60, 60, 60,
        60, 60, 60, 60, 60, 60, 30, 20, 20, 60, 30, 40, 30, 30, 50, 50,
        50, 50, 30, 30, 30, 30, 30, 50, 80, 120, 30, 30, 30, 30, 30, 70,
        40, 40, 50, 60, 50, 40, 70, 40
    };
    NSArray<NSString*>* testFormulas = MathTestFormulas();
    for (NSUInteger i = 0; i < testFormulas.count; i++) {
        CGFloat height = HeightAtIndex(testHeights, sizeof(testHeights)/sizeof(CGFloat), i, 40);
        [self.labels addObject:[self createMathLabel:testFormulas[i] withHeight:height]];
    }

    CGFloat documentHeight = 10;
    for (NSUInteger i = 0; i < demoFormulas.count; i++) {
        documentHeight += HeightAtIndex(demoHeights, sizeof(demoHeights)/sizeof(CGFloat), i, 60);
        documentHeight += 10;
    }
    documentHeight += 30;
    for (NSUInteger i = 0; i < testFormulas.count; i++) {
        documentHeight += HeightAtIndex(testHeights, sizeof(testHeights)/sizeof(CGFloat), i, 40);
        documentHeight += 10;
    }
    contentView.frame = NSMakeRect(0, 0, docWidth, documentHeight);

    // Rendering properties that are not shared (alignment, mode, color, insets, fontSize).
    NSColor* highlight = [NSColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    self.labels[0].backgroundColor = highlight;
    self.labels[1].backgroundColor = highlight;
    self.labels[1].textAlignment = kMTTextAlignmentCenter;
    self.labels[3].backgroundColor = highlight;
    self.labels[3].textAlignment = kMTTextAlignmentRight;
    self.labels[3].contentInsets = NSEdgeInsetsMake(0, 0, 0, 20);
    self.labels[5].labelMode = kMTMathUILabelModeText;
    self.labels[6].backgroundColor = highlight;
    self.labels[6].contentInsets = NSEdgeInsetsMake(0, 20, 0, 0);
    self.labels[7].backgroundColor = highlight;
    self.labels[7].labelMode = kMTMathUILabelModeText;
    self.labels[8].fontSize = 30;
    self.labels[8].textAlignment = kMTTextAlignmentCenter;
    self.labels[9].fontSize = 10;
    self.labels[9].textAlignment = kMTTextAlignmentCenter;
    self.labels[17].labelMode = kMTMathUILabelModeText;
    self.labels[18].labelMode = kMTMathUILabelModeText;
    self.labels[26].labelMode = kMTMathUILabelModeText;
    self.labels[28].labelMode = kMTMathUILabelModeText;

    [self addLabelAsSubview:self.labels[0] to:contentView];
    [self setVerticalGap:30 between:lastDemoLabel and:self.labels[0]];
    for (NSUInteger i = 1; i < self.labels.count; i++) {
        [self addLabelWithIndex:i inArray:self.labels toView:contentView];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

#pragma mark - Label creation helpers

- (MTMathUILabel*)createMathLabel:(NSString*)latex withHeight:(CGFloat)height
{
    MTMathUILabel* label = [[MTMathUILabel alloc] init];
    [self setHeight:height forView:label];
    label.latex = latex;
    return label;
}

- (void)addLabelWithIndex:(NSUInteger)idx inArray:(NSArray<MTMathUILabel*>*)array toView:(NSView*)contentView
{
    NSAssert(idx > 0, @"Index should be greater than 0. For the first label add manually.");
    [self addLabelAsSubview:array[idx] to:contentView];
    [self setVerticalGap:10 between:array[idx - 1] and:array[idx]];
}

#pragma mark - Auto Layout helpers

- (void)addLabelAsSubview:(NSView*)label to:(NSView*)parent
{
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [parent addSubview:label];
    NSDictionary* views = NSDictionaryOfVariableBindings(label);
    [NSLayoutConstraint activateConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[label]-(10)-|"
                                             options:0 metrics:nil views:views]];
}

- (void)setHeight:(CGFloat)height forView:(NSView*)view
{
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:1 constant:height].active = YES;
}

- (void)setVerticalGap:(CGFloat)gap between:(NSView*)view1 and:(NSView*)view2
{
    [NSLayoutConstraint constraintWithItem:view2
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view1
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1 constant:gap].active = YES;
}

@end
