//
//  MTMathListTest.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTMathListTest.h"
#import "MTMathListBuilder.h"

@implementation MTMathListTest

- (void) testSubScript
{
    NSString *str = @"-52x^{13+y}_{15-} + (-12.3 *)\\frac{-12}{15.2}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    MTMathList* finalized = list.finalized;
    [self checkListContents:finalized];
    // refinalizing a finalized list should not cause any more changes
    [self checkListContents:finalized.finalized];
}

- (void) checkListContents: (MTMathList*) finalized
{
    // check
    XCTAssertEqualObjects(@(finalized.atoms.count), @10, @"Num atoms");
    MTMathAtom* atom = finalized.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomUnaryOperator, @"Atom 0");
    XCTAssertEqualObjects(atom.nucleus, @"-", @"Atom 0 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(0, 1)), @"Range");
    atom = finalized.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"Atom 1");
    XCTAssertEqualObjects(atom.nucleus, @"52", @"Atom 1 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(1, 2)), @"Range");
    atom = finalized.atoms[2];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"Atom 2");
    XCTAssertEqualObjects(atom.nucleus, @"x", @"Atom 2 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(3, 1)), @"Range");
    
    MTMathList* superScr = atom.superScript;
    XCTAssertEqualObjects(@(superScr.atoms.count), @3, @"Super script");
    atom = superScr.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"Super Atom 0");
    XCTAssertEqualObjects(atom.nucleus, @"13", @"Super Atom 0 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(0, 2)), @"Range");
    atom = superScr.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomBinaryOperator, @"Super Atom 1");
    XCTAssertEqualObjects(atom.nucleus, @"+", @"Super Atom 1 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(2, 1)), @"Range");
    atom = superScr.atoms[2];
    XCTAssertEqual(atom.type, kMTMathAtomVariable, @"Super Atom 2");
    XCTAssertEqualObjects(atom.nucleus, @"y", @"Super Atom 2 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(3, 1)), @"Range");
    
    atom = finalized.atoms[2];
    MTMathList* subScr = atom.subScript;
    XCTAssertEqualObjects(@(subScr.atoms.count), @2, @"Sub script");
    atom = subScr.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"Sub Atom 0");
    XCTAssertEqualObjects(atom.nucleus, @"15", @"Sub Atom 0 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(0, 2)), @"Range");
    atom = subScr.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomUnaryOperator, @"Sub Atom 1");
    XCTAssertEqualObjects(atom.nucleus, @"-", @"Sub Atom 1 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(2, 1)), @"Range");
    
    atom = finalized.atoms[3];
    XCTAssertEqual(atom.type, kMTMathAtomBinaryOperator, @"Atom 3");
    XCTAssertEqualObjects(atom.nucleus, @"+", @"Atom 3 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(4, 1)), @"Range");
    atom = finalized.atoms[4];
    XCTAssertEqual(atom.type, kMTMathAtomOpen, @"Atom 4");
    XCTAssertEqualObjects(atom.nucleus, @"(", @"Atom 4 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(5, 1)), @"Range");
    atom = finalized.atoms[5];
    XCTAssertEqual(atom.type, kMTMathAtomUnaryOperator, @"Atom 5");
    XCTAssertEqualObjects(atom.nucleus, @"-", @"Atom 5 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(6, 1)), @"Range");
    atom = finalized.atoms[6];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"Atom 6");
    XCTAssertEqualObjects(atom.nucleus, @"12.3", @"Atom 6 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(7, 4)), @"Range");
    atom = finalized.atoms[7];
    XCTAssertEqual(atom.type, kMTMathAtomUnaryOperator, @"Atom 7");
    XCTAssertEqualObjects(atom.nucleus, @"*", @"Atom 7 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(11, 1)), @"Range");
    atom = finalized.atoms[8];
    XCTAssertEqual(atom.type, kMTMathAtomClose, @"Atom 8");
    XCTAssertEqualObjects(atom.nucleus, @")", @"Atom 8 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(12, 1)), @"Range");
    
    MTFraction* frac = finalized.atoms[9];
    XCTAssertEqual(frac.type, kMTMathAtomFraction, @"Atom 9");
    XCTAssertEqualObjects(frac.nucleus, @"", @"Atom 9 value");
    XCTAssertTrue(NSEqualRanges(frac.indexRange, NSMakeRange(13, 1)), @"Range");
    
    MTMathList* numer = frac.numerator;
    XCTAssertNotNil(numer, @"Numerator");
    XCTAssertEqualObjects(@(numer.atoms.count), @2, @"Numer script");
    atom = numer.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomUnaryOperator, @"Numer Atom 0");
    XCTAssertEqualObjects(atom.nucleus, @"-", @"Numer Atom 0 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(0, 1)), @"Range");
    atom = numer.atoms[1];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"Numer Atom 1");
    XCTAssertEqualObjects(atom.nucleus, @"12", @"Numer Atom 1 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(1, 2)), @"Range");
    
    
    MTMathList* denom = frac.denominator;
    XCTAssertNotNil(denom, @"Denominator");
    XCTAssertEqualObjects(@(denom.atoms.count), @1, @"Denom script");
    atom = denom.atoms[0];
    XCTAssertEqual(atom.type, kMTMathAtomNumber, @"Denom Atom 0");
    XCTAssertEqualObjects(atom.nucleus, @"15.2", @"Denom Atom 0 value");
    XCTAssertTrue(NSEqualRanges(atom.indexRange, NSMakeRange(0, 4)), @"Range");
    
    
}

@end
