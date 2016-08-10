//
//  MTMathListBuilderTest.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

@import XCTest;

#import "MTMathListBuilder.h"

@interface MTMathListBuilderTest : XCTestCase

@end

@implementation MTMathListBuilderTest

- (void) checkAtomTypes:(MTMathList*) list types:(NSArray*) types desc:(NSString*) desc
{
    XCTAssertEqual(list.atoms.count, types.count, @"%@", desc);
    for (int i = 0; i < list.atoms.count; i++) {
        MTMathAtom *atom = list.atoms[i];
        XCTAssertNotNil(atom, @"%@", desc);
        XCTAssertEqualObjects(@(atom.type), types[i], @"%@", desc);
    }
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

static NSArray* getTestData() {
    return @[
             @[ @"x", @[ @(kMTMathAtomVariable) ] , @"x"],
             @[ @"1", @[ @(kMTMathAtomNumber) ] , @"1"],
             @[ @"*", @[ @(kMTMathAtomBinaryOperator) ] ,@"*"],
             @[ @"+", @[ @(kMTMathAtomBinaryOperator) ], @"+"],
             @[ @".", @[ @(kMTMathAtomNumber) ], @"." ],
             @[ @"(", @[ @(kMTMathAtomOpen) ], @"(" ],
             @[ @")", @[ @(kMTMathAtomClose) ], @")" ],
             @[ @",", @[ @(kMTMathAtomPunctuation)], @"," ],
             @[ @"!", @[ @(kMTMathAtomClose)], @"!" ],
             @[ @"=", @[ @(kMTMathAtomRelation)], @"=" ],
             @[ @"x+2", @[ @(kMTMathAtomVariable), @(kMTMathAtomBinaryOperator), @(kMTMathAtomNumber) ], @"x+2"],
             // spaces are ignored
             @[ @"(2.3 * 8)", @[ @(kMTMathAtomOpen), @(kMTMathAtomNumber), @(kMTMathAtomNumber), @(kMTMathAtomNumber), @(kMTMathAtomBinaryOperator), @(kMTMathAtomNumber) , @(kMTMathAtomClose) ], @"(2.3*8)"],
             // braces are just for grouping
             @[ @"5{3+4}", @[@(kMTMathAtomNumber), @(kMTMathAtomNumber), @(kMTMathAtomBinaryOperator), @(kMTMathAtomNumber)], @"53+4"],
             // commands
             @[ @"\\pi+\\theta\\geq 3",@[ @(kMTMathAtomVariable), @(kMTMathAtomBinaryOperator), @(kMTMathAtomVariable), @(kMTMathAtomRelation), @(kMTMathAtomNumber)], @"\\pi +\\theta \\geq 3"],
             // aliases
             @[ @"\\pi\\ne 5 \\land 3", @[ @(kMTMathAtomVariable), @(kMTMathAtomRelation), @(kMTMathAtomNumber), @(kMTMathAtomBinaryOperator), @(kMTMathAtomNumber)], @"\\pi \\neq 5\\wedge 3"],
             // control space
             @[ @"x \\ y", @[  @(kMTMathAtomVariable), @(kMTMathAtomOrdinary), @(kMTMathAtomVariable)], @"x\\  y"],
             // spacing
             @[ @"x \\quad y \\; z \\! q", @[  @(kMTMathAtomVariable), @(kMTMathAtomSpace), @(kMTMathAtomVariable),@(kMTMathAtomSpace), @(kMTMathAtomVariable),@(kMTMathAtomSpace), @(kMTMathAtomVariable)], @"x\\quad y\\; z\\! q"],
             ];
}


- (void) testBuilder
{
    NSArray* data = getTestData();
    for (NSArray* testCase in data) {
        NSString* str = testCase[0];
        NSError* error;
        MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
        XCTAssertNil(error);
        NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
        NSArray* atomTypes = testCase[1];
        [self checkAtomTypes:list types:atomTypes desc:desc];
        
        // convert it back to latex
        NSString* latex = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(latex, testCase[2], @"%@", desc);
    }
}

static NSArray* getTestDataSuperScript() {
    return @[
             @[ @"x^2", @[ @(kMTMathAtomVariable) ],  @[ @(kMTMathAtomNumber) ], @"x^{2}"],
             @[ @"x^23", @[ @(kMTMathAtomVariable), @(kMTMathAtomNumber) ],  @[ @(kMTMathAtomNumber) ], @"x^{2}3"],
             @[ @"x^{23}", @[ @(kMTMathAtomVariable) ],  @[ @(kMTMathAtomNumber), @(kMTMathAtomNumber) ], @"x^{23}"],
             @[ @"x^2^3", @[ @(kMTMathAtomVariable), @(kMTMathAtomOrdinary) ],  @[ @(kMTMathAtomNumber) ], @"x^{2}{}^{3}" ],
             @[ @"x^{2^3}", @[ @(kMTMathAtomVariable) ], @[ @(kMTMathAtomNumber)], @[ @(kMTMathAtomNumber),], @"x^{2^{3}}"],
             @[ @"x^{^2*}", @[ @(kMTMathAtomVariable) ], @[ @(kMTMathAtomOrdinary), @(kMTMathAtomBinaryOperator)], @[ @(kMTMathAtomNumber),], @"x^{{}^{2}*}"],
             @[ @"^2", @ [ @(kMTMathAtomOrdinary)], @[ @(kMTMathAtomNumber) ], @"{}^{2}"],
             @[ @"{}^2", @ [ @(kMTMathAtomOrdinary)], @[ @(kMTMathAtomNumber) ], @"{}^{2}"],
             @[ @"x^^2", @[ @(kMTMathAtomVariable), @(kMTMathAtomOrdinary) ],  @[ ], @"x^{}{}^{2}"],
             @[ @"5{x}^2", @ [ @(kMTMathAtomNumber), @(kMTMathAtomVariable)], @[ ], @"5x^{2}"],
             ];
}

- (void) testSuperScript
{
    NSArray* data = getTestDataSuperScript();
    for (NSArray* testCase in data) {
        NSString* str = testCase[0];
        NSError* error;
        MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
        XCTAssertNil(error);
        NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
        NSArray* atomTypes = testCase[1];
        [self checkAtomTypes:list types:atomTypes desc:desc];
        
        // get the first atom
        MTMathAtom* first = list.atoms[0];
        // check it's superscript
        NSArray* types = testCase[2];
        if (types.count > 0) {
            XCTAssertNotNil(first.superScript, @"%@", desc);
        }
        MTMathList* superlist = first.superScript;
        [self checkAtomTypes:superlist types:testCase[2] desc:desc];
        
        if (testCase.count == 5) {
            // one more level
            MTMathAtom* superFirst = superlist.atoms[0];
            MTMathList* supersuperList = superFirst.superScript;
            [self checkAtomTypes:supersuperList types:testCase[3] desc:desc];
        }
        
        // convert it back to latex
        NSString* latex = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(latex, [testCase lastObject], @"%@", desc);
    }
}

static NSArray* getTestDataSubScript() {
    return @[
             @[ @"x_2", @[ @(kMTMathAtomVariable) ],  @[ @(kMTMathAtomNumber) ], @"x_{2}" ],
             @[ @"x_23", @[ @(kMTMathAtomVariable), @(kMTMathAtomNumber) ],  @[ @(kMTMathAtomNumber) ], @"x_{2}3"],
             @[ @"x_{23}", @[ @(kMTMathAtomVariable) ],  @[ @(kMTMathAtomNumber), @(kMTMathAtomNumber) ], @"x_{23}"],
             @[ @"x_2_3", @[ @(kMTMathAtomVariable) , @(kMTMathAtomOrdinary)],  @[ @(kMTMathAtomNumber) ], @"x_{2}{}_{3}" ],
             @[ @"x_{2_3}", @[ @(kMTMathAtomVariable) ], @[ @(kMTMathAtomNumber)], @[ @(kMTMathAtomNumber),], @"x_{2_{3}}"],
             @[ @"x_{_2*}", @[ @(kMTMathAtomVariable) ], @[ @(kMTMathAtomOrdinary), @(kMTMathAtomBinaryOperator)], @[ @(kMTMathAtomNumber),], @"x_{{}_{2}*}"],
             @[ @"_2", @ [ @(kMTMathAtomOrdinary)], @[ @(kMTMathAtomNumber) ], @"{}_{2}" ],
             @[ @"{}_2", @ [ @(kMTMathAtomOrdinary)], @[ @(kMTMathAtomNumber) ], @"{}_{2}" ],
             @[ @"x__2", @[ @(kMTMathAtomVariable), @(kMTMathAtomOrdinary) ],  @[ ], @"x_{}{}_{2}"],
             @[ @"5{x}_2", @ [ @(kMTMathAtomNumber), @(kMTMathAtomVariable)], @[ ], @"5x_{2}"],
             ];
}

- (void) testSubScript
{
    NSArray* data = getTestDataSubScript();
    for (NSArray* testCase in data) {
        NSString* str = testCase[0];
        NSError* error;
        MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
        XCTAssertNil(error);
        
        NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
        NSArray* atomTypes = testCase[1];
        [self checkAtomTypes:list types:atomTypes desc:desc];
        
        // get the first atom
        MTMathAtom* first = list.atoms[0];
        // check it's superscript
        NSArray* types = testCase[2];
        if (types.count > 0) {
            XCTAssertNotNil(first.subScript, @"%@", desc);
        }
        MTMathList* sublist = first.subScript;
        [self checkAtomTypes:sublist types:testCase[2] desc:desc];
        
        if (testCase.count == 5) {
            // one more level
            MTMathAtom* subFirst = sublist.atoms[0];
            MTMathList* subsubList = subFirst.subScript;
            [self checkAtomTypes:subsubList types:testCase[3] desc:desc];
        }
        
        // convert it back to latex
        NSString* latex = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(latex, [testCase lastObject], @"%@", desc);
    }
}

static NSArray* getTestDataSuperSubScript() {
    return @[
             @[ @"x_2^*", @[ @(kMTMathAtomVariable) ],  @[ @(kMTMathAtomNumber) ], @[ @(kMTMathAtomBinaryOperator) ], @"x^{*}_{2}" ],
             @[ @"x^*_2", @[ @(kMTMathAtomVariable) ],  @[ @(kMTMathAtomNumber) ], @[ @(kMTMathAtomBinaryOperator) ], @"x^{*}_{2}" ],
             @[ @"x_^*", @[ @(kMTMathAtomVariable) ],  @[ ], @[ @(kMTMathAtomBinaryOperator) ], @"x^{*}_{}" ],
             @[ @"x^_2", @[ @(kMTMathAtomVariable) ],  @[ @(kMTMathAtomNumber)], @[ ], @"x^{}_{2}"],
             @[ @"x_{2^*}", @[ @(kMTMathAtomVariable) ],  @[ @(kMTMathAtomNumber)], @[ ], @"x_{2^{*}}"],
             @[ @"x^{*_2}", @[ @(kMTMathAtomVariable) ], @[ ], @[ @(kMTMathAtomBinaryOperator),], @"x^{*_{2}}"],
             @[ @"_2^*", @ [ @(kMTMathAtomOrdinary)], @[ @(kMTMathAtomNumber) ], @[ @(kMTMathAtomBinaryOperator) ], @"{}^{*}_{2}"],
             ];
}

- (void) testSuperSubScript
{
    NSArray* data = getTestDataSuperSubScript();
    for (NSArray* testCase in data) {
        NSString* str = testCase[0];
        MTMathList* list = [MTMathListBuilder buildFromString:str];
        NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
        NSArray* atomTypes = testCase[1];
        [self checkAtomTypes:list types:atomTypes desc:desc];
        
        // get the first atom
        MTMathAtom* first = list.atoms[0];

        NSArray* subscript = testCase[2];
        if (subscript.count > 0) {
            XCTAssertNotNil(first.subScript, @"%@", desc);
            MTMathList* sublist = first.subScript;
            [self checkAtomTypes:sublist types:subscript desc:desc];
        }
        NSArray* superscript = testCase[3];
        if (superscript.count > 0) {
            XCTAssertNotNil(first.superScript, @"%@", desc);
            MTMathList* sublist = first.superScript;
            [self checkAtomTypes:sublist types:superscript desc:desc];
        }
        
        // convert it back to latex
        NSString* latex = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(latex, [testCase lastObject], @"%@", desc);
    }
}

- (void) testSymbols
{
    NSString *str = @"5\\times3^{2\\div2}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @3, @"%@", desc);
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"5", @"%@", desc);
    atom = list.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomBinaryOperator, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"\u00D7", @"%@", desc);
    atom = list.atoms[2];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"3", @"%@", desc);
    
    // super script
    MTMathList* superList = atom.superScript;
    XCTAssertNotNil(superList, @"%@", desc);
    XCTAssertEqualObjects(@(superList.atoms.count), @3, @"%@", desc);
    atom = superList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"2", @"%@", desc);
    atom = superList.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomBinaryOperator, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"\u00F7", @"%@", desc);
    atom = superList.atoms[2];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"2", @"%@", desc);
}

- (void) testFrac
{
    NSString *str = @"\\frac1c";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertTrue(frac.hasRule);
    XCTAssertNil(frac.rightDelimiter);
    XCTAssertNil(frac.leftDelimiter);
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"1", @"%@", desc);
    
    atom = list.atoms[0];
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"c", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\frac{1}{c}", @"%@", desc);
}

- (void) testFracInFrac
{
    NSString *str = @"\\frac1\\frac23";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertTrue(frac.hasRule);
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"1", @"%@", desc);
    
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    frac = subList.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    
    
    subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"2", @"%@", desc);
    
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"3", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\frac{1}{\\frac{2}{3}}", @"%@", desc);
}

- (void) testSqrt
{
    NSString *str = @"\\sqrt2";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTRadical* rad = list.atoms[0];
    XCTAssertEqual(rad.type, kMTMathAtomRadical, @"%@", desc);
    XCTAssertEqualObjects(rad.nucleus, @"", @"%@", desc);

    MTMathList *subList = rad.radicand;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"2", @"%@", desc);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\sqrt{2}", @"%@", desc);
}

- (void) testSqrtInSqrt
{
    NSString *str = @"\\sqrt\\sqrt2";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTRadical* rad = list.atoms[0];
    XCTAssertEqual(rad.type, kMTMathAtomRadical, @"%@", desc);
    XCTAssertEqualObjects(rad.nucleus, @"", @"%@", desc);

    MTMathList *subList = rad.radicand;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    rad = subList.atoms[0];
    XCTAssertEqual(rad.type, kMTMathAtomRadical, @"%@", desc);
    XCTAssertEqualObjects(rad.nucleus, @"", @"%@", desc);


    subList = rad.radicand;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom* atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"2", @"%@", desc);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\sqrt{\\sqrt{2}}", @"%@", desc);
}

- (void) testRad
{
    NSString *str = @"\\sqrt[3]2";
    MTMathList* list = [MTMathListBuilder buildFromString:str];

    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTRadical* rad = list.atoms[0];
    XCTAssertEqual(rad.type, kMTMathAtomRadical);
    XCTAssertEqualObjects(rad.nucleus, @"");

    MTMathList *subList = rad.radicand;
    XCTAssertNotNil(subList);
    XCTAssertEqualObjects(@(subList.atoms.count), @1);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber);
    XCTAssertEqualObjects(atom.nucleus, @"2");

    subList = rad.degree;
    XCTAssertNotNil(subList);
    XCTAssertEqualObjects(@(subList.atoms.count), @1);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber);
    XCTAssertEqualObjects(atom.nucleus, @"3");

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\sqrt[3]{2}");
}

static NSArray* getTestDataLeftRight() {
    return @[
             @[@"\\left( 2 \\right)", @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomNumber)], @"(", @")", @"\\left( 2\\right) "],
             // spacing
             @[@"\\left ( 2 \\right )", @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomNumber)], @"(", @")", @"\\left( 2\\right) "],
             // commands
             @[@"\\left\\{ 2 \\right\\}", @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomNumber)], @"{", @"}", @"\\left\\{ 2\\right\\} "],
             // complex commands
             @[@"\\left\\langle x \\right\\rangle", @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomVariable)], @"\u2329", @"\u232A", @"\\left< x\\right> "],
             // bars
             @[@"\\left| x \\right\\|", @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomVariable)], @"|", @"\u2016", @"\\left| x\\right\\| "],
             // inner in between
             @[@"5 + \\left( 2 \\right) - 2", @[ @(kMTMathAtomNumber), @(kMTMathAtomBinaryOperator), @(kMTMathAtomInner), @(kMTMathAtomBinaryOperator), @(kMTMathAtomNumber) ], @2, @[ @(kMTMathAtomNumber)], @"(", @")", @"5+\\left( 2\\right) -2"],
             // long inner
             @[@"\\left( 2 + \\frac12\\right)", @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomNumber), @(kMTMathAtomBinaryOperator), @(kMTMathAtomFraction)], @"(", @")", @"\\left( 2+\\frac{1}{2}\\right) "],
             // nested
             @[@"\\left[ 2 + \\left|\\frac{-x}{2}\\right| \\right]", @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomNumber), @(kMTMathAtomBinaryOperator), @(kMTMathAtomInner)], @"[", @"]", @"\\left[ 2+\\left| \\frac{-x}{2}\\right| \\right] "],
             // With scripts
             @[@"\\left( 2 \\right)^2", @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomNumber)], @"(", @")", @"\\left( 2\\right) ^{2}"],
             // Scripts on left
             @[@"\\left(^2 \\right )", @[ @(kMTMathAtomInner)], @0, @[ @(kMTMathAtomOrdinary)], @"(", @")", @"\\left( {}^{2}\\right) "],
             // Dot
             @[@"\\left( 2 \\right.", @[ @(kMTMathAtomInner)], @0, @[ @(kMTMathAtomNumber)], @"(", @"", @"\\left( 2\\right. "],
        ];
}

- (void) testLeftRight
{
    NSArray* data = getTestDataLeftRight();
    for (NSArray* testCase in data) {
        NSString* str = testCase[0];
        
        NSError* error;
        MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
        
        XCTAssertNotNil(list, @"%@", str);
        XCTAssertNil(error, @"%@", str);
        
        [self checkAtomTypes:list types:testCase[1] desc:[NSString stringWithFormat:@"%@ outer", str]];

        NSNumber* innerLoc = testCase[2];
        MTInner* inner = list.atoms[innerLoc.intValue];
        XCTAssertEqual(inner.type, kMTMathAtomInner, @"%@", str);
        XCTAssertEqualObjects(inner.nucleus, @"", @"%@", str);
    
        MTMathList* innerList = inner.innerList;
        XCTAssertNotNil(innerList, @"%@", str);
        [self checkAtomTypes:innerList types:testCase[3] desc:[NSString stringWithFormat:@"%@ inner", str]];
        
        XCTAssertNotNil(inner.leftBoundary, @"%@", str);
        XCTAssertEqual(inner.leftBoundary.type, kMTMathAtomBoundary, @"%@", str);
        XCTAssertEqualObjects(inner.leftBoundary.nucleus, testCase[4], @"%@", str);
        
        XCTAssertNotNil(inner.rightBoundary, @"%@", str);
        XCTAssertEqual(inner.rightBoundary.type, kMTMathAtomBoundary, @"%@", str);
        XCTAssertEqualObjects(inner.rightBoundary.nucleus, testCase[5], @"%@", str);
        
        // convert it back to latex
        NSString* latex = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(latex, testCase[6], @"%@", str);
    }
}

- (void) testOver
{
    NSString *str = @"1 \\over c";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertTrue(frac.hasRule);
    XCTAssertNil(frac.rightDelimiter);
    XCTAssertNil(frac.leftDelimiter);
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"1", @"%@", desc);
    
    atom = list.atoms[0];
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"c", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\frac{1}{c}", @"%@", desc);
}

- (void) testOverInParens
{
    NSString *str = @"5 + {1 \\over c} + 8";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @5, @"%@", desc);
    NSArray* types = @[@(kMTMathAtomNumber), @(kMTMathAtomBinaryOperator), @(kMTMathAtomFraction), @(kMTMathAtomBinaryOperator), @(kMTMathAtomNumber)];
    [self checkAtomTypes:list types:types desc:desc];
    
    MTFraction* frac = list.atoms[2];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertTrue(frac.hasRule);
    XCTAssertNil(frac.rightDelimiter);
    XCTAssertNil(frac.leftDelimiter);
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"1", @"%@", desc);
    
    atom = list.atoms[0];
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"c", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"5+\\frac{1}{c}+8", @"%@", desc);
}

- (void) testAtop
{
    NSString *str = @"1 \\atop c";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertFalse(frac.hasRule);
    XCTAssertNil(frac.rightDelimiter);
    XCTAssertNil(frac.leftDelimiter);
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"1", @"%@", desc);
    
    atom = list.atoms[0];
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"c", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"{1 \\atop c}", @"%@", desc);
}

- (void) testAtopInParens
{
    NSString *str = @"5 + {1 \\atop c} + 8";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @5, @"%@", desc);
    NSArray* types = @[@(kMTMathAtomNumber), @(kMTMathAtomBinaryOperator), @(kMTMathAtomFraction), @(kMTMathAtomBinaryOperator), @(kMTMathAtomNumber)];
    [self checkAtomTypes:list types:types desc:desc];
    
    MTFraction* frac = list.atoms[2];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertFalse(frac.hasRule);
    XCTAssertNil(frac.rightDelimiter);
    XCTAssertNil(frac.leftDelimiter);
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"1", @"%@", desc);
    
    atom = list.atoms[0];
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"c", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"5+{1 \\atop c}+8", @"%@", desc);
}

- (void) testChoose
{
    NSString *str = @"n \\choose k";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertFalse(frac.hasRule);
    XCTAssertEqualObjects(frac.rightDelimiter, @")");
    XCTAssertEqualObjects(frac.leftDelimiter, @"(");
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"n", @"%@", desc);
    
    atom = list.atoms[0];
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"k", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"{n \\choose k}", @"%@", desc);
}

- (void) testBrack
{
    NSString *str = @"n \\brack k";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertFalse(frac.hasRule);
    XCTAssertEqualObjects(frac.rightDelimiter, @"]");
    XCTAssertEqualObjects(frac.leftDelimiter, @"[");
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"n", @"%@", desc);
    
    atom = list.atoms[0];
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"k", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"{n \\brack k}", @"%@", desc);
}

- (void) testBrace
{
    NSString *str = @"n \\brace k";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertFalse(frac.hasRule);
    XCTAssertEqualObjects(frac.rightDelimiter, @"}");
    XCTAssertEqualObjects(frac.leftDelimiter, @"{");
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"n", @"%@", desc);
    
    atom = list.atoms[0];
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"k", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"{n \\brace k}", @"%@", desc);
}

- (void) testBinom
{
    NSString *str = @"\\binom{n}{k}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"%@", desc);
    XCTAssertEqualObjects(frac.nucleus, @"", @"%@", desc);
    XCTAssertFalse(frac.hasRule);
    XCTAssertEqualObjects(frac.rightDelimiter, @")");
    XCTAssertEqualObjects(frac.leftDelimiter, @"(");
    
    MTMathList *subList = frac.numerator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"n", @"%@", desc);
    
    atom = list.atoms[0];
    subList = frac.denominator;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"k", @"%@", desc);
    
    // convert it back to latex (binom converts to choose)
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"{n \\choose k}", @"%@", desc);
}

- (void) testOverLine
{
    NSString *str = @"\\overline 2";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTOverLine* over = list.atoms[0];
    XCTAssertEqual(over.type, kMTMathAtomOverline, @"%@", desc);
    XCTAssertEqualObjects(over.nucleus, @"", @"%@", desc);
    
    MTMathList *subList = over.innerList;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"2", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\overline{2}", @"%@", desc);
}

- (void) testUnderline
{
    NSString *str = @"\\underline 2";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTUnderLine* under = list.atoms[0];
    XCTAssertEqual(under.type, kMTMathAtomUnderline, @"%@", desc);
    XCTAssertEqualObjects(under.nucleus, @"", @"%@", desc);
    
    MTMathList *subList = under.innerList;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"2", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\underline{2}", @"%@", desc);
}

- (void) testAccent
{
    NSString *str = @"\\bar x";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTAccent* accent = list.atoms[0];
    XCTAssertEqual(accent.type, kMTMathAtomAccent, @"%@", desc);
    XCTAssertEqualObjects(accent.nucleus, @"\u0304", @"%@", desc);
    
    MTMathList *subList = accent.innerList;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @1, @"%@", desc);
    MTMathAtom *atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"x", @"%@", desc);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\bar{x}", @"%@", desc);
}

- (void) testMathSpace
{
    NSString *str = @"\\!";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTMathSpace* space = list.atoms[0];
    XCTAssertEqual(space.type, kMTMathAtomSpace, @"%@", desc);
    XCTAssertEqualObjects(space.nucleus, @"", @"%@", desc);
    XCTAssertEqual(space.space, -3);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\! ", @"%@", desc);
}

- (void) testMathStyle
{
    NSString *str = @"\\textstyle y \\scriptstyle x";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @4, @"%@", desc);
    MTMathStyle* style = list.atoms[0];
    XCTAssertEqual(style.type, kMTMathAtomStyle, @"%@", desc);
    XCTAssertEqualObjects(style.nucleus, @"", @"%@", desc);
    XCTAssertEqual(style.style, kMTLineStyleText);
    
    MTMathStyle* style2 = list.atoms[2];
    XCTAssertEqual(style2.type, kMTMathAtomStyle, @"%@", desc);
    XCTAssertEqualObjects(style2.nucleus, @"", @"%@", desc);
    XCTAssertEqual(style2.style, kMTLineStyleScript);
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\textstyle y\\scriptstyle x", @"%@", desc);
}

static NSArray* getTestDataParseErrors() {
    return @[
              @[@"}a", @(MTParseErrorMismatchBraces)],
              @[@"\\notacommand", @(MTParseErrorInvalidCommand)],
              @[@"\\sqrt[5+3", @(MTParseErrorCharacterNotFound)],
              @[@"{5+3", @(MTParseErrorMismatchBraces)],
              @[@"5+3}", @(MTParseErrorMismatchBraces)],
              @[@"{1+\\frac{3+2", @(MTParseErrorMismatchBraces)],
              @[@"1+\\left", @(MTParseErrorMissingDelimiter)],
              @[@"\\left(\\frac12\\right", @(MTParseErrorMissingDelimiter)],
              @[@"\\left 5 + 3 \\right)", @(MTParseErrorInvalidDelimiter)],
              @[@"\\left(\\frac12\\right + 3", @(MTParseErrorInvalidDelimiter)],
              @[@"\\left\\lmoustache 5 + 3 \\right)", @(MTParseErrorInvalidDelimiter)],
              @[@"\\left(\\frac12\\right\\rmoustache + 3", @(MTParseErrorInvalidDelimiter)],
              @[@"5 + 3 \\right)", @(MTParseErrorMissingLeft)],
              @[@"\\left(\\frac12", @(MTParseErrorMissingRight)],
              @[@"\\left(5 + \\left| \\frac12 \\right)", @(MTParseErrorMissingRight)],
              @[@"5+ \\left|\\frac12\\right| \\right)", @(MTParseErrorMissingLeft)],
              ];
};

- (void) testErrors
{
        NSArray* data = getTestDataParseErrors();
        for (NSArray* testCase in data) {
            NSString* str = testCase[0];
            NSError* error = nil;
            MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
            NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
            XCTAssertNil(list, @"%@", desc);
            XCTAssertNotNil(error, @"%@", desc);
            XCTAssertEqual(error.domain, MTParseError, @"%@", desc);
            NSNumber* num = testCase[1];
            NSInteger code = [num integerValue];
            XCTAssertEqual(error.code, code, @"%@", desc);
        }
}

@end
