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
#import "MTMathListBuilder.h"

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
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
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
    XCTAssertTrue(NSEqualRanges(line.range, NSMakeRange(0, 1)));
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
    MTMathList* mathList = [MTMathAtomFactory mathListForCharacters:@"xyzw"];
    
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
    XCTAssertTrue(NSEqualRanges(line.range, NSMakeRange(0, 4)));
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
    MTMathList* mathList = [MTMathAtomFactory mathListForCharacters:@"xy2w"];
    
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
    XCTAssertTrue(NSEqualRanges(line.range, NSMakeRange(0, 4)));
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
    MTMathList* mathList = [MTMathAtomFactory mathListForCharacters:@"2x+3=y"];
    
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
    XCTAssertTrue(NSEqualRanges(line.range, NSMakeRange(0, 6)));
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


#define XCTAssertEqualNSRange(r1, r2, ...) \
    XCTAssertEqual(r1.location, r2.location, __VA_ARGS__); \
    XCTAssertEqual(r1.length, r2.length, __VA_ARGS__)

- (void)testSuperscript {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTMathAtom* x = [MTMathAtomFactory atomForCharacter:'x'];
    MTMathList* supersc = [[MTMathList alloc] init];
    [supersc addAtom:[MTMathAtomFactory atomForCharacter:'2']];
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
    MTMathAtom* x = [MTMathAtomFactory atomForCharacter:'x'];
    MTMathList* subsc = [[MTMathList alloc] init];
    [subsc addAtom:[MTMathAtomFactory atomForCharacter:'1']];
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
    XCTAssertEqualObjects(line2.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertFalse(line2.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 8.834, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 4.954, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 18.44, 0.01);
}

- (void)testSupersubscript {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTMathAtom* x = [MTMathAtomFactory atomForCharacter:'x'];
    MTMathList* supersc = [[MTMathList alloc] init];
    [supersc addAtom:[MTMathAtomFactory atomForCharacter:'2']];
    MTMathList* subsc = [[MTMathList alloc] init];
    [subsc addAtom:[MTMathAtomFactory atomForCharacter:'1']];
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
    // Positioned differently when both subscript and superscript present.
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

- (void)testRadical {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTRadical* rad = [[MTRadical alloc] init];
    MTMathList* radicand = [[MTMathList alloc] init];
    [radicand addAtom:[MTMathAtomFactory atomForCharacter:'1']];
    rad.radicand = radicand;
    [mathList addAtom:rad];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTRadicalDisplay class]]);
    MTRadicalDisplay* radical = (MTRadicalDisplay*) sub0;
    XCTAssertTrue(NSEqualRanges(radical.range, NSMakeRange(0, 1)));
    XCTAssertFalse(radical.hasScript);
    XCTAssertTrue(CGPointEqualToPoint(radical.position, CGPointZero));
    XCTAssertNotNil(radical.radicand);
    XCTAssertNil(radical.degree);

    MTMathListDisplay* display2 = radical.radicand;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(16.66, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* subrad = display2.subDisplays[0];
    XCTAssertTrue([subrad isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) subrad;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line2.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 19.34, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 1.48, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 26.66, 0.01);
}

- (void)testRadicalWithDegree {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTRadical* rad = [[MTRadical alloc] init];
    MTMathList* radicand = [[MTMathList alloc] init];
    [radicand addAtom:[MTMathAtomFactory atomForCharacter:'1']];
    MTMathList* degree = [[MTMathList alloc] init];
    [degree addAtom:[MTMathAtomFactory atomForCharacter:'3']];
    rad.radicand = radicand;
    rad.degree = degree;
    [mathList addAtom:rad];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTRadicalDisplay class]]);
    MTRadicalDisplay* radical = (MTRadicalDisplay*) sub0;
    XCTAssertTrue(NSEqualRanges(radical.range, NSMakeRange(0, 1)));
    XCTAssertFalse(radical.hasScript);
    XCTAssertTrue(CGPointEqualToPoint(radical.position, CGPointZero));
    XCTAssertNotNil(radical.radicand);
    XCTAssertNotNil(radical.degree);
    
    MTMathListDisplay* display2 = radical.radicand;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(16.66, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* subrad = display2.subDisplays[0];
    XCTAssertTrue([subrad isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) subrad;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line2.hasScript);
    
    MTMathListDisplay* display3 = radical.degree;
    XCTAssertEqual(display3.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display3.position, CGPointMake(6.12, 10.716), 0.01);
    XCTAssertTrue(NSEqualRanges(display3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display3.hasScript);
    XCTAssertEqual(display3.index, NSNotFound);
    XCTAssertEqual(display3.subDisplays.count, 1);
    
    MTDisplay* subdeg = display3.subDisplays[0];
    XCTAssertTrue([subdeg isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line3 = (MTCTLineDisplay*) subdeg;
    XCTAssertEqual(line3.atoms.count, 1);
    XCTAssertEqualObjects(line3.attributedString.string, @"3");
    XCTAssertTrue(CGPointEqualToPoint(line3.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line3.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 19.34, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 1.48, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 26.66, 0.01);
}

- (void)testFraction {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTFraction* frac = [[MTFraction alloc] initWithRule:YES];
    MTMathList* num = [[MTMathList alloc] init];
    [num addAtom:[MTMathAtomFactory atomForCharacter:'1']];
    MTMathList* denom = [[MTMathList alloc] init];
    [denom addAtom:[MTMathAtomFactory atomForCharacter:'3']];
    frac.numerator = num;
    frac.denominator = denom;
    [mathList addAtom:frac];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTFractionDisplay class]]);
    MTFractionDisplay* fraction = (MTFractionDisplay*) sub0;
    XCTAssertTrue(NSEqualRanges(fraction.range, NSMakeRange(0, 1)));
    XCTAssertFalse(fraction.hasScript);
    XCTAssertTrue(CGPointEqualToPoint(fraction.position, CGPointZero));
    XCTAssertNotNil(fraction.numerator);
    XCTAssertNotNil(fraction.denominator);
    
    MTMathListDisplay* display2 = fraction.numerator;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(0, 13.54), 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* subnum = display2.subDisplays[0];
    XCTAssertTrue([subnum isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) subnum;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line2.hasScript);
    
    MTMathListDisplay* display3 = fraction.denominator;
    XCTAssertEqual(display3.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display3.position, CGPointMake(0, -13.72), 0.01);
    XCTAssertTrue(NSEqualRanges(display3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display3.hasScript);
    XCTAssertEqual(display3.index, NSNotFound);
    XCTAssertEqual(display3.subDisplays.count, 1);
    
    MTDisplay* subdenom = display3.subDisplays[0];
    XCTAssertTrue([subdenom isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line3 = (MTCTLineDisplay*) subdenom;
    XCTAssertEqual(line3.atoms.count, 1);
    XCTAssertEqualObjects(line3.attributedString.string, @"3");
    XCTAssertTrue(CGPointEqualToPoint(line3.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line3.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 26.86, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 14.18, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 10, 0.01);
}

- (void)testAtop {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTFraction* frac = [[MTFraction alloc] initWithRule:NO];
    MTMathList* num = [[MTMathList alloc] init];
    [num addAtom:[MTMathAtomFactory atomForCharacter:'1']];
    MTMathList* denom = [[MTMathList alloc] init];
    [denom addAtom:[MTMathAtomFactory atomForCharacter:'3']];
    frac.numerator = num;
    frac.denominator = denom;
    [mathList addAtom:frac];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTFractionDisplay class]]);
    MTFractionDisplay* fraction = (MTFractionDisplay*) sub0;
    XCTAssertTrue(NSEqualRanges(fraction.range, NSMakeRange(0, 1)));
    XCTAssertFalse(fraction.hasScript);
    XCTAssertTrue(CGPointEqualToPoint(fraction.position, CGPointZero));
    XCTAssertNotNil(fraction.numerator);
    XCTAssertNotNil(fraction.denominator);
    
    MTMathListDisplay* display2 = fraction.numerator;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(0, 13.54), 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* subnum = display2.subDisplays[0];
    XCTAssertTrue([subnum isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) subnum;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line2.hasScript);
    
    MTMathListDisplay* display3 = fraction.denominator;
    XCTAssertEqual(display3.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display3.position, CGPointMake(0, -13.72), 0.01);
    XCTAssertTrue(NSEqualRanges(display3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display3.hasScript);
    XCTAssertEqual(display3.index, NSNotFound);
    XCTAssertEqual(display3.subDisplays.count, 1);
    
    MTDisplay* subdenom = display3.subDisplays[0];
    XCTAssertTrue([subdenom isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line3 = (MTCTLineDisplay*) subdenom;
    XCTAssertEqual(line3.atoms.count, 1);
    XCTAssertEqualObjects(line3.attributedString.string, @"3");
    XCTAssertTrue(CGPointEqualToPoint(line3.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line3.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 26.86, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 14.18, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 10, 0.01);
}

- (void)testBinomial {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTFraction* frac = [[MTFraction alloc] initWithRule:NO];
    MTMathList* num = [[MTMathList alloc] init];
    [num addAtom:[MTMathAtomFactory atomForCharacter:'1']];
    MTMathList* denom = [[MTMathList alloc] init];
    [denom addAtom:[MTMathAtomFactory atomForCharacter:'3']];
    frac.numerator = num;
    frac.denominator = denom;
    frac.leftDelimiter = @"(";
    frac.rightDelimiter = @")";
    [mathList addAtom:frac];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* display0 = (MTMathListDisplay*) sub0;
    XCTAssertNotNil(display0);
    XCTAssertEqual(display0.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display0.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display0.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display0.hasScript);
    XCTAssertEqual(display0.index, NSNotFound);
    XCTAssertEqual(display0.subDisplays.count, 3);
    
    MTDisplay* subLeft = display0.subDisplays[0];
    XCTAssertTrue([subLeft isKindOfClass:[MTGlyphDisplay class]]);
    MTGlyphDisplay* glyph = (MTGlyphDisplay*) subLeft;
    XCTAssertTrue(CGPointEqualToPoint(glyph.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(glyph.range, NSMakeRange(NSNotFound, 0)));
    XCTAssertFalse(glyph.hasScript);
    
    MTDisplay* subFrac = display0.subDisplays[1];
    XCTAssertTrue([subFrac isKindOfClass:[MTFractionDisplay class]]);
    MTFractionDisplay* fraction = (MTFractionDisplay*) subFrac;
    XCTAssertTrue(NSEqualRanges(fraction.range, NSMakeRange(0, 1)));
    XCTAssertFalse(fraction.hasScript);
    XCTAssertEqualsCGPoint(fraction.position, CGPointMake(14.72, 0), 0.01);
    XCTAssertNotNil(fraction.numerator);
    XCTAssertNotNil(fraction.denominator);
    
    MTMathListDisplay* display2 = fraction.numerator;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(14.72, 13.54), 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* subnum = display2.subDisplays[0];
    XCTAssertTrue([subnum isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) subnum;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line2.hasScript);
    
    MTMathListDisplay* display3 = fraction.denominator;
    XCTAssertEqual(display3.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display3.position, CGPointMake(14.72, -13.72), 0.01);
    XCTAssertTrue(NSEqualRanges(display3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display3.hasScript);
    XCTAssertEqual(display3.index, NSNotFound);
    XCTAssertEqual(display3.subDisplays.count, 1);
    
    MTDisplay* subdenom = display3.subDisplays[0];
    XCTAssertTrue([subdenom isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line3 = (MTCTLineDisplay*) subdenom;
    XCTAssertEqual(line3.atoms.count, 1);
    XCTAssertEqualObjects(line3.attributedString.string, @"3");
    XCTAssertTrue(CGPointEqualToPoint(line3.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line3.hasScript);
    
    MTDisplay* subRight = display0.subDisplays[2];
    XCTAssertTrue([subRight isKindOfClass:[MTGlyphDisplay class]]);
    MTGlyphDisplay* glyph2 = (MTGlyphDisplay*) subRight;
    XCTAssertEqualsCGPoint(glyph2.position, CGPointMake(24.72, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(glyph2.range, NSMakeRange(NSNotFound, 0)), "Got %@ instead", NSStringFromRange(glyph2.range));
    XCTAssertFalse(glyph2.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 28.93, 0.001);
    XCTAssertEqualWithAccuracy(display.descent, 18.93, 0.001);
    XCTAssertEqualWithAccuracy(display.width, 39.44, 0.001);
}

- (void)testLargeOpNoLimitsText {
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtomFactory atomForLatexSymbolName:@"sin"]];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 2)), "Got %@ instead", NSStringFromRange(display.range));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 2);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
    XCTAssertEqual(line.atoms.count, 1);
    XCTAssertEqualObjects(line.attributedString.string, @"sin");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line.hasScript);
    
    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub1;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑥");
    XCTAssertEqualsCGPoint(line2.position, CGPointMake(27.893, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(1, 1)), "Got %@ instead", NSStringFromRange(line2.range));
    XCTAssertFalse(line2.hasScript);
    
    XCTAssertEqualWithAccuracy(display.ascent, 13.14, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 0.24, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 39.33, 0.01);
}

- (void)testLargeOpNoLimitsSymbol {
    MTMathList* mathList = [[MTMathList alloc] init];
    // Integral
    [mathList addAtom:[MTMathAtomFactory atomForLatexSymbolName:@"int"]];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 2)), "Got %@ instead", NSStringFromRange(display.range));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 2);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTGlyphDisplay class]]);
    MTGlyphDisplay* glyph = (MTGlyphDisplay*) sub0;
    XCTAssertTrue(CGPointEqualToPoint(glyph.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(glyph.range, NSMakeRange(0, 1)));
    XCTAssertFalse(glyph.hasScript);
    
    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub1;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑥");
    XCTAssertEqualsCGPoint(line2.position, CGPointMake(23.313, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(1, 1)), "Got %@ instead", NSStringFromRange(line2.range));
    XCTAssertFalse(line2.hasScript);
    
    XCTAssertEqualWithAccuracy(display.ascent, 27.23, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 17.23, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 34.753, 0.01);
}

- (void)testLargeOpNoLimitsSymbolWithScripts {
    MTMathList* mathList = [[MTMathList alloc] init];
    // Integral
    MTMathAtom* op = [MTMathAtomFactory atomForLatexSymbolName:@"int"];
    op.superScript = [[MTMathList alloc] init];
    [op.superScript addAtom:[MTMathAtomFactory atomForCharacter:'1']];
    op.subScript = [[MTMathList alloc] init];
    [op.subScript addAtom:[MTMathAtomFactory atomForCharacter:'0']];
    [mathList addAtom:op];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 2)), "Got %@ instead", NSStringFromRange(display.range));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 4);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* display0 = (MTMathListDisplay*) sub0;
    XCTAssertEqual(display0.type, kMTLinePositionSuperscript);
    XCTAssertEqualsCGPoint(display0.position, CGPointMake(19.98, 23.73), 0.001);
    XCTAssertTrue(NSEqualRanges(display0.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display0.hasScript);
    XCTAssertEqual(display0.index, 0);
    XCTAssertEqual(display0.subDisplays.count, 1);
    
    MTDisplay* sub0sub0 = display0.subDisplays[0];
    XCTAssertTrue([sub0sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line1 = (MTCTLineDisplay*) sub0sub0;
    XCTAssertEqual(line1.atoms.count, 1);
    XCTAssertEqualObjects(line1.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line1.position, CGPointZero));
    XCTAssertFalse(line1.hasScript);
    
    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* display1 = (MTMathListDisplay*) sub1;
    XCTAssertEqual(display1.type, kMTLinePositionSubscript);
    // Due to italic correction, positioned before subscript.
    XCTAssertEqualsCGPoint(display1.position, CGPointMake(8.16, -20.03), 0.001);
    XCTAssertTrue(NSEqualRanges(display1.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display1.hasScript);
    XCTAssertEqual(display1.index, 0);
    XCTAssertEqual(display1.subDisplays.count, 1);
    
    MTDisplay* sub1sub0 = display1.subDisplays[0];
    XCTAssertTrue([sub1sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line3 = (MTCTLineDisplay*) sub1sub0;
    XCTAssertEqual(line3.atoms.count, 1);
    XCTAssertEqualObjects(line3.attributedString.string, @"0");
    XCTAssertTrue(CGPointEqualToPoint(line3.position, CGPointZero));
    XCTAssertFalse(line3.hasScript);
    
    MTDisplay* sub2 = display.subDisplays[2];
    XCTAssertTrue([sub2 isKindOfClass:[MTGlyphDisplay class]]);
    MTGlyphDisplay* glyph = (MTGlyphDisplay*) sub2;
    XCTAssertTrue(CGPointEqualToPoint(glyph.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(glyph.range, NSMakeRange(0, 1)));
    XCTAssertTrue(glyph.hasScript); // There are subscripts and superscripts
    
    MTDisplay* sub3 = display.subDisplays[3];
    XCTAssertTrue([sub3 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub3;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑥");
    XCTAssertEqualsCGPoint(line2.position, CGPointMake(31.433, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(1, 1)), "Got %@ instead", NSStringFromRange(line2.range));
    XCTAssertFalse(line1.hasScript);
    
    XCTAssertEqualWithAccuracy(display.ascent, 33.054, 0.001);
    XCTAssertEqualWithAccuracy(display.descent, 20.352, 0.001);
    XCTAssertEqualWithAccuracy(display.width, 42.873, 0.001);
}


- (void)testLargeOpWithLimitsTextWithScripts {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTMathAtom* op = [MTMathAtomFactory atomForLatexSymbolName:@"lim"];
    op.subScript = [[MTMathList alloc] init];
    [op.subScript addAtom:[MTMathAtomFactory atomForLatexSymbolName:@"infty"]];
    [mathList addAtom:op];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 2)), "Got %@ instead", NSStringFromRange(display.range));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 2);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTLargeOpLimitsDisplay class]]);
    MTLargeOpLimitsDisplay* largeOp = (MTLargeOpLimitsDisplay*) sub0;
    XCTAssertTrue(CGPointEqualToPoint(largeOp.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(largeOp.range, NSMakeRange(0, 1)));
    XCTAssertFalse(largeOp.hasScript);
    XCTAssertNotNil(largeOp.lowerLimit);
    XCTAssertNil(largeOp.upperLimit);
    
    MTMathListDisplay* display2 = largeOp.lowerLimit;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(6.89, -12.02), 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* sub0sub0 = display2.subDisplays[0];
    XCTAssertTrue([sub0sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line1 = (MTCTLineDisplay*) sub0sub0;
    XCTAssertEqual(line1.atoms.count, 1);
    XCTAssertEqualObjects(line1.attributedString.string, @"∞");
    XCTAssertTrue(CGPointEqualToPoint(line1.position, CGPointZero));
    XCTAssertFalse(line1.hasScript);
    
    MTDisplay* sub3 = display.subDisplays[1];
    XCTAssertTrue([sub3 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub3;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑥");
    XCTAssertEqualsCGPoint(line2.position, CGPointMake(31.1133, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(1, 1)), "Got %@ instead", NSStringFromRange(line2.range));
    XCTAssertFalse(line1.hasScript);
    
    XCTAssertEqualWithAccuracy(display.ascent, 13.88, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 12.188, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 42.553, 0.01);
}

- (void)testLargeOpWithLimitsSymboltWithScripts {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTMathAtom* op = [MTMathAtomFactory atomForLatexSymbolName:@"sum"];
    op.superScript = [[MTMathList alloc] init];
    [op.superScript addAtom:[MTMathAtomFactory atomForLatexSymbolName:@"infty"]];
    op.subScript = [[MTMathList alloc] init];
    [op.subScript addAtom:[MTMathAtomFactory atomForCharacter:'0']];
    [mathList addAtom:op];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 2)), "Got %@ instead", NSStringFromRange(display.range));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 2);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTLargeOpLimitsDisplay class]]);
    MTLargeOpLimitsDisplay* largeOp = (MTLargeOpLimitsDisplay*) sub0;
    XCTAssertTrue(CGPointEqualToPoint(largeOp.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(largeOp.range, NSMakeRange(0, 1)));
    XCTAssertFalse(largeOp.hasScript);
    XCTAssertNotNil(largeOp.lowerLimit);
    XCTAssertNotNil(largeOp.upperLimit);
    
    MTMathListDisplay* display2 = largeOp.lowerLimit;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(10.94, -21.674), 0.001);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* sub0sub0 = display2.subDisplays[0];
    XCTAssertTrue([sub0sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line1 = (MTCTLineDisplay*) sub0sub0;
    XCTAssertEqual(line1.atoms.count, 1);
    XCTAssertEqualObjects(line1.attributedString.string, @"0");
    XCTAssertTrue(CGPointEqualToPoint(line1.position, CGPointZero));
    XCTAssertFalse(line1.hasScript);
    
    MTMathListDisplay* displayU = largeOp.upperLimit;
    XCTAssertEqual(displayU.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(displayU.position, CGPointMake(7.44, 23.178), 0.001);
    XCTAssertTrue(NSEqualRanges(displayU.range, NSMakeRange(0, 1)));
    XCTAssertFalse(displayU.hasScript);
    XCTAssertEqual(displayU.index, NSNotFound);
    XCTAssertEqual(displayU.subDisplays.count, 1);
    
    MTDisplay* sub0subU = displayU.subDisplays[0];
    XCTAssertTrue([sub0subU isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line3 = (MTCTLineDisplay*) sub0subU;
    XCTAssertEqual(line3.atoms.count, 1);
    XCTAssertEqualObjects(line3.attributedString.string, @"∞");
    XCTAssertTrue(CGPointEqualToPoint(line3.position, CGPointZero));
    XCTAssertFalse(line3.hasScript);
    
    MTDisplay* sub3 = display.subDisplays[1];
    XCTAssertTrue([sub3 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub3;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑥");
    XCTAssertEqualsCGPoint(line2.position, CGPointMake(32.2133, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(1, 1)), "Got %@ instead", NSStringFromRange(line2.range));
    XCTAssertFalse(line2.hasScript);
    
    XCTAssertEqualWithAccuracy(display.ascent, 29.366, 0.001);
    XCTAssertEqualWithAccuracy(display.descent, 21.996, 0.001);
    XCTAssertEqualWithAccuracy(display.width, 43.653, 0.001);
}

- (void)testInner {
    MTMathList* innerList = [[MTMathList alloc] init];
    [innerList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    MTInner* inner = [[MTInner alloc] init];
    inner.innerList = innerList;
    inner.leftBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@"("];
    inner.rightBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@")"];
    
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:inner];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTInnerDisplay class]]);
    MTInnerDisplay* display2 = (MTInnerDisplay*) sub0;
    XCTAssertTrue(CGPointEqualToPoint(display2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertTrue([display2.leftDelimiter isKindOfClass:[MTGlyphDisplay class]]);

    MTGlyphDisplay* glyph = (MTGlyphDisplay*) display2.leftDelimiter;
    XCTAssertTrue(CGPointEqualToPoint(glyph.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(glyph.range, NSMakeRange(NSNotFound, 0)));
    XCTAssertFalse(glyph.hasScript);
  
    XCTAssertTrue([display2.inner isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* innerMathListDisplay = (MTMathListDisplay*) display2.inner;
    XCTAssertEqualsCGPoint(innerMathListDisplay.position, CGPointMake(7.78, 0), 0.001);
    XCTAssertTrue(NSEqualRanges(innerMathListDisplay.range, NSMakeRange(0, 1)));
    XCTAssertFalse(innerMathListDisplay.hasScript);
    XCTAssertEqual(innerMathListDisplay.index, NSNotFound);
    XCTAssertEqual(innerMathListDisplay.subDisplays.count, 1);

    MTDisplay* subsub3 = innerMathListDisplay.subDisplays[0];
    XCTAssertTrue([subsub3 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) subsub3;
    XCTAssertEqual(line.atoms.count, 1);
    // The x is italicized
    XCTAssertEqualObjects(line.attributedString.string, @"𝑥");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertFalse(line.hasScript);

    XCTAssertTrue([display2.rightDelimiter isKindOfClass:[MTGlyphDisplay class]]);
    MTGlyphDisplay* glyph2 = (MTGlyphDisplay*) display2.rightDelimiter;
    XCTAssertEqualsCGPoint(glyph2.position, CGPointMake(19.22, 0), 0.001);
    XCTAssertTrue(NSEqualRanges(glyph2.range, NSMakeRange(NSNotFound, 0)), "Got %@ instead", NSStringFromRange(glyph2.range));
    XCTAssertFalse(glyph2.hasScript);

    // dimensions
    XCTAssertEqual(display.ascent, display2.ascent);
    XCTAssertEqual(display.descent, display2.descent);
    XCTAssertEqual(display.width, display2.width);

    XCTAssertEqualWithAccuracy(display.ascent, 14.97, 0.001);
    XCTAssertEqualWithAccuracy(display.descent, 4.97, 0.001);
    XCTAssertEqualWithAccuracy(display.width, 27, 0.01);
}

- (void)testOverline {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTOverLine* over = [[MTOverLine alloc] init];
    MTMathList* inner = [[MTMathList alloc] init];
    [inner addAtom:[MTMathAtomFactory atomForCharacter:'1']];
    over.innerList = inner;
    [mathList addAtom:over];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTLineDisplay class]]);
    MTLineDisplay* overline = (MTLineDisplay*) sub0;
    XCTAssertTrue(NSEqualRanges(overline.range, NSMakeRange(0, 1)));
    XCTAssertFalse(overline.hasScript);
    XCTAssertTrue(CGPointEqualToPoint(overline.position, CGPointZero));
    XCTAssertNotNil(overline.inner);
    
    MTMathListDisplay* display2 = overline.inner;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointZero, 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* subover = display2.subDisplays[0];
    XCTAssertTrue([subover isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) subover;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line2.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 17.32, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 0.02, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 10, 0.01);
}

- (void)testUnderline {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTUnderLine* under = [[MTUnderLine alloc] init];
    MTMathList* inner = [[MTMathList alloc] init];
    [inner addAtom:[MTMathAtomFactory atomForCharacter:'1']];
    under.innerList = inner;
    [mathList addAtom:under];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTLineDisplay class]]);
    MTLineDisplay* underline = (MTLineDisplay*) sub0;
    XCTAssertTrue(NSEqualRanges(underline.range, NSMakeRange(0, 1)));
    XCTAssertFalse(underline.hasScript);
    XCTAssertTrue(CGPointEqualToPoint(underline.position, CGPointZero));
    XCTAssertNotNil(underline.inner);
    
    MTMathListDisplay* display2 = underline.inner;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointZero, 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);
    
    MTDisplay* subover = display2.subDisplays[0];
    XCTAssertTrue([subover isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) subover;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"1");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line2.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 13.32, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 4.02, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 10, 0.01);
}

- (void)testSpacing {
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    [mathList addAtom:[[MTMathSpace alloc] initWithSpace:9]];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'y']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 3)), "Got %@ instead", NSStringFromRange(display.range));
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
    XCTAssertTrue(NSEqualRanges(line.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line.hasScript);
    
    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub1;
    XCTAssertEqual(line2.atoms.count, 1);
    // The x is italicized
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑦");
    XCTAssertEqualsCGPoint(line2.position, CGPointMake(21.44, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(2, 1)), "Got %@ instead", NSStringFromRange(line2.range));
    XCTAssertFalse(line2.hasScript);
    
    MTMathList* noSpace = [[MTMathList alloc] init];
    [noSpace addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    [noSpace addAtom:[MTMathAtomFactory atomForCharacter:'y']];
    
    MTMathListDisplay* noSpaceDisplay = [MTTypesetter createLineForMathList:noSpace font:self.font style:kMTLineStyleDisplay];
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, noSpaceDisplay.ascent, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, noSpaceDisplay.descent, 0.01);
    XCTAssertEqualWithAccuracy(display.width, noSpaceDisplay.width + 10, 0.01);
}

// For issue: https://github.com/kostub/iosMath/issues/5
- (void) testLargeRadicalDescent
{
    MTMathList* list = [MTMathListBuilder buildFromString:@"\\sqrt{\\frac{\\sqrt{\\frac{1}{2}} + 3}{\\sqrt{5}^x}}"];
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list font:self.font style:kMTLineStyleDisplay];
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 49.18, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 21.308, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 82.569, 0.01);
}

- (void) testMathTable
{
    MTMathList* c00 = [MTMathAtomFactory mathListForCharacters:@"1"];
    MTMathList* c01 = [MTMathAtomFactory mathListForCharacters:@"y+z"];
    MTMathList* c02 = [MTMathAtomFactory mathListForCharacters:@"y"];
    
    MTMathList* c11 = [[MTMathList alloc] init];
    [c11 addAtom:[MTMathAtomFactory fractionWithNumeratorStr:@"1" denominatorStr:@"2x"]];
    MTMathList* c12 = [MTMathAtomFactory mathListForCharacters:@"x-y"];
    
    MTMathList* c20 = [MTMathAtomFactory mathListForCharacters:@"x+5"];
    MTMathList* c22 = [MTMathAtomFactory mathListForCharacters:@"12"];

    
    MTMathTable* table = [[MTMathTable alloc] init];
    [table setCell:c00 forRow:0 column:0];
    [table setCell:c01 forRow:0 column:1];
    [table setCell:c02 forRow:0 column:2];
    [table setCell:c11 forRow:1 column:1];
    [table setCell:c12 forRow:1 column:2];
    [table setCell:c20 forRow:2 column:0];
    [table setCell:c22 forRow:2 column:2];
    
    // alignments
    [table setAlignment:kMTColumnAlignmentRight forColumn:0];
    [table setAlignment:kMTColumnAlignmentLeft forColumn:2];
    
    table.interColumnSpacing = 18; // 1 quad
    
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:table];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTMathListDisplay class]]);
    
    MTMathListDisplay* display2 = (MTMathListDisplay*) sub0;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointZero, 0.01);
    XCTAssertEqualNSRange(display2.range, NSMakeRange(0, 1));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 3);
    CGFloat rowPos[3] = { 30.31, -2.67, -31.95};
    // alignment is right, center, left.
    CGFloat cellPos[3][3] = { { 35.89, 65.89, 129.438 }, { 45.89, 76.94, 129.438}, { 0, 87.66, 129.438}};
    // check the 3 rows of the matrix
    for (int i = 0; i < 3; i++) {
        MTDisplay* sub0i = display2.subDisplays[i];
        XCTAssertTrue([sub0i isKindOfClass:[MTMathListDisplay class]]);
        
        MTMathListDisplay* row = (MTMathListDisplay*) sub0i;
        XCTAssertEqual(row.type, kMTLinePositionRegular);
        XCTAssertEqualsCGPoint(row.position, CGPointMake(0, rowPos[i]), 0.01);
        XCTAssertTrue(NSEqualRanges(row.range, NSMakeRange(0, 3)));
        XCTAssertFalse(row.hasScript);
        XCTAssertEqual(row.index, NSNotFound);
        XCTAssertEqual(row.subDisplays.count, 3);
        
        for (int j = 0; j < 3; j++) {
            MTDisplay* sub0ij = row.subDisplays[j];
            XCTAssertTrue([sub0ij isKindOfClass:[MTMathListDisplay class]]);
            
            MTMathListDisplay* col = (MTMathListDisplay*) sub0ij;
            XCTAssertEqual(col.type, kMTLinePositionRegular);
            XCTAssertEqualsCGPoint(col.position, CGPointMake(cellPos[i][j], 0) ,0.01);
            XCTAssertFalse(col.hasScript);
            XCTAssertEqual(col.index, NSNotFound);
        }
    }
}

- (void) testLatexSymbols
{
    // Test all latex symbols
    NSArray<NSString*>* allSymbols = [MTMathAtomFactory supportedLatexSymbolNames];
    for (NSString* symName in allSymbols) {
        MTMathList* list = [[MTMathList alloc] init];
        MTMathAtom* atom = [MTMathAtomFactory atomForLatexSymbolName:symName];
        XCTAssertNotNil(atom);
        if (atom.type >= kMTMathAtomBoundary) {
            // Skip these types as they aren't symbols.
            continue;
        }
        
        [list addAtom:atom];
        
        MTMathListDisplay* display = [MTTypesetter createLineForMathList:list font:self.font style:kMTLineStyleDisplay];
        XCTAssertNotNil(display, @"Symbol %@", symName);
        
        XCTAssertEqual(display.type, kMTLinePositionRegular);
        XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
        XCTAssertEqualNSRange(display.range, NSMakeRange(0, 1));
        XCTAssertFalse(display.hasScript);
        XCTAssertEqual(display.index, NSNotFound);
        XCTAssertEqual(display.subDisplays.count, 1, @"Symbol %@", symName);
        
        MTDisplay* sub0 = display.subDisplays[0];
        if (atom.type == kMTMathAtomLargeOperator && atom.nucleus.length == 1) {
            // These large operators are rendered differently;
            XCTAssertTrue([sub0 isKindOfClass:[MTGlyphDisplay class]]);
            MTGlyphDisplay* glyph = (MTGlyphDisplay*) sub0;
            XCTAssertEqualsCGPoint(glyph.position, CGPointZero, 0.01);
            XCTAssertEqualNSRange(glyph.range, NSMakeRange(0, 1));
            XCTAssertFalse(glyph.hasScript);
        } else {
            XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]], @"Symbol %@", symName);
            MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
            XCTAssertEqual(line.atoms.count, 1);
            if (atom.type != kMTMathAtomVariable) {
                XCTAssertEqualObjects(line.attributedString.string, atom.nucleus);
            }
            XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
            XCTAssertEqualNSRange(line.range, NSMakeRange(0, 1));
            XCTAssertFalse(line.hasScript);
        }
        
        // dimensions
        XCTAssertEqual(display.ascent, sub0.ascent);
        XCTAssertEqual(display.descent, sub0.descent);
        XCTAssertEqual(display.width, sub0.width);
        
        // All chars will occupy some space.
        if (![atom.nucleus isEqualToString:@" "]) {
            // all chars except space have height
            XCTAssertGreaterThan(display.ascent + display.descent, 0, @"Symbol %@", symName);
        }
        // all chars have a width.
        XCTAssertGreaterThan(display.width, 0);
    }
}

- (void) testAtomWithAllFontStyles:(MTMathAtom*) atom
{
    NSArray* fontStyles = @[
                            @(kMTFontStyleDefault),
                            @(kMTFontStyleRoman),
                            @(kMTFontStyleBold),
                            @(kMTFontStyleCaligraphic),
                            @(kMTFontStyleTypewriter),
                            @(kMTFontStyleItalic),
                            @(kMTFontStyleSansSerif),
                            @(kMTFontStyleFraktur),
                            @(kMTFontStyleBlackboard),
                            @(kMTFontStyleBoldItalic),
                            ];
    for (NSNumber* fontStyle in fontStyles) {
        NSInteger style = fontStyle.integerValue;
        MTMathAtom* copy = [atom copy];
        copy.fontStyle = style;
        MTMathList* list = [MTMathList mathListWithAtoms:copy, nil];

        MTMathListDisplay* display = [MTTypesetter createLineForMathList:list font:self.font style:kMTLineStyleDisplay];
        XCTAssertNotNil(display, @"Symbol %@", atom.nucleus);

        XCTAssertEqual(display.type, kMTLinePositionRegular);
        XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
        XCTAssertEqualNSRange(display.range, NSMakeRange(0, 1));
        XCTAssertFalse(display.hasScript);
        XCTAssertEqual(display.index, NSNotFound);
        XCTAssertEqual(display.subDisplays.count, 1, @"Symbol %@", atom.nucleus);

        MTDisplay* sub0 = display.subDisplays[0];
        XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]], @"Symbol %@", atom.nucleus);
        MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
        XCTAssertEqual(line.atoms.count, 1);
        XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
        XCTAssertEqualNSRange(line.range, NSMakeRange(0, 1));
        XCTAssertFalse(line.hasScript);

        // dimensions
        XCTAssertEqual(display.ascent, sub0.ascent);
        XCTAssertEqual(display.descent, sub0.descent);
        XCTAssertEqual(display.width, sub0.width);

        // All chars will occupy some space.
        XCTAssertGreaterThan(display.ascent + display.descent, 0, @"Symbol %@", atom.nucleus);
        // all chars have a width.
        XCTAssertGreaterThan(display.width, 0);
    }
}

- (void) testVariables
{
    // Test all variables
    NSArray<NSString*>* allSymbols = [MTMathAtomFactory supportedLatexSymbolNames];
    for (NSString* symName in allSymbols) {
        MTMathAtom* atom = [MTMathAtomFactory atomForLatexSymbolName:symName];
        XCTAssertNotNil(atom);
        if (atom.type != kMTMathAtomVariable) {
            // Skip these types as we are only interested in variables.
            continue;
        }
        [self testAtomWithAllFontStyles:atom];
    }
    NSString* alphaNum = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.";
    MTMathList* mathList = [MTMathAtomFactory mathListForCharacters:alphaNum];
    for (MTMathAtom* atom in mathList.atoms) {
        [self testAtomWithAllFontStyles:atom];
    }
}

- (void) testStyleChanges
{
    MTFraction* frac = [MTMathAtomFactory fractionWithNumeratorStr:@"1" denominatorStr:@"2"];
    MTMathList* list = [MTMathList mathListWithAtoms:frac, nil];
    MTMathAtom* style = [[MTMathStyle alloc] initWithStyle:kMTLineStyleText];
    MTMathList* textList = [MTMathList mathListWithAtoms:style, frac, nil];
    
    // This should make the display same as text.
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:textList font:self.font style:kMTLineStyleDisplay];
    MTMathListDisplay* textDisplay = [MTTypesetter createLineForMathList:list font:self.font style:kMTLineStyleText];
    MTMathListDisplay* originalDisplay = [MTTypesetter createLineForMathList:list font:self.font style:kMTLineStyleDisplay];
    
    // Display should be the same as rendering the fraction in text style.
    XCTAssertEqual(display.ascent, textDisplay.ascent);
    XCTAssertEqual(display.descent, textDisplay.descent);
    XCTAssertEqual(display.width, textDisplay.width);
    
    // Original display should be larger than display since it is greater.
    XCTAssertGreaterThan(originalDisplay.ascent, display.ascent);
    XCTAssertGreaterThan(originalDisplay.descent, display.descent);
    XCTAssertGreaterThan(originalDisplay.width, display.width);
}

- (void) testStyleMiddle
{
    MTMathAtom* atom1 = [MTMathAtomFactory atomForCharacter:'x'];
    MTMathAtom* style1 = [[MTMathStyle alloc] initWithStyle:kMTLineStyleScript];
    MTMathAtom* atom2 = [MTMathAtomFactory atomForCharacter:'y'];
    MTMathAtom* style2 = [[MTMathStyle alloc] initWithStyle:kMTLineStyleScriptScript];
    MTMathAtom* atom3 = [MTMathAtomFactory atomForCharacter:'z'];
    MTMathList* list = [MTMathList mathListWithAtoms:atom1, style1, atom2, style2, atom3, nil];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertEqualNSRange(display.range, NSMakeRange(0, 5));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 3);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) sub0;
    XCTAssertEqual(line.atoms.count, 1);
    XCTAssertEqualObjects(line.attributedString.string, @"𝑥");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertEqualNSRange(line.range, NSMakeRange(0, 1));
    XCTAssertFalse(line.hasScript);
    
    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line1 = (MTCTLineDisplay*) sub1;
    XCTAssertEqual(line1.atoms.count, 1);
    XCTAssertEqualObjects(line1.attributedString.string, @"𝑦");
    XCTAssertEqualNSRange(line1.range, NSMakeRange(2, 1));
    XCTAssertFalse(line1.hasScript);
    
    MTDisplay* sub2 = display.subDisplays[2];
    XCTAssertTrue([sub2 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub2;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑧");
    XCTAssertEqualNSRange(line2.range, NSMakeRange(4, 1));
    XCTAssertFalse(line2.hasScript);
}

- (void)testAccent {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTAccent* accent = [MTMathAtomFactory accentWithName:@"hat"];
    MTMathList* inner = [[MTMathList alloc] init];
    [inner addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    accent.innerList = inner;
    [mathList addAtom:accent];

    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTAccentDisplay class]]);
    MTAccentDisplay* accentDisp = (MTAccentDisplay*) sub0;
    XCTAssertTrue(NSEqualRanges(accentDisp.range, NSMakeRange(0, 1)));
    XCTAssertFalse(accentDisp.hasScript);
    XCTAssertTrue(CGPointEqualToPoint(accentDisp.position, CGPointZero));
    XCTAssertNotNil(accentDisp.accentee);
    XCTAssertNotNil(accentDisp.accent);

    MTMathListDisplay* display2 = accentDisp.accentee;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointZero, 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);

    MTDisplay* subaccentee = display2.subDisplays[0];
    XCTAssertTrue([subaccentee isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) subaccentee;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑥");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(line2.hasScript);

    MTGlyphDisplay* glyph = accentDisp.accent;
    XCTAssertEqualsCGPoint(glyph.position, CGPointMake(11.86, 0), 0.01);
    XCTAssertEqualNSRange(glyph.range, NSMakeRange(0, 1));
    XCTAssertFalse(glyph.hasScript);

    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 14.68, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 0.24, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 11.44, 0.01);
}

- (void)testWideAccent {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTAccent* accent = [MTMathAtomFactory accentWithName:@"hat"];
    accent.innerList = [MTMathAtomFactory mathListForCharacters:@"xyzw"];
    [mathList addAtom:accent];

    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 1);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTAccentDisplay class]]);
    MTAccentDisplay* accentDisp = (MTAccentDisplay*) sub0;
    XCTAssertTrue(NSEqualRanges(accentDisp.range, NSMakeRange(0, 1)));
    XCTAssertFalse(accentDisp.hasScript);
    XCTAssertTrue(CGPointEqualToPoint(accentDisp.position, CGPointZero));
    XCTAssertNotNil(accentDisp.accentee);
    XCTAssertNotNil(accentDisp.accent);

    MTMathListDisplay* display2 = accentDisp.accentee;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointZero, 0.01);
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 4)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 1);

    MTDisplay* subaccentee = display2.subDisplays[0];
    XCTAssertTrue([subaccentee isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) subaccentee;
    XCTAssertEqual(line2.atoms.count, 4);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑥𝑦𝑧𝑤");
    XCTAssertTrue(CGPointEqualToPoint(line2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(0, 4)));
    XCTAssertFalse(line2.hasScript);

    MTGlyphDisplay* glyph = accentDisp.accent;
    XCTAssertEqualsCGPoint(glyph.position, CGPointMake(3.47, 0), 0.01);
    XCTAssertEqualNSRange(glyph.range, NSMakeRange(0, 1));
    XCTAssertFalse(glyph.hasScript);

    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 14.98, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 4.12, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 44.86, 0.01);
}


@end
