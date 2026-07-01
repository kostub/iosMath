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
             // braces create an Ord group (MTMathGroup)
             @[ @"5{3+4}", @[@(kMTMathAtomNumber), @(kMTMathAtomOrdGroup)], @"5{3+4}"],
             // commands
             @[ @"\\pi+\\theta\\geq 3",@[ @(kMTMathAtomVariable), @(kMTMathAtomBinaryOperator), @(kMTMathAtomVariable), @(kMTMathAtomRelation), @(kMTMathAtomNumber)], @"\\pi +\\theta \\geq 3"],
             // aliases
             @[ @"\\pi\\ne 5 \\land 3", @[ @(kMTMathAtomVariable), @(kMTMathAtomRelation), @(kMTMathAtomNumber), @(kMTMathAtomBinaryOperator), @(kMTMathAtomNumber)], @"\\pi \\neq 5\\wedge 3"],
             // control space
             @[ @"x \\ y", @[  @(kMTMathAtomVariable), @(kMTMathAtomOrdinary), @(kMTMathAtomVariable)], @"x\\  y"],
             // spacing
             @[ @"x \\quad y \\; z \\! q", @[  @(kMTMathAtomVariable), @(kMTMathAtomSpace), @(kMTMathAtomVariable),@(kMTMathAtomSpace), @(kMTMathAtomVariable),@(kMTMathAtomSpace), @(kMTMathAtomVariable)], @"x\\quad y\\; z\\! q"],
             // tilde is a non-breaking space (renders as an ordinary space, same as a literal space)
             @[ @"x~y", @[  @(kMTMathAtomVariable), @(kMTMathAtomOrdinary), @(kMTMathAtomVariable)], @"x\\  y"],
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
             @[ @"{}^2", @ [ @(kMTMathAtomOrdGroup)], @[ @(kMTMathAtomNumber) ], @"{}^{2}"],
             @[ @"x^^2", @[ @(kMTMathAtomVariable), @(kMTMathAtomOrdinary) ],  @[ ], @"x^{}{}^{2}"],
             @[ @"5{x}^2", @ [ @(kMTMathAtomNumber), @(kMTMathAtomOrdGroup)], @[ ], @"5{x}^{2}"],
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
             @[ @"{}_2", @ [ @(kMTMathAtomOrdGroup)], @[ @(kMTMathAtomNumber) ], @"{}_{2}" ],
             @[ @"x__2", @[ @(kMTMathAtomVariable), @(kMTMathAtomOrdinary) ],  @[ ], @"x_{}{}_{2}"],
             @[ @"5{x}_2", @ [ @(kMTMathAtomNumber), @(kMTMathAtomOrdGroup)], @[ ], @"5{x}_{2}"],
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
    XCTAssertEqual(frac.styleOverride, kMTFractionStyleAuto);
    XCTAssertFalse(frac.isContinuedFraction);
    XCTAssertEqual(frac.numeratorAlignment, kMTFractionAlignmentCenter);

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

- (void) testSqrtAtEnd
{
    // A lone \sqrt with no argument at the end of the input must not crash
    // (it previously asserted in getNextCharacter). It should parse as a
    // radical with an empty radicand, matching \sqrt{}.
    NSString *str = @"\\sqrt";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    MTRadical* rad = list.atoms[0];
    XCTAssertEqual(rad.type, kMTMathAtomRadical, @"%@", desc);
    XCTAssertEqualObjects(rad.nucleus, @"", @"%@", desc);

    MTMathList *subList = rad.radicand;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @0, @"%@", desc);
    XCTAssertNil(rad.degree, @"%@", desc);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\sqrt{}", @"%@", desc);
}

- (void) testSqrtInGroup
{
    // A \sqrt with no argument inside a brace group. With MTMathGroup semantics,
    // the {…} wraps as an Ord subformula — the radical lives inside the group.
    // This exercises the MTMathGroup path without crashing.
    NSString *str = @"{\\sqrt}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];

    XCTAssertNotNil(list, @"%@", desc);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
    // The outer atom is an MTMathGroup (Ord subformula wrapping the radical).
    MTMathGroup* group = list.atoms[0];
    XCTAssertEqual(group.type, kMTMathAtomOrdGroup, @"%@", desc);

    XCTAssertEqualObjects(@(group.innerList.atoms.count), @1, @"%@", desc);
    MTRadical* rad = group.innerList.atoms[0];
    XCTAssertEqual(rad.type, kMTMathAtomRadical, @"%@", desc);

    MTMathList *subList = rad.radicand;
    XCTAssertNotNil(subList, @"%@", desc);
    XCTAssertEqualObjects(@(subList.atoms.count), @0, @"%@", desc);
    XCTAssertNil(rad.degree, @"%@", desc);

    // convert it back to latex — braces preserved, radical serializes as \sqrt{}
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"{\\sqrt{}}", @"%@", desc);
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
             @[@"\\left\\langle x \\right\\rangle", @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomVariable)], @"\u27E8", @"\u27E9", @"\\left< x\\right> "],
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
             // Double arrows (REN-1): Uparrow/Downarrow nuclei must be the actual Unicode glyphs, not the literal strings "21D1"/"21D3"
             @[@"\\left\\Uparrow x \\right\\Downarrow",
               @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomVariable)],
               @"\u21D1", @"\u21D3",
               @"\\left\\Uparrow x\\right\\Downarrow "],
             // Updownarrow (REN-1): nucleus must be the Unicode glyph U+21D5, not the literal string "21D5"
             @[@"\\left\\Updownarrow x \\right\\Updownarrow",
               @[ @(kMTMathAtomInner) ], @0, @[ @(kMTMathAtomVariable)],
               @"\u21D5", @"\u21D5",
               @"\\left\\Updownarrow x\\right\\Updownarrow "],
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
    XCTAssertEqual(frac.styleOverride, kMTFractionStyleAuto);
    XCTAssertFalse(frac.isContinuedFraction);
    XCTAssertEqual(frac.numeratorAlignment, kMTFractionAlignmentCenter);

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

- (void) testFractionAppendLaTexWithStyleOverride
{
    // Build an MTFraction directly, set styleOverride, then serialize.
    // (Parser support for \dfrac etc. arrives in item 7.)
    MTFraction* dfrac = [MTFraction new];
    dfrac.numerator = [MTMathListBuilder buildFromString:@"a"];
    dfrac.denominator = [MTMathListBuilder buildFromString:@"b"];
    dfrac.styleOverride = kMTFractionStyleDisplay;
    MTMathList* dlist = [MTMathList new];
    [dlist addAtom:dfrac];
    NSString* dlatex = [MTMathListBuilder mathListToString:dlist];
    XCTAssertEqualObjects(dlatex, @"\\frac{\\displaystyle{a}}{\\displaystyle{b}}");

    MTFraction* tfrac = [MTFraction new];
    tfrac.numerator = [MTMathListBuilder buildFromString:@"a"];
    tfrac.denominator = [MTMathListBuilder buildFromString:@"b"];
    tfrac.styleOverride = kMTFractionStyleText;
    MTMathList* tlist = [MTMathList new];
    [tlist addAtom:tfrac];
    NSString* tlatex = [MTMathListBuilder mathListToString:tlist];
    XCTAssertEqualObjects(tlatex, @"\\frac{\\textstyle{a}}{\\textstyle{b}}");

    // \dbinom-shaped (hasRule = NO, ( ) delimiters, Display override)
    MTFraction* dbinom = [[MTFraction alloc] initWithRule:NO];
    dbinom.numerator = [MTMathListBuilder buildFromString:@"n"];
    dbinom.denominator = [MTMathListBuilder buildFromString:@"k"];
    dbinom.leftDelimiter = @"(";
    dbinom.rightDelimiter = @")";
    dbinom.styleOverride = kMTFractionStyleDisplay;
    MTMathList* dblist = [MTMathList new];
    [dblist addAtom:dbinom];
    NSString* dblatex = [MTMathListBuilder mathListToString:dblist];
    XCTAssertEqualObjects(dblatex, @"{\\displaystyle{n} \\choose \\displaystyle{k}}");
}

- (void) testDfrac
{
    NSString *str = @"\\dfrac1c";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction);
    XCTAssertTrue(frac.hasRule);
    XCTAssertEqual(frac.styleOverride, kMTFractionStyleDisplay);
    XCTAssertFalse(frac.isContinuedFraction);
    XCTAssertEqual(frac.numeratorAlignment, kMTFractionAlignmentCenter);
    XCTAssertNil(frac.leftDelimiter);
    XCTAssertNil(frac.rightDelimiter);
    // numerator = "1", denominator = "c"
    XCTAssertEqualObjects(@(frac.numerator.atoms.count), @1);
    XCTAssertEqualObjects(((MTMathAtom*)frac.numerator.atoms[0]).nucleus, @"1");
    XCTAssertEqualObjects(@(frac.denominator.atoms.count), @1);
    XCTAssertEqualObjects(((MTMathAtom*)frac.denominator.atoms[0]).nucleus, @"c");
    // Round-trip wraps each operand in \displaystyle rather than emitting
    // \dfrac directly. Re-parsing produces MTMathStyle(Display) atoms inside
    // each operand sub-list and styleOverride = kMTFractionStyleAuto on the
    // fraction itself (partial-fidelity trade-off per LLD 3.3.5 / 5.1).
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\frac{\\displaystyle{1}}{\\displaystyle{c}}");
}

- (void) testTfrac
{
    NSString *str = @"\\tfrac1c";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    XCTAssertNotNil(list);
    MTFraction* frac = list.atoms[0];
    XCTAssertTrue(frac.hasRule);
    XCTAssertEqual(frac.styleOverride, kMTFractionStyleText);
    XCTAssertFalse(frac.isContinuedFraction);
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\frac{\\textstyle{1}}{\\textstyle{c}}");
}

- (void) testDbinom
{
    NSString *str = @"\\dbinom{n}{k}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    XCTAssertNotNil(list);
    MTFraction* frac = list.atoms[0];
    XCTAssertFalse(frac.hasRule);
    XCTAssertEqualObjects(frac.leftDelimiter, @"(");
    XCTAssertEqualObjects(frac.rightDelimiter, @")");
    XCTAssertEqual(frac.styleOverride, kMTFractionStyleDisplay);
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"{\\displaystyle{n} \\choose \\displaystyle{k}}");
}

- (void) testTbinom
{
    NSString *str = @"\\tbinom{n}{k}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    XCTAssertNotNil(list);
    MTFraction* frac = list.atoms[0];
    XCTAssertFalse(frac.hasRule);
    XCTAssertEqualObjects(frac.leftDelimiter, @"(");
    XCTAssertEqualObjects(frac.rightDelimiter, @")");
    XCTAssertEqual(frac.styleOverride, kMTFractionStyleText);
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"{\\textstyle{n} \\choose \\textstyle{k}}");
}

- (void) testCfrac
{
    NSString *str = @"\\cfrac{a}{b}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    XCTAssertNotNil(list);
    MTFraction* frac = list.atoms[0];
    XCTAssertTrue(frac.hasRule);
    XCTAssertEqual(frac.styleOverride, kMTFractionStyleDisplay);
    XCTAssertTrue(frac.isContinuedFraction);
    XCTAssertEqual(frac.numeratorAlignment, kMTFractionAlignmentCenter);
    // Round-trip is lossy: the cfrac flag and alignment are not emitted.
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\frac{\\displaystyle{a}}{\\displaystyle{b}}");
}

- (void) testCfracLeftAlign
{
    NSString *str = @"\\cfrac[l]{a}{b}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    XCTAssertNotNil(list);
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.numeratorAlignment, kMTFractionAlignmentLeft);
    XCTAssertTrue(frac.isContinuedFraction);
    // Round-trip drops the [l] alignment (and the \cfrac flag); the output
    // is indistinguishable from \cfrac{a}{b}. Asserting it here pins the
    // lossy contract so a future serializer change can't silently emit
    // alignment data in a form the parser can't read back.
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\frac{\\displaystyle{a}}{\\displaystyle{b}}");
}

- (void) testCfracRightAlign
{
    NSString *str = @"\\cfrac[r]{a}{b}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.numeratorAlignment, kMTFractionAlignmentRight);
    // Round-trip drops the [r] alignment; same lossy contract as [l].
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\frac{\\displaystyle{a}}{\\displaystyle{b}}");
}

- (void) testCfracCenterAlignExplicit
{
    NSString *str = @"\\cfrac[c]{a}{b}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    MTFraction* frac = list.atoms[0];
    XCTAssertEqual(frac.numeratorAlignment, kMTFractionAlignmentCenter);
}

- (void) testCfracInvalidAlign
{
    NSString *str = @"\\cfrac[zzz]{a}{b}";
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNil(list);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

- (void) testDfracInDfrac
{
    NSString *str = @"\\dfrac{1}{x+\\dfrac{1}{y}}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    MTFraction* outer = list.atoms[0];
    XCTAssertEqual(outer.styleOverride, kMTFractionStyleDisplay);
    // Denominator: x + (inner dfrac)
    // Find the inner fraction inside the denominator
    MTFraction* inner = nil;
    for (MTMathAtom* atom in outer.denominator.atoms) {
        if (atom.type == kMTMathAtomFraction) {
            inner = (MTFraction*)atom;
            break;
        }
    }
    XCTAssertNotNil(inner);
    XCTAssertEqual(inner.styleOverride, kMTFractionStyleDisplay);
}

- (void) testMultiIntegrals
{
    NSDictionary<NSString*, NSString*>* expected = @{
        @"iint"             : @"∬",
        @"iiint"            : @"∭",
        @"iiiint"           : @"⨌",
        @"oiint"            : @"∯",
        @"oiiint"           : @"∰",
        @"varointclockwise" : @"∲",
        @"ointctrclockwise" : @"∳",
    };
    for (NSString* cmd in expected) {
        NSString* str = [NSString stringWithFormat:@"\\%@", cmd];
        MTMathList* list = [MTMathListBuilder buildFromString:str];
        NSString* desc = [NSString stringWithFormat:@"command \\%@", cmd];
        XCTAssertNotNil(list, @"%@", desc);
        XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);
        MTMathAtom* atom = list.atoms[0];
        XCTAssertEqual(atom.type, kMTMathAtomLargeOperator, @"%@", desc);
        XCTAssertEqualObjects(atom.nucleus, expected[cmd], @"%@", desc);
        MTLargeOperator* op = (MTLargeOperator*)atom;
        XCTAssertFalse(op.limits, @"%@", desc);
        // Round-trip
        NSString* latex = [MTMathListBuilder mathListToString:list];
        // appendLaTeXToString: emits "\<cmd> " with a trailing space; strip for comparison.
        NSString* trimmed = [latex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        XCTAssertEqualObjects(trimmed, str, @"%@", desc);
    }
}

- (void) testIintWithLimitsModifier
{
    NSString *str = @"\\iint\\limits_a^b";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    XCTAssertNotNil(list);
    MTLargeOperator* op = list.atoms[0];
    XCTAssertEqualObjects(op.nucleus, @"∬");
    XCTAssertTrue(op.limits);
    XCTAssertNotNil(op.subScript);
    XCTAssertNotNil(op.superScript);
    // Round-trip should include \limits (since default for \iint is NO).
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\iint \\limits ^{b}_{a}");
}

- (void) testIntStillRoundTripsAsInt
{
    // Regression: the existing \int (U+222B) must still serialize as \int, not as
    // \iint or anything else. The short-command-wins tiebreaker keeps it stable.
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\int"];
    NSString* latex = [MTMathListBuilder mathListToString:list];
    NSString* trimmed = [latex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    XCTAssertEqualObjects(trimmed, @"\\int");
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
    // Cells render in textstyle, stored on the table rather than per-cell.
    XCTAssertEqual(table.cellStyle, kMTLineStyleText);

    for (int i = 0; i < 2; i++) {
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
    XCTAssertEqualObjects(latex, @"\\begin{matrix}x&y\\\\ z&w\\end{matrix}");
}

- (void) testSmallMatrix
{
    NSString *str = @"\\begin{smallmatrix} x & y \\\\ z & w \\end{smallmatrix}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];

    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTMathTable* table = list.atoms[0];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    XCTAssertEqualObjects(table.nucleus, @"");
    XCTAssertEqualObjects(table.environment, @"smallmatrix");
    XCTAssertEqual(table.interRowAdditionalSpacing, 0);
    // Honest amsmath value: \thickspace = 5mu, stored unscaled. PR 1's renderer
    // scales it to the Script cell style at layout time (5 * scriptScaleDown outer-mu).
    XCTAssertEqual(table.interColumnSpacing, 5);
    XCTAssertEqual(table.numRows, 2);
    XCTAssertEqual(table.numColumns, 2);
    // Cells render in scriptstyle, stored on the table rather than per-cell.
    XCTAssertEqual(table.cellStyle, kMTLineStyleScript);

    for (int i = 0; i < 2; i++) {
        MTColumnAlignment alignment = [table getAlignmentForColumn:i];
        XCTAssertEqual(alignment, kMTColumnAlignmentCenter);
        for (int j = 0; j < 2; j++) {
            MTMathList* cell = table.cells[j][i];
            XCTAssertEqual(cell.atoms.count, 1);
            MTMathAtom* atom = cell.atoms[0];
            XCTAssertEqual(atom.type, kMTMathAtomVariable);
        }
    }

    // round-trip: cells carry no injected style atom (style is on table.cellStyle)
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\begin{smallmatrix}x&y\\\\ z&w\\end{smallmatrix}");
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
    // Cells render in textstyle, stored on the table rather than per-cell.
    XCTAssertEqual(table.cellStyle, kMTLineStyleText);

    for (int i = 0; i < 2; i++) {
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

- (void) testGathered
{
    NSString *str = @"\\begin{gathered} x \\\\ y \\end{gathered}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];

    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTMathTable* table = list.atoms[0];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    XCTAssertEqualObjects(table.environment, @"gathered");
    XCTAssertEqual(table.interRowAdditionalSpacing, 1);
    XCTAssertEqual(table.interColumnSpacing, 0);
    XCTAssertEqual(table.numRows, 2);
    XCTAssertEqual(table.numColumns, 1);
    XCTAssertEqual([table getAlignmentForColumn:0], kMTColumnAlignmentCenter);

    // single centered column, no injected atoms — straight round-trip
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\begin{gathered}x\\\\ y\\end{gathered}");
}

- (void) testAlignedat
{
    NSString *str = @"\\begin{alignedat}{2} 10&x +& 3&y \\\\ 3&x +& 13&y \\end{alignedat}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];

    XCTAssertNotNil(list);
    XCTAssertEqualObjects(@(list.atoms.count), @1);
    MTMathTable* table = list.atoms[0];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    XCTAssertEqualObjects(table.environment, @"alignedat");
    XCTAssertEqual(table.interRowAdditionalSpacing, 1);
    XCTAssertEqual(table.interColumnSpacing, 0);
    XCTAssertEqual(table.numRows, 2);
    XCTAssertEqual(table.numColumns, 4);

    // alternating Right / Left across the 2 alignment pairs
    MTColumnAlignment expected[4] = {
        kMTColumnAlignmentRight, kMTColumnAlignmentLeft,
        kMTColumnAlignmentRight, kMTColumnAlignmentLeft };
    for (int j = 0; j < 4; j++) {
        XCTAssertEqual([table getAlignmentForColumn:j], expected[j]);
    }

    // a relation spacer (empty ordinary) is injected at index 0 of every odd column
    for (int row = 0; row < 2; row++) {
        for (int col = 0; col < 4; col++) {
            MTMathList* cell = table.cells[row][col];
            if (col % 2 == 1) {
                MTMathAtom* spacer = cell.atoms[0];
                XCTAssertEqual(spacer.type, kMTMathAtomOrdinary);
                XCTAssertEqual(spacer.nucleus.length, 0u);
            } else {
                XCTAssertEqual(cell.atoms[0].type, kMTMathAtomNumber);
            }
        }
    }
}

static NSArray* getTestDataParseErrors() {
    return @[
              @[@"}a", @(MTParseErrorMismatchBraces)],
              @[@"\\notacommand", @(MTParseErrorInvalidCommand)],
              @[@"\\sqrt[5+3", @(MTParseErrorCharacterNotFound)],
              @[@"\\smash[t", @(MTParseErrorCharacterNotFound)], // missing ] on smash optional arg
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
              @[@"\\begin{gathered} x & y \\end{gathered}", @(MTParseErrorInvalidNumColumns)],
              @[@"\\nolimits", @(MTParseErrorInvalidLimits)],
              @[@"\\frac\\limits{1}{2}", @(MTParseErrorInvalidLimits)],
              // REN-6: generalized-fraction commands are illegal in one-char script slots
              @[@"x^\\over y",   @(MTParseErrorInvalidCommand)],
              @[@"x_\\over y",   @(MTParseErrorInvalidCommand)],
              @[@"x^\\atop y",   @(MTParseErrorInvalidCommand)],
              @[@"x^\\choose y", @(MTParseErrorInvalidCommand)],
              @[@"x^\\brack y",  @(MTParseErrorInvalidCommand)],
              @[@"x^\\brace y",  @(MTParseErrorInvalidCommand)],
              // REN-5: non-ASCII literal characters should produce MTParseErrorInvalidCharacter
              @[@"π", @(MTParseErrorInvalidCharacter)],          // π (U+03C0)
              @[@"3 × 4", @(MTParseErrorInvalidCharacter)],      // 3 × 4
              @[@"x ≤ y", @(MTParseErrorInvalidCharacter)],      // x ≤ y
              @[@"x 𝑎 y", @(MTParseErrorInvalidCharacter)],      // above-BMP literal (U+1D44E, surrogate pair)
              // Special characters with no meaning in math mode are errors (match LaTeX:
              // % is a comment, # is a macro parameter, $ toggles math mode - none valid here).
              @[@"a % b", @(MTParseErrorInvalidCharacter)],
              @[@"a # b", @(MTParseErrorInvalidCharacter)],
              @[@"a $ b", @(MTParseErrorInvalidCharacter)],
              // Item 4: spacing dimension parse errors
              @[@"\\kern", @(MTParseErrorInvalidCommand)],          // missing distance at EOF
              @[@"\\kernabc", @(MTParseErrorInvalidCommand)],       // no number/unit
              @[@"\\hspace{abc}", @(MTParseErrorInvalidCommand)],   // no number/unit
              @[@"\\hspace{}", @(MTParseErrorInvalidCommand)],      // empty
              @[@"\\mkern{1em}", @(MTParseErrorInvalidCommand)],    // mu required for \mkern
              @[@"\\kern1pt", @(MTParseErrorInvalidCommand)],      // valid number, unsupported unit
              @[@"\\kern1xx", @(MTParseErrorInvalidCommand)],      // valid number, unknown unit
              @[@"\\begin{alignedat} x & y \\end{alignedat}", @(MTParseErrorInvalidCommand)],  // missing {n}
              @[@"\\begin{alignedat}{x} a&b \\end{alignedat}", @(MTParseErrorInvalidCommand)],      // non-numeric
              @[@"\\begin{alignedat}{0} a&b \\end{alignedat}", @(MTParseErrorInvalidCommand)],      // n < 1
              @[@"\\begin{alignedat}{2} a&b&c \\end{alignedat}", @(MTParseErrorInvalidNumColumns)], // 3 cols != 2n
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

// REN-5: characters TeX silently discards (whitespace catcode 10/5 and NUL
// catcode 9) must continue to parse without error. Guards against the error
// path swallowing legitimate whitespace.
- (void) testIgnoredWhitespaceCharacters
{
    unichar nulChars[3] = { 'x', 0x0000, 'y' };
    NSString* withNul = [NSString stringWithCharacters:nulChars length:3];
    NSArray* inputs = @[ @"x\ty", @"x\ny", @"x\ry", withNul ];
    for (NSString* str in inputs) {
        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
        NSString* desc = [NSString stringWithFormat:@"whitespace input %@", str];
        XCTAssertNotNil(list, @"%@", desc);
        XCTAssertNil(error, @"%@", desc);
        XCTAssertEqual(list.atoms.count, 2u, @"%@", desc);
        XCTAssertEqual([list.atoms[0] type], kMTMathAtomVariable, @"%@", desc);
        XCTAssertEqual([list.atoms[1] type], kMTMathAtomVariable, @"%@", desc);
    }
}

// REN-6: \over inside an explicit-brace script group must still parse correctly.
- (void) testOverInScriptBraces
{
    NSString* str = @"x^{1 \\over y}";
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNotNil(list, @"x^{1 \\over y} should parse without error");
    XCTAssertNil(error, @"x^{1 \\over y} should not produce an error");
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"x^{\\frac{1}{y}}", @"round-trip for x^{1 \\over y}");
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

- (void) testCustomSymbolDoesNotReplacePreferredReverseName
{
    MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u00B1"];
    [MTMathAtomFactory addLatexSymbol:@"zzpm" value:atom];

    XCTAssertEqualObjects([MTMathAtomFactory latexSymbolNameForAtom:atom], @"pm");
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
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"%@", desc);

    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomText, @"%@", desc);
    XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]], @"%@", desc);
    XCTAssertEqualObjects(((MTTextAtom *)atom).text, @"x y", @"%@", desc);
    XCTAssertEqual(((MTTextAtom *)atom).textStyle, kMTTextStyleRoman, @"%@", desc);
    XCTAssertEqual(atom.fontStyle, kMTFontStyleDefault, @"%@", desc);

    // convert it back to latex
    NSString* latex = [MTMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"\\text{x y}", @"%@", desc);
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
        @[ @"\\Biggm\\langle", @(kMTMathAtomRelation),@(kMTDelimiterSize4), @"\u27E8", @"\\Biggm<" ],
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
    // Each row: @[ command (no leading \), expected nucleus (NSNumber for codepoint or NSString) ]
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
        @[ @"nsucceq",         @0x22E1 ],
        @[ @"npreceq",         @0x22E0 ],
        @[ @"nsucccurlyeq",    @0x22E1, @"nsucceq" ],
        @[ @"npreccurlyeq",    @0x22E0, @"npreceq" ],
        @[ @"nprecsim",        @0x22E8 ],
        @[ @"nsuccsim",        @0x22E9 ],
        @[ @"nprecapprox",     @0x2AB9 ],
        @[ @"nsuccapprox",     @0x2ABA ],
        @[ @"precneq",         @0x2AB1 ],
        @[ @"succneq",         @0x2AB2 ],
        @[ @"precneqq",        @0x2AB5 ],
        @[ @"succneqq",        @0x2AB6 ],
        @[ @"precnsim",        @0x22E6 ],
        @[ @"succnsim",        @0x22E7 ],
        @[ @"precnapprox",     @0x2AB9, @"nprecapprox" ],
        @[ @"succnapprox",     @0x2ABA, @"nsuccapprox" ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)45);
    for (NSArray* r in rows) {
        NSString* cmd = r[0];
        unichar expectedNuc = (unichar)[r[1] unsignedIntegerValue];
        NSString* input = [@"\\" stringByAppendingString:cmd];
        NSString* expectedRTName = (r.count > 2) ? r[2] : cmd;

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
        NSString* expectedRT = [NSString stringWithFormat:@"a\\%@ b", expectedRTName];
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

- (void) testMissingRelationOperatorAndOrdinarySymbols
{
    // command, expected nucleus, expected atom type
    NSArray* rows = @[
        @[ @"lt",              @0x003C, @(kMTMathAtomRelation) ],
        @[ @"gt",              @0x003E, @(kMTMathAtomRelation) ],
        @[ @"frown",           @0x2322, @(kMTMathAtomRelation) ],
        @[ @"smile",           @0x2323, @(kMTMathAtomRelation) ],
        @[ @"bowtie",          @0x22C8, @(kMTMathAtomRelation) ],
        @[ @"longmapsto",      @0x27FC, @(kMTMathAtomRelation) ],
        @[ @"bigcirc",         @0x25EF, @(kMTMathAtomBinaryOperator) ],
        @[ @"bigtriangleup",   @0x25B3, @(kMTMathAtomBinaryOperator) ],
        @[ @"bigtriangledown", @0x25BD, @(kMTMathAtomBinaryOperator) ],
        @[ @"diamond",         @0x22C4, @(kMTMathAtomBinaryOperator) ],
        @[ @"surd",            @0x221A, @(kMTMathAtomOrdinary) ],
        @[ @"flat",            @0x266D, @(kMTMathAtomOrdinary) ],
        @[ @"natural",         @0x266E, @(kMTMathAtomOrdinary) ],
        @[ @"sharp",           @0x266F, @(kMTMathAtomOrdinary) ],
    ];
    XCTAssertEqual(rows.count, (NSUInteger)14);
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
        XCTAssertEqual(atom.type, expectedType, @"%@ type", input);
        XCTAssertEqual(atom.nucleus.length, (NSUInteger)1, @"%@ nucleus length", input);
        XCTAssertEqual([atom.nucleus characterAtIndex:0], expectedNuc, @"%@ nucleus", input);

        // Round-trip: surround with variables so finalize keeps the atom class stable.
        NSString* probe = [NSString stringWithFormat:@"a%@ b", input];
        MTMathList* probeList = [MTMathListBuilder buildFromString:probe error:&error];
        XCTAssertNil(error, @"%@", input);
        XCTAssertEqualObjects([MTMathListBuilder mathListToString:probeList],
                              ([NSString stringWithFormat:@"a%@ b", input]),
                              @"round-trip %@", input);
    }
}

- (void) testBigtriangleupIsBinaryOpDistinctFromTriangle
{
    // Same glyph (U+25B3), different atom class: \triangle is ordinary, \bigtriangleup is a binary op.
    MTMathAtom* tri = [MTMathListBuilder buildFromString:@"\\triangle"].atoms[0];
    MTMathAtom* big = [MTMathListBuilder buildFromString:@"\\bigtriangleup"].atoms[0];
    XCTAssertEqualObjects(tri.nucleus, big.nucleus);
    XCTAssertEqual(tri.type, kMTMathAtomOrdinary);
    XCTAssertEqual(big.type, kMTMathAtomBinaryOperator);
}

- (void) testDiamondIsBinaryOpDistinctFromDiamondsuit
{
    MTMathAtom* diamond = [MTMathListBuilder buildFromString:@"\\diamond"].atoms[0];
    MTMathAtom* suit = [MTMathListBuilder buildFromString:@"\\diamondsuit"].atoms[0];
    XCTAssertEqual(diamond.type, kMTMathAtomBinaryOperator);
    XCTAssertEqualObjects(diamond.nucleus, @"⋄");
    XCTAssertEqual(suit.type, kMTMathAtomOrdinary);
    XCTAssertEqualObjects(suit.nucleus, @"♢");
}

- (void) testStackrelFrown
{
    // Regression for #63: \stackrel{\frown}{AD}
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\stackrel{\\frown}{AD}" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(list);
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
}

- (void) testPrecedesSucceeds
{
    NSArray* rows = @[
        @[ @"prec",         @0x227A ],
        @[ @"succ",         @0x227B ],
        @[ @"preceq",       @0x2AAF ],
        @[ @"succeq",       @0x2AB0 ],
        @[ @"preccurlyeq",  @0x227C ],
        @[ @"succcurlyeq",  @0x227D ],
        @[ @"curlyeqprec",  @0x22DE ],
        @[ @"curlyeqsucc",  @0x22DF ],
        @[ @"precsim",      @0x227E ],
        @[ @"succsim",      @0x227F ],
        @[ @"precapprox",   @0x2AB7 ],
        @[ @"succapprox",   @0x2AB8 ],
    ];
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

#pragma mark - MTTextStyle factory APIs

- (void) testTextStyleWithNameKnown
{
    XCTAssertEqual([MTMathAtomFactory textStyleWithName:@"text"],   kMTTextStyleRoman);
    XCTAssertEqual([MTMathAtomFactory textStyleWithName:@"textrm"], kMTTextStyleRoman);
    XCTAssertEqual([MTMathAtomFactory textStyleWithName:@"textbf"], kMTTextStyleBold);
    XCTAssertEqual([MTMathAtomFactory textStyleWithName:@"textit"], kMTTextStyleItalic);
    XCTAssertEqual([MTMathAtomFactory textStyleWithName:@"textsf"], kMTTextStyleSansSerif);
    XCTAssertEqual([MTMathAtomFactory textStyleWithName:@"texttt"], kMTTextStyleTypewriter);
}

- (void) testTextStyleWithNameUnknown
{
    XCTAssertEqual([MTMathAtomFactory textStyleWithName:@"mathbf"], (MTTextStyle)NSNotFound);
    XCTAssertEqual([MTMathAtomFactory textStyleWithName:@"foobar"], (MTTextStyle)NSNotFound);
    XCTAssertEqual([MTMathAtomFactory textStyleWithName:@""],       (MTTextStyle)NSNotFound);
}

- (void) testCommandNameForTextStyle
{
    XCTAssertEqualObjects([MTMathAtomFactory commandNameForTextStyle:kMTTextStyleRoman],      @"text");
    XCTAssertEqualObjects([MTMathAtomFactory commandNameForTextStyle:kMTTextStyleBold],       @"textbf");
    XCTAssertEqualObjects([MTMathAtomFactory commandNameForTextStyle:kMTTextStyleItalic],     @"textit");
    XCTAssertEqualObjects([MTMathAtomFactory commandNameForTextStyle:kMTTextStyleSansSerif],  @"textsf");
    XCTAssertEqualObjects([MTMathAtomFactory commandNameForTextStyle:kMTTextStyleTypewriter], @"texttt");
}

#pragma mark - MTTextAtom parsing — body capture

- (void) testTextEmpty {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{}"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqualObjects(atom.text, @"");
    XCTAssertEqual(atom.textStyle, kMTTextStyleRoman);
}

- (void) testTextAscii {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{abc}"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"abc");
    XCTAssertEqual(atom.textStyle, kMTTextStyleRoman);
}

- (void) testTextStyles {
    NSDictionary *cases = @{
        @"\\textrm{x}":  @(kMTTextStyleRoman),
        @"\\text{x}":    @(kMTTextStyleRoman),
        @"\\textbf{x}":  @(kMTTextStyleBold),
        @"\\textit{x}":  @(kMTTextStyleItalic),
        @"\\textsf{x}":  @(kMTTextStyleSansSerif),
        @"\\texttt{x}":  @(kMTTextStyleTypewriter),
    };
    for (NSString *src in cases) {
        MTMathList *list = [MTMathListBuilder buildFromString:src];
        XCTAssertEqual(list.atoms.count, (NSUInteger)1, @"%@", src);
        MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
        XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]], @"%@", src);
        XCTAssertEqualObjects(atom.text, @"x", @"%@", src);
        XCTAssertEqual(atom.textStyle,
                       (MTTextStyle)[cases[src] unsignedIntegerValue],
                       @"%@", src);
    }
}

- (void) testTextSingleCharacterArgument {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textbf abc"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)3);

    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqualObjects(atom.text, @"a");
    XCTAssertEqual(atom.textStyle, kMTTextStyleBold);
    XCTAssertEqualObjects(list.atoms[1].nucleus, @"b");
    XCTAssertEqualObjects(list.atoms[2].nucleus, @"c");
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\textbf{a}bc");
}

- (void) testTextSingleEscapedArgument {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textit\\%"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);

    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqualObjects(atom.text, @"%");
    XCTAssertEqual(atom.textStyle, kMTTextStyleItalic);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\textit{\\%}");
}

- (void) testTextSingleNonLatinArgument {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text 你"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);

    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqualObjects(atom.text, @"你");
    XCTAssertEqual(atom.textStyle, kMTTextStyleRoman);
}

- (void) testTextChinese {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{你好}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"你好");
}

- (void) testTextCyrillicRoman {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{Привет}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"Привет");
    XCTAssertEqual(atom.textStyle, kMTTextStyleRoman);
}

- (void) testTextCyrillicBold {
    // Today \textbf{Привет} drops the body characters because Cyrillic
    // outside U+0411–U+044E is filtered and bold-font-trait styling is
    // unavailable. New path captures the body raw.
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textbf{Привет}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"Привет");
    XCTAssertEqual(atom.textStyle, kMTTextStyleBold);
}

- (void) testTextCyrillicItalic {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textit{Привет}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"Привет");
    XCTAssertEqual(atom.textStyle, kMTTextStyleItalic);
}

- (void) testTextDevanagari {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{नमस्ते}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"नमस्ते");
}

- (void) testTextHebrew {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{שלום}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"שלום");
}

- (void) testTextArabic {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{مرحبا}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"مرحبا");
}

- (void) testTextMixedScripts {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{Hello 你好 שלום}"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"Hello 你好 שלום");
}

- (void) testTextWithSpaces {
    // \textbf{a b} previously dropped the space silently because
    // _spacesAllowed was set only for \text. Raw capture keeps it.
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textbf{a b}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"a b");
    XCTAssertEqual(atom.textStyle, kMTTextStyleBold);
}

- (void) testTextEscapes {
    NSString *src = @"\\text{50\\% \\$5 \\{x\\} \\\\}";
    MTMathList *list = [MTMathListBuilder buildFromString:src];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"50% $5 {x} \\");
}

- (void) testTextBackslashSpace {
    // \<space> is the canonical LaTeX forced space in text mode. The legacy
    // parser accepted it via the single-char command table, so existing
    // inputs like \text{hello\ world} and \textbf{hello\ world} must keep
    // working under the new \text* path.
    MTMathList *plain = [MTMathListBuilder buildFromString:@"\\text{hello\\ world}"];
    MTTextAtom *plainAtom = (MTTextAtom *)plain.atoms[0];
    XCTAssertTrue([plainAtom isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqualObjects(plainAtom.text, @"hello world");

    MTMathList *bold = [MTMathListBuilder buildFromString:@"\\textbf{hello\\ world}"];
    MTTextAtom *boldAtom = (MTTextAtom *)bold.atoms[0];
    XCTAssertTrue([boldAtom isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqualObjects(boldAtom.text, @"hello world");
    XCTAssertEqual(boldAtom.textStyle, kMTTextStyleBold);
}

- (void) testTextUnicodeWhitespace {
    // U+00A0 NBSP must pass through unchanged.
    NSString *src = [NSString stringWithFormat:@"\\text{a%Cb}", (unichar)0x00A0];
    MTMathList *list = [MTMathListBuilder buildFromString:src];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    NSString *expected = [NSString stringWithFormat:@"a%Cb", (unichar)0x00A0];
    XCTAssertEqualObjects(atom.text, expected);
}

- (void) testTextNestedBraceGrouping {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{a {b} c}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"a b c");
}

- (void) testTextDeeplyNestedGrouping {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{{{x}}}"];
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertEqualObjects(atom.text, @"x");
}

#pragma mark - MTTextAtom parsing — scripts

- (void) testTextSuperscript {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textbf{abc}^2"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]]);
    XCTAssertNotNil(atom.superScript);
    XCTAssertEqual(atom.superScript.atoms.count, (NSUInteger)1);
    XCTAssertEqualObjects(atom.superScript.atoms[0].nucleus, @"2");
}

- (void) testTextSubAndSuperscript {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textbf{abc}_i^{n+1}"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTTextAtom *atom = (MTTextAtom *)list.atoms[0];
    XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqualObjects(atom.text, @"abc");

    XCTAssertNotNil(atom.subScript);
    XCTAssertEqual(atom.subScript.atoms.count, (NSUInteger)1);
    XCTAssertEqualObjects(atom.subScript.atoms[0].nucleus, @"i");

    XCTAssertNotNil(atom.superScript);
    XCTAssertEqual(atom.superScript.atoms.count, (NSUInteger)3);
    XCTAssertEqualObjects(atom.superScript.atoms[0].nucleus, @"n");
    XCTAssertEqualObjects(atom.superScript.atoms[1].nucleus, @"+");
    XCTAssertEqualObjects(atom.superScript.atoms[2].nucleus, @"1");

    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list],
                          @"\\textbf{abc}^{n+1}_{i}");
}

#pragma mark - MTTextAtom parsing — round-trip

- (void) testTextRoundTripChineseBold {
    NSString *src = @"\\textbf{你好}";
    MTMathList *list = [MTMathListBuilder buildFromString:src];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], src);
}

- (void) testTextRoundTripWithScript {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textbf{你好}^{2}"];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list],
                          @"\\textbf{你好}^{2}");
}

- (void) testTextRoundTripEscapes {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{50\\% \\$5}"];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list],
                          @"\\text{50\\% \\$5}");
}

#pragma mark - MTTextAtom parsing — error cases

- (void) testTextMissingArgument {
    NSError *error = nil;
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textbf"
                                                     error:&error];
    XCTAssertNil(list);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, MTParseErrorCharacterNotFound);
}

- (void) testTextMissingCloseBrace {
    NSError *error = nil;
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{abc"
                                                     error:&error];
    XCTAssertNil(list);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, MTParseErrorMismatchBraces);
}

- (void) testTextUnbalancedNestedBrace {
    NSError *error = nil;
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{a{b}"
                                                     error:&error];
    XCTAssertNil(list);
    XCTAssertEqual(error.code, MTParseErrorMismatchBraces);
}

- (void) testTextNestedTextRejected {
    NSError *error = nil;
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textbf{\\textit{x}}"
                                                     error:&error];
    XCTAssertNil(list);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

- (void) testTextDollarRejected {
    NSError *error = nil;
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{$x$}"
                                                     error:&error];
    XCTAssertNil(list);
    XCTAssertNotNil(error);
}

- (void) testTextUnknownEscapeRejected {
    NSError *error = nil;
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{a\\foo b}"
                                                     error:&error];
    XCTAssertNil(list);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

- (void) testRawCyrillicDropped {
    // Post-removal: raw Cyrillic outside \text* drops to nothing.
    // Pre-removal: U+0411–U+044E silently became Variable atoms.
    MTMathList *list = [MTMathListBuilder buildFromString:@"Привет"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)0);
}

- (void) testRawCyrillicInTextStillWorks {
    // Sanity: the only supported path is \text* — already covered
    // elsewhere, repeated here for symmetry against the regression.
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{Привет}"];
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    XCTAssertEqualObjects(((MTTextAtom *)list.atoms[0]).text, @"Привет");
}

- (void)testStackCommandSpecArgRoles
{
    MTMathStackCommandSpec* overset = [MTMathAtomFactory stackCommandSpec:@"overset"];
    XCTAssertNotNil(overset);
    XCTAssertEqualObjects(overset.argRoles, (@[@(kMTStackArgOver), @(kMTStackArgBase)]));
    XCTAssertTrue(overset.inheritsClass);

    MTMathStackCommandSpec* underset = [MTMathAtomFactory stackCommandSpec:@"underset"];
    XCTAssertEqualObjects(underset.argRoles, (@[@(kMTStackArgUnder), @(kMTStackArgBase)]));
    XCTAssertTrue(underset.inheritsClass);

    MTMathStackCommandSpec* stackrel = [MTMathAtomFactory stackCommandSpec:@"stackrel"];
    XCTAssertFalse(stackrel.inheritsClass);
    XCTAssertEqual(stackrel.displayClass, kMTMathAtomRelation);

    MTMathStackCommandSpec* stackbin = [MTMathAtomFactory stackCommandSpec:@"stackbin"];
    XCTAssertEqual(stackbin.displayClass, kMTMathAtomBinaryOperator);

    // Existing stretchy command keeps a base-only role list.
    MTMathStackCommandSpec* over = [MTMathAtomFactory stackCommandSpec:@"overrightarrow"];
    XCTAssertEqualObjects(over.argRoles, (@[@(kMTStackArgBase)]));
    XCTAssertFalse(over.inheritsClass);

    XCTAssertNil([MTMathAtomFactory stackCommandSpec:@"overfoo"]);
}

- (void)testInheritedDisplayClassForBase
{
    MTMathList* (^one)(unichar) = ^MTMathList*(unichar ch) {
        MTMathList* l = [MTMathList new];
        [l addAtom:[MTMathAtomFactory atomForCharacter:ch]];
        return l;
    };
    // Lone relation '=' -> Relation; lone binary '+' -> Binary (intrinsic, pre-finalize).
    XCTAssertEqual([MTMathAtomFactory inheritedDisplayClassForBase:one('=')], kMTMathAtomRelation);
    XCTAssertEqual([MTMathAtomFactory inheritedDisplayClassForBase:one('+')], kMTMathAtomBinaryOperator);
    // Lone ordinary letter -> Ordinary.
    XCTAssertEqual([MTMathAtomFactory inheritedDisplayClassForBase:one('x')], kMTMathAtomOrdinary);
    // Multi-atom base -> Ordinary.
    MTMathList* multi = [MTMathList new];
    [multi addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    [multi addAtom:[MTMathAtomFactory atomForCharacter:'+']];
    [multi addAtom:[MTMathAtomFactory atomForCharacter:'y']];
    XCTAssertEqual([MTMathAtomFactory inheritedDisplayClassForBase:multi], kMTMathAtomOrdinary);
    // Empty base -> Ordinary.
    XCTAssertEqual([MTMathAtomFactory inheritedDisplayClassForBase:[MTMathList new]], kMTMathAtomOrdinary);
}

- (void)testOversetParsesStructureAndClass
{
    NSArray<NSArray*>* cases = @[
        // latex, expected displayClass, hasOver, hasUnder
        @[@"\\stackrel{?}{=}", @(kMTMathAtomRelation),       @YES, @NO],
        @[@"\\stackbin{x}{+}", @(kMTMathAtomBinaryOperator), @YES, @NO],
        @[@"\\overset{!}{=}",  @(kMTMathAtomRelation),       @YES, @NO],
        @[@"\\overset{a}{+}",  @(kMTMathAtomBinaryOperator), @YES, @NO],
        @[@"\\overset{a}{x}",  @(kMTMathAtomOrdinary),       @YES, @NO],
        @[@"\\overset{a}{x+y}",@(kMTMathAtomOrdinary),       @YES, @NO],
        @[@"\\underset{b}{=}", @(kMTMathAtomRelation),       @NO,  @YES],
        @[@"\\underset{b}{x}", @(kMTMathAtomOrdinary),       @NO,  @YES],
    ];
    for (NSArray* c in cases) {
        NSString* latex = c[0];
        MTMathList* list = [MTMathListBuilder buildFromString:latex];
        XCTAssertNotNil(list, @"%@", latex);
        XCTAssertEqual(list.atoms.count, 1u, @"%@", latex);
        MTMathStack* stack = list.atoms[0];
        XCTAssertEqual(stack.type, kMTMathAtomStack, @"%@", latex);
        XCTAssertEqual(stack.displayClass, [c[1] unsignedIntegerValue], @"%@", latex);
        XCTAssertNotNil(stack.innerList, @"%@", latex);
        if ([c[2] boolValue]) {
            XCTAssertNotNil(stack.over, @"%@", latex);
            XCTAssertEqual(stack.over.kind, kMTMathStackConstructionMathList, @"%@", latex);
        } else {
            XCTAssertNil(stack.over, @"%@", latex);
        }
        if ([c[3] boolValue]) {
            XCTAssertNotNil(stack.under, @"%@", latex);
            XCTAssertEqual(stack.under.kind, kMTMathStackConstructionMathList, @"%@", latex);
        } else {
            XCTAssertNil(stack.under, @"%@", latex);
        }
    }
}

- (void)testOversetMissingArgsAreGraceful
{
    // Matches \frac: missing args at EOF produce empty rows, no crash, no parse error.
    for (NSString* latex in @[@"\\overset", @"\\overset{a}", @"\\underset", @"\\stackrel{a}"]) {
        NSError* error = nil;
        MTMathList* list = [MTMathListBuilder buildFromString:latex error:&error];
        XCTAssertNotNil(list, @"%@", latex);
        XCTAssertNil(error, @"%@", latex);
        XCTAssertEqual(list.atoms.count, 1u, @"%@", latex);
        XCTAssertEqual(((MTMathAtom*)list.atoms[0]).type, kMTMathAtomStack, @"%@", latex);
    }
}

- (void)testOversetNestingParse
{
    // \underset{b}{\overset{a}{X}} -> outer under-stack whose base is an inner over-stack.
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\underset{b}{\\overset{a}{X}}"];
    XCTAssertNotNil(list);
    XCTAssertEqual(list.atoms.count, 1u);
    MTMathStack* outer = list.atoms[0];
    XCTAssertEqual(outer.type, kMTMathAtomStack);
    XCTAssertNotNil(outer.under);
    XCTAssertNil(outer.over);
    XCTAssertEqual(outer.innerList.atoms.count, 1u);
    MTMathStack* inner = outer.innerList.atoms[0];
    XCTAssertEqual(inner.type, kMTMathAtomStack);
    XCTAssertNotNil(inner.over);
    XCTAssertNil(inner.under);
}

- (void)testOversetRoundTrip
{
    NSArray<NSArray*>* cases = @[
        @[@"\\stackrel{?}{=}", @"\\stackrel{?}{=}"],
        @[@"\\stackbin{x}{+}", @"\\stackbin{x}{+}"],
        @[@"\\underset{b}{x}", @"\\underset{b}{x}"],
        @[@"\\overset{a}{x}",  @"\\overset{a}{x}"],
        @[@"\\overset{a}{+}",  @"\\stackbin{a}{+}"],  // inherited Binary canonicalizes to \stackbin
        @[@"\\overset{!}{=}",  @"\\stackrel{!}{=}"],  // inherited Relation canonicalizes to \stackrel
    ];
    for (NSArray* c in cases) {
        MTMathList* list = [MTMathListBuilder buildFromString:c[0]];
        XCTAssertNotNil(list, @"%@", c[0]);
        NSString* latex = [MTMathListBuilder mathListToString:list];
        XCTAssertEqualObjects(latex, c[1], @"%@", c[0]);
        // Round-trip is at least an equivalent fixed point (re-parse + re-serialize stable).
        NSString* latex2 = [MTMathListBuilder mathListToString:[MTMathListBuilder buildFromString:latex]];
        XCTAssertEqualObjects(latex2, c[1], @"%@", c[0]);
    }
}

- (void)testProgrammaticBothRowsSerializeNested
{
    // A stack carrying both over and under MathList rows emits nested commands.
    MTMathStack* stack = [MTMathStack new];
    MTMathList* base = [MTMathList new];
    [base addAtom:[MTMathAtomFactory atomForCharacter:'X']];
    MTMathList* top = [MTMathList new];
    [top addAtom:[MTMathAtomFactory atomForCharacter:'a']];
    MTMathList* bot = [MTMathList new];
    [bot addAtom:[MTMathAtomFactory atomForCharacter:'b']];
    stack.innerList = base;
    stack.over = [MTMathStackConstruction mathListWithList:top];
    stack.under = [MTMathStackConstruction mathListWithList:bot];
    MTMathList* list = [MTMathList new];
    [list addAtom:stack];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\underset{b}{\\overset{a}{X}}");
}

#pragma mark - \color and \colorbox tests

- (void)testColorValidHexSix
{
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\color{#ff0000}x" error:&error];
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertNotNil(list);
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTMathColor* colorAtom = (MTMathColor*)list.atoms[0];
    XCTAssertEqual(colorAtom.type, kMTMathAtomColor);
    XCTAssertEqualObjects(colorAtom.colorString, @"#ff0000");
    XCTAssertNotNil(colorAtom.innerList);
    XCTAssertEqual(colorAtom.innerList.atoms.count, (NSUInteger)1);
    // stringValue round-trip (mathListToString uses appendLaTeXToString: which MTMathColor
    // inherits from the base class; stringValue is the color-specific round-trip method).
    XCTAssertEqualObjects(colorAtom.stringValue, @"\\color{#ff0000}{x}");
}

- (void)testColorValidHexThree
{
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\color{#f00}x" error:&error];
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertNotNil(list);
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTMathColor* colorAtom = (MTMathColor*)list.atoms[0];
    XCTAssertEqual(colorAtom.type, kMTMathAtomColor);
    XCTAssertEqualObjects(colorAtom.colorString, @"#f00");
}

- (void)testColorboxValidHexSix
{
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\colorbox{#00ff00}x" error:&error];
    XCTAssertNil(error, @"Unexpected error: %@", error);
    XCTAssertNotNil(list);
    XCTAssertEqual(list.atoms.count, (NSUInteger)1);
    MTMathColorbox* colorboxAtom = (MTMathColorbox*)list.atoms[0];
    XCTAssertEqual(colorboxAtom.type, kMTMathAtomColorbox);
    XCTAssertEqualObjects(colorboxAtom.colorString, @"#00ff00");
}

- (void)testColorInvalidNamedColorIsParseError
{
    // Named colors like "red" must be a parse error (not a silent no-op).
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\color{red}x" error:&error];
    XCTAssertNil(list, @"Expected nil list for invalid color");
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

- (void)testColorInvalidMissingHashIsParseError
{
    // "ff0000" without leading # must be a parse error (silent failure bug).
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\color{ff0000}x" error:&error];
    XCTAssertNil(list, @"Expected nil list for color missing #");
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

- (void)testColorInvalidNonHexDigitIsParseError
{
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\color{#gg0000}x" error:&error];
    XCTAssertNil(list, @"Expected nil list for non-hex color");
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

- (void)testColorInvalidWrongLengthIsParseError
{
    // 4-digit hex is neither #RGB nor #RRGGBB.
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\color{#ff00}x" error:&error];
    XCTAssertNil(list, @"Expected nil list for wrong-length color");
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

- (void)testColorboxInvalidNamedColorIsParseError
{
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\colorbox{red}x" error:&error];
    XCTAssertNil(list, @"Expected nil list for invalid colorbox color");
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

- (void)testColorInvalidEmbeddedWhitespaceIsParseError
{
    // An embedded space must be captured into the token and rejected as an
    // invalid color, not break token reading early and yield "Missing }".
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\color{#ff 00}x" error:&error];
    XCTAssertNil(list, @"Expected nil list for color with embedded whitespace");
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

- (void)testColorInvalidNonASCIIIsParseError
{
    // A non-ASCII character must be captured into the token and rejected as an
    // invalid color, not break token reading early and yield "Missing }".
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\color{#ff00é}x" error:&error];
    XCTAssertNil(list, @"Expected nil list for color with non-ASCII character");
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorInvalidCommand);
}

#pragma mark - SEC-1: Recursion depth cap

// SEC-1 Test 1: Thousands of nested braces must surface as a parse error,
// not a stack-overflow crash. The test passing at all proves the process
// did not crash.
- (void)testDeeplyNestedBracesReturnsParseError
{
    const NSInteger depth = 1000;
    NSMutableString* str = [NSMutableString string];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"{"];
    }
    [str appendString:@"1"];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"}"];
    }

    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNil(list, @"Expected nil for depth-%ld nesting", (long)depth);
    XCTAssertNotNil(error, @"Expected error for depth-%ld nesting", (long)depth);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorNestingTooDeep,
                   @"Expected MTParseErrorNestingTooDeep, got %ld", (long)error.code);
}

// SEC-1 Test 2: Thousands of nested superscripts must surface as a parse error.
- (void)testDeeplyNestedSuperscriptsReturnsParseError
{
    const NSInteger depth = 1000;
    // Produces: x^{x^{x^{...}}}
    NSMutableString* str = [NSMutableString stringWithString:@"x"];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"^{x"];
    }
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"}"];
    }

    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNil(list, @"Expected nil for depth-%ld superscript nesting", (long)depth);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorNestingTooDeep,
                   @"Expected MTParseErrorNestingTooDeep, got %ld", (long)error.code);
}

// SEC-1 Test 3: Thousands of nested \frac commands must surface as a parse error.
- (void)testDeeplyNestedFracReturnsParseError
{
    const NSInteger depth = 1000;
    // Produces: \frac{1}{\frac{1}{\frac{...}}}
    NSMutableString* str = [NSMutableString string];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"\\frac{1}{"];
    }
    [str appendString:@"1"];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"}"];
    }

    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNil(list, @"Expected nil for depth-%ld \\frac nesting", (long)depth);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorNestingTooDeep,
                   @"Expected MTParseErrorNestingTooDeep, got %ld", (long)error.code);
}

// SEC-1 Test 4: Moderate nesting (well under the cap) must still parse successfully.
- (void)testModerateNestingStillParses
{
    // 20 nested brace groups — should be far below the 150-frame cap.
    const NSInteger depth = 20;
    NSMutableString* str = [NSMutableString string];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"{"];
    }
    [str appendString:@"1"];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"}"];
    }

    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNotNil(list, @"Expected successful parse for depth-%ld nesting", (long)depth);
    XCTAssertNil(error, @"Unexpected error: %@", error);
}

// SEC-1 Test 5: Many sibling groups (wide-not-deep) must not trigger the cap.
// This confirms the cap measures recursion depth, not the total number of groups
// (i.e. the counter is correctly decremented on return).
- (void)testManySiblingGroupsDoNotTriggerDepthCap
{
    // 500 single-character brace groups: {a}{b}{c}...
    const NSInteger count = 500;
    NSMutableString* str = [NSMutableString string];
    for (NSInteger i = 0; i < count; i++) {
        [str appendString:@"{a}"];
    }

    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNotNil(list, @"Expected successful parse for %ld sibling groups", (long)count);
    XCTAssertNil(error, @"Unexpected error for sibling groups: %@", error);
    XCTAssertEqual(list.atoms.count, (NSUInteger)count,
                   @"Expected %ld atoms, got %lu", (long)count, (unsigned long)list.atoms.count);
}

// SEC-1 Test 6: Deeply nested \left..\right groups are an independent re-entry
// point into the chokepoint (buildInternal stopChar) and must also be capped.
- (void)testDeeplyNestedLeftRightReturnsParseError
{
    const NSInteger depth = 1000;
    // Produces: \left(\left(...1...\right)\right)
    NSMutableString* str = [NSMutableString string];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"\\left("];
    }
    [str appendString:@"1"];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"\\right)"];
    }

    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNil(list, @"Expected nil for depth-%ld \\left..\\right nesting", (long)depth);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorNestingTooDeep,
                   @"Expected MTParseErrorNestingTooDeep, got %ld", (long)error.code);
}

// SEC-1 Test 7: Deeply nested environments (\begin{matrix}..\end{matrix}) reach
// the chokepoint via buildTable -> buildInternal, so the table path is also
// charged against the depth cap.
- (void)testDeeplyNestedEnvironmentsReturnsParseError
{
    const NSInteger depth = 1000;
    // Produces: \begin{matrix}\begin{matrix}...1...\end{matrix}\end{matrix}
    NSMutableString* str = [NSMutableString string];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"\\begin{matrix}"];
    }
    [str appendString:@"1"];
    for (NSInteger i = 0; i < depth; i++) {
        [str appendString:@"\\end{matrix}"];
    }

    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:str error:&error];
    XCTAssertNil(list, @"Expected nil for depth-%ld nested-environment nesting", (long)depth);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MTParseError);
    XCTAssertEqual(error.code, MTParseErrorNestingTooDeep,
                   @"Expected MTParseErrorNestingTooDeep, got %ld", (long)error.code);
}

// REN-4: delimiter-table angle brackets must use U+27E8/U+27E9, matching the symbol table.
- (void)testAngleBracketDelimiterConsistency
{
    // Build \langle x \rangle (plain open/close atoms — goes through the symbol table)
    NSError* error = nil;
    MTMathList* plainList = [MTMathListBuilder buildFromString:@"\\langle x \\rangle" error:&error];
    XCTAssertNotNil(plainList, @"\\langle x \\rangle");
    XCTAssertNil(error, @"\\langle x \\rangle");
    XCTAssertEqual(plainList.atoms.count, (NSUInteger)3, @"\\langle x \\rangle");
    MTMathAtom* plainOpen  = plainList.atoms[0];
    MTMathAtom* plainClose = plainList.atoms[2];
    XCTAssertEqual(plainOpen.type,  kMTMathAtomOpen,  @"\\langle x \\rangle open type");
    XCTAssertEqual(plainClose.type, kMTMathAtomClose, @"\\langle x \\rangle close type");

    // Build \left\langle x \right\rangle (goes through the delimiter table)
    MTMathList* leftRightList = [MTMathListBuilder buildFromString:@"\\left\\langle x \\right\\rangle" error:&error];
    XCTAssertNotNil(leftRightList, @"\\left\\langle x \\right\\rangle");
    XCTAssertNil(error, @"\\left\\langle x \\right\\rangle");
    XCTAssertEqual(leftRightList.atoms.count, (NSUInteger)1, @"\\left\\langle x \\right\\rangle");
    MTInner* inner = (MTInner*)leftRightList.atoms[0];
    XCTAssertEqual(inner.type, kMTMathAtomInner, @"inner type");
    XCTAssertEqualObjects(inner.leftBoundary.nucleus,  plainOpen.nucleus,
                          @"\\left\\langle boundary nucleus must equal \\langle symbol nucleus");
    XCTAssertEqualObjects(inner.rightBoundary.nucleus, plainClose.nucleus,
                          @"\\right\\rangle boundary nucleus must equal \\rangle symbol nucleus");

    // The nuclei must be U+27E8 / U+27E9 specifically
    XCTAssertEqualObjects(inner.leftBoundary.nucleus,  @"⟨", @"left boundary should be U+27E8");
    XCTAssertEqualObjects(inner.rightBoundary.nucleus, @"⟩", @"right boundary should be U+27E9");

    // Build \left< x \right> (shorthand) — covers the "<"/">" delimiter-table entries
    MTMathList* angleShortList = [MTMathListBuilder buildFromString:@"\\left< x \\right>" error:&error];
    XCTAssertNotNil(angleShortList, @"\\left< x \\right>");
    XCTAssertNil(error, @"\\left< x \\right>");
    MTInner* innerShort = (MTInner*)angleShortList.atoms[0];
    XCTAssertEqualObjects(innerShort.leftBoundary.nucleus,  @"⟨",
                          @"\\left< boundary should be U+27E8");
    XCTAssertEqualObjects(innerShort.rightBoundary.nucleus, @"⟩",
                          @"\\right> boundary should be U+27E9");

    // Serialization must stay \left< x\right>  (unchanged round-trip)
    NSString* serialized = [MTMathListBuilder mathListToString:leftRightList];
    XCTAssertEqualObjects(serialized, @"\\left< x\\right> ", @"serialized LaTeX unchanged");
}

// Item 4: spacing command parsing tests (TDD — added before implementation)

- (void) testParseSpacingDimensions
{
    // \kern accepts em or mu; em -> value*18 mu
    for (NSString* latex in @[@"\\kern1em", @"\\kern{1em}", @"\\kern 1em"]) {
        MTMathList* list = [MTMathListBuilder buildFromString:latex];
        [self checkAtomTypes:list types:@[@(kMTMathAtomSpace)] desc:latex];
        MTMathSpace* sp = list.atoms[0];
        XCTAssertEqualWithAccuracy(sp.space, 18.0, 0.001, @"%@", latex);
    }

    MTMathSpace* neg = [MTMathListBuilder buildFromString:@"\\kern-1em"].atoms[0];
    XCTAssertEqualWithAccuracy(neg.space, -18.0, 0.001);

    MTMathSpace* half = [MTMathListBuilder buildFromString:@"\\kern{.5em}"].atoms[0];
    XCTAssertEqualWithAccuracy(half.space, 9.0, 0.001);

    MTMathSpace* mk = [MTMathListBuilder buildFromString:@"\\mkern3mu"].atoms[0];
    XCTAssertEqualWithAccuracy(mk.space, 3.0, 0.001);

    // whitespace around the dimension, leading-zero-less decimal, sign
    MTMathSpace* ws = [MTMathListBuilder buildFromString:@"\\hspace{ -.2em }"].atoms[0];
    XCTAssertEqualWithAccuracy(ws.space, -3.6, 0.001);
}

- (void) testParseSpacingAliases
{
    // \hspace*, \hskip behave as \hspace/\kern (em or mu); \mskip, \mspace as \mkern (mu only)
    XCTAssertEqualWithAccuracy(((MTMathSpace*)[MTMathListBuilder buildFromString:@"\\hspace*{1em}"].atoms[0]).space, 18.0, 0.001);
    // TeX tolerates whitespace between the command and the '*' (e.g. "\hspace *{1em}")
    XCTAssertEqualWithAccuracy(((MTMathSpace*)[MTMathListBuilder buildFromString:@"\\hspace *{1em}"].atoms[0]).space, 18.0, 0.001);
    XCTAssertEqualWithAccuracy(((MTMathSpace*)[MTMathListBuilder buildFromString:@"\\hskip 1em"].atoms[0]).space, 18.0, 0.001);
    XCTAssertEqualWithAccuracy(((MTMathSpace*)[MTMathListBuilder buildFromString:@"\\mskip 4mu"].atoms[0]).space, 4.0, 0.001);
    XCTAssertEqualWithAccuracy(((MTMathSpace*)[MTMathListBuilder buildFromString:@"\\mspace{4mu}"].atoms[0]).space, 4.0, 0.001);
}

- (void) testParseGlueTailIgnored
{
    // \mkern 3mu plus 1mu -> 3mu space followed by ordinary math "plus 1mu" (no glue detection)
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\mkern 3mu plus 1mu"];
    XCTAssertEqual(list.atoms.count > 1, YES);
    MTMathSpace* sp = list.atoms[0];
    XCTAssertEqual(sp.type, kMTMathAtomSpace);
    XCTAssertEqualWithAccuracy(sp.space, 3.0, 0.001);
    // remaining atoms are ordinary math (the literal letters p,l,u,s, ...), not spaces
    XCTAssertNotEqual(((MTMathAtom*)list.atoms[1]).type, kMTMathAtomSpace);
}

- (void) testParsePhantomFamily
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\phantom{x}"];
    [self checkAtomTypes:list types:@[@(kMTMathAtomBox)] desc:@"phantom"];
    MTMathBox* box = list.atoms[0];
    XCTAssertTrue(box.keepWidth && box.keepHeight && box.keepDepth && !box.drawChild);
    XCTAssertEqual(box.innerList.atoms.count, 1);

    // \phantom x : single-character argument (buildInternal:true), no braces
    MTMathBox* box2 = [MTMathListBuilder buildFromString:@"\\phantom x"].atoms[0];
    XCTAssertEqual(box2.innerList.atoms.count, 1);

    MTMathBox* h = [MTMathListBuilder buildFromString:@"\\hphantom{x}"].atoms[0];
    XCTAssertTrue(h.keepWidth && !h.keepHeight && !h.keepDepth && !h.drawChild);

    MTMathBox* v = [MTMathListBuilder buildFromString:@"\\vphantom{x}"].atoms[0];
    XCTAssertTrue(!v.keepWidth && v.keepHeight && v.keepDepth && !v.drawChild);

    // \mathstrut: no argument, synthetic inner = open paren "(", vphantom flags
    MTMathBox* strut = [MTMathListBuilder buildFromString:@"\\mathstrut"].atoms[0];
    XCTAssertTrue(!strut.keepWidth && strut.keepHeight && strut.keepDepth && !strut.drawChild);
    XCTAssertEqual(strut.innerList.atoms.count, 1);
    XCTAssertEqualObjects(((MTMathAtom*)strut.innerList.atoms[0]).nucleus, @"(");
}

- (void) testParseSmash
{
    MTMathBox* s = [MTMathListBuilder buildFromString:@"\\smash{x}"].atoms[0];
    XCTAssertTrue(s.keepWidth && !s.keepHeight && !s.keepDepth && s.drawChild);

    MTMathBox* st = [MTMathListBuilder buildFromString:@"\\smash[t]{x}"].atoms[0];
    XCTAssertTrue(st.keepWidth && !st.keepHeight && st.keepDepth && st.drawChild);

    MTMathBox* sb = [MTMathListBuilder buildFromString:@"\\smash[b]{x}"].atoms[0];
    XCTAssertTrue(sb.keepWidth && sb.keepHeight && !sb.keepDepth && sb.drawChild);

    // bad optional value: ignore bracket, smash both, no crash (PRD §7.2.2)
    MTMathBox* sx = [MTMathListBuilder buildFromString:@"\\smash[q]{x}"].atoms[0];
    XCTAssertTrue(!sx.keepHeight && !sx.keepDepth);
}

- (void) testParseLaps
{
    NSDictionary<NSString*, NSNumber*>* cases = @{
        @"\\llap{x}": @(kMTBoxHAlignRight),  @"\\mathllap{x}": @(kMTBoxHAlignRight),
        @"\\rlap{x}": @(kMTBoxHAlignLeft),   @"\\mathrlap{x}": @(kMTBoxHAlignLeft),
        @"\\clap{x}": @(kMTBoxHAlignCenter), @"\\mathclap{x}": @(kMTBoxHAlignCenter),
    };
    for (NSString* latex in cases) {
        MTMathBox* box = [MTMathListBuilder buildFromString:latex].atoms[0];
        XCTAssertEqual(box.type, kMTMathAtomBox, @"%@", latex);
        XCTAssertTrue(!box.keepWidth && box.keepHeight && box.keepDepth && box.drawChild, @"%@", latex);
        XCTAssertEqual(box.hAlign, (MTBoxHAlign)cases[latex].unsignedIntegerValue, @"%@", latex);
    }
}

- (void) testParseBoxAtEOF
{
    // \phantom with no argument at EOF: empty inner, no crash (LLD §6)
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\phantom"];
    XCTAssertNotNil(list);
    MTMathBox* box = list.atoms[0];
    XCTAssertEqual(box.innerList.atoms.count, 0);
}

- (void) testBoxRoundTrip
{
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:
        [MTMathListBuilder buildFromString:@"\\phantom{x}"]], @"\\phantom{x}");
    // \mathstrut serializes lossily to \vphantom{(}
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:
        [MTMathListBuilder buildFromString:@"\\mathstrut"]], @"\\vphantom{(}");
}

- (void)testBraceGrouping
{
    // x{\scriptstyle y}z — the issue #177 case. The group is a distinct atom;
    // \scriptstyle lives inside it; round-trips with braces preserved.
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"x{\\scriptstyle y}z" error:&error];
    XCTAssertNil(error);
    [self checkAtomTypes:list
                   types:@[ @(kMTMathAtomVariable), @(kMTMathAtomOrdGroup), @(kMTMathAtomVariable) ]
                    desc:@"x{\\scriptstyle y}z"];
    MTMathGroup* group = (MTMathGroup*) list.atoms[1];
    XCTAssertTrue([group isKindOfClass:[MTMathGroup class]]);
    [self checkAtomTypes:group.innerList
                   types:@[ @(kMTMathAtomStyle), @(kMTMathAtomVariable) ]
                    desc:@"group innerList"];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"x{\\scriptstyle y}z");

    // {x}^2 — the script attaches to the whole group.
    list = [MTMathListBuilder buildFromString:@"{x}^2" error:&error];
    XCTAssertNil(error);
    [self checkAtomTypes:list types:@[ @(kMTMathAtomOrdGroup) ] desc:@"{x}^2"];
    group = (MTMathGroup*) list.atoms[0];
    XCTAssertNotNil(group.superScript, @"superscript must be on the group");
    [self checkAtomTypes:group.superScript types:@[ @(kMTMathAtomNumber) ] desc:@"{x}^2 script"];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"{x}^{2}");

    // {a+b} — Bin classification stays inside the group; round-trips with braces.
    list = [MTMathListBuilder buildFromString:@"{a+b}c" error:&error];
    XCTAssertNil(error);
    [self checkAtomTypes:list types:@[ @(kMTMathAtomOrdGroup), @(kMTMathAtomVariable) ] desc:@"{a+b}c"];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"{a+b}c");

    // Nested {{x}} — outer group's innerList holds a single inner group.
    list = [MTMathListBuilder buildFromString:@"{{x}}" error:&error];
    XCTAssertNil(error);
    [self checkAtomTypes:list types:@[ @(kMTMathAtomOrdGroup) ] desc:@"{{x}}"];
    group = (MTMathGroup*) list.atoms[0];
    [self checkAtomTypes:group.innerList types:@[ @(kMTMathAtomOrdGroup) ] desc:@"{{x}} inner"];
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"{{x}}");

    // Empty {} — a group with an empty innerList; round-trips as {}.
    list = [MTMathListBuilder buildFromString:@"{}" error:&error];
    XCTAssertNil(error);
    [self checkAtomTypes:list types:@[ @(kMTMathAtomOrdGroup) ] desc:@"{}"];
    group = (MTMathGroup*) list.atoms[0];
    XCTAssertEqual(group.innerList.atoms.count, 0u);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"{}");

    // Field braces must NOT wrap: ^{\scriptstyle y}z keeps the style scoped to the
    // superscript field, with no group wrapper and no leak onto z.
    list = [MTMathListBuilder buildFromString:@"x^{\\scriptstyle y}z" error:&error];
    XCTAssertNil(error);
    [self checkAtomTypes:list types:@[ @(kMTMathAtomVariable), @(kMTMathAtomVariable) ] desc:@"x^{...}z"];
    MTMathList* super0 = ((MTMathAtom*) list.atoms[0]).superScript;
    [self checkAtomTypes:super0 types:@[ @(kMTMathAtomStyle), @(kMTMathAtomVariable) ] desc:@"super field"];
}

- (void)testBraceGroupingAroundOverTransform
{
    // Regression: an inner group transformed by \over must NOT cause the
    // ENCLOSING group to be dropped. {{a \over b}c} → the outer group survives,
    // wrapping [Fraction, Variable(c)] (the inner {a \over b} became a Fraction,
    // but that transform is scoped to the inner group only).
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"{{a \\over b}c}" error:&error];
    XCTAssertNil(error);
    [self checkAtomTypes:list types:@[ @(kMTMathAtomOrdGroup) ] desc:@"{{a \\over b}c} top"];
    MTMathGroup* group = (MTMathGroup*) list.atoms[0];
    XCTAssertTrue([group isKindOfClass:[MTMathGroup class]]);
    [self checkAtomTypes:group.innerList
                   types:@[ @(kMTMathAtomFraction), @(kMTMathAtomVariable) ]
                    desc:@"{{a \\over b}c} inner"];

    // The #177 leak variant: \scriptstyle inside the enclosing group must stay
    // scoped to that group even when a leading inner group was \over-transformed.
    // Before the fix the inner group's "transformed" flag leaked upward, the
    // outer group was dropped, and \scriptstyle escaped onto z.
    list = [MTMathListBuilder buildFromString:@"{{a \\over b}\\scriptstyle c}z" error:&error];
    XCTAssertNil(error);
    [self checkAtomTypes:list
                   types:@[ @(kMTMathAtomOrdGroup), @(kMTMathAtomVariable) ]
                    desc:@"{{a \\over b}\\scriptstyle c}z top"];
    group = (MTMathGroup*) list.atoms[0];
    [self checkAtomTypes:group.innerList
                   types:@[ @(kMTMathAtomFraction), @(kMTMathAtomStyle), @(kMTMathAtomVariable) ]
                    desc:@"group innerList"];
    // z is a separate top-level atom — \scriptstyle did NOT leak out of the group.
    XCTAssertEqual(((MTMathAtom*) list.atoms[1]).type, kMTMathAtomVariable,
                   @"z must be a plain top-level variable, not style-contaminated");
}

- (void)testScriptAfterOverTransformedGroupAttachesToFraction
{
    // {a \over b}^2 — \over transforms the enclosing group into a Fraction at
    // the parent level (TeX group-transformation). The following ^2 must attach
    // to THAT fraction, not to a spurious empty Ord. Before the prevAtom fix the
    // transformed path appended the fraction without updating prevAtom, so the ^
    // branch allocated an empty Ord and hung the superscript on it instead.
    NSError* error = nil;
    MTMathList* list = [MTMathListBuilder buildFromString:@"{a \\over b}^2" error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"expected a single fraction atom, not fraction + empty Ord");
    MTMathAtom* frac = list.atoms[0];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"expected the \\over fraction");
    XCTAssertNotNil(frac.superScript, @"^2 must attach to the fraction");
    [self checkAtomTypes:frac.superScript types:@[ @(kMTMathAtomNumber) ] desc:@"{a \\over b}^2 superscript"];
    // Round-trip: \over normalizes to \frac{}{} on serialization (existing
    // behavior); the superscript stays on the fraction.
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:list], @"\\frac{a}{b}^{2}");
}

@end
