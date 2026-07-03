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

@import XCTest;

#import "MTMathListBuilder.h"
#import "MTMathAtomFactory.h"
#import "MTMathListIndex.h"

@interface MTMathListTest : XCTestCase

@end

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
    XCTAssertEqualObjects(atom.nucleus, @"−", @"Atom 0 value");
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
    XCTAssertEqualObjects(atom.nucleus, @"−", @"Sub Atom 1 value");
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
    XCTAssertEqualObjects(atom.nucleus, @"−", @"Atom 5 value");
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
    XCTAssertEqualObjects(atom.nucleus, @"−", @"Numer Atom 0 value");
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

- (void) testAdd
{
    MTMathList* list = [[MTMathList alloc] init];
    XCTAssertEqual(list.atoms.count, 0);
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    [list addAtom:atom];
    XCTAssertEqual(list.atoms.count, 1);
    XCTAssertEqual(list.atoms[0], atom);
    MTMathAtom* atom2 = [MTMathAtomFactory placeholder];
    [list addAtom:atom2];
    XCTAssertEqual(list.atoms.count, 2);
    XCTAssertEqual(list.atoms[0], atom);
    XCTAssertEqual(list.atoms[1], atom2);
}

- (void) testAddErrors
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = nil;
    XCTAssertThrows([list addAtom:atom]);
    atom = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@""];
    XCTAssertThrows([list addAtom:atom]);
}

- (void) testInsert
{
    MTMathList* list = [[MTMathList alloc] init];
    XCTAssertEqual(list.atoms.count, 0);
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    [list insertAtom:atom atIndex:0];
    XCTAssertEqual(list.atoms.count, 1);
    XCTAssertEqual(list.atoms[0], atom);
    MTMathAtom* atom2 = [MTMathAtomFactory placeholder];
    [list insertAtom:atom2 atIndex:0];
    XCTAssertEqual(list.atoms.count, 2);
    XCTAssertEqual(list.atoms[0], atom2);
    XCTAssertEqual(list.atoms[1], atom);
    MTMathAtom* atom3 = [MTMathAtomFactory placeholder];
    [list insertAtom:atom3 atIndex:2];
    XCTAssertEqual(list.atoms.count, 3);
    XCTAssertEqual(list.atoms[0], atom2);
    XCTAssertEqual(list.atoms[1], atom);
    XCTAssertEqual(list.atoms[2], atom3);
}

- (void) testInsertErrors
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = nil;
    XCTAssertThrows([list insertAtom:atom atIndex:0]);
    atom = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@""];
    XCTAssertThrows([list insertAtom:atom atIndex:0]);
    atom = [MTMathAtomFactory placeholder];
    XCTAssertThrows([list insertAtom:atom atIndex:1]);
}

- (void) testAppend
{
    MTMathList* list1 = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory placeholder];
    MTMathAtom* atom3 = [MTMathAtomFactory placeholder];
    [list1 addAtom:atom];
    [list1 addAtom:atom2];
    [list1 addAtom:atom3];
    
    MTMathList* list2 = [[MTMathList alloc] init];
    MTMathAtom* atom5 = [MTMathAtomFactory times];
    MTMathAtom* atom6 = [MTMathAtomFactory divide];
    [list2 addAtom:atom5];
    [list2 addAtom:atom6];
    
    XCTAssertEqual(list1.atoms.count, 3);
    XCTAssertEqual(list2.atoms.count, 2);
    
    [list1 append:list2];
    XCTAssertEqual(list1.atoms.count, 5);
    XCTAssertEqual(list1.atoms[3], atom5);
    XCTAssertEqual(list1.atoms[4], atom6);
}

- (void) testRemoveLast
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    [list addAtom:atom];
    XCTAssertEqual(list.atoms.count, 1);
    [list removeLastAtom];
    XCTAssertEqual(list.atoms.count, 0);
    // Removing from empty list.
    [list removeLastAtom];
    XCTAssertEqual(list.atoms.count, 0);
    MTMathAtom* atom2 = [MTMathAtomFactory placeholder];
    [list addAtom:atom];
    [list addAtom:atom2];
    XCTAssertEqual(list.atoms.count, 2);
    [list removeLastAtom];
    XCTAssertEqual(list.atoms.count, 1);
    XCTAssertEqual(list.atoms[0], atom);
}

- (void) testRemoveAtomAtIndex
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory placeholder];
    [list addAtom:atom];
    [list addAtom:atom2];
    XCTAssertEqual(list.atoms.count, 2);
    [list removeAtomAtIndex:0];
    XCTAssertEqual(list.atoms.count, 1);
    XCTAssertEqual(list.atoms[0], atom2);
    
    // Index out of range
    XCTAssertThrows([list removeAtomAtIndex:2]);
}

- (void) testRemoveAtomsInRange
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory placeholder];
    MTMathAtom* atom3 = [MTMathAtomFactory placeholder];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];
    XCTAssertEqual(list.atoms.count, 3);
    [list removeAtomsInRange:NSMakeRange(1, 2)];
    XCTAssertEqual(list.atoms.count, 1);
    XCTAssertEqual(list.atoms[0], atom);
    
    // Index out of range
    XCTAssertThrows([list removeAtomsInRange:NSMakeRange(1, 3)]);
}

#define MTAssertEqual(test, expression1, expression2, ...) \
_XCTPrimitiveAssertEqual(test, expression1, @#expression1, expression2, @#expression2, __VA_ARGS__)

#define MTAssertNotEqual(test, expression1, expression2, ...) \
_XCTPrimitiveAssertNotEqual(test, expression1, @#expression1, expression2, @#expression2, __VA_ARGS__)

+ (void) checkAtomCopy:(MTMathAtom*) copy original:(MTMathAtom*) original forTest:(XCTestCase*) test
{
    MTAssertEqual(test, copy.type, original.type);
    MTAssertEqual(test, copy.nucleus, original.nucleus);
    // Deep copy
    MTAssertNotEqual(test, copy, original);
}

+ (void) checkListCopy:(MTMathList*) copy original:(MTMathList*) original forTest:(XCTestCase*) test
{
    MTAssertEqual(test, copy.atoms.count, original.atoms.count);
    int i = 0;
    for (MTMathAtom* copyAtom in copy.atoms) {
        MTMathAtom* origAtom = original.atoms[i];
        [self checkAtomCopy:copyAtom original:origAtom forTest:test];
        i++;
    }
}

- (void) testCopy
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];
    
    MTMathList* list2 = [list copy];
    [MTMathListTest checkListCopy:list2 original:list forTest:self];
}

- (void)testMathTableVerticalHorizontalLinesDefaultAndCopy
{
    MTMathTable* table = [[MTMathTable alloc] init];
    // Default: both empty (inert — existing envs unaffected).
    XCTAssertNotNil(table.verticalLines);
    XCTAssertNotNil(table.horizontalLines);
    XCTAssertEqual(table.verticalLines.count, 0);
    XCTAssertEqual(table.horizontalLines.count, 0);

    table.verticalLines = @[ @1, @0, @2 ];
    table.horizontalLines = @[ @1, @0 ];
    MTMathTable* copy = [table copy];
    XCTAssertEqualObjects(copy.verticalLines, (@[ @1, @0, @2 ]));
    XCTAssertEqualObjects(copy.horizontalLines, (@[ @1, @0 ]));
    // Mutating the original's field must not affect the copy.
    table.verticalLines = @[ @9 ];
    XCTAssertEqualObjects(copy.verticalLines, (@[ @1, @0, @2 ]));
}

- (void)testArrayTableFactoryBuildsBareTextstyleTable
{
    MTMathList* a = [MTMathListBuilder buildFromString:@"a"];
    MTMathList* b = [MTMathListBuilder buildFromString:@"b"];
    MTMathList* c = [MTMathListBuilder buildFromString:@"c"];
    MTMathList* d = [MTMathListBuilder buildFromString:@"d"];
    NSArray* rows = @[ @[ a, b ], @[ c, d ] ];

    NSError* error = nil;
    MTMathAtom* atom = [MTMathAtomFactory
        arrayTableWithAlignments:@[ @(kMTColumnAlignmentRight), @(kMTColumnAlignmentLeft) ]
                   verticalLines:@[ @1, @0, @1 ]
                 horizontalLines:@[ @1 ]
                            rows:rows
                           error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(atom);
    // Bare table — no MTInner / delimiters wrapping.
    XCTAssertEqual(atom.type, kMTMathAtomTable);
    MTMathTable* table = (MTMathTable*) atom;
    XCTAssertEqualObjects(table.environment, @"array");
    XCTAssertEqual(table.numRows, 2);
    XCTAssertEqual(table.numColumns, 2);
    XCTAssertEqual([table getAlignmentForColumn:0], kMTColumnAlignmentRight);
    XCTAssertEqual([table getAlignmentForColumn:1], kMTColumnAlignmentLeft);
    XCTAssertEqualObjects(table.verticalLines, (@[ @1, @0, @1 ]));
    // horizontalLines normalized to numRows+1 == 3.
    XCTAssertEqualObjects(table.horizontalLines, (@[ @1, @0, @0 ]));
    XCTAssertEqual(table.interColumnSpacing, 18);
    XCTAssertEqual(table.interRowAdditionalSpacing, 0);
    XCTAssertEqual(table.cellStyle, kMTLineStyleText);
}

- (void)testArrayTableFactoryRejectsTooManyCells
{
    MTMathList* a = [MTMathListBuilder buildFromString:@"a"];
    MTMathList* b = [MTMathListBuilder buildFromString:@"b"];
    // Spec declares 1 column but the row has 2 cells.
    NSError* error = nil;
    MTMathAtom* atom = [MTMathAtomFactory
        arrayTableWithAlignments:@[ @(kMTColumnAlignmentCenter) ]
                   verticalLines:@[ @0, @0 ]
                 horizontalLines:@[]
                            rows:@[ @[ a, b ] ]
                           error:&error];
    XCTAssertNil(atom);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, MTParseErrorInvalidNumColumns);
    XCTAssertEqualObjects(error.localizedDescription,
        @"array row has 2 cells but column specification declares 1 columns");
}

- (void)testArrayTableFactoryAcceptsShortRows
{
    MTMathList* a = [MTMathListBuilder buildFromString:@"a"];
    // Spec declares 3 columns; row has 1 cell — allowed, trailing cells absent.
    NSError* error = nil;
    MTMathAtom* atom = [MTMathAtomFactory
        arrayTableWithAlignments:@[ @(kMTColumnAlignmentCenter),
                                    @(kMTColumnAlignmentCenter),
                                    @(kMTColumnAlignmentCenter) ]
                   verticalLines:@[ @0, @0, @0, @0 ]
                 horizontalLines:@[]
                            rows:@[ @[ a ] ]
                           error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(atom);
    MTMathTable* table = (MTMathTable*) atom;
    XCTAssertEqual([table.cells[0] count], 1);
}

@end

@interface MTMathAtomTest : XCTestCase

@end

@implementation MTMathAtomTest

- (void) testAtomInit
{
    MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomOpen value:@"("];
    XCTAssertEqual(atom.nucleus, @"(");
    XCTAssertEqual(atom.type, kMTMathAtomOpen);
    
    atom = [MTMathAtom atomWithType:kMTMathAtomRadical value:@"("];
    XCTAssertEqual(atom.nucleus, @"");
    XCTAssertEqual(atom.type, kMTMathAtomRadical);
}

- (void) testAtomScripts
{
    MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomOpen value:@"("];
    XCTAssertTrue(atom.scriptsAllowed);
    atom.subScript = [[MTMathList alloc] init];
    XCTAssertNotNil(atom.subScript);
    atom.superScript = [[MTMathList alloc] init];
    XCTAssertNotNil(atom.superScript);
    
    atom = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@"("];
    XCTAssertFalse(atom.scriptsAllowed);
    // Can set to nil
    atom.subScript = nil;
    XCTAssertNil(atom.subScript);
    atom.superScript = nil;
    XCTAssertNil(atom.superScript);
    // Can't set to value
    MTMathList* list = [[MTMathList alloc] init];
    XCTAssertThrows(atom.subScript = list);
    XCTAssertThrows(atom.superScript = list);
}

- (void) testAtomCopy
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom1 = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom1];
    [list addAtom:atom2];
    [list addAtom:atom3];
    
    MTMathList* list2 = [[MTMathList alloc] init];
    [list2 addAtom:atom3];
    [list2 addAtom:atom2];
    
    MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomOpen value:@"("];
    atom.subScript = list;
    atom.superScript = list2;
    MTMathAtom* copy = [atom copy];
    
    [MTMathListTest checkAtomCopy:copy original:atom forTest:self];
    [MTMathListTest checkListCopy:copy.superScript original:atom.superScript forTest:self];
    [MTMathListTest checkListCopy:copy.subScript original:atom.subScript forTest:self];
}

- (void) testCopyFraction
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];
    
    MTMathList* list2 = [[MTMathList alloc] init];
    [list2 addAtom:atom3];
    [list2 addAtom:atom2];
    
    MTFraction* frac = [[MTFraction alloc] initWithRule:NO];
    XCTAssertEqual(frac.type, kMTMathAtomFraction);
    frac.numerator = list;
    frac.denominator = list2;
    frac.leftDelimiter = @"a";
    frac.rightDelimiter = @"b";
    
    MTFraction* copy = [frac copy];
    [MTMathListTest checkAtomCopy:copy original:frac forTest:self];
    [MTMathListTest checkListCopy:copy.numerator original:frac.numerator forTest:self];
    [MTMathListTest checkListCopy:copy.denominator original:frac.denominator forTest:self];
    XCTAssertFalse(copy.hasRule);
    XCTAssertEqualObjects(copy.leftDelimiter, @"a");
    XCTAssertEqualObjects(copy.rightDelimiter, @"b");
}

- (void) testCopyRadical
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];
    
    MTMathList* list2 = [[MTMathList alloc] init];
    [list2 addAtom:atom3];
    [list2 addAtom:atom2];
    
    MTRadical* rad = [[MTRadical alloc] init];
    XCTAssertEqual(rad.type, kMTMathAtomRadical);
    rad.radicand = list;
    rad.degree = list2;
    
    MTRadical* copy = [rad copy];
    [MTMathListTest checkAtomCopy:copy original:rad forTest:self];
    [MTMathListTest checkListCopy:copy.radicand original:rad.radicand forTest:self];
    [MTMathListTest checkListCopy:copy.degree original:rad.degree forTest:self];
}

- (void) testCopyLargeOperator
{
    MTLargeOperator* lg = [[MTLargeOperator alloc] initWithValue:@"lim" limits:true];
    XCTAssertEqual(lg.type, kMTMathAtomLargeOperator);
    XCTAssertTrue(lg.limits);
    
    MTLargeOperator* copy = [lg copy];
    [MTMathListTest checkAtomCopy:copy original:lg forTest:self];
    XCTAssertEqual(copy.limits, lg.limits);
}
- (void) testCopyInner
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];
    
    MTInner* inner = [[MTInner alloc] init];
    inner.innerList = list;
    inner.leftBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@"("];
    inner.rightBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@")"];
    XCTAssertEqual(inner.type, kMTMathAtomInner);
    
    MTInner* copy = [inner copy];
    [MTMathListTest checkAtomCopy:copy original:inner forTest:self];
    [MTMathListTest checkListCopy:copy.innerList original:inner.innerList forTest:self];
    [MTMathListTest checkAtomCopy:copy.leftBoundary original:inner.leftBoundary forTest:self];
    [MTMathListTest checkAtomCopy:copy.rightBoundary original:inner.rightBoundary forTest:self];
}

- (void) testSetInnerBoundary
{
    MTInner* inner = [[MTInner alloc] init];
    
    // Can set non-nil
    inner.leftBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@"("];
    inner.rightBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@")"];
    XCTAssertNotNil(inner.leftBoundary);
    XCTAssertNotNil(inner.rightBoundary);
    // Can set nil
    inner.leftBoundary = nil;
    inner.rightBoundary = nil;
    XCTAssertNil(inner.leftBoundary);
    XCTAssertNil(inner.rightBoundary);
    // Can't set non boundary
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    XCTAssertThrows(inner.leftBoundary = atom);
    XCTAssertThrows(inner.rightBoundary = atom);
}

- (void) testCopyOverline
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];

    MTOverLine* over = [[MTOverLine alloc] init];
    XCTAssertEqual(over.type, kMTMathAtomOverline);
    over.innerList = list;
    
    MTOverLine* copy = [over copy];
    [MTMathListTest checkAtomCopy:copy original:over forTest:self];
    [MTMathListTest checkListCopy:copy.innerList original:over.innerList forTest:self];
}

- (void) testCopyUnderline
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];
    
    MTUnderLine* under = [[MTUnderLine alloc] init];
    XCTAssertEqual(under.type, kMTMathAtomUnderline);
    under.innerList = list;
    
    MTUnderLine* copy = [under copy];
    [MTMathListTest checkAtomCopy:copy original:under forTest:self];
    [MTMathListTest checkListCopy:copy.innerList original:under.innerList forTest:self];
}

- (void) testCopyAcccent
{
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];
    
    MTAccent* accent = [[MTAccent alloc] initWithValue:@"^"];
    XCTAssertEqual(accent.type, kMTMathAtomAccent);
    accent.innerList = list;
    
    MTAccent* copy = [accent copy];
    [MTMathListTest checkAtomCopy:copy original:accent forTest:self];
    [MTMathListTest checkListCopy:copy.innerList original:accent.innerList forTest:self];
}

- (void) testCreateLargeDelimiter
{
    MTLargeDelimiter* big = [[MTLargeDelimiter alloc] initWithDelimiterNucleus:@"("
                                                                    mathClass:kMTMathAtomOpen
                                                                         size:kMTDelimiterSize2];
    XCTAssertEqualObjects(big.nucleus, @"(");
    XCTAssertEqual(big.type, kMTMathAtomOpen);
    XCTAssertEqual(big.delimiterSize, kMTDelimiterSize2);
    XCTAssertTrue(big.scriptsAllowed);

    // Empty nucleus is allowed (null delimiter `.`).
    MTLargeDelimiter* null = [[MTLargeDelimiter alloc] initWithDelimiterNucleus:@""
                                                                     mathClass:kMTMathAtomOrdinary
                                                                          size:kMTDelimiterSize1];
    XCTAssertEqualObjects(null.nucleus, @"");
    XCTAssertEqual(null.type, kMTMathAtomOrdinary);
    XCTAssertEqual(null.delimiterSize, kMTDelimiterSize1);

    // Legacy atomWithType:value: factory does not route to MTLargeDelimiter.
    MTMathAtom* generic = [MTMathAtom atomWithType:kMTMathAtomOpen value:@"("];
    XCTAssertFalse([generic isKindOfClass:[MTLargeDelimiter class]]);
}

- (void) testCopyLargeDelimiter
{
    MTLargeDelimiter* big = [[MTLargeDelimiter alloc] initWithDelimiterNucleus:@"\u2308"
                                                                    mathClass:kMTMathAtomRelation
                                                                         size:kMTDelimiterSize3];

    MTMathList* scriptList = [[MTMathList alloc] init];
    [scriptList addAtom:[MTMathAtomFactory placeholder]];
    big.superScript = scriptList;

    MTLargeDelimiter* copy = [big copy];
    [MTMathListTest checkAtomCopy:copy original:big forTest:self];
    XCTAssertEqual(copy.delimiterSize, big.delimiterSize);
    XCTAssertEqual(copy.type, kMTMathAtomRelation);
    [MTMathListTest checkListCopy:copy.superScript original:big.superScript forTest:self];
}

- (void) testCopySpace
{
    MTMathSpace* space = [[MTMathSpace alloc] initWithSpace:3];
    XCTAssertEqual(space.type, kMTMathAtomSpace);
    
    MTMathSpace* copy = [space copy];
    [MTMathListTest checkAtomCopy:copy original:space forTest:self];
    XCTAssertEqual(space.space, copy.space);
}

- (void) testCopyStyle
{
    MTMathStyle* style = [[MTMathStyle alloc] initWithStyle:kMTLineStyleScript];
    XCTAssertEqual(style.type, kMTMathAtomStyle);
    
    MTMathStyle* copy = [style copy];
    [MTMathListTest checkAtomCopy:copy original:style forTest:self];
    XCTAssertEqual(style.style, copy.style);
}

- (void) testCreateMathTable
{
    MTMathTable* table = [[MTMathTable alloc] init];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];
    
    MTMathList* list2 = [[MTMathList alloc] init];
    [list2 addAtom:atom3];
    [list2 addAtom:atom2];
    
    [table setCell:list forRow:3 column:2];
    [table setCell:list2 forRow:1 column:0];
    
    [table setAlignment:kMTColumnAlignmentLeft forColumn:2];
    [table setAlignment:kMTColumnAlignmentRight forColumn:1];
    
    // Verify that everything is created correctly
    XCTAssertEqual(table.cells.count, 4);  // 4 rows
    XCTAssertNotNil(table.cells[0]);
    XCTAssertEqual(table.cells[0].count, 0); // 0 elements in row 0
    XCTAssertEqual(table.cells[1].count, 1); // 1 element in row 1
    XCTAssertNotNil(table.cells[2]);
    XCTAssertEqual(table.cells[2].count, 0);
    XCTAssertEqual(table.cells[3].count, 3);
    
    // Verify the elements in the rows
    XCTAssertEqual(table.cells[1][0].atoms.count, 2);
    XCTAssertEqual(table.cells[1][0], list2);
    XCTAssertNotNil(table.cells[3][0]);
    XCTAssertEqual(table.cells[3][0].atoms.count, 0);
    
    XCTAssertNotNil(table.cells[3][0]);
    XCTAssertEqual(table.cells[3][0].atoms.count, 0);
    
    XCTAssertNotNil(table.cells[3][1]);
    XCTAssertEqual(table.cells[3][1].atoms.count, 0);
    
    XCTAssertEqual(table.cells[3][2], list);
    
    XCTAssertEqual(table.numRows, 4);
    XCTAssertEqual(table.numColumns, 3);
    
    // Verify the alignments
    XCTAssertEqual(table.alignments.count, 3);
    XCTAssertEqual(table.alignments[0].integerValue, kMTColumnAlignmentCenter);
    XCTAssertEqual(table.alignments[1].integerValue, kMTColumnAlignmentRight);
    XCTAssertEqual(table.alignments[2].integerValue, kMTColumnAlignmentLeft);
}

- (void) testCopyMathTable
{
    MTMathTable* table = [[MTMathTable alloc] init];
    XCTAssertEqual(table.type, kMTMathAtomTable);
    
    MTMathList* list = [[MTMathList alloc] init];
    MTMathAtom* atom = [MTMathAtomFactory placeholder];
    MTMathAtom* atom2 = [MTMathAtomFactory times];
    MTMathAtom* atom3 = [MTMathAtomFactory divide];
    [list addAtom:atom];
    [list addAtom:atom2];
    [list addAtom:atom3];
    
    MTMathList* list2 = [[MTMathList alloc] init];
    [list2 addAtom:atom3];
    [list2 addAtom:atom2];
    
    [table setCell:list forRow:0 column:1];
    [table setCell:list2 forRow:0 column:2];
    
    [table setAlignment:kMTColumnAlignmentLeft forColumn:2];
    [table setAlignment:kMTColumnAlignmentRight forColumn:1];
    table.interRowAdditionalSpacing = 3;
    table.interColumnSpacing = 10;
    table.cellStyle = kMTLineStyleScript;

    MTMathTable* copy = [table copy];
    [MTMathListTest checkAtomCopy:copy original:table forTest:self];
    XCTAssertEqual(copy.interColumnSpacing, table.interColumnSpacing);
    XCTAssertEqual(copy.interRowAdditionalSpacing, table.interRowAdditionalSpacing);
    XCTAssertEqual(copy.cellStyle, table.cellStyle);
    XCTAssertEqualObjects(copy.alignments, table.alignments);
    XCTAssertNotEqual(copy.alignments, table.alignments);
    
    XCTAssertNotEqual(copy.cells, table.cells);
    XCTAssertNotEqual(copy.cells[0], table.cells[0]);
    XCTAssertEqual(copy.cells[0].count, table.cells[0].count);
    XCTAssertEqual(copy.cells[0][0].atoms.count, 0);
    XCTAssertNotEqual(copy.cells[0][0], table.cells[0][0]);
    [MTMathListTest checkListCopy:copy.cells[0][1] original:list forTest:self];
    [MTMathListTest checkListCopy:copy.cells[0][2] original:list2 forTest:self];
}

#pragma mark - MTTextAtom

- (void) testTextAtomTypeIsText
{
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"abc" style:kMTTextStyleRoman];
    XCTAssertEqual(atom.type, kMTMathAtomText);
    XCTAssertEqualObjects(atom.text, @"abc");
    XCTAssertEqual(atom.textStyle, kMTTextStyleRoman);
    XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]]);
}

- (void) testTextAtomFactoryCreatesTextAtom
{
    MTMathAtom *atom = [MTMathAtom atomWithType:kMTMathAtomText value:@"abc"];
    XCTAssertTrue([atom isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqual(atom.type, kMTMathAtomText);
    XCTAssertEqualObjects(atom.nucleus, @"abc");
    XCTAssertEqualObjects(((MTTextAtom *)atom).text, @"abc");
    XCTAssertEqual(((MTTextAtom *)atom).textStyle, kMTTextStyleRoman);
}

- (void) testTextAtomTextAndNucleusStayInSync
{
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"abc" style:kMTTextStyleRoman];
    atom.text = @"def";
    XCTAssertEqualObjects(atom.nucleus, @"def");
    XCTAssertEqualObjects(atom.stringValue, @"def");

    atom.nucleus = @"ghi";
    XCTAssertEqualObjects(atom.text, @"ghi");

    NSMutableString *out = [NSMutableString string];
    [atom appendLaTeXToString:out];
    XCTAssertEqualObjects(out, @"\\text{ghi}");
}

- (void) testTextAtomScriptsAllowed
{
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"x" style:kMTTextStyleBold];
    XCTAssertTrue(atom.scriptsAllowed);
}

- (void) testTextAtomFontStyleDefault
{
    // MTTextAtom must keep fontStyle = Default so the round-trip serializer
    // does not wrap it in a \mathrm{...} group; the atom's own
    // appendLaTeXToString: writes the \textbf{...} envelope.
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"x" style:kMTTextStyleBold];
    XCTAssertEqual(atom.fontStyle, kMTFontStyleDefault);
}

- (void) testTextAtomCopy
{
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"你好" style:kMTTextStyleItalic];
    MTMathList *sup = [[MTMathList alloc] init];
    [sup addAtom:[MTMathAtomFactory atomForCharacter:'2']];
    atom.superScript = sup;
    // indexRange is read-only in the public header; set via KVC for this test.
    [atom setValue:[NSValue valueWithRange:NSMakeRange(3, 7)] forKey:@"indexRange"];

    MTTextAtom *copy = [atom copy];
    XCTAssertTrue([copy isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqualObjects(copy.text, @"你好");
    XCTAssertEqual(copy.textStyle, kMTTextStyleItalic);
    XCTAssertNotNil(copy.superScript);
    XCTAssertNotEqual(copy.superScript, sup); // deep copy
    XCTAssertEqual(copy.indexRange.location, (NSUInteger)3);
    XCTAssertEqual(copy.indexRange.length,   (NSUInteger)7);
}

- (void) testTextAtomFinalize
{
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"x" style:kMTTextStyleRoman];
    MTMathList *sup = [[MTMathList alloc] init];
    [sup addAtom:[MTMathAtomFactory atomForCharacter:'2']];
    atom.superScript = sup;

    MTTextAtom *fin = (MTTextAtom *)[atom finalized];
    XCTAssertTrue([fin isKindOfClass:[MTTextAtom class]]);
    XCTAssertEqualObjects(fin.text, @"x");
    XCTAssertNotNil(fin.superScript);
}

- (void) testTextAtomRoundTripPlain
{
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"abc" style:kMTTextStyleRoman];
    NSMutableString *out = [NSMutableString string];
    [atom appendLaTeXToString:out];
    XCTAssertEqualObjects(out, @"\\text{abc}");
}

- (void) testTextAtomRoundTripBold
{
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"你好" style:kMTTextStyleBold];
    NSMutableString *out = [NSMutableString string];
    [atom appendLaTeXToString:out];
    XCTAssertEqualObjects(out, @"\\textbf{你好}");
}

- (void) testTextAtomRoundTripEscapes
{
    // Body contains characters that must be escaped on round-trip:
    // backslash, braces, _, ^, %, &, #, $.
    MTTextAtom *atom = [[MTTextAtom alloc]
                         initWithText:@"50% $5 {x} \\ a_b^c &d #e"
                                style:kMTTextStyleRoman];
    NSMutableString *out = [NSMutableString string];
    [atom appendLaTeXToString:out];
    XCTAssertEqualObjects(out, @"\\text{50\\% \\$5 \\{x\\} \\\\ a\\_b\\^c \\&d \\#e}");
}

- (void) testTextAtomAllStylesRoundTrip
{
    NSDictionary *cases = @{
        @(kMTTextStyleRoman):      @"\\text{x}",
        @(kMTTextStyleBold):       @"\\textbf{x}",
        @(kMTTextStyleItalic):     @"\\textit{x}",
        @(kMTTextStyleSansSerif):  @"\\textsf{x}",
        @(kMTTextStyleTypewriter): @"\\texttt{x}",
    };
    for (NSNumber *key in cases) {
        MTTextAtom *atom = [[MTTextAtom alloc]
                             initWithText:@"x"
                                    style:(MTTextStyle)key.unsignedIntegerValue];
        NSMutableString *out = [NSMutableString string];
        [atom appendLaTeXToString:out];
        XCTAssertEqualObjects(out, cases[key], @"style %@", key);
    }
}

// Regression test for FUN-3: MTFraction.stringValue had \frac and \atop swapped.
- (void) testFractionStringValueRuledUsesFrac
{
    // A fraction created with hasRule:YES is the standard ruled \frac form.
    MTFraction *frac = [[MTFraction alloc] initWithRule:YES];
    frac.numerator = [MTMathList new];
    frac.denominator = [MTMathList new];

    NSString *sv = frac.stringValue;
    XCTAssertTrue([sv containsString:@"\\frac"],
                  @"ruled fraction stringValue should contain \\frac, got: %@", sv);
    XCTAssertFalse([sv containsString:@"\\atop"],
                   @"ruled fraction stringValue must not contain \\atop, got: %@", sv);
}

- (void) testFractionStringValueRulelessUsesAtop
{
    // A fraction created with hasRule:NO is the rule-less \atop form.
    MTFraction *frac = [[MTFraction alloc] initWithRule:NO];
    frac.numerator = [MTMathList new];
    frac.denominator = [MTMathList new];

    NSString *sv = frac.stringValue;
    XCTAssertTrue([sv containsString:@"\\atop"],
                  @"rule-less fraction stringValue should contain \\atop, got: %@", sv);
    XCTAssertFalse([sv containsString:@"\\frac"],
                   @"rule-less fraction stringValue must not contain \\frac, got: %@", sv);
}

@end

// ---------------------------------------------------------------------------
// MTMathListRangeTest — unit tests for MTMathListRange, especially +unionRanges:
// ---------------------------------------------------------------------------

@interface MTMathListRangeTest : XCTestCase
@end

@implementation MTMathListRangeTest

// FUN-1: unionRanges: with two adjacent ranges must span both, not return ranges[0].
- (void)testUnionRangesTwoRangesSpansBoth
{
    // r1 covers atoms 0–2 (start=0, length=3), r2 covers atoms 3–4 (start=3, length=2)
    MTMathListIndex* i0 = [MTMathListIndex level0Index:0];
    MTMathListIndex* i3 = [MTMathListIndex level0Index:3];
    MTMathListRange* r1 = [MTMathListRange makeRange:i0 length:3];
    MTMathListRange* r2 = [MTMathListRange makeRange:i3 length:2];

    MTMathListRange* result = [MTMathListRange unionRanges:@[r1, r2]];

    // Expected: start=0, length=5
    XCTAssertEqual(result.start.atomIndex, (NSUInteger)0, @"start should be 0");
    XCTAssertEqual(result.length, (NSUInteger)5, @"length should span both ranges (5)");
}

// FUN-1: unionRanges: with three ranges must accumulate across all iterations.
- (void)testUnionRangesThreeRangesSpansAll
{
    MTMathListIndex* i0 = [MTMathListIndex level0Index:0];
    MTMathListIndex* i2 = [MTMathListIndex level0Index:2];
    MTMathListIndex* i5 = [MTMathListIndex level0Index:5];
    MTMathListRange* r1 = [MTMathListRange makeRange:i0 length:2];  // 0–1
    MTMathListRange* r2 = [MTMathListRange makeRange:i2 length:2];  // 2–3
    MTMathListRange* r3 = [MTMathListRange makeRange:i5 length:3];  // 5–7

    MTMathListRange* result = [MTMathListRange unionRanges:@[r1, r2, r3]];

    // Expected: start=0, length=8 (union of 0–1, 2–3, 5–7 → NSUnionRange gives 0–7 → length=8)
    XCTAssertEqual(result.start.atomIndex, (NSUInteger)0, @"start should be 0");
    XCTAssertEqual(result.length, (NSUInteger)8, @"length should span all three ranges (8)");
}

// Single-range edge case: must return an equivalent range.
- (void)testUnionRangesSingleRangeReturnsSelf
{
    MTMathListIndex* i2 = [MTMathListIndex level0Index:2];
    MTMathListRange* r = [MTMathListRange makeRange:i2 length:4];

    MTMathListRange* result = [MTMathListRange unionRanges:@[r]];

    XCTAssertEqual(result.start.atomIndex, (NSUInteger)2, @"start should be 2");
    XCTAssertEqual(result.length, (NSUInteger)4, @"length should be 4");
}

// Order independence: [r1, r2] and [r2, r1] must produce the same span.
- (void)testUnionRangesOrderIndependence
{
    MTMathListIndex* i1 = [MTMathListIndex level0Index:1];
    MTMathListIndex* i4 = [MTMathListIndex level0Index:4];
    MTMathListRange* r1 = [MTMathListRange makeRange:i1 length:2];  // 1–2
    MTMathListRange* r2 = [MTMathListRange makeRange:i4 length:3];  // 4–6

    MTMathListRange* fwd = [MTMathListRange unionRanges:@[r1, r2]];
    MTMathListRange* rev = [MTMathListRange unionRanges:@[r2, r1]];

    XCTAssertEqual(fwd.start.atomIndex, rev.start.atomIndex, @"start should be equal");
    XCTAssertEqual(fwd.length, rev.length, @"length should be equal");
    // Both should span from index 1 to 6 → start=1, length=6
    XCTAssertEqual(fwd.start.atomIndex, (NSUInteger)1, @"start should be 1");
    XCTAssertEqual(fwd.length, (NSUInteger)6, @"length should be 6");
}

- (void) testMathBoxModel
{
    MTMathBox* box = [MTMathBox new];
    XCTAssertEqual(box.type, kMTMathAtomBox);
    XCTAssertTrue(box.scriptsAllowed, @"kMTMathAtomBox (20) < kMTMathAtomBoundary (101) so scripts are allowed");

    MTMathList* inner = [[MTMathList alloc] init];
    [inner addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    box.innerList = inner;
    box.keepWidth = YES; box.keepHeight = YES; box.keepDepth = YES;
    box.drawChild = NO; box.hAlign = kMTBoxHAlignCenter;

    // typeToText
    XCTAssertEqualObjects([MTMathAtom atomWithType:kMTMathAtomBox value:@""].class, MTMathBox.class);

    // copy is deep and preserves every flag
    MTMathBox* copy = [box copy];
    XCTAssertNotEqual(copy.innerList, box.innerList);
    XCTAssertEqual(copy.innerList.atoms.count, 1);
    XCTAssertEqual(copy.keepWidth, box.keepWidth);
    XCTAssertEqual(copy.keepHeight, box.keepHeight);
    XCTAssertEqual(copy.keepDepth, box.keepDepth);
    XCTAssertEqual(copy.drawChild, box.drawChild);
    XCTAssertEqual(copy.hAlign, box.hAlign);

    // initWithType:value: guard throws for the wrong type
    XCTAssertThrows([[MTMathBox alloc] initWithType:kMTMathAtomOrdinary value:@""]);
}

- (void)testMathGroupAtom
{
    // Factory returns an MTMathGroup for the OrdGroup type.
    MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomOrdGroup value:@""];
    XCTAssertTrue([atom isKindOfClass:[MTMathGroup class]]);
    XCTAssertEqual(atom.type, kMTMathAtomOrdGroup);

    // Scripts are allowed (type < kMTMathAtomBoundary): no "scripts not allowed" throw.
    XCTAssertTrue(atom.scriptsAllowed);
    XCTAssertNoThrow(atom.superScript = [MTMathListBuilder buildFromString:@"2"]);

    // stringValue braces the group and preserves an interior \scriptstyle
    // (uses mathListToString:, not innerList.stringValue).
    MTMathGroup* group = (MTMathGroup*) [MTMathAtom atomWithType:kMTMathAtomOrdGroup value:@""];
    group.innerList = [MTMathListBuilder buildFromString:@"\\scriptstyle y"];
    XCTAssertEqualObjects(group.stringValue, @"{\\scriptstyle y}");

    // copyWithZone: deep-copies innerList (distinct object, equal content).
    MTMathGroup* copy = [group copy];
    XCTAssertNotEqual(copy.innerList, group.innerList);
    XCTAssertEqualObjects([MTMathListBuilder mathListToString:copy.innerList],
                          [MTMathListBuilder mathListToString:group.innerList]);

    // initWithType: guard — only kMTMathAtomOrdGroup is permitted.
    XCTAssertThrows([[MTMathGroup alloc] initWithType:kMTMathAtomBox value:@""]);
}

@end
