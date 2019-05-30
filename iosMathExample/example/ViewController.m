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
    [self setHeight:4350 forView:contentView];


    // Demo formulae
    // Quadratic formula
    self.demoLabels[0] = [self createMathLabel:@"\\text{ваш вопрос: }x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}" withHeight:60];
    [self addLabelAsSubview:self.demoLabels[0] to:contentView];
    self.demoLabels[0].fontSize = 15;
    // This is first label so set the height from the top
    UIView* view = self.demoLabels[0];
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[view]"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:views]];


    self.demoLabels[1] = [self createMathLabel:@"\\color{#ff3399}{(a_1+a_2)^2}=a_1^2+2a_1a_2+a_2^2" withHeight:40];

    self.demoLabels[2] = [self createMathLabel:@"\\cos(\\theta + \\varphi) = \
                                 \\cos(\\theta)\\cos(\\varphi) - \\sin(\\theta)\\sin(\\varphi)"
                                           withHeight:40];

    self.demoLabels[3] = [self createMathLabel:@"\\frac{1}{\\left(\\sqrt{\\phi \\sqrt{5}}-\\phi\\right) e^{\\frac25 \\pi}} \
                                 = 1+\\frac{e^{-2\\pi}} {1 +\\frac{e^{-4\\pi}} {1+\\frac{e^{-6\\pi}} {1+\\frac{e^{-8\\pi}} {1+\\cdots} } } }"
                                           withHeight:80];

    self.demoLabels[4] = [self createMathLabel:@"\\sigma = \\sqrt{\\frac{1}{N}\\sum_{i=1}^N (x_i - \\mu)^2}"
                                    withHeight:60];

    self.demoLabels[5] = [self createMathLabel:@"\\neg(P\\land Q) \\iff (\\neg P)\\lor(\\neg Q)" withHeight:40];

    self.demoLabels[6] = [self createMathLabel:@"\\log_b(x) = \\frac{\\log_a(x)}{\\log_a(b)}" withHeight:40];

    self.demoLabels[7] = [self createMathLabel:@"\\lim_{x\\to\\infty}\\left(1 + \\frac{k}{x}\\right)^x = e^k" withHeight:40];

    self.demoLabels[8] = [self createMathLabel:@"\\int_{-\\infty}^\\infty \\! e^{-x^2} dx = \\sqrt{\\pi}" withHeight:40];

    self.demoLabels[9] = [self createMathLabel:@"\\frac 1 n \\sum_{i=1}^{n}x_i \\geq \\sqrt[n]{\\prod_{i=1}^{n}x_i}" withHeight:60];

    self.demoLabels[10] = [self createMathLabel:@"f^{(n)}(z_0) = \\frac{n!}{2\\pi i}\\oint_\\gamma\\frac{f(z)}{(z-z_0)^{n+1}}\\,dz" withHeight:40];

    self.demoLabels[11] = [self createMathLabel:@"i\\hbar\\frac{\\partial}{\\partial t}\\mathbf\\Psi(\\mathbf{x},t) = "
                           "-\\frac{\\hbar}{2m}\\nabla^2\\mathbf\\Psi(\\mathbf{x},t) + "
                           "V(\\mathbf{x})\\mathbf\\Psi(\\mathbf{x},t)" withHeight:40];
    
    self.demoLabels[12] = [self createMathLabel:@"\\left(\\sum_{k=1}^n a_k b_k \\right)^2 \\le \\left(\\sum_{k=1}^n a_k^2\\right)\\left(\\sum_{k=1}^n b_k^2\\right)" withHeight:60];
    
    self.demoLabels[13] = [self createMathLabel:@"{n \\brace k} = \\frac{1}{k!}\\sum_{j=0}^k (-1)^{k-j}\\binom{k}{j}(k-j)^n" withHeight:60];

    self.demoLabels[14] = [self createMathLabel:@"f(x) = \\int\\limits_{-\\infty}^\\infty\\!\\hat f(\\xi)\\,e^{2 \\pi i \\xi x}\\,\\mathrm{d}\\xi" withHeight:60];

    self.demoLabels[15] = [self createMathLabel:@"\\begin{gather}"
                           "\\dot{x} = \\sigma(y-x) \\\\"
                           "\\dot{y} = \\rho x - y - xz \\\\"
                           "\\dot{z} = -\\beta z + xy"
                           "\\end{gather}" withHeight:70];

    self.demoLabels[16] = [self createMathLabel:@"\\vec \\bf V_1 \\times \\vec \\bf V_2 =  \\begin{vmatrix}"
                           "\\hat \\imath &\\hat \\jmath &\\hat k \\\\"
                           "\\frac{\\partial X}{\\partial u} &  \\frac{\\partial Y}{\\partial u} & 0 \\\\"
                           "\\frac{\\partial X}{\\partial v} &  \\frac{\\partial Y}{\\partial v} & 0"
                           "\\end{vmatrix}" withHeight:70];

    self.demoLabels[17] = [self createMathLabel:@"\\begin{eqalign}"
                           "\\nabla \\cdot \\vec{\\bf{E}} & = \\frac {\\rho} {\\varepsilon_0} \\\\"
                           "\\nabla \\cdot \\vec{\\bf{B}} & = 0 \\\\"
                           "\\nabla \\times \\vec{\\bf{E}} &= - \\frac{\\partial\\vec{\\bf{B}}}{\\partial t} \\\\"
                           "\\nabla \\times \\vec{\\bf{B}} & = \\mu_0\\vec{\\bf{J}} + \\mu_0\\varepsilon_0 \\frac{\\partial\\vec{\\bf{E}}}{\\partial t}"
                           "\\end{eqalign}" withHeight:140];

    self.demoLabels[18] = [self createMathLabel:@"\\begin{pmatrix}"
                           "a & b\\\\ c & d"
                           "\\end{pmatrix}"
                           "\\begin{pmatrix}"
                           "\\alpha & \\beta \\\\ \\gamma & \\delta"
                           "\\end{pmatrix} = "
                           "\\begin{pmatrix}"
                           "a\\alpha + b\\gamma & a\\beta + b \\delta \\\\"
                           "c\\alpha + d\\gamma & c\\beta + d \\delta "
                           "\\end{pmatrix}"
                                     withHeight:60];

    self.demoLabels[19] = [self createMathLabel:@"\\frak Q(\\lambda,\\hat{\\lambda}) = "
                           "-\\frac{1}{2} \\mathbb P(O \\mid \\lambda ) \\sum_s \\sum_m \\sum_t \\gamma_m^{(s)} (t) +\\\\ "
                           "\\quad \\left( \\log(2 \\pi ) + \\log \\left| \\cal C_m^{(s)} \\right| + "
                           "\\left( o_t - \\hat{\\mu}_m^{(s)} \\right) ^T \\cal C_m^{(s)-1} \\right) "
                           "" withHeight:90];

    self.demoLabels[20] = [self createMathLabel:@"f(x) = \\begin{cases}"
                           "\\frac{e^x}{2} & x \\geq 0 \\\\"
                           "1 & x < 0"
                           "\\end{cases}" withHeight:60];
    
    self.demoLabels[21] = [self createMathLabel:@"\\color{#ff3333}{c}\\color{#9933ff}{o}\\color{#ff0080}{l}+\\color{#99ff33}{\\frac{\\color{#ff99ff}{o}}{\\color{#990099}{r}}}-\\color{#33ffff}{\\sqrt[\\color{#3399ff}{e}]{\\color{#3333ff}{d}}}" withHeight:60];


    for (NSUInteger i = 1; i < self.demoLabels.count; i++) {
        self.demoLabels[i].fontSize = 15;
        [self addLabelWithIndex:i inArray:self.demoLabels toView:contentView];
    }

    MTMathUILabel* lastDemoLabel = self.demoLabels[self.demoLabels.count - 1];

    // Test formulae
    self.labels[0] = [self createMathLabel:@"3+2-5 = 0" withHeight:40];
    self.labels[0].backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    [self addLabelAsSubview:self.labels[0] to:contentView];
    [self setVerticalGap:30 between:lastDemoLabel and:self.labels[0]];

    // Infix and prefix Operators
    self.labels[1] = [self createMathLabel:@"12+-3 > +14" withHeight:40];
    self.labels[1].backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    self.labels[1].textAlignment = kMTTextAlignmentCenter;

    // Punct, parens
    self.labels[2] = [self createMathLabel:@"(-3-5=-8, -6-7=-13)" withHeight:40];

    // Latex commands
    self.labels[3] = [self createMathLabel:@"5\\times(-2 \\div 1) = -10" withHeight:40];
    self.labels[3].backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    self.labels[3].textAlignment = kMTTextAlignmentRight;
    self.labels[3].contentInsets = UIEdgeInsetsMake(0, 0, 0, 20);

    self.labels[4] = [self createMathLabel:@"-h - (5xy+2) = z" withHeight:40];

    // Text mode fraction
    self.labels[5] = [self createMathLabel:@"\\frac12x + \\frac{3\\div4}2y = 25" withHeight:60];
    self.labels[5].labelMode = kMTMathUILabelModeText;


    // Display mode fraction
    self.labels[6] = [self createMathLabel:@"\\frac{x+\\frac{12}{5}}{y}+\\frac1z = \\frac{xz+y+\\frac{12}{5}z}{yz}" withHeight:60];
    self.labels[6].backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    self.labels[6].contentInsets = UIEdgeInsetsMake(0, 20, 0, 0);

    // fraction in fraction in text mode
    self.labels[7] = [self createMathLabel:@"\\frac{x+\\frac{12}{5}}{y}+\\frac1z = \\frac{xz+y+\\frac{12}{5}z}{yz}" withHeight:60];
    self.labels[7].backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    self.labels[7].labelMode = kMTMathUILabelModeText;

    // Exponents and subscripts
    // Large font
    self.labels[8] = [self createMathLabel:@"\\frac{x^{2+3y}}{x^{2+4y}} = x^y \\times \\frac{z_1^{y+1}}{z_1^{y+1}}" withHeight:90];
    self.labels[8].fontSize = 30;
    self.labels[8].textAlignment = kMTTextAlignmentCenter;

    // Small font
    self.labels[9] = [self createMathLabel:@"\\frac{x^{2+3y}}{x^{2+4y}} = x^y \\times \\frac{z_1^{y+1}}{z_1^{y+1}}" withHeight:30];
    self.labels[9].fontSize = 10;
    self.labels[9].textAlignment = kMTTextAlignmentCenter;

    // Square root
    self.labels[10] = [self createMathLabel:@"5+\\sqrt{2}+3" withHeight:40];

    // Square root inside square roots and with fractions
    self.labels[11] = [self createMathLabel:@"\\sqrt{\\frac{\\sqrt{\\frac{1}{2}} + 3}{\\sqrt5^x}}+\\sqrt{3x}+x^{\\sqrt2}" withHeight:90];

    // General root
    self.labels[12] = [self createMathLabel:@"\\sqrt[3]{24} + 3\\sqrt{2}24" withHeight:40];

    // Fractions and formulae in root
    self.labels[13] = [self createMathLabel:@"\\sqrt[x+\\frac{3}{4}]{\\frac{2}{4}+1}" withHeight:60];

    // Non-symbol operators with no limits
    self.labels[14] = [self createMathLabel:@"\\sin^2(\\theta)=\\log_3^2(\\pi)" withHeight:60];

    // Non-symbol operators with limits
    self.labels[15] = [self createMathLabel:@"\\lim_{x\\to\\infty}\\frac{e^2}{1-x}=\\limsup_{\\sigma}5" withHeight:60];

    // Symbol operators with limits
    self.labels[16] = [self createMathLabel:@"\\sum_{n=1}^{\\infty}\\frac{1+n}{1-n}=\\bigcup_{A\\in\\Im}C\\cup B" withHeight:60];

    // Symbol operators with limits text style
    self.labels[17] = [self createMathLabel:@"\\sum_{n=1}^{\\infty}\\frac{1+n}{1-n}=\\bigcup_{A\\in\\Im}C\\cup B" withHeight:60];
    self.labels[17].labelMode = kMTMathUILabelModeText;

    // Non-symbol operators with limits text style
    self.labels[18] = [self createMathLabel:@"\\lim_{x\\to\\infty}\\frac{e^2}{1-x}=\\limsup_{\\sigma}5" withHeight:60];
    self.labels[18].labelMode = kMTMathUILabelModeText;

    // Symbol operators with no limits
    self.labels[19] = [self createMathLabel:@"\\int_{0}^{\\infty}e^x \\,dx=\\oint_0^{\\Delta}5\\Gamma" withHeight:60];

    // Test italic correction for large ops
    self.labels[20] = [self createMathLabel:@"\\int\\int\\int^{\\infty}\\int_0\\int^{\\infty}_0\\int" withHeight:60];

    // Test italic correction for superscript/subscript
    self.labels[21] = [self createMathLabel:@"U_3^2UY_3^2U_3Y^2f_1f^2ff" withHeight:60];

    // Error
    self.labels[22] = [self createMathLabel:@"\\notacommand" withHeight:30];
    
    self.labels[23] = [self createMathLabel:@"\\sqrt{1}" withHeight:20];
    self.labels[24] = [self createMathLabel:@"\\sqrt[|]{1}" withHeight:20];
    self.labels[25] = [self createMathLabel:@"{n \\choose k}" withHeight:60];
    self.labels[26] = [self createMathLabel:@"{n \\choose k}" withHeight:30];
    self.labels[26].labelMode = kMTMathUILabelModeText;
    self.labels[27] = [self createMathLabel:@"\\left({n \\atop k}\\right)" withHeight:40];
    self.labels[28] = [self createMathLabel:@"\\left({n \\atop k}\\right)" withHeight:30];
    self.labels[28].labelMode = kMTMathUILabelModeText;
    self.labels[29] = [self createMathLabel:@"\\underline{xyz}+\\overline{abc}" withHeight:30];
    self.labels[30] = [self createMathLabel:@"\\underline{\\frac12}+\\overline{\\frac34}" withHeight:50];
    self.labels[31] = [self createMathLabel:@"\\underline{x^\\overline{y}_\\overline{z}+5}" withHeight:50];
    
    // spacing examples from the TeX book
    self.labels[32] = [self createMathLabel:@"\\int\\!\\!\\!\\int_D dx\\,dy" withHeight:50];
    // no spacing
    self.labels[33] = [self createMathLabel:@"\\int\\int_D dxdy" withHeight:50];
    self.labels[34] = [self createMathLabel:@"y\\,dx-x\\,dy" withHeight:30];
    self.labels[35] = [self createMathLabel:@"y dx - x dy" withHeight:30];
    
    // large spaces
    self.labels[36] = [self createMathLabel:@"hello\\ from \\quad the \\qquad other\\ side" withHeight:30];

    // Accents
    self.labels[37] = [self createMathLabel:@"\\vec x \\; \\hat y \\; \\breve {x^2} \\; \\tilde x \\tilde x^2 x^2 " withHeight:30];
    self.labels[38] = [self createMathLabel:@"\\hat{xyz} \\; \\widehat{xyz}\\; \\vec{2ab}" withHeight:30];
    self.labels[39] = [self createMathLabel:@"\\hat{\\frac12} \\; \\hat{\\sqrt 3}" withHeight:50];

    // large roots
    self.labels[40] = [self createMathLabel:@"\\colorbox{#f0f0e0}{\\sqrt{1+\\colorbox{#d0c0d0}{\\sqrt{1+\\colorbox{#a080c0}{\\sqrt{1+\\colorbox{#7050a0}{\\sqrt{1+\\colorbox{403060}{\\colorbox{#102000}{\\sqrt{1+\\cdots}}}}}}}}}}}" withHeight:80];
    
    self.labels[41] = [self createMathLabel:@"\\begin{bmatrix}"
                           "a & b\\\\ c & d \\\\ e & f \\\\ g &  h \\\\ i & j"
                           "\\end{bmatrix}"
                                     withHeight:120];
    self.labels[42] = [self createMathLabel:@"x{\\scriptstyle y}z" withHeight:30];
    self.labels[43] = [self createMathLabel:@"x \\mathrm x \\mathbf x \\mathcal X \\mathfrak x \\mathsf x \\bm x \\mathtt x \\mathit \\Lambda \\cal g" withHeight:30];
    self.labels[44] = [self createMathLabel:@"\\mathrm{using\\ mathrm}" withHeight:30];
    self.labels[45] = [self createMathLabel:@"\\text{using text}" withHeight:30];
    self.labels[46] = [self createMathLabel:@"\\text{Mary has }\\$500 + \\$200." withHeight:30];
    
    self.labels[47] = [self createMathLabel:@"\\colorbox{#888888}{\\begin{pmatrix}"
                       "\\colorbox{#ff0000}{a} & \\colorbox{#00ff00}{b} \\\\"
                       "\\colorbox{#00aaff}{c} & \\colorbox{#f0f0f0}{d}"
                       "\\end{pmatrix}}"
                                 withHeight:70];

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
