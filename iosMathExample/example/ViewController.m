//
//  ViewController.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/29/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "ViewController.h"
#import "MTMathUILabel.h"
#import "MTFontManager.h"
#import "../../MathExamples.h"

@interface FontPickerDelegate : NSObject <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) NSArray<NSString*> *fontNames;
@property (nonatomic, weak) ViewController* controller;

@end

@interface ColorPickerDelegate : NSObject <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) NSArray<UIColor*> *colors;
@property (nonatomic, weak) ViewController* controller;

@end

@interface ViewController () <UITextFieldDelegate>

@property (nonatomic, nonnull) NSMutableArray<MTMathUILabel*>* demoLabels;
@property (nonatomic, nonnull) NSMutableArray<MTMathUILabel*>* labels;
// Height constraints + their startup constants, so the size slider can rescale
// each label (and the content view) instead of clipping at larger font sizes.
// Demo labels render at fontSize 15; test labels at the default 20.
@property (nonatomic, nonnull) NSMutableArray<NSLayoutConstraint*>* demoHeightConstraints;
@property (nonatomic, nonnull) NSMutableArray<NSLayoutConstraint*>* testHeightConstraints;
@property (nonatomic, nonnull) NSMutableArray<NSNumber*>* demoBaseHeights;
@property (nonatomic, nonnull) NSMutableArray<NSNumber*>* testBaseHeights;
@property (nonatomic) NSLayoutConstraint* contentHeightConstraint;
@property (weak, nonatomic) IBOutlet UITextField *fontField;
@property (nonatomic) FontPickerDelegate* pickerDelegate;
@property (weak, nonatomic) IBOutlet UITextField *colorField;
@property (nonatomic) ColorPickerDelegate* colorPickerDelegate;
@property (nonatomic) UILabel* sizeLabel;
@property (weak, nonatomic) IBOutlet MTMathUILabel *mathLabel;
@property (weak, nonatomic) IBOutlet UITextField *latexField;

- (void)applyFontWithName:(NSString *)name;

@end

@implementation ViewController

static CGFloat HeightAtIndex(const CGFloat *heights, NSUInteger count, NSUInteger index, CGFloat fallback)
{
    return (index < count) ? heights[index] : fallback;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.demoLabels = [[NSMutableArray alloc] init];
        self.labels = [[NSMutableArray alloc] init];
        self.demoHeightConstraints = [[NSMutableArray alloc] init];
        self.testHeightConstraints = [[NSMutableArray alloc] init];
        self.demoBaseHeights = [[NSMutableArray alloc] init];
        self.testBaseHeights = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup the font picker
    self.pickerDelegate = [[FontPickerDelegate alloc] init];
    self.pickerDelegate.controller = self;
    UIPickerView* picker = [[UIPickerView alloc] init];
    picker.delegate = self.pickerDelegate;
    picker.dataSource = self.pickerDelegate;
    self.fontField.inputView = picker;
    self.fontField.delegate = self;
    self.fontField.text = self.pickerDelegate.fontNames[0];

    // Setup the color picker
    self.colorPickerDelegate = [[ColorPickerDelegate alloc] init];
    self.colorPickerDelegate.controller = self;
    picker = [[UIPickerView alloc] init];
    picker.delegate = self.colorPickerDelegate;
    picker.dataSource = self.colorPickerDelegate;
    self.colorField.inputView = picker;
    self.colorField.delegate = self;
    UIColor* initialColor = self.colorPickerDelegate.colors[0];
    self.colorField.backgroundColor = initialColor;
    
    self.mathLabel.textColor = initialColor;
    
    self.latexField.delegate = self;

    // Global font-size control in the top row, beside the font + colour fields.
    // A stepper (rather than a slider) shows the exact point size and keeps a
    // fixed footprint, so it doesn't drift as the selected font name changes.
    UIView* fontsPanel = self.fontField.superview;
    self.sizeLabel = [[UILabel alloc] init];
    self.sizeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.sizeLabel.font = [UIFont systemFontOfSize:14];
    [fontsPanel addSubview:self.sizeLabel];

    UIStepper* sizeStepper = [[UIStepper alloc] init];
    sizeStepper.translatesAutoresizingMaskIntoConstraints = NO;
    sizeStepper.minimumValue = 10;
    sizeStepper.maximumValue = 40;
    sizeStepper.stepValue = 1;
    sizeStepper.value = 15;
    [sizeStepper addTarget:self action:@selector(sizeChanged:) forControlEvents:UIControlEventValueChanged];
    [fontsPanel addSubview:sizeStepper];
    // Row order: font field → colour field → size label → stepper. The stepper is
    // anchored to the trailing safe area and the colour/size controls have fixed
    // (intrinsic) widths, so the font field — which had its fixed width removed in
    // the XIB — absorbs the remaining space. Everything stays on-screen and
    // tappable at any width (iPhone 16 Pro included).
    [NSLayoutConstraint activateConstraints:@[
        [self.sizeLabel.leadingAnchor constraintEqualToAnchor:self.colorField.trailingAnchor constant:12],
        [self.sizeLabel.centerYAnchor constraintEqualToAnchor:self.colorField.centerYAnchor],
        [sizeStepper.leadingAnchor constraintEqualToAnchor:self.sizeLabel.trailingAnchor constant:8],
        [sizeStepper.centerYAnchor constraintEqualToAnchor:self.colorField.centerYAnchor],
        [sizeStepper.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-12],
    ]];
    // Let the font field shrink to fit the row rather than the size controls.
    [self.fontField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.fontField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self updateSizeLabel:sizeStepper.value];

    UIView* contentView = [[UIView alloc] init];
    [self addFullSizeView:contentView to:self.scrollView];
    // Let the content view grow wider than the viewport so wide formulae (e.g.
    // Rogers–Ramanujan in Latin Modern, or any formula at a large font size) can
    // be reached by scrolling horizontally instead of being clipped. It still
    // fills the viewport when every formula is narrower (low-priority equal width).
    [contentView.widthAnchor constraintGreaterThanOrEqualToAnchor:self.scrollView.widthAnchor].active = YES;
    NSLayoutConstraint* contentFillsWidth = [contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor];
    contentFillsWidth.priority = UILayoutPriorityDefaultLow;
    contentFillsWidth.active = YES;
    // Demo formulae — LaTeX strings from MathExamples.h
    static const CGFloat demoHeights[] = {
        60, 40, 120, 60, 40, 40, 40, 40, 60, 40, 40, 60, 60, 60, 70, 70, 140, 60, 90, 60,
        60
    };
    NSArray<NSString*>* demoFormulas = MathDemoFormulas();
    for (NSUInteger i = 0; i < demoFormulas.count; i++) {
        CGFloat height = HeightAtIndex(demoHeights, sizeof(demoHeights)/sizeof(CGFloat), i, 60);
        MTMathUILabel* label = [[MTMathUILabel alloc] init];
        label.latex = demoFormulas[i];
        label.fontSize = 15;
        label.textColor = initialColor;
        [self.demoLabels addObject:label];
        [self.demoHeightConstraints addObject:[self setHeight:height forView:label]];
        [self.demoBaseHeights addObject:@(height)];
    }

    [self addLabelAsSubview:self.demoLabels[0] to:contentView];
    // First label pinned to top of content view.
    UIView* view = self.demoLabels[0];
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[view]"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:views]];
    for (NSUInteger i = 1; i < self.demoLabels.count; i++) {
        [self addLabelWithIndex:i inArray:self.demoLabels toView:contentView];
    }

    MTMathUILabel* lastDemoLabel = self.demoLabels[self.demoLabels.count - 1];

    // Test formulae — LaTeX strings from MathExamples.h
    static const CGFloat testHeights[] = {
        40, 40, 40, 40, 40, 60, 60, 60, 90, 30, 40, 90, 40, 60, 60, 60,
        60, 60, 60, 60, 60, 60, 30, 20, 20, 60, 30, 40, 30, 30, 50, 50,
        50, 50, 30, 30, 30, 30, 30, 50, 80, 120, 30, 30, 30, 30, 30, 70,
        40, 40, 50, 60, 50, 40, 70, 40,
        40, 40, 40, 40, 40, 50, 50, 60, 50, 50, 40, 70,
        80, 150, 60, 60, 50, 60, 50,
        40, 60, 60, 70, 60, 60, 70, 60, 60, 60, 60,
        70, 40, 40, 50, 40, 50
    };
    NSArray<NSString*>* testFormulas = MathTestFormulas();
    for (NSUInteger i = 0; i < testFormulas.count; i++) {
        CGFloat height = HeightAtIndex(testHeights, sizeof(testHeights)/sizeof(CGFloat), i, 40);
        MTMathUILabel* label = [[MTMathUILabel alloc] init];
        label.latex = testFormulas[i];
        label.textColor = initialColor;
        [self.labels addObject:label];
        [self.testHeightConstraints addObject:[self setHeight:height forView:label]];
        [self.testBaseHeights addObject:@(height)];
    }

    CGFloat totalHeight = 10; // top inset
    for (NSUInteger i = 0; i < demoFormulas.count; i++) {
        totalHeight += HeightAtIndex(demoHeights, sizeof(demoHeights)/sizeof(CGFloat), i, 60);
        totalHeight += 10;
    }
    totalHeight += 30; // gap between sections
    for (NSUInteger i = 0; i < testFormulas.count; i++) {
        totalHeight += HeightAtIndex(testHeights, sizeof(testHeights)/sizeof(CGFloat), i, 40);
        totalHeight += 10;
    }
    self.contentHeightConstraint = [self setHeight:totalHeight forView:contentView];

    // Rendering properties that are not shared (alignment, mode, color, insets, fontSize).
    UIColor* highlight = [UIColor colorWithHue:0.15 saturation:0.5 brightness:1.0 alpha:0.5];
    self.labels[0].backgroundColor = highlight;
    self.labels[1].backgroundColor = highlight;
    self.labels[1].textAlignment = kMTTextAlignmentCenter;
    self.labels[3].backgroundColor = highlight;
    self.labels[3].textAlignment = kMTTextAlignmentRight;
    self.labels[3].contentInsets = UIEdgeInsetsMake(0, 0, 0, 20);
    self.labels[5].labelMode = kMTMathUILabelModeText;
    self.labels[6].backgroundColor = highlight;
    self.labels[6].contentInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    self.labels[7].backgroundColor = highlight;
    self.labels[7].labelMode = kMTMathUILabelModeText;
    self.labels[8].textAlignment = kMTTextAlignmentCenter;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) addLabelWithIndex:(NSUInteger) idx inArray:(NSArray<MTMathUILabel*>*) array toView:(UIView*) contentView
{
    NSAssert(idx > 0, @"Index should be greater than 0. For the first label add manually.");
    [self addLabelAsSubview:array[idx] to:contentView];
    [self setVerticalGap:10 between:array[idx - 1] and:array[idx]];
}

#pragma mark Constraints
- (void)addFullSizeView:(UIView *)view to:(UIView*) parent
{
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [parent addSubview:view];
    [parent addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views]];
    [parent addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views]];
}

- (NSLayoutConstraint*) setHeight:(CGFloat) height forView:(UIView*) view
{
    view.translatesAutoresizingMaskIntoConstraints = false;
    // Add height constraint
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute multiplier:1
                                                                   constant:height];
    constraint.active = YES;
    return constraint;
}

- (void) addLabelAsSubview:(UIView*) label to:(UIView*) parent
{
    label.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(label);
    [parent addSubview:label];
    // Pin the label's leading edge; leave the trailing as a >= gap so the label
    // keeps its natural (intrinsic) width and pushes the content view wider than
    // the viewport when needed, enabling horizontal scrolling instead of clipping.
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[label]-(>=10)-|"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:views]];
}

- (void) setVerticalGap:(CGFloat) gap between:(UIView*) view1 and:(UIView*) view2
{
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:view2
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view1
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1 constant:gap];
    constraint.active = YES;
}

#pragma mark Actions

- (void)updateSizeLabel:(CGFloat)size
{
    self.sizeLabel.text = [NSString stringWithFormat:@"%dpt", (int)size];
}

- (void)sizeChanged:(UIStepper *)sender
{
    CGFloat size = (CGFloat)sender.value;
    [self updateSizeLabel:size];
    // Scale each label's height from its startup baseline so formulas grow with
    // the font instead of being clipped by the fixed startup heights.
    CGFloat total = 10; // top inset
    for (NSUInteger i = 0; i < self.demoLabels.count; i++) {
        self.demoLabels[i].fontSize = size;
        CGFloat h = self.demoBaseHeights[i].doubleValue * (size / 15.0);
        self.demoHeightConstraints[i].constant = h;
        total += h + 10;
    }
    total += 30; // gap between sections
    for (NSUInteger i = 0; i < self.labels.count; i++) {
        self.labels[i].fontSize = size;
        CGFloat h = self.testBaseHeights[i].doubleValue * (size / 20.0);
        self.testHeightConstraints[i].constant = h;
        total += h + 10;
    }
    self.contentHeightConstraint.constant = total;
}

#pragma mark Buttons
- (void)applyFontWithName:(NSString *)name
{
    for (MTMathUILabel* label in self.demoLabels) {
        label.font = [[MTFontManager fontManager] fontWithName:name size:label.font.fontSize];
    }
    for (MTMathUILabel* label in self.labels) {
        label.font = [[MTFontManager fontManager] fontWithName:name size:label.font.fontSize];
    }
}

- (void) changeColor:(UIColor*) color
{
    for (MTMathUILabel* label in self.demoLabels) {
        label.textColor = color;
    }
    for (MTMathUILabel* label in self.labels) {
        label.textColor = color;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.latexField) {
        return YES;
    }
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.latexField) {
        [textField resignFirstResponder];
        self.mathLabel.latex = self.latexField.text;
        return YES;
    }
    return NO;
}

@end

@implementation FontPickerDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fontNames = @[@"Latin Modern Math", @"TeX Gyre Termes", @"XITS Math",
                           @"New Computer Modern", @"TeX Gyre Pagella", @"STIX Two",
                           @"Fira Math", @"Noto Sans Math"];
    }
    return self;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.fontNames.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.fontNames[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // Display names (self.fontNames) map 1:1 to these loader keys.
    // Not static: extern const NSString* values aren't compile-time constants.
    NSString *const kFontKeys[] = {
        MTFontNameLatinModern, MTFontNameTermes, MTFontNameXITS,
        MTFontNameNewComputerModern, MTFontNamePagella, MTFontNameSTIXTwo,
        MTFontNameFiraMath, MTFontNameNotoSansMath,
    };
    self.controller.fontField.text = self.fontNames[row];
    [self.controller.fontField resignFirstResponder];
    [self.controller applyFontWithName:kFontKeys[row]];
}

@end

@implementation ColorPickerDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.colors = @[
            UIColor.labelColor, // Initial color: black in light mode, white in dark mode.
            UIColor.systemPurpleColor,
            UIColor.systemBlueColor,
            UIColor.systemTealColor,
            UIColor.systemGreenColor,
            UIColor.systemYellowColor,
            UIColor.systemOrangeColor,
            UIColor.systemRedColor,
            UIColor.systemPinkColor,
        ];
    }
    return self;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.colors.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    label.backgroundColor = self.colors[row];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    UIColor* color = self.colors[row];
    self.controller.colorField.backgroundColor = color;
    [self.controller changeColor:color];
    [self.controller.colorField resignFirstResponder];
}

@end
