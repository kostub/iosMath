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
#import "MTMathAtomFactory.h"

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

- (void) testMatrix
{
    NSString *str = @"\\begin{matrix} x & y \\\\ z & w \\end{matrix}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    
    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTMathTable* table = list.atoms[0];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    XCTAssertEqualObjects(table.nucleus, @"");
    XCTAssertEqualObjects(table.environment, @"matrix");
    XCTAssertEqual(table.interRowAdditionalSpacing, 0);
    XCTAssertEqual(table.interColumnSpacing, 18);
    XCTAssertEqual(table.numRows, 2);
    XCTAssertEqual(table.numColumns, 2);
    
    for (int i = 0; i < 2; i++) {
        MTColumnAlignment alignment = [table getAlignmentForColumn:i];
        XCTAssertEqual(alignment, kMTColumnAlignmentCenter);
        for (int j = 0; j < 2; j++) {
            MTMathList* cell = table.cells[j][i];
            XCTAssertEqual(cell.atoms.count, 2);
            MTMathStyle* style = cell.atoms[0];
            XCTAssertEqual(style.type, kMTMathAtomStyle);
            XCTAssertEqual(style.style, kMTLineStyleText);
            
            MTMathAtom* atom = cell.atoms[1];
            XCTAssertEqual(atom.type, kMTMathAtomVariable);
        }
    }
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\begin{matrix}x&y\\\\ z&w\\end{matrix}");
}

- (void) testPMatrix
{
    NSString *str = @"\\begin{pmatrix} x & y \\\\ z & w \\end{pmatrix}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    
    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTInner* inner = list.atoms[0];
    XCTAssertEqual(inner.type, kMTMathAtomInner, @"%@", str);
    XCTAssertEqualObjects(inner.nucleus, @"", @"%@", str);
    
    MTMathList* innerList = inner.innerList;
    XCTAssertNotNil(innerList, @"%@", str);
    
    XCTAssertNotNil(inner.leftBoundary, @"%@", str);
    XCTAssertEqual(inner.leftBoundary.type, kMTMathAtomBoundary, @"%@", str);
    XCTAssertEqualObjects(inner.leftBoundary.nucleus, @"(", @"%@", str);
    
    XCTAssertNotNil(inner.rightBoundary, @"%@", str);
    XCTAssertEqual(inner.rightBoundary.type, kMTMathAtomBoundary, @"%@", str);
    XCTAssertEqualObjects(inner.rightBoundary.nucleus, @")", @"%@", str);
    
    XCTAssertEqualObjects(@(innerList.atoms.count), @1);
    MTMathTable* table = innerList.atoms[0];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    XCTAssertEqualObjects(table.nucleus, @"");
    XCTAssertEqualObjects(table.environment, @"matrix");
    XCTAssertEqual(table.interRowAdditionalSpacing, 0);
    XCTAssertEqual(table.interColumnSpacing, 18);
    XCTAssertEqual(table.numRows, 2);
    XCTAssertEqual(table.numColumns, 2);
    
    for (int i = 0; i < 2; i++) {
        MTColumnAlignment alignment = [table getAlignmentForColumn:i];
        XCTAssertEqual(alignment, kMTColumnAlignmentCenter);
        for (int j = 0; j < 2; j++) {
            MTMathList* cell = table.cells[j][i];
            XCTAssertEqual(cell.atoms.count, 2);
            MTMathStyle* style = cell.atoms[0];
            XCTAssertEqual(style.type, kMTMathAtomStyle);
            XCTAssertEqual(style.style, kMTLineStyleText);
            
            MTMathAtom* atom = cell.atoms[1];
            XCTAssertEqual(atom.type, kMTMathAtomVariable);
        }
    }
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\left( \\begin{matrix}x&y\\\\ z&w\\end{matrix}\\right) ");
}

- (void) testDefaultTable
{
    NSString *str = @"x \\\\ y";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    
    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTMathTable* table = list.atoms[0];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    XCTAssertEqualObjects(table.nucleus, @"");
    XCTAssertNil(table.environment);
    XCTAssertEqual(table.interRowAdditionalSpacing, 1);
    XCTAssertEqual(table.interColumnSpacing, 0);
    XCTAssertEqual(table.numRows, 2);
    XCTAssertEqual(table.numColumns, 1);
    
    for (int i = 0; i < 1; i++) {
        MTColumnAlignment alignment = [table getAlignmentForColumn:i];
        XCTAssertEqual(alignment, kMTColumnAlignmentLeft);
        for (int j = 0; j < 2; j++) {
            MTMathList* cell = table.cells[j][i];
            XCTAssertEqual(cell.atoms.count, 1);
            MTMathAtom* atom = cell.atoms[0];
            XCTAssertEqual(atom.type, kMTMathAtomVariable);
        }
    }
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"x\\\\ y");
}

- (void) testDefaultTableWithCols
{
    NSString *str = @"x & y \\\\ z & w";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    
    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTMathTable* table = list.atoms[0];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    XCTAssertEqualObjects(table.nucleus, @"");
    XCTAssertNil(table.environment);
    XCTAssertEqual(table.interRowAdditionalSpacing, 1);
    XCTAssertEqual(table.interColumnSpacing, 0);
    XCTAssertEqual(table.numRows, 2);
    XCTAssertEqual(table.numColumns, 2);
    
    for (int i = 0; i < 2; i++) {
        MTColumnAlignment alignment = [table getAlignmentForColumn:i];
        XCTAssertEqual(alignment, kMTColumnAlignmentLeft);
        for (int j = 0; j < 2; j++) {
            MTMathList* cell = table.cells[j][i];
            XCTAssertEqual(cell.atoms.count, 1);
            MTMathAtom* atom = cell.atoms[0];
            XCTAssertEqual(atom.type, kMTMathAtomVariable);
        }
    }
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"x&y\\\\ z&w");
}

- (void) testEqalign
{
    NSString *str1 = @"\\begin{eqalign}x&y\\\\ z&w\\end{eqalign}";
    NSString *str2 = @"\\begin{split}x&y\\\\ z&w\\end{split}";
    NSString *str3 = @"\\begin{aligned}x&y\\\\ z&w\\end{aligned}";
    for (NSString* str in @[str1, str2, str3]) {
        MTMathList* list = [MTMathListBuilder buildFromString:str];
        
        XCTAssertNotNil(list);
        XCTAssertEqualObjects(@(list.atoms.count), @1);
        MTMathTable* table = list.atoms[0];
        XCTAssertEqual(table.type, kMTMathAtomTable);
        XCTAssertEqualObjects(table.nucleus, @"");
        XCTAssertEqual(table.interRowAdditionalSpacing, 1);
        XCTAssertEqual(table.interColumnSpacing, 0);
        XCTAssertEqual(table.numRows, 2);
        XCTAssertEqual(table.numColumns, 2);
        
        for (int i = 0; i < 2; i++) {
            MTColumnAlignment alignment = [table getAlignmentForColumn:i];
            XCTAssertEqual(alignment, (i == 0) ? kMTColumnAlignmentRight: kMTColumnAlignmentLeft);
            for (int j = 0; j < 2; j++) {
                MTMathList* cell = table.cells[j][i];
                if (i == 0) {
                    XCTAssertEqual(cell.atoms.count, 1);
                    MTMathAtom* atom = cell.atoms[0];
                    XCTAssertEqual(atom.type, kMTMathAtomVariable);
                } else {
                    XCTAssertEqual(cell.atoms.count, 2);
                    [self checkAtomTypes:cell types:@[@(kMTMathAtomOrdinary), @(kMTMathAtomVariable)] desc:str];
                }
            }
        }
        
        // convert it back to latex
        NSString* latex = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(latex, str);
    }
}

// Regression test: trailing \\ creates a final row with only 1 cell; accessing row[1]
// without a bounds check used to crash (NSRangeException index 1 beyond bounds [0..0]).
- (void) testEqalignTrailingNewline
{
    NSString *str1 = @"\\begin{eqalign}x&y\\\\\\end{eqalign}";
    NSString *str2 = @"\\begin{split}x&y\\\\\\end{split}";
    NSString *str3 = @"\\begin{aligned}x&y\\\\\\end{aligned}";
    for (NSString* str in @[str1, str2, str3]) {
        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
        XCTAssertNotNil(list, @"Should not crash on trailing \\\\: %@", error);
        XCTAssertNil(error);
        MTMathTable* table = list.atoms[0];
        XCTAssertEqual(table.numRows, 2);
        // Second row exists but has no second column — numColumns is still 2 (the max).
        XCTAssertEqual(table.numColumns, 2);
    }
}

- (void) testDisplayLines
{
    NSString *str1 = @"\\begin{displaylines}x\\\\ y\\end{displaylines}";
    NSString *str2 = @"\\begin{gather}x\\\\ y\\end{gather}";
    for (NSString* str in @[str1, str2]) {
        MTMathList* list = [MTMathListBuilder buildFromString:str];
        
        XCTAssertNotNil(list);
        XCTAssertEqualObjects(@(list.atoms.count), @1);
        MTMathTable* table = list.atoms[0];
        XCTAssertEqual(table.type, kMTMathAtomTable);
        XCTAssertEqualObjects(table.nucleus, @"");
        XCTAssertEqual(table.interRowAdditionalSpacing, 1);
        XCTAssertEqual(table.interColumnSpacing, 0);
        XCTAssertEqual(table.numRows, 2);
        XCTAssertEqual(table.numColumns, 1);
        
        for (int i = 0; i < 1; i++) {
            MTColumnAlignment alignment = [table getAlignmentForColumn:i];
            XCTAssertEqual(alignment, kMTColumnAlignmentCenter);
            for (int j = 0; j < 2; j++) {
                MTMathList* cell = table.cells[j][i];
                XCTAssertEqual(cell.atoms.count, 1);
                MTMathAtom* atom = cell.atoms[0];
                XCTAssertEqual(atom.type, kMTMathAtomVariable);
            }
        }
        
        // convert it back to latex
        NSString* latex = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(latex, str);
    }
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
              @[@"\\begin matrix \\end matrix", @(MTParseErrorCharacterNotFound)], // missing {
              @[@"\\begin", @(MTParseErrorCharacterNotFound)], // missing {
              @[@"\\begin{", @(MTParseErrorCharacterNotFound)], // missing }
              @[@"\\begin{matrix parens}", @(MTParseErrorCharacterNotFound)], // missing } (no spaces in env)
              @[@"\\begin{matrix} x", @(MTParseErrorMissingEnd)],
              @[@"\\begin{matrix} x \\end", @(MTParseErrorCharacterNotFound)], // missing {
              @[@"\\begin{matrix} x \\end + 3", @(MTParseErrorCharacterNotFound)], // missing {
              @[@"\\begin{matrix} x \\end{", @(MTParseErrorCharacterNotFound)], // missing }
              @[@"\\begin{matrix} x \\end{matrix + 3", @(MTParseErrorCharacterNotFound)], // missing }
              @[@"\\begin{matrix} x \\end{pmatrix}", @(MTParseErrorInvalidEnv)],
              @[@"x \\end{matrix}", @(MTParseErrorMissingBegin)],
              @[@"\\begin{notanenv} x \\end{notanenv}", @(MTParseErrorInvalidEnv)],
              @[@"\\begin{matrix} \\notacommand \\end{matrix}", @(MTParseErrorInvalidCommand)],
              @[@"\\begin{displaylines} x & y \\end{displaylines}", @(MTParseErrorInvalidNumColumns)],
              @[@"\\begin{eqalign} x \\end{eqalign}", @(MTParseErrorInvalidNumColumns)],
              @[@"\\nolimits", @(MTParseErrorInvalidLimits)],
              @[@"\\frac\\limits{1}{2}", @(MTParseErrorInvalidLimits)],
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

- (void) testCustom
{
    NSString* str = @"\\lcm(a,b)";
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNil(list);
    XCTAssertNotNil(error);
    
    [MTMathAtomFactory addLatexSymbol:@"lcm" value:[MTMathAtomFactory operatorWithName:@"lcm" limits:NO]];
    error = nil;
    list = [MTMathListBuilder buildFromString:str error:&error];
    NSArray* atomTypes = @[@(kMTMathAtomLargeOperator), @(kMTMathAtomOpen), @(kMTMathAtomVariable), @(kMTMathAtomPunctuation), @(kMTMathAtomVariable), @(kMTMathAtomClose)];
    [self checkAtomTypes:list types:atomTypes desc:@"Error for lcm"];
    
    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\lcm (a,b)");
}

- (void) testFontSingle
{
    NSString *str = @"\\mathbf x";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"x", @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleBold);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\mathbf{x}", @"%@", desc);
}

- (void) testFontOneChar
{
    NSString *str = @"\\cal xy";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @2, @"%@", desc);
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"x", @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleCaligraphic);

    atom = list.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"y", @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleDefault);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\mathcal{x}y", @"%@", desc);
}

- (void) testFontMultipleChars
{
    NSString *str = @"\\frak{xy}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @2, @"%@", desc);
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"x", @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleFraktur);

    atom = list.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"y", @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleFraktur);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\mathfrak{xy}", @"%@", desc);
}

- (void) testFontOneCharInside
{
    NSString *str = @"\\sqrt \\mathrm x y";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @2, @"%@", desc);

    MTRadical* rad = list.atoms[0];
    XCTAssertEqual(rad.type, kMTMathAtomRadical, @"%@", desc);
    XCTAssertEqualObjects(rad.nucleus, @"", @"%@", desc);

    MTMathList *subList = rad.radicand;
    MTMathAtom* atom = subList.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"x", @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleRoman);

    atom = list.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"y", @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleDefault);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\sqrt{\\mathrm{x}}y", @"%@", desc);
}

- (void) testText
{
    NSString *str = @"\\text{x y}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @3, @"%@", desc);
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"x", @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleRoman);

    atom = list.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomOrdinary, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @" ", @"%@", desc);

    atom = list.atoms[2];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"%@", desc);
    XCTAssertEqualObjects(atom.nucleus, @"y", @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleRoman);


    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\mathrm{x\\  y}", @"%@", desc);
}

- (void) testLimits
{
    // Int with no limits (default)
    NSString *str = @"\\int";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTLargeOperator* op = list.atoms[0];
    XCTAssertEqual(op.type, kMTMathAtomLargeOperator, @"%@", desc);
    XCTAssertFalse(op.limits);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\int ", @"%@", desc);

    // Int with limits
    str = @"\\int\\limits";
    list = [MTMathListBuilder buildFromString:str];
    desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    op = list.atoms[0];
    XCTAssertEqual(op.type, kMTMathAtomLargeOperator, @"%@", desc);
    XCTAssertTrue(op.limits);

    // convert it back to latex
    latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\int \\limits ", @"%@", desc);
}

- (void) testNoLimits
{
    // Sum with limits (default)
    NSString *str = @"\\sum";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTLargeOperator* op = list.atoms[0];
    XCTAssertEqual(op.type, kMTMathAtomLargeOperator, @"%@", desc);
    XCTAssertTrue(op.limits);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\sum ", @"%@", desc);

    // Int with limits
    str = @"\\sum\\nolimits";
    list = [MTMathListBuilder buildFromString:str];
    desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    op = list.atoms[0];
    XCTAssertEqual(op.type, kMTMathAtomLargeOperator, @"%@", desc);
    XCTAssertFalse(op.limits);

    // convert it back to latex
    latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\sum \\nolimits ", @"%@", desc);
}

static NSArray* getTestDataLargeDelimiters() {
    // Each entry: [latex, expected class, expected size, expected nucleus, expected serialized latex?]
    return @[
        @[ @"\\big(",     @(kMTMathAtomOrdinary), @(kMTDelimiterSize1), @"(" ],
        @[ @"\\Big(",     @(kMTMathAtomOrdinary), @(kMTDelimiterSize2), @"(" ],
        @[ @"\\bigg(",    @(kMTMathAtomOrdinary), @(kMTDelimiterSize3), @"(" ],
        @[ @"\\Bigg(",    @(kMTMathAtomOrdinary), @(kMTDelimiterSize4), @"(" ],
        @[ @"\\bigl(",    @(kMTMathAtomOpen),     @(kMTDelimiterSize1), @"(" ],
        @[ @"\\Bigl[",    @(kMTMathAtomOpen),     @(kMTDelimiterSize2), @"[" ],
        @[ @"\\biggl\\{", @(kMTMathAtomOpen),     @(kMTDelimiterSize3), @"{" ],
        @[ @"\\Biggl\\lceil", @(kMTMathAtomOpen), @(kMTDelimiterSize4), @"\u2308" ],
        @[ @"\\bigr)",    @(kMTMathAtomClose),    @(kMTDelimiterSize1), @")" ],
        @[ @"\\Bigr]",    @(kMTMathAtomClose),    @(kMTDelimiterSize2), @"]" ],
        @[ @"\\biggr\\}", @(kMTMathAtomClose),    @(kMTDelimiterSize3), @"}" ],
        @[ @"\\Biggr\\rfloor", @(kMTMathAtomClose),@(kMTDelimiterSize4), @"\u230B" ],
        @[ @"\\bigm|",    @(kMTMathAtomRelation), @(kMTDelimiterSize1), @"|" ],
        @[ @"\\Bigm\\|",  @(kMTMathAtomRelation), @(kMTDelimiterSize2), @"\u2016" ],
        @[ @"\\biggm\\Vert", @(kMTMathAtomRelation),@(kMTDelimiterSize3), @"\u2016", @"\\biggm\\|" ],
        @[ @"\\Biggm\\langle", @(kMTMathAtomRelation),@(kMTDelimiterSize4), @"\u2329", @"\\Biggm<" ],
        // Null delimiter.
        @[ @"\\bigl.",    @(kMTMathAtomOpen),     @(kMTDelimiterSize1), @"" ],
        @[ @"\\bigr.",    @(kMTMathAtomClose),    @(kMTDelimiterSize1), @"" ],
        @[ @"\\big.",     @(kMTMathAtomOrdinary), @(kMTDelimiterSize1), @"" ],
    ];
}

- (void) testLargeDelimiter
{
    for (NSArray* testCase in getTestDataLargeDelimiters()) {
        NSString* str = testCase[0];
        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
        XCTAssertNotNil(list, @"%@", str);
        XCTAssertNil(error, @"%@", str);
        XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", str);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertTrue([atom isKindOfClass:[MTLargeDelimiter class]], @"%@", str);
        MTLargeDelimiter* big = (MTLargeDelimiter*)atom;
        XCTAssertEqual(big.type, (MTMathAtomType)[testCase[1] unsignedIntegerValue], @"%@", str);
        XCTAssertEqual(big.delimiterSize, (MTDelimiterSize)[testCase[2] unsignedIntegerValue], @"%@", str);
        XCTAssertEqualObjects(big.nucleus, testCase[3], @"%@", str);

        NSString* latex = [MTMathListBuilder mathListToString:list];
        NSString* expected = (testCase.count > 4) ? testCase[4] : str;
        XCTAssertEqualObjects(latex, expected, @"%@", str);
    }
}

- (void) testLargeDelimiterScripts
{
    NSString* str = @"\\bigl(^2";
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNotNil(list);
    XCTAssertNil(error);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTLargeDelimiter* big = (MTLargeDelimiter*)list.atoms[0];
    XCTAssertTrue([big isKindOfClass:[MTLargeDelimiter class]]);
    XCTAssertNotNil(big.superScript);
    XCTAssertEqualObjects(@(big.superScript.atoms.count), @1);
    XCTAssertEqual(big.superScript.atoms[0].type, kMTMathAtomNumber);

    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\bigl(^{2}");
}

- (void) testLargeDelimiterErrors
{
    NSArray* errors = @[
        @[ @"\\big",    @(MTParseErrorMissingDelimiter) ],
        @[ @"\\Bigl",   @(MTParseErrorMissingDelimiter) ],
        @[ @"\\bigr?",  @(MTParseErrorInvalidDelimiter) ],
        @[ @"\\Bigm\\notadelim", @(MTParseErrorInvalidDelimiter) ],
    ];
    for (NSArray* testCase in errors) {
        NSString* str = testCase[0];
        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
        XCTAssertNil(list, @"%@", str);
        XCTAssertNotNil(error, @"%@", str);
        XCTAssertEqual(error.code, [testCase[1] integerValue], @"%@", str);
    }
}

- (void) testLargeDelimiterInBetween
{
    // Ensure adjacency with ordinary/number atoms works and the large
    // delimiter sits as an independent atom of the expected class.
    NSString* str = @"a \\big( b";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @3);
    XCTAssertEqual([list.atoms[0] type], kMTMathAtomVariable);
    XCTAssertEqual([list.atoms[2] type], kMTMathAtomVariable);
    XCTAssertTrue([list.atoms[1] isKindOfClass:[MTLargeDelimiter class]]);
    MTLargeDelimiter* big = list.atoms[1];
    XCTAssertEqual(big.type, kMTMathAtomOrdinary);
    XCTAssertEqual(big.delimiterSize, kMTDelimiterSize1);
    XCTAssertEqualObjects(big.nucleus, @"(");
}

- (void) testLargeDelimiterSerializationCanonicalDelimiters
{
    NSArray<NSArray<NSString*>*>* cases = @[
        @[ @"\\bigl|", @"\\bigl|" ],
        @[ @"\\bigm\\|", @"\\bigm\\|" ],
        @[ @"\\biggm\\Vert", @"\\biggm\\|" ],
        @[ @"\\bigl.", @"\\bigl." ],
    ];
    for (NSArray<NSString*>* testCase in cases) {
        NSString* input = testCase[0];
        NSString* expected = testCase[1];
        MTMathList* list = [MTMathListBuilder buildFromString:input];
        XCTAssertNotNil(list, @"%@", input);
        NSString* latex = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(latex, expected, @"%@", input);
    }
}

- (void) testStackCommands
{
    // Each entry: command, overGlyph, underGlyph.
    // Each cap is the stretchy cap glyph; the typesetter walks its OpenType h_variants
    // and falls back to HorizontalGlyphAssembly to cover wide bases.
    NSArray* cases = @[
        @[@"overrightarrow",     @"\u2192",          [NSNull null]],
        @[@"overleftarrow",      @"\u2190",          [NSNull null]],
        @[@"overleftrightarrow", @"\u2194",          [NSNull null]],
        @[@"underrightarrow",    [NSNull null], @"\u2192"],
        @[@"underleftarrow",     [NSNull null], @"\u2190"],
        @[@"underleftrightarrow",[NSNull null], @"\u2194"],
        @[@"overbrace",          @"\u23DE",          [NSNull null]],
        @[@"underbrace",         [NSNull null], @"\u23DF"],
    ];

    for (NSArray* row in cases) {
        NSString* cmd        = row[0];
        id overGlyph  = row[1];
        id underGlyph = row[2];

        NSString* latex = [NSString stringWithFormat:@"\\%@{x}", cmd];
        MTMathList* list = [MTMathListBuilder buildFromString:latex];
        XCTAssertNotNil(list, @"nil list for \\%@", cmd);
        XCTAssertEqual(list.atoms.count, 1u, @"atom count for \\%@", cmd);

        MTMathStack* stack = list.atoms[0];
        XCTAssertEqual(stack.type, kMTMathAtomStack, @"type for \\%@", cmd);
        XCTAssertEqual(stack.displayClass, kMTMathAtomOrdinary, @"displayClass for \\%@", cmd);
        XCTAssertNotNil(stack.innerList, @"innerList for \\%@", cmd);
        XCTAssertEqual(stack.innerList.atoms.count, 1u, @"innerList count for \\%@", cmd);

        if (![overGlyph isKindOfClass:[NSNull class]]) {
            XCTAssertNotNil(stack.over, @"over for \\%@", cmd);
            XCTAssertEqual(stack.over.kind, kMTMathStackConstructionExtensible, @"over.kind for \\%@", cmd);
            XCTAssertEqualObjects(stack.over.glyph, overGlyph, @"over.glyph for \\%@", cmd);
        } else {
            XCTAssertNil(stack.over, @"over should be nil for \\%@", cmd);
        }

        if (![underGlyph isKindOfClass:[NSNull class]]) {
            XCTAssertNotNil(stack.under, @"under for \\%@", cmd);
            XCTAssertEqual(stack.under.kind, kMTMathStackConstructionExtensible, @"under.kind for \\%@", cmd);
            XCTAssertEqualObjects(stack.under.glyph, underGlyph, @"under.glyph for \\%@", cmd);
        } else {
            XCTAssertNil(stack.under, @"under should be nil for \\%@", cmd);
        }

        // Round-trip serialization.
        NSString* roundTrip = [MTMathListBuilder mathListToString:list];
        NSString* expectedLatex = [NSString stringWithFormat:@"\\%@{x}", cmd];
        XCTAssertEqualObjects(roundTrip, expectedLatex, @"round-trip for \\%@", cmd);
    }
}

- (void) testStackRoundTripNested
{
    NSString* input = @"\\overrightarrow{\\frac{a}{b}}";
    MTMathList* list = [MTMathListBuilder buildFromString:input];
    XCTAssertNotNil(list);
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\overrightarrow{\\frac{a}{b}}");
}

- (void) testStackUnknownCommandFallthrough
{
    // \overfoo is not a known stack command — should produce a parse error.
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\overfoo{x}" error:&error];
    XCTAssertNil(list);
    XCTAssertNotNil(error);
}

- (void) testStackNonCanonicalSerializesInnerOnly
{
    // A programmatically-built stack with non-canonical fields (leftCap = "Z") cannot
    // round-trip to a command name; serialization should emit only the inner list.
    MTMathStack* stack = [[MTMathStack alloc] init];
    stack.over = [MTMathStackConstruction extensibleWithGlyph:@"Z"];
    MTMathList* inner = [MTMathList new];
    [inner addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    stack.innerList = inner;
    MTMathList* list = [MTMathList new];
    [list addAtom:stack];
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"x");
}

- (void) testReverseMapTypeKeyedRoundTrip
{
    // Regression guard for Feature 7: re-keying the reverse map by
    // (nucleus, type) must not break round-tripping of Bin symbols that
    // become Un at the start of a list via -[MTMathList finalized].
    NSArray<NSArray*>* cases = @[
        @[ @"\\pm a",   @"\\pm a" ],
        @[ @"a\\pm b",  @"a\\pm b" ],
        @[ @"\\pm",     @"\\pm " ],
        @[ @"\\cdot a", @"\\cdot a" ],
        @[ @"a\\cdot b",@"a\\cdot b" ],
        @[ @"\\leq",    @"\\leq " ],
        @[ @"\\alpha",  @"\\alpha " ],
        @[ @"\\to",     @"\\rightarrow " ],   // alias resolves to canonical
    ];
    for (NSArray* c in cases) {
        NSString* input = c[0];
        NSString* expected = c[1];
        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"Parse error for %@", input);
        XCTAssertNotNil(list, @"Nil list for %@", input);
        MTMathList* final = [list finalized];
        NSString* roundTrip = [MTMathListBuilder mathListToString:final];
        XCTAssertEqualObjects(roundTrip, expected, @"Round-trip mismatch for %@", input);
    }
}

- (void) testPrimes
{
    // Per-case shape: @[ input,
    //                    expected top-level atom types,
    //                    index-into-top-level of the atom whose superscript holds the primes,
    //                    expected superscript atom types of that atom,
    //                    expected round-trip ]
    NSArray* cases = @[
        @[ @"f'",
           @[@(kMTMathAtomVariable)],
           @0, @[@(kMTMathAtomOrdinary)],
           @"f^{\\prime }" ],
        @[ @"y''",
           @[@(kMTMathAtomVariable)],
           @0, @[@(kMTMathAtomOrdinary), @(kMTMathAtomOrdinary)],
           @"y^{\\prime \\prime }" ],
        @[ @"f'''(x)",
           @[@(kMTMathAtomVariable), @(kMTMathAtomOpen),
             @(kMTMathAtomVariable), @(kMTMathAtomClose)],
           @0,
           @[@(kMTMathAtomOrdinary), @(kMTMathAtomOrdinary), @(kMTMathAtomOrdinary)],
           @"f^{\\prime \\prime \\prime }(x)" ],
        @[ @"'2",
           @[@(kMTMathAtomOrdinary), @(kMTMathAtomNumber)],
           @0, @[@(kMTMathAtomOrdinary)],
           @"{}^{\\prime }2" ],
        @[ @"f'^2",
           @[@(kMTMathAtomVariable)],
           @0,
           @[@(kMTMathAtomOrdinary), @(kMTMathAtomNumber)],
           @"f^{\\prime 2}" ],
        @[ @"f'_n",
           @[@(kMTMathAtomVariable)],
           @0, @[@(kMTMathAtomOrdinary)],
           @"f^{\\prime }_{n}" ],
        @[ @"f^\\prime",
           @[@(kMTMathAtomVariable)],
           @0, @[@(kMTMathAtomOrdinary)],
           @"f^{\\prime }" ],
    ];
    for (NSArray* c in cases) {
        NSString* input = c[0];
        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"Parse error for %@", input);
        XCTAssertNotNil(list, @"Nil list for %@", input);
        [self checkAtomTypes:list types:c[1] desc:input];

        NSUInteger idx = [c[2] unsignedIntegerValue];
        MTMathAtom* hostAtom = list.atoms[idx];
        XCTAssertNotNil(hostAtom.superScript, @"Missing superscript for %@", input);
        [self checkAtomTypes:hostAtom.superScript types:c[3] desc:input];

        // Each Ord atom in the superscript that has nucleus length 1 must be
        // a prime (U+2032). Number / Variable atoms in the merge case
        // (f'^2 -> [\prime, 2]) are allowed and skipped.
        for (MTMathAtom* a in hostAtom.superScript.atoms) {
            if (a.type == kMTMathAtomOrdinary && a.nucleus.length == 1) {
                XCTAssertEqualObjects(a.nucleus, @"′", @"%@ prime nucleus", input);
            }
        }

        NSString* roundTrip = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(roundTrip, c[4], @"Round-trip mismatch for %@", input);
    }
}

- (void) testPrimesDoubleSuperscript
{
    // f^2'  ->  f has superscript [2]; the ' triggers double-superscript path,
    // which mirrors the existing ^^ handling: allocate an empty Ord whose
    // superscript is the prime list.
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"f^2'" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(list.atoms.count, (NSUInteger)2);
    MTMathAtom* f = list.atoms[0];
    XCTAssertEqual(f.type, kMTMathAtomVariable);
    XCTAssertEqualObjects(f.nucleus, @"f");
    XCTAssertNotNil(f.superScript);
    XCTAssertEqual(f.superScript.atoms.count, (NSUInteger)1);

    MTMathAtom* empty = list.atoms[1];
    XCTAssertEqual(empty.type, kMTMathAtomOrdinary);
    XCTAssertEqualObjects(empty.nucleus, @"");
    XCTAssertNotNil(empty.superScript);
    XCTAssertEqual(empty.superScript.atoms.count, (NSUInteger)1);
    MTMathAtom* prime = empty.superScript.atoms[0];
    XCTAssertEqualObjects(prime.nucleus, @"′");

    NSString* rt = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(rt, @"f^{2}{}^{\\prime }");
}

- (void) testPrimesInsideBraces
{
    // f^{2'}  ->  f has superscript [2]; the inner ' attaches to the inner 2.
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"f^{2'}" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTMathAtom* f = list.atoms[0];
    XCTAssertNotNil(f.superScript);
    XCTAssertEqual(f.superScript.atoms.count, (NSUInteger)1);
    MTMathAtom* two = f.superScript.atoms[0];
    XCTAssertEqual(two.type, kMTMathAtomNumber);
    XCTAssertEqualObjects(two.nucleus, @"2");
    XCTAssertNotNil(two.superScript);
    XCTAssertEqual(two.superScript.atoms.count, (NSUInteger)1);
    XCTAssertEqualObjects(two.superScript.atoms[0].nucleus, @"′");

    NSString* rt = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(rt, @"f^{2^{\\prime }}");
}

- (void) testNegatedRelations
{
    // Each row: @[ command (no leading \), expected nucleus codepoint NSNumber ]
    NSArray* rows = @[
        @[ @"nleq",            @0x2270 ],
        @[ @"ngeq",            @0x2271 ],
        @[ @"nless",           @0x226E ],
        @[ @"ngtr",            @0x226F ],
        @[ @"nsubseteq",       @0x2288 ],
        @[ @"nsupseteq",       @0x2289 ],
        @[ @"nmid",            @0x2224 ],
        @[ @"nparallel",       @0x2226 ],
        @[ @"nleftarrow",      @0x219A ],
        @[ @"nrightarrow",     @0x219B ],
        @[ @"nLeftarrow",      @0x21CD ],
        @[ @"nRightarrow",     @0x21CF ],
        @[ @"nleftrightarrow", @0x21AE ],
        @[ @"nLeftrightarrow", @0x21CE ],
        @[ @"nvdash",          @0x22AC ],
        @[ @"nvDash",          @0x22AD ],
        @[ @"nVdash",          @0x22AE ],
        @[ @"nVDash",          @0x22AF ],
        @[ @"ntriangleleft",   @0x22EA ],
        @[ @"ntriangleright",  @0x22EB ],
        @[ @"ntrianglelefteq", @0x22EC ],
        @[ @"ntrianglerighteq",@0x22ED ],
        @[ @"nsim",            @0x2241 ],
        @[ @"ncong",           @0x2247 ],
        @[ @"nequiv",          @0x2262 ],
        @[ @"nsubset",         @0x2284 ],
        @[ @"nsupset",         @0x2285 ],
        @[ @"nsucc",           @0x2281 ],
        @[ @"nprec",           @0x2280 ],
        @[ @"nsucceq",         @0x2AB1 ],
        @[ @"npreceq",         @0x2AB0 ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)31);
    for (NSArray* r in rows) {
        NSString* cmd = r[0];
        unichar expectedNuc = (unichar)[r[1] unsignedIntegerValue];
        NSString* input = [@"\\" stringByAppendingString:cmd];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"Parse error for %@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1, @"%@", input);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqual(atom.type, kMTMathAtomRelation, @"%@ type", input);
        XCTAssertEqual(atom.nucleus.length, (NSUInteger)1, @"%@ nucleus length", input);
        XCTAssertEqual([atom.nucleus characterAtIndex:0], expectedNuc, @"%@ nucleus", input);

        // Round-trip: relation surrounded by variables to keep finalize stable.
        NSString* probe = [NSString stringWithFormat:@"a%@ b", input];
        MTMathList* probeList = [MTMathListBuilder buildFromString:probe error:&error];
        XCTAssertNil(error);
        NSString* expectedRT = [NSString stringWithFormat:@"a%@ b", input];
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:probeList], expectedRT, @"round-trip %@", input);
    }
}

- (void) testHarpoonsAndExtendedArrows
{
    NSArray* rows = @[
        @[ @"rightleftharpoons", @0x21CC ],
        @[ @"leftrightharpoons", @0x21CB ],
        @[ @"upharpoonleft",     @0x21BF ],
        @[ @"upharpoonright",    @0x21BE ],
        @[ @"downharpoonleft",   @0x21C3 ],
        @[ @"downharpoonright",  @0x21C2 ],
        @[ @"rightharpoonup",    @0x21C0 ],
        @[ @"leftharpoonup",     @0x21BC ],
        @[ @"rightharpoondown",  @0x21C1 ],
        @[ @"leftharpoondown",   @0x21BD ],
        @[ @"hookleftarrow",     @0x21A9 ],
        @[ @"hookrightarrow",    @0x21AA ],
        @[ @"twoheadleftarrow",  @0x219E ],
        @[ @"twoheadrightarrow", @0x21A0 ],
        @[ @"rightarrowtail",    @0x21A3 ],
        @[ @"leftarrowtail",     @0x21A2 ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)16);
    for (NSArray* r in rows) {
        NSString* cmd = r[0];
        unichar expectedNuc = (unichar)[r[1] unsignedIntegerValue];
        NSString* input = [@"\\" stringByAppendingString:cmd];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"%@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqual(atom.type, kMTMathAtomRelation, @"%@ type", input);
        XCTAssertEqual([atom.nucleus characterAtIndex:0], expectedNuc, @"%@ nucleus", input);

        NSString* probe = [NSString stringWithFormat:@"a%@ b", input];
        MTMathList* probeList = [MTMathListBuilder buildFromString:probe error:&error];
        XCTAssertNil(error);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:probeList],
                              ([NSString stringWithFormat:@"a%@ b", input]),
                              @"round-trip %@", input);
    }
}

- (void) testRestrictionAlias
{
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\restriction" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomRelation);
    XCTAssertEqualObjects(atom.nucleus, @"↾", @"\\restriction should resolve to \\upharpoonright (U+21BE)");

    // Round-trip emits canonical.
    MTMathList* probe = [MTMathListBuilder buildFromString:@"a\\restriction b" error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:probe], @"a\\upharpoonright b");
}

- (void) testBoxedCircledOperators
{
    NSArray* rows = @[
        @[ @"boxplus",       @0x229E ],
        @[ @"boxminus",      @0x229F ],
        @[ @"boxtimes",      @0x22A0 ],
        @[ @"boxdot",        @0x22A1 ],
        @[ @"circledast",    @0x229B ],
        @[ @"circledcirc",   @0x229A ],
        @[ @"circleddash",   @0x229D ],
        @[ @"barwedge",      @0x22BC ],
        @[ @"veebar",        @0x22BB ],
        @[ @"triangleleft",  @0x25C1 ],
        @[ @"triangleright", @0x25B7 ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)11);
    for (NSArray* r in rows) {
        NSString* cmd = r[0];
        unichar expectedNuc = (unichar)[r[1] unsignedIntegerValue];
        NSString* input = [@"\\" stringByAppendingString:cmd];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"%@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqual(atom.type, kMTMathAtomBinaryOperator, @"%@ pre-finalize type", input);
        XCTAssertEqual([atom.nucleus characterAtIndex:0], expectedNuc, @"%@ nucleus", input);

        // Between variables: stays Bin.
        NSString* middle = [NSString stringWithFormat:@"a%@ b", input];
        MTMathList* middleList = [MTMathListBuilder buildFromString:middle error:&error];
        XCTAssertNil(error);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:middleList],
                              ([NSString stringWithFormat:@"a%@ b", input]),
                              @"round-trip Bin in middle %@", input);

        // At start of list: finalize reclassifies Bin → Un. Round-trip must
        // still recover the command name via the Un/Bin retry (PR 1).
        NSString* start = [NSString stringWithFormat:@"%@ a", input];
        MTMathList* startList = [MTMathListBuilder buildFromString:start error:&error];
        XCTAssertNil(error);
        MTMathList* startFinal = [startList finalized];
        XCTAssertEqual([startFinal.atoms[0] type], kMTMathAtomUnaryOperator,
                       @"%@ should finalize to Un at start of list", input);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:startFinal],
                              ([NSString stringWithFormat:@"%@ a", input]),
                              @"round-trip Bin→Un at start %@", input);
    }
}

- (void) testMissingRelationsAndOrdinaries
{
    NSArray* rows = @[
        // Relations
        @[ @"vdash",            @0x22A2, @(kMTMathAtomRelation) ],
        @[ @"dashv",            @0x22A3, @(kMTMathAtomRelation) ],
        @[ @"Subset",           @0x22D0, @(kMTMathAtomRelation) ],
        @[ @"Supset",           @0x22D1, @(kMTMathAtomRelation) ],
        @[ @"backsim",          @0x223D, @(kMTMathAtomRelation) ],
        @[ @"backsimeq",        @0x22CD, @(kMTMathAtomRelation) ],
        @[ @"eqsim",            @0x2242, @(kMTMathAtomRelation) ],
        @[ @"Bumpeq",           @0x224E, @(kMTMathAtomRelation) ],
        @[ @"bumpeq",           @0x224F, @(kMTMathAtomRelation) ],
        @[ @"therefore",        @0x2234, @(kMTMathAtomRelation) ],
        @[ @"because",          @0x2235, @(kMTMathAtomRelation) ],
        @[ @"multimap",         @0x22B8, @(kMTMathAtomRelation) ],
        @[ @"vartriangleleft",  @0x22B2, @(kMTMathAtomRelation) ],
        @[ @"vartriangleright", @0x22B3, @(kMTMathAtomRelation) ],
        @[ @"trianglelefteq",   @0x22B4, @(kMTMathAtomRelation) ],
        @[ @"trianglerighteq",  @0x22B5, @(kMTMathAtomRelation) ],
        @[ @"triangleq",        @0x225C, @(kMTMathAtomRelation) ],
        // Ordinaries
        @[ @"complement",       @0x2201, @(kMTMathAtomOrdinary) ],
        @[ @"Box",              @0x25A1, @(kMTMathAtomOrdinary) ],
        @[ @"Diamond",          @0x25C7, @(kMTMathAtomOrdinary) ],
        @[ @"lozenge",          @0x25CA, @(kMTMathAtomOrdinary) ],
        @[ @"blacklozenge",     @0x29EB, @(kMTMathAtomOrdinary) ],
        @[ @"diamondsuit",      @0x2662, @(kMTMathAtomOrdinary) ],
        @[ @"heartsuit",        @0x2661, @(kMTMathAtomOrdinary) ],
        @[ @"spadesuit",        @0x2660, @(kMTMathAtomOrdinary) ],
        @[ @"clubsuit",         @0x2663, @(kMTMathAtomOrdinary) ],
        @[ @"beth",             @0x2136, @(kMTMathAtomOrdinary) ],
        @[ @"gimel",            @0x2137, @(kMTMathAtomOrdinary) ],
        @[ @"daleth",           @0x2138, @(kMTMathAtomOrdinary) ],
        @[ @"triangledown",     @0x25BD, @(kMTMathAtomOrdinary) ],
        @[ @"blacktriangle",    @0x25B2, @(kMTMathAtomOrdinary) ],
        @[ @"blacktriangledown",@0x25BC, @(kMTMathAtomOrdinary) ],
        @[ @"blacktriangleleft",@0x25C0, @(kMTMathAtomOrdinary) ],
        @[ @"blacktriangleright",@0x25B6, @(kMTMathAtomOrdinary) ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)34);
    for (NSArray* r in rows) {
        NSString* cmd = r[0];
        unichar expectedNuc = (unichar)[r[1] unsignedIntegerValue];
        MTMathAtomType expectedType = (MTMathAtomType)[r[2] unsignedIntegerValue];
        NSString* input = [@"\\" stringByAppendingString:cmd];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"%@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1, @"%@", input);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqual(atom.type, expectedType, @"%@ pre-finalize type", input);
        XCTAssertEqual([atom.nucleus characterAtIndex:0], expectedNuc, @"%@ nucleus", input);
    }
}

- (void) testNewAliases
{
    NSArray* rows = @[
        @[ @"implies",      @"Longrightarrow", @"⟹", @"\\Longrightarrow " ],
        @[ @"impliedby",    @"Longleftarrow",  @"⟸", @"\\Longleftarrow " ],
        @[ @"dotsc",        @"ldots",          @"…", @"\\ldots " ],
        @[ @"dotsb",        @"cdots",          @"⋯", @"\\cdots " ],
        @[ @"dotsm",        @"cdots",          @"⋯", @"\\cdots " ],
        @[ @"dotsi",        @"ldots",          @"…", @"\\ldots " ],
        @[ @"square",       @"Box",            @"□", @"\\Box " ],
        @[ @"vartriangle",  @"triangle",       @"△", @"\\triangle " ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)8);
    for (NSArray* r in rows) {
        NSString* alias = r[0];
        NSString* expectedNucleus = r[2];
        NSString* expectedRT = r[3];
        NSString* input = [@"\\" stringByAppendingString:alias];

        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:input error:&error];
        XCTAssertNil(error, @"%@", input);
        XCTAssertEqual(list.atoms.count, (NSUInteger)1);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqualObjects(atom.nucleus, expectedNucleus, @"%@ nucleus", input);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], expectedRT,
                              @"%@ round-trip", input);
    }
}

- (void) testSquareBoxParity
{
    NSError* error = nil;
    MTMathList* a = [MTMathListBuilder buildFromString:@"\\square" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(a.atoms.count, (NSUInteger)1);
    XCTAssertEqual([a.atoms[0] type], kMTMathAtomOrdinary);
    XCTAssertEqualObjects([a.atoms[0] nucleus], @"□");

    MTMathList* b = [MTMathListBuilder buildFromString:@"\\Box" error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(b.atoms.count, (NSUInteger)1);
    XCTAssertEqual([b.atoms[0] type], kMTMathAtomOrdinary);
    XCTAssertEqualObjects([b.atoms[0] nucleus], @"□");

    XCTAssertEqualObjects([MTMathListBuilder mathListToString:a], @"\\Box ");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:b], @"\\Box ");

    MTMathAtom* p = [MTMathAtomFactory placeholder];
    XCTAssertEqual(p.type, kMTMathAtomPlaceholder);
    XCTAssertEqualObjects(p.nucleus, @"□");
}

@end
