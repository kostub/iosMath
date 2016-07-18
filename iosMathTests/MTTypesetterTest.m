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
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'y']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'z']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'w']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'y']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'2']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'w']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'2']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'+']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'3']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'=']];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'y']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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

- (void)testSuperscript {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTMathAtom* x = [MTMathAtomFactory atomForCharacter:'x'];
    MTMathList* supersc = [[MTMathList alloc] init];
    [supersc addAtom:[MTMathAtomFactory atomForCharacter:'2']];
    x.superScript = supersc;
    [mathList addAtom:x];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(17.08, 0), 0.01);
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
    XCTAssertEqualWithAccuracy(display.width, 27.08, 0.01);
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
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(17.08, 0), 0.01);
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
    XCTAssertEqualWithAccuracy(display.width, 27.08, 0.01);
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
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    XCTAssertTrue([subLeft isKindOfClass:[MTLargeGlyphDisplay class]]);
    MTLargeGlyphDisplay* glyph = (MTLargeGlyphDisplay*) subLeft;
    XCTAssertTrue(CGPointEqualToPoint(glyph.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(glyph.range, NSMakeRange(NSNotFound, 0)));
    XCTAssertFalse(glyph.hasScript);
    
    MTDisplay* subFrac = display0.subDisplays[1];
    XCTAssertTrue([subFrac isKindOfClass:[MTFractionDisplay class]]);
    MTFractionDisplay* fraction = (MTFractionDisplay*) subFrac;
    XCTAssertTrue(NSEqualRanges(fraction.range, NSMakeRange(0, 1)));
    XCTAssertFalse(fraction.hasScript);
    XCTAssertEqualsCGPoint(fraction.position, CGPointMake(13.66, 0), 0.01);
    XCTAssertNotNil(fraction.numerator);
    XCTAssertNotNil(fraction.denominator);
    
    MTMathListDisplay* display2 = fraction.numerator;
    XCTAssertEqual(display2.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(13.66, 13.54), 0.01);
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
    XCTAssertEqualsCGPoint(display3.position, CGPointMake(13.66, -13.72), 0.01);
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
    XCTAssertTrue([subRight isKindOfClass:[MTLargeGlyphDisplay class]]);
    MTLargeGlyphDisplay* glyph2 = (MTLargeGlyphDisplay*) subRight;
    XCTAssertEqualsCGPoint(glyph2.position, CGPointMake(23.66, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(glyph2.range, NSMakeRange(NSNotFound, 0)), "Got %@ instead", NSStringFromRange(glyph2.range));
    XCTAssertFalse(glyph2.hasScript);
    
    // dimensions
    XCTAssertEqualWithAccuracy(display.ascent, 28.92, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 18.94, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 33.88, 0.01);
}

- (void)testLargeOpNoLimitsText {
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:[MTMathAtomFactory atomForLatexSymbol:@"sin"]];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    [mathList addAtom:[MTMathAtomFactory atomForLatexSymbol:@"int"]];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 2)), "Got %@ instead", NSStringFromRange(display.range));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.index, NSNotFound);
    XCTAssertEqual(display.subDisplays.count, 2);
    
    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTLargeGlyphDisplay class]]);
    MTLargeGlyphDisplay* glyph = (MTLargeGlyphDisplay*) sub0;
    XCTAssertTrue(CGPointEqualToPoint(glyph.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(glyph.range, NSMakeRange(0, 1)));
    XCTAssertFalse(glyph.hasScript);
    
    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub1;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑥");
    XCTAssertEqualsCGPoint(line2.position, CGPointMake(22.213, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(1, 1)), "Got %@ instead", NSStringFromRange(line2.range));
    XCTAssertFalse(line2.hasScript);
    
    XCTAssertEqualWithAccuracy(display.ascent, 27.22, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 17.24, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 33.653, 0.01);
}

- (void)testLargeOpNoLimitsSymbolWithScripts {
    MTMathList* mathList = [[MTMathList alloc] init];
    // Integral
    MTMathAtom* op = [MTMathAtomFactory atomForLatexSymbol:@"int"];
    op.superScript = [[MTMathList alloc] init];
    [op.superScript addAtom:[MTMathAtomFactory atomForCharacter:'1']];
    op.subScript = [[MTMathList alloc] init];
    [op.subScript addAtom:[MTMathAtomFactory atomForCharacter:'0']];
    [mathList addAtom:op];
    [mathList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    XCTAssertEqualsCGPoint(display0.position, CGPointMake(18.88, 23.72), 0.01);
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
    XCTAssertEqualsCGPoint(display1.position, CGPointMake(7.06, -20.04), 0.01);
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
    XCTAssertTrue([sub2 isKindOfClass:[MTLargeGlyphDisplay class]]);
    MTLargeGlyphDisplay* glyph = (MTLargeGlyphDisplay*) sub2;
    XCTAssertTrue(CGPointEqualToPoint(glyph.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(glyph.range, NSMakeRange(0, 1)));
    XCTAssertTrue(glyph.hasScript); // There are subscripts and superscripts
    
    MTDisplay* sub3 = display.subDisplays[3];
    XCTAssertTrue([sub3 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line2 = (MTCTLineDisplay*) sub3;
    XCTAssertEqual(line2.atoms.count, 1);
    XCTAssertEqualObjects(line2.attributedString.string, @"𝑥");
    XCTAssertEqualsCGPoint(line2.position, CGPointMake(30.333, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(1, 1)), "Got %@ instead", NSStringFromRange(line2.range));
    XCTAssertFalse(line1.hasScript);
    
    XCTAssertEqualWithAccuracy(display.ascent, 33.044, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 20.362, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 41.773, 0.01);
}


- (void)testLargeOpWithLimitsTextWithScripts {
    MTMathList* mathList = [[MTMathList alloc] init];
    MTMathAtom* op = [MTMathAtomFactory atomForLatexSymbol:@"lim"];
    op.subScript = [[MTMathList alloc] init];
    [op.subScript addAtom:[MTMathAtomFactory atomForLatexSymbol:@"infty"]];
    [mathList addAtom:op];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    MTMathAtom* op = [MTMathAtomFactory atomForLatexSymbol:@"sum"];
    op.superScript = [[MTMathList alloc] init];
    [op.superScript addAtom:[MTMathAtomFactory atomForLatexSymbol:@"infty"]];
    op.subScript = [[MTMathList alloc] init];
    [op.subScript addAtom:[MTMathAtomFactory atomForCharacter:'0']];
    [mathList addAtom:op];
    [mathList addAtom:[MTMathAtom atomWithType:kMTMathAtomVariable value:@"x"]];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(10.38, -21.684), 0.01);
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
    XCTAssertEqualsCGPoint(displayU.position, CGPointMake(6.89, 23.168), 0.01);
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
    XCTAssertEqualsCGPoint(line2.position, CGPointMake(31.0933, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(line2.range, NSMakeRange(1, 1)), "Got %@ instead", NSStringFromRange(line2.range));
    XCTAssertFalse(line2.hasScript);
    
    XCTAssertEqualWithAccuracy(display.ascent, 29.356, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 22.006, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 42.533, 0.01);
}

- (void)testInner {
    MTMathList* innerList = [[MTMathList alloc] init];
    [innerList addAtom:[MTMathAtomFactory atomForCharacter:'x']];
    MTInner* inner = [[MTInner alloc] init];
    inner.innerList = innerList;
    inner.leftBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@"("];
    inner.rightBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:@"("];
    
    MTMathList* mathList = [[MTMathList alloc] init];
    [mathList addAtom:inner];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:mathList font:self.font style:kMTLineStyleDisplay textColor:[UIColor whiteColor]];
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
    XCTAssertTrue(CGPointEqualToPoint(display2.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display2.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display2.hasScript);
    XCTAssertEqual(display2.index, NSNotFound);
    XCTAssertEqual(display2.subDisplays.count, 3);
    
    MTDisplay* subLeft = display2.subDisplays[0];
    XCTAssertTrue([subLeft isKindOfClass:[MTLargeGlyphDisplay class]]);
    MTLargeGlyphDisplay* glyph = (MTLargeGlyphDisplay*) subLeft;
    XCTAssertTrue(CGPointEqualToPoint(glyph.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(glyph.range, NSMakeRange(NSNotFound, 0)));
    XCTAssertFalse(glyph.hasScript);
    
    MTDisplay* sub3 = display2.subDisplays[1];
    XCTAssertTrue([sub3 isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* display3 = (MTMathListDisplay*) sub3;
    XCTAssertEqual(display3.type, kMTLinePositionRegular);
    XCTAssertEqualsCGPoint(display3.position, CGPointMake(6.66, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(display3.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display3.hasScript);
    XCTAssertEqual(display3.index, NSNotFound);
    XCTAssertEqual(display3.subDisplays.count, 1);
    
    MTDisplay* subsub3 = display3.subDisplays[0];
    XCTAssertTrue([subsub3 isKindOfClass:[MTCTLineDisplay class]]);
    MTCTLineDisplay* line = (MTCTLineDisplay*) subsub3;
    XCTAssertEqual(line.atoms.count, 1);
    // The x is italicized
    XCTAssertEqualObjects(line.attributedString.string, @"𝑥");
    XCTAssertTrue(CGPointEqualToPoint(line.position, CGPointZero));
    XCTAssertFalse(line.hasScript);
    
    MTDisplay* subRight = display2.subDisplays[2];
    XCTAssertTrue([subRight isKindOfClass:[MTLargeGlyphDisplay class]]);
    MTLargeGlyphDisplay* glyph2 = (MTLargeGlyphDisplay*) subRight;
    XCTAssertEqualsCGPoint(glyph2.position, CGPointMake(18.1, 0), 0.01);
    XCTAssertTrue(NSEqualRanges(glyph2.range, NSMakeRange(NSNotFound, 0)), "Got %@ instead", NSStringFromRange(glyph2.range));
    XCTAssertFalse(glyph2.hasScript);
    
    // dimensions
    XCTAssertEqual(display.ascent, display2.ascent);
    XCTAssertEqual(display.descent, display2.descent);
    XCTAssertEqual(display.width, display2.width);
    
    XCTAssertEqualWithAccuracy(display.ascent, 14.96, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 4.98, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 24.76, 0.01);
}

@end
