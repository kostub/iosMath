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
@property (weak, nonatomic) IBOutlet UITextField *fontField;
@property (nonatomic) FontPickerDelegate* pickerDelegate;
@property (weak, nonatomic) IBOutlet UITextField *colorField;
@property (nonatomic) ColorPickerDelegate* colorPickerDelegate;
@property (weak, nonatomic) IBOutlet MTMathUILabel *mathLabel;
@property (weak, nonatomic) IBOutlet UITextField *latexField;

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

    self.latexField.delegate = self;

    UIView* contentView = [[UIView alloc] init];
    [self addFullSizeView:contentView to:self.scrollView];
    // set the size of the content view
    // Disable horizontal scrolling.
    [self setEqualWidths:contentView andView:self.scrollView];
    // Demo formulae — LaTeX strings from MathExamples.h
    static const CGFloat demoHeights[] = {
        60, 40, 40, 80, 60, 40, 40, 40, 40, 60, 40, 40, 60, 60, 60, 70, 70, 140, 60, 90, 60, 60, 70,
        60, 60, 60, 70, 60, 60, 60, 60
    };
    NSArray<NSString*>* demoFormulas = MathDemoFormulas();
    for (NSUInteger i = 0; i < demoFormulas.count; i++) {
        CGFloat height = HeightAtIndex(demoHeights, sizeof(demoHeights)/sizeof(CGFloat), i, 60);
        MTMathUILabel* label = [self createMathLabel:demoFormulas[i] withHeight:height];
        label.fontSize = 15;
        [self.demoLabels addObject:label];
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
        40, 40, 50, 60, 50, 40, 70, 40
    };
    NSArray<NSString*>* testFormulas = MathTestFormulas();
    for (NSUInteger i = 0; i < testFormulas.count; i++) {
        CGFloat height = HeightAtIndex(testHeights, sizeof(testHeights)/sizeof(CGFloat), i, 40);
        [self.labels addObject:[self createMathLabel:testFormulas[i] withHeight:height]];
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
    [self setHeight:totalHeight forView:contentView];

    // Rendering properties that are not shared (alignment, mode, color, insets, fontSize).
    UIColor* highlight = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
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

-(MTMathUILabel*) createMathLabel:(NSString*) latex withHeight:(CGFloat) height
{
    MTMathUILabel* label = [[MTMathUILabel alloc] init];
    [self setHeight:height forView:label];
    label.latex = latex;
    return label;
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

- (void) setHeight:(CGFloat) height forView:(UIView*) view
{
    view.translatesAutoresizingMaskIntoConstraints = false;
    // Add height constraint
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute multiplier:1
                                                                   constant:height];
    constraint.active = YES;
}

- (void) setEqualWidths:(UIView*) view1 andView:(UIView*) view2
{
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:view1
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual toItem:view2
                                                                  attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    constraint.active = YES;
}

- (void) addLabelAsSubview:(UIView*) label to:(UIView*) parent
{
    label.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(label);
    [parent addSubview:label];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[label]-(10)-|"
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

#pragma mark Buttons
- (void)latinButtonPressed:(id)sender
{
    for (MTMathUILabel* label in self.demoLabels) {
        label.font = [[MTFontManager fontManager] latinModernFontWithSize:label.font.fontSize];
    }
    for (MTMathUILabel* label in self.labels) {
        label.font = [[MTFontManager fontManager] latinModernFontWithSize:label.font.fontSize];
    }
}

- (void)termesButtonPressed:(id)sender
{
    for (MTMathUILabel* label in self.demoLabels) {
        label.font = [[MTFontManager fontManager] termesFontWithSize:label.font.fontSize];
    }
    for (MTMathUILabel* label in self.labels) {
        label.font = [[MTFontManager fontManager] termesFontWithSize:label.font.fontSize];
    }
}

- (void)xitsButtonPressed:(id)sender
{
    for (MTMathUILabel* label in self.demoLabels) {
        label.font = [[MTFontManager fontManager] xitsFontWithSize:label.font.fontSize];
    }
    for (MTMathUILabel* label in self.labels) {
        label.font = [[MTFontManager fontManager] xitsFontWithSize:label.font.fontSize];
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
        self.fontNames = @[@"Latin Modern Math", @"TeX Gyre Termes", @"XITS Math"];
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
    self.controller.fontField.text = self.fontNames[row];
    [self.controller.fontField resignFirstResponder];
    switch (row) {
        case 0:
            [self.controller latinButtonPressed:nil];
            break;

        case 1:
            [self.controller termesButtonPressed:nil];

        case 2:
            [self.controller xitsButtonPressed:nil];

        default:
            break;
    }
}

@end

@implementation ColorPickerDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.colors = @[UIColor.blackColor, UIColor.blueColor, UIColor.redColor, UIColor.greenColor];
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
