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

@interface ViewController ()

@property (nonatomic, nonnull) NSMutableArray<MTMathUILabel*>* demoLabels;
@property (nonatomic, nonnull) NSMutableArray<MTMathUILabel*>* labels;

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

    UIView* contentView = [[UIView alloc] init];
    [self addFullSizeView:contentView to:self.scrollView];
    // set the size of the content view
    // Disable horizontal scrolling.
    [self setEqualWidths:contentView andView:self.scrollView];
    [self setHeight:2880 forView:contentView];


    // Demo formulae
    // Quadratic formula
    self.demoLabels[0] = [self createMathLabel:@"x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}" withHeight:60];
    [self addLabelAsSubview:self.demoLabels[0] to:contentView];
    self.demoLabels[0].fontSize = 15;
    // This is first label so set the height from the top
    UIView* view = self.demoLabels[0];
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(30)-[view]"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:views]];


    self.demoLabels[1] = [self createMathLabel:@"(a_1+a_2)^2=a_1^2+2a_1a_2+a_2^2" withHeight:40];

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

    self.demoLabels[8] = [self createMathLabel:@"\\int_{-\\infty}^\\infty e^{-x^2} dx = \\sqrt{\\pi}" withHeight:40];

    self.demoLabels[9] = [self createMathLabel:@"\\frac 1 n \\sum_{i=1}^{n}x_i \\geq \\sqrt[n]{\\prod_{i=1}^{n}x_i}" withHeight:60];

    self.demoLabels[10] = [self createMathLabel:@"f^{(n)}(z_0) = \\frac{n!}{2\\pi i}\\oint_\\gamma\\frac{f(z)}{(z-z_0)^{n+1}}dz" withHeight:40];

    self.demoLabels[11] = [self createMathLabel:@"i\\hbar\\frac{\\partial}{\\partial t}\\Psi(x,t) = -\\frac{\\hbar}{2m}\\nabla^2\\Psi(x,t) + V(x)\\Psi(x,t)" withHeight:40];
    
    self.demoLabels[12] = [self createMathLabel:@"\\left(\\sum_{k=1}^n a_k b_k \\right)^2 \\le \\left(\\sum_{k=1}^n a_k^2\\right)\\left(\\sum_{k=1}^n b_k^2\\right)" withHeight:60];
    
    self.demoLabels[13] = [self createMathLabel:@"{n \\brace k} = \\frac{1}{k!}\\sum_{j=0}^k (-1)^{k-j}\\binom{k}{j}(k-j)^n" withHeight:60];

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
    self.labels[3].paddingRight = 20;

    self.labels[4] = [self createMathLabel:@"-h - (5xy+2) = z" withHeight:40];

    // Text mode fraction
    self.labels[5] = [self createMathLabel:@"\\frac12x + \\frac{3\\div4}2y = 25" withHeight:60];
    self.labels[5].labelMode = kMTMathUILabelModeText;


    // Display mode fraction
    self.labels[6] = [self createMathLabel:@"\\frac{x+\\frac{12}{5}}{y}+\\frac1z = \\frac{xz+y+\\frac{12}{5}z}{yz}" withHeight:60];
    self.labels[6].backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    self.labels[6].paddingLeft = 20;

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
    self.labels[19] = [self createMathLabel:@"\\int_{0}^{\\infty}e^x dx=\\oint_0^{\\Delta}5\\Gamma" withHeight:60];

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
- (IBAction)latinButtonPressed:(id)sender
{
    for (MTMathUILabel* label in self.demoLabels) {
        label.font = [[MTFontManager fontManager] latinModernFontWithSize:label.font.fontSize];
    }
    for (MTMathUILabel* label in self.labels) {
        label.font = [[MTFontManager fontManager] latinModernFontWithSize:label.font.fontSize];
    }
}

- (IBAction)termesButtonPressed:(id)sender
{
    for (MTMathUILabel* label in self.demoLabels) {
        label.font = [[MTFontManager fontManager] termesFontWithSize:label.font.fontSize];
    }
    for (MTMathUILabel* label in self.labels) {
        label.font = [[MTFontManager fontManager] termesFontWithSize:label.font.fontSize];
    }
}

- (IBAction)xitsButtonPressed:(id)sender
{
    for (MTMathUILabel* label in self.demoLabels) {
        label.font = [[MTFontManager fontManager] xitsFontWithSize:label.font.fontSize];
    }
    for (MTMathUILabel* label in self.labels) {
        label.font = [[MTFontManager fontManager] xitsFontWithSize:label.font.fontSize];
    }
}

@end
