//
//  MTTypesetterTest.m
//  iosMath
//
//  Created by Kostub Deshmukh on 6/29/16.
//
//

#import <XCTest/XCTest.h>

#import "MTTypesetter.h"
#import "MTFontManager.h"
#import "MTMathListDisplay.h"
#import "MTMathAtomFactory.h"

@interface MTTypesetterTest : XCTestCase

@property (nonatomic) MTFont* font;

@end

@implementation MTTypesetterTest

- (void)setUp {
    [super setUp];
    self.font = MTFontManager.fontManager.defaultFont;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSimpleVariable {
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
    XCTAssertEqual(line.atoms.count, 1);
    // The x is italicized
    XCTAssertEqualObjects(line.attributedString.string, @"𝑥");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line.hasScript);
    
    // dimensions
    XCTAssertEqual(display.ascent, line.ascent);
    XCTAssertEqual(display.descent, line.descent);
    XCTAssertEqual(display.width, line.width);
    
    XCTAssertEqualWithAccuracy(display.ascent, 8.834, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 0.24, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 11.44, 0.01);
}

- (void)testMultipleVariables {
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"y"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"z"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"w"]];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 4)), "Got %@ instead", NSStringFromRange(display.range));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
    XCTAssertEqual(line.atoms.count, 4);
    XCTAssertEqualObjects(line.attributedString.string, @"𝑥𝑦𝑧𝑤");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 4)));
    XCTAssertFalse(line.hasScript);
    
    // dimensions
    XCTAssertEqual(display.ascent, line.ascent);
    XCTAssertEqual(display.descent, line.descent);
    XCTAssertEqual(display.width, line.width);
    
    XCTAssertEqualWithAccuracy(display.ascent, 8.834, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 4.12, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 44.86, 0.01);
}

- (void)testVariablesAndNumbers {
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"y"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomNumber value:@"2"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"w"]];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 4)), "Got %@ instead", NSStringFromRange(display.range));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
    XCTAssertEqual(line.atoms.count, 4);
    XCTAssertEqualObjects(line.attributedString.string, @"𝑥𝑦2𝑤");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 4)));
    XCTAssertFalse(line.hasScript);
    
    // dimensions
    XCTAssertEqual(display.ascent, line.ascent);
    XCTAssertEqual(display.descent, line.descent);
    XCTAssertEqual(display.width, line.width);
    
    XCTAssertEqualWithAccuracy(display.ascent, 13.32, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 4.12, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 45.56, 0.01);
}

- (void)testEquationWithOperatorsAndRelations {
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomNumber value:@"2"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"+"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomNumber value:@"3"]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomRelation value:@"="]];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"y"]];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 6)), "Got %@ instead", NSStringFromRange(display.range));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
    XCTAssertEqual(line.atoms.count, 6);
    XCTAssertEqualObjects(line.attributedString.string, @"2𝑥+3=𝑦");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 6)));
    XCTAssertFalse(line.hasScript);
    
    // dimensions
    XCTAssertEqual(display.ascent, line.ascent);
    XCTAssertEqual(display.descent, line.descent);
    XCTAssertEqual(display.width, line.width);
    
    XCTAssertEqualWithAccuracy(display.ascent, 13.32, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 4.12, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 92.36, 0.01);
}

#define XCTAssertEqualsCGPoint(p1, p2, accuracy, ...) \
    XCTAssertEqualWithAccuracy(p1.x, p2.x, accuracy, __VA_ARGS__); \
    XCTAssertEqualWithAccuracy(p1.y, p2.y, accuracy, __VA_ARGS__)

- (void)testSuperscript {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTMathAtom* x = [MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"];
    MTMathList* supersc = [[MTMathList alloc] init];
    [supersc addAtom:[MTMathAtom atomWithType:kMTMathAtomNumber value:@"2"]];
    x.superScript = supersc;
    [mathList addAtom:x];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 2);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
    XCTAssertEqual(line.atoms.count, 1);
    // The x is italicized
    XCTAssertEqualObjects(line.attributedString.string, @"𝑥");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertTrue(line.hasScript);
    
    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* display2 = (MTMathListDisplay*) sub1;
    XCTAssertEqual(display2.type, kMTLinePositionSuperscript);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(11.44, 7.26), 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, 0);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* sub1sub0 = display2.subDisplays[0];
    XCTAssertTrue([sub1sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub1sub0;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"2");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertFalse(line2.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 16.584, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 0.24, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 18.44, 0.01);
}

- (void)testSubscript {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTMathAtom* x = [MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"];
    MTMathList* subsc = [[MTMathList alloc] init];
    [subsc addAtom:[MTMathAtom atomWithType:kMTMathAtomNumber value:@"2"]];
    x.subScript = subsc;
    [mathList addAtom:x];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 2);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
    XCTAssertEqual(line.atoms.count, 1);
    // The x is italicized
    XCTAssertEqualObjects(line.attributedString.string, @"𝑥");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertTrue(line.hasScript);
    
    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* display2 = (MTMathListDisplay*) sub1;
    XCTAssertEqual(display2.type, kMTLinePositionSubscript);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(11.44, -4.94), 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, 0);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* sub1sub0 = display2.subDisplays[0];
    XCTAssertTrue([sub1sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub1sub0;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"2");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertFalse(line2.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 8.834, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 4.954, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 18.44, 0.01);
}

- (void)testSupersubscript {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTMathAtom* x = [MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"];
    MTMathList* supersc = [[MTMathList alloc] init];
    [supersc addAtom:[MTMathAtom atomWithType:kMTMathAtomNumber value:@"2"]];
    MTMathList* subsc = [[MTMathList alloc] init];
    [subsc addAtom:[MTMathAtom atomWithType:kMTMathAtomNumber value:@"1"]];
    x.subScript = subsc;
    x.superScript = supersc;
    [mathList addAtom:x];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 3);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
    XCTAssertEqual(line.atoms.count, 1);
    // The x is italicized
    XCTAssertEqualObjects(line.attributedString.string, @"𝑥");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertTrue(line.hasScript);
    
    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* display2 = (MTMathListDisplay*) sub1;
    XCTAssertEqual(display2.type, kMTLinePositionSuperscript);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(11.44, 7.26), 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, 0);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* sub1sub0 = display2.subDisplays[0];
    XCTAssertTrue([sub1sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub1sub0;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"2");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertFalse(line2.hasScript);
    
    MTDisplay* sub2 = display.subDisplays[2];
    XCTAssertTrue([sub2 isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* display3 = (MTMathListDisplay*) sub2;
    XCTAssertEqual(display3.type, kMTLinePositionSubscript);
    XCTAssertEqualsCGPoint(display3.position, CGPointMake(11.44, -5.278), 0.01);
    XCTAssertTrue(NSEqualRanges(display3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display3.hasScript);
    XCTAssertEqual(display3.index, 0);
    XCTAssertEqual(display3.subDisplays.count, 1);
    
    MTDisplay* sub2sub0 = display3.subDisplays[0];
    XCTAssertTrue([sub2sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line3 = (MTCTLineDisplay*) sub2sub0;
    XCTAssertEqual(line3.atoms.count, 1);
    XCTAssertEqualObjects(line3.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line3.position, CGPointZero));
    XCTAssertFalse(line3.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 16.584, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 5.292, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 18.44, 0.01);
}

@end
