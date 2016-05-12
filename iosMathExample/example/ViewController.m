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
#import "MTMathListBuilder.h"

@interface ViewController ()

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    CGRect frame = [UIApplication sharedApplication].keyWindow.bounds;
    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:frame];
    self.view = scrollView;

    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 1080)];
    [scrollView addSubview:view];
    [scrollView setContentSize:view.frame.size];
    
    MTMathUILabel* label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 10, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.mathList = [MTMathListBuilder buildFromString:@"3+2-5 = 0"];
    [self.view addSubview:label];
    
    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 80, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.textAlignment = kMTTextAlignmentCenter;
    label.paddingLeft = 20;
    label.mathList = [MTMathListBuilder buildFromString:@"12+-3 > +14"];
    [self.view addSubview:label];
    
    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 150, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.textAlignment = kMTTextAlignmentRight;
    label.paddingRight = 20;
    label.mathList = [MTMathListBuilder buildFromString:@"5\\times(-2 \\div 1) = -10"];
    [self.view addSubview:label];
    
    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 220, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.mathList = [MTMathListBuilder buildFromString:@"-h - (5xy+2) = z"];
    [self.view addSubview:label];

    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 290, 400, 60)];
    label.labelMode = kMTMathUILabelModeText;
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.mathList = [MTMathListBuilder buildFromString:@"\\frac12x + \\frac{3\\div4}2y = 25"];
    [self.view addSubview:label];

    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 360, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.paddingLeft = 20;
    label.mathList = [MTMathListBuilder buildFromString:@"\\frac{x+\\frac{12}{5}}{y}+\\frac1z = \\frac{xz+y+\\frac{12}{5}z}{yz}"];
    [self.view addSubview:label];
    
    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 430, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.mathList = [MTMathListBuilder buildFromString:@"(a_1+a_2)^2=a_1^2+a_2^2+2a_1a_2"];
    [self.view addSubview:label];
    
    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 500, 400, 90)];
    label.fontSize = 30;
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.textAlignment = kMTTextAlignmentCenter;
    label.mathList = [MTMathListBuilder buildFromString:@"\\frac{x^{2+3y}}{x^{2+4y}} = x^y \\times \\frac{z_1^{y+1}}{z_1^{y+1}}"];
    [self.view addSubview:label];


    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 600, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.mathList = [MTMathListBuilder buildFromString:@"5+\\sqrt{2}+3"];
    [self.view addSubview:label];

    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 670, 400, 90)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.mathList = [MTMathListBuilder buildFromString:@"\\sqrt{\\frac{\\sqrt{\\frac{1}{2}} + 3}{\\sqrt5^x}}+\\sqrt{3x}+x^{\\sqrt2}"];
    [self.view addSubview:label];

    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 770, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.mathList = [MTMathListBuilder buildFromString:@"3\\sqrt{2}24"];
    [self.view addSubview:label];

    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 840, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.mathList = [MTMathList new];
    label.mathList = [MTMathListBuilder buildFromString:@"\\sqrt[3]{24}"];
    [self.view addSubview:label];


    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 910, 400, 60)];
    label.backgroundColor = [UIColor colorWithHue:0.15 saturation:0.2 brightness:1.0 alpha:1.0];
    label.mathList = [MTMathList new];
    label.mathList = [MTMathListBuilder buildFromString:@"\\sqrt[x+\\frac{3}{4}]{\\frac{2}{4}+1}"];
    [self.view addSubview:label];

    label = [[MTMathUILabel alloc] initWithFrame:CGRectMake(10, 1000, 400, 60)];
    label.mathList = [MTMathListBuilder buildFromString:@"x = \\frac{-b + \\sqrt{b^2-4ac}}{2a}"];
    [self.view addSubview:label];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
