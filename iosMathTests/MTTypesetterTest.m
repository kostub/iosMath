//
//  MTTypesetterTest.m
//  iosMath
//
//  Created by Kostub Deshmukh on 6/29/16.
//
//

#import <XCTest/XCTest.h>
#import <CoreText/CoreText.h>

#import "MTTypesetter.h"
#import "MTFont+Internal.h"
#import "MTFontManager.h"
#import "MTMathListDisplay.h"
#import "MTMathListDisplayInternal.h"
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

- (MTMathListDisplay*)displayForLaTeX:(NSString*)latex
{
    MTMathList* list = [MTMathListBuilder buildFromString:latex];
    XCTAssertNotNil(list, @"%@", latex);
    return [MTTypesetter createLineForMathList:list font:self.font style:kMTLineStyleDisplay];
}

- (MTDisplay*)singleDisplayForLaTeX:(NSString*)latex
{
    MTMathListDisplay* display = [self displayForLaTeX:latex];
    XCTAssertEqual(display.subDisplays.count, 1, @"%@", latex);
    return display.subDisplays.firstObject;
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
    XCTAssertEqualWithAccuracy(display.descent, 0.22, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 4.1, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 4.1, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 4.1, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 0.22, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 4.94, 0.01);
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
    XCTAssertEqualsCGPoint(display3.position, CGPointMake(11.44, -5.264), 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 5.264, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 1.46, 0.01);
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
    XCTAssertEqualsCGPoint(display3.position, CGPointMake(6.12, 10.728), 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 1.46, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 14.16, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 14.16, 0.01);
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
    XCTAssertEqualWithAccuracy(display.ascent, 28.92, 0.001);
    XCTAssertEqualWithAccuracy(display.descent, 18.92, 0.001);
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
    XCTAssertEqualWithAccuracy(display.descent, 0.22, 0.01);
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
    
    XCTAssertEqualWithAccuracy(display.ascent, 27.22, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 17.22, 0.01);
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
    XCTAssertEqualsCGPoint(display0.position, CGPointMake(19.98, 23.72), 0.001);
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
    XCTAssertEqualsCGPoint(display1.position, CGPointMake(8.16, -20.02), 0.001);
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
    
    XCTAssertEqualWithAccuracy(display.ascent, 33.044, 0.001);
    XCTAssertEqualWithAccuracy(display.descent, 20.328, 0.001);
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
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(6.89, -12.0), 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 12.154, 0.01);
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
    XCTAssertEqualsCGPoint(display2.position, CGPointMake(10.94, -21.664), 0.001);
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
    XCTAssertEqualsCGPoint(displayU.position, CGPointMake(7.44, 23.154), 0.001);
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
    
    XCTAssertEqualWithAccuracy(display.ascent, 29.342, 0.001);
    XCTAssertEqualWithAccuracy(display.descent, 21.972, 0.001);
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

    XCTAssertEqualWithAccuracy(display.ascent, 14.96, 0.001);
    XCTAssertEqualWithAccuracy(display.descent, 4.96, 0.001);
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
    XCTAssertEqualWithAccuracy(display.descent, 0.0, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 4.0, 0.01);
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
    XCTAssertEqualWithAccuracy(display.ascent, 49.16, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, 21.288, 0.01);
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
    CGFloat rowPos[3] = { 30.28, -2.68, -31.95};
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
    XCTAssertEqualWithAccuracy(display.descent, 0.22, 0.01);
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
    XCTAssertEqualWithAccuracy(display.descent, 4.1, 0.01);
    XCTAssertEqualWithAccuracy(display.width, 44.86, 0.01);
}

- (void)testLargeDelimiterHeightsIncreaseBySize
{
    NSArray<NSString*>* tests = @[ @"\\big(", @"\\Big(", @"\\bigg(", @"\\Bigg(" ];
    CGFloat previousHeight = 0;
    for (NSString* latex in tests) {
        MTDisplay* delimiter = [self singleDisplayForLaTeX:latex];
        XCTAssertTrue([delimiter isKindOfClass:[MTGlyphDisplay class]], @"%@", latex);
        CGFloat height = delimiter.ascent + delimiter.descent;
        XCTAssertGreaterThan(height, previousHeight, @"%@", latex);
        previousHeight = height;
    }
    XCTAssertGreaterThanOrEqual(previousHeight, 2.470f * self.font.fontSize);
}

- (void)testLargeDelimiterClassDoesNotChangeGlyphMetrics
{
    MTDisplay* ordinary = [self singleDisplayForLaTeX:@"\\big("];
    MTDisplay* open = [self singleDisplayForLaTeX:@"\\bigl("];
    MTDisplay* close = [self singleDisplayForLaTeX:@"\\bigr("];
    XCTAssertEqualWithAccuracy(ordinary.ascent, open.ascent, 0.01);
    XCTAssertEqualWithAccuracy(ordinary.descent, open.descent, 0.01);
    XCTAssertEqualWithAccuracy(ordinary.width, open.width, 0.01);
    XCTAssertEqualWithAccuracy(ordinary.ascent, close.ascent, 0.01);
    XCTAssertEqualWithAccuracy(ordinary.descent, close.descent, 0.01);
    XCTAssertEqualWithAccuracy(ordinary.width, close.width, 0.01);
}

- (void)testLargeDelimiterOpenSpacingIsZeroBeforeOrdinaryAtom
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\bigl(x"];
    XCTAssertEqual(display.subDisplays.count, 2u);

    MTDisplay* left = display.subDisplays[0];
    MTDisplay* x = display.subDisplays[1];
    CGFloat gap = x.position.x - (left.position.x + left.width);
    XCTAssertEqualWithAccuracy(gap, 0, 0.01);
}

- (void)testLargeDelimiterRelationSpacingExceedsOrdinaryDelimiterSpacing
{
    MTMathListDisplay* relation = [self displayForLaTeX:@"\\bigm|x"];
    MTMathListDisplay* ordinary = [self displayForLaTeX:@"|x"];
    XCTAssertEqual(relation.subDisplays.count, 2u);
    XCTAssertEqual(ordinary.subDisplays.count, 1u);

    MTDisplay* relDelimiter = relation.subDisplays[0];
    MTDisplay* relX = relation.subDisplays[1];
    MTCTLineDisplay* ordinaryLine = (MTCTLineDisplay*)ordinary.subDisplays[0];
    XCTAssertTrue([ordinaryLine isKindOfClass:[MTCTLineDisplay class]]);
    XCTAssertEqual(ordinaryLine.atoms.count, 2u);

    CGFloat relationGap = relX.position.x - (relDelimiter.position.x + relDelimiter.width);
    XCTAssertGreaterThan(relationGap, 0.0);
}

- (void)testLargeDelimiterNullDelimiterHasZeroWidth
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\bigl.x\\bigr."];
    XCTAssertEqual(display.subDisplays.count, 3u);

    MTDisplay* left = display.subDisplays[0];
    MTDisplay* x = display.subDisplays[1];
    MTDisplay* right = display.subDisplays[2];

    XCTAssertEqualWithAccuracy(left.width, 0, 0.001);
    XCTAssertEqualWithAccuracy(left.ascent, 0, 0.001);
    XCTAssertEqualWithAccuracy(left.descent, 0, 0.001);
    XCTAssertEqualWithAccuracy(right.width, 0, 0.001);
    XCTAssertEqualWithAccuracy(x.position.x, 0, 0.001);
}

- (void)testLargeDelimiterScalesInScriptStyle
{
    MTDisplay* displayStyle = [self singleDisplayForLaTeX:@"\\big("];
    MTDisplay* scriptStyle = [self singleDisplayForLaTeX:@"\\scriptstyle\\big("];
    CGFloat displayHeight = displayStyle.ascent + displayStyle.descent;
    CGFloat scriptHeight = scriptStyle.ascent + scriptStyle.descent;
    CGFloat expectedRatio = self.font.mathTable.scriptScaleDown;
    XCTAssertEqualWithAccuracy(scriptHeight / displayHeight, expectedRatio, 0.12);
}

- (void)testLargeDelimiterSupportsScripts
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\big(^2"];
    XCTAssertEqual(display.subDisplays.count, 2u);
    MTDisplay* delimiter = display.subDisplays[0];
    MTMathListDisplay* superscript = (MTMathListDisplay*)display.subDisplays[1];
    XCTAssertTrue([delimiter isKindOfClass:[MTGlyphDisplay class]]);
    XCTAssertTrue([superscript isKindOfClass:[MTMathListDisplay class]]);
    XCTAssertEqual(superscript.type, kMTLinePositionSuperscript);
}

#pragma mark - Stack tests

- (void)testOverrightarrowNarrow
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\overrightarrow{x}"];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.type, kMTLinePositionRegular);
    XCTAssertTrue(CGPointEqualToPoint(display.position, CGPointZero));
    XCTAssertTrue(NSEqualRanges(display.range, NSMakeRange(0, 1)));
    XCTAssertFalse(display.hasScript);
    XCTAssertEqual(display.subDisplays.count, 1u);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTStackDisplay class]]);
    MTStackDisplay* stack = (MTStackDisplay*)sub0;
    XCTAssertTrue(NSEqualRanges(stack.range, NSMakeRange(0, 1)));
    XCTAssertFalse(stack.hasScript);
    XCTAssertTrue(CGPointEqualToPoint(stack.position, CGPointZero));

    XCTAssertNotNil(stack.base);
    XCTAssertNotNil(stack.over);
    XCTAssertNil(stack.under);

    // For narrow 'x' the assembled-path fast-path fires: widest rightarrow variant covers x.
    XCTAssertTrue([stack.over isKindOfClass:[MTGlyphDisplay class]]);

    // Base is at y=0 (baseline aligned to stack origin).
    XCTAssertEqualWithAccuracy(stack.base.position.y, 0, 0.01);

    // Dimension assertions using dynamic font metrics.
    CGFloat gapAbove = self.font.mathTable.stretchStackGapAboveMin;
    CGFloat expectedAscent = stack.base.ascent + gapAbove + stack.over.ascent + stack.over.descent;
    XCTAssertEqualWithAccuracy(display.ascent, expectedAscent, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, stack.base.descent, 0.01);

    // Width accommodates both base and over-row.
    XCTAssertGreaterThanOrEqual(display.width + 0.01, stack.base.width);
    XCTAssertGreaterThanOrEqual(display.width + 0.01, stack.over.width);
}

- (void)testOverrightarrowWide
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\overrightarrow{ABCD}"];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.subDisplays.count, 1u);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTStackDisplay class]]);
    MTStackDisplay* stack = (MTStackDisplay*)sub0;

    XCTAssertNotNil(stack.over);
    XCTAssertNil(stack.under);

    // Wide base forces assembly: over-row must be a horizontal glyph assembly.
    XCTAssertTrue([stack.over isKindOfClass:[MTHorizontalGlyphAssemblyDisplay class]]);

    // Over must span the full base width.
    XCTAssertGreaterThanOrEqual(stack.over.width + 0.01, stack.base.width);

    CGFloat gapAbove = self.font.mathTable.stretchStackGapAboveMin;
    CGFloat expectedAscent = stack.base.ascent + gapAbove + stack.over.ascent + stack.over.descent;
    XCTAssertEqualWithAccuracy(display.ascent, expectedAscent, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, stack.base.descent, 0.01);
    XCTAssertGreaterThanOrEqual(display.width + 0.01, stack.base.width);
}

- (void)testOverleftrightarrow
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\overleftrightarrow{xyz}"];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.subDisplays.count, 1u);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTStackDisplay class]]);
    MTStackDisplay* stack = (MTStackDisplay*)sub0;

    XCTAssertNotNil(stack.over);
    XCTAssertNil(stack.under);

    // \overleftrightarrow uses U+2194 (single cap, stretchy). For 'xyz' (wider than the largest preset variant), uses horizontal glyph assembly.
    XCTAssertTrue([stack.over isKindOfClass:[MTHorizontalGlyphAssemblyDisplay class]]);

    // Over must cover the base.
    XCTAssertGreaterThanOrEqual(stack.over.width + 0.01, stack.base.width);
}

- (void)testOverbrace
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\overbrace{ABC}"];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.subDisplays.count, 1u);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTStackDisplay class]]);
    MTStackDisplay* stack = (MTStackDisplay*)sub0;

    XCTAssertNotNil(stack.over);
    XCTAssertNil(stack.under);

    // For a narrow base, the smallest preset h_variant of the brace cap covers the width -> plain MTGlyphDisplay.
    XCTAssertTrue([stack.over isKindOfClass:[MTGlyphDisplay class]]);

    // Selected variant must be wide enough to cover the base.
    XCTAssertGreaterThanOrEqual(stack.over.width + 0.01, stack.base.width);

    CGFloat gapAbove = self.font.mathTable.stretchStackGapAboveMin;
    CGFloat expectedAscent = stack.base.ascent + gapAbove + stack.over.ascent + stack.over.descent;
    XCTAssertEqualWithAccuracy(display.ascent, expectedAscent, 0.01);
    XCTAssertEqualWithAccuracy(display.descent, stack.base.descent, 0.01);
}

- (void)testUnderbrace
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\underbrace{ABC}"];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.subDisplays.count, 1u);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTStackDisplay class]]);
    MTStackDisplay* stack = (MTStackDisplay*)sub0;

    XCTAssertNil(stack.over);
    XCTAssertNotNil(stack.under);

    // Brace uses single-stretchy variant path -> plain MTGlyphDisplay.
    XCTAssertTrue([stack.under isKindOfClass:[MTGlyphDisplay class]]);

    // Selected variant must be wide enough to cover the base.
    XCTAssertGreaterThanOrEqual(stack.under.width + 0.01, stack.base.width);

    CGFloat gapBelow = self.font.mathTable.stretchStackGapBelowMin;
    CGFloat expectedDescent = stack.base.descent + gapBelow + stack.under.ascent + stack.under.descent;
    XCTAssertEqualWithAccuracy(display.descent, expectedDescent, 0.01);
    XCTAssertEqualWithAccuracy(display.ascent, stack.base.ascent, 0.01);
}

- (void)testUnderrightarrow
{
    MTMathListDisplay* display = [self displayForLaTeX:@"\\underrightarrow{x}"];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.subDisplays.count, 1u);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTStackDisplay class]]);
    MTStackDisplay* stack = (MTStackDisplay*)sub0;

    XCTAssertNil(stack.over);
    XCTAssertNotNil(stack.under);

    XCTAssertEqualWithAccuracy(display.ascent, stack.base.ascent, 0.01);

    CGFloat gapBelow = self.font.mathTable.stretchStackGapBelowMin;
    CGFloat expectedDescent = stack.base.descent + gapBelow + stack.under.ascent + stack.under.descent;
    XCTAssertEqualWithAccuracy(display.descent, expectedDescent, 0.01);
}

- (void)testStackScripts
{
    // \overrightarrow{x}^2: the superscript should attach to the whole stack, not just the base.
    MTMathListDisplay* display = [self displayForLaTeX:@"\\overrightarrow{x}^2"];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.subDisplays.count, 2u);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTStackDisplay class]]);

    MTDisplay* sub1 = display.subDisplays[1];
    XCTAssertTrue([sub1 isKindOfClass:[MTMathListDisplay class]]);
    MTMathListDisplay* superscript = (MTMathListDisplay*)sub1;
    XCTAssertEqual(superscript.type, kMTLinePositionSuperscript);

    // Superscript must sit above the baseline and to the right of the stack.
    XCTAssertGreaterThan(superscript.position.y, 0.0);
    XCTAssertGreaterThan(superscript.position.x, 0.0);

    // Superscript must be positioned at or above the stack's full ascent
    // (it should not overlap with the over-row).
    MTStackDisplay* stack = (MTStackDisplay*)sub0;
    XCTAssertGreaterThanOrEqual(superscript.position.y + superscript.descent + 0.01,
                                stack.base.ascent);
}

- (void)testStackNestedStacks
{
    // \overrightarrow{\overleftarrow{x}}: outer base is itself an MTStackDisplay.
    MTMathListDisplay* display = [self displayForLaTeX:@"\\overrightarrow{\\overleftarrow{x}}"];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.subDisplays.count, 1u);

    MTDisplay* sub0 = display.subDisplays[0];
    XCTAssertTrue([sub0 isKindOfClass:[MTStackDisplay class]]);
    MTStackDisplay* outerStack = (MTStackDisplay*)sub0;

    XCTAssertNotNil(outerStack.base);
    XCTAssertEqual(outerStack.base.subDisplays.count, 1u);
    MTDisplay* innerSub0 = outerStack.base.subDisplays[0];
    XCTAssertTrue([innerSub0 isKindOfClass:[MTStackDisplay class]]);

    // Outer ascent must be greater than the base's ascent (it adds the outer over-row).
    XCTAssertGreaterThan(display.ascent, outerStack.base.ascent);
}

- (void)testWideStackBaseFallsBackToHorizontalAssembly
{
    // Both braces and arrows take the same path: try preset h_variants of the cap first,
    // and fall back to OpenType HorizontalGlyphAssembly when no preset variant is wide enough.
    // For a sufficiently wide base, both must produce MTHorizontalGlyphAssemblyDisplay.
    MTMathListDisplay* braceDisplay = [self displayForLaTeX:@"\\overbrace{ABCDEF}"];
    XCTAssertEqual(braceDisplay.subDisplays.count, 1u);
    MTStackDisplay* braceStack = (MTStackDisplay*)braceDisplay.subDisplays[0];
    XCTAssertTrue([braceStack isKindOfClass:[MTStackDisplay class]]);
    XCTAssertTrue([braceStack.over isKindOfClass:[MTHorizontalGlyphAssemblyDisplay class]]);
    XCTAssertGreaterThanOrEqual(braceStack.over.width + 0.01, braceStack.base.width);

    MTMathListDisplay* arrowDisplay = [self displayForLaTeX:@"\\overrightarrow{ABCDEF}"];
    XCTAssertEqual(arrowDisplay.subDisplays.count, 1u);
    MTStackDisplay* arrowStack = (MTStackDisplay*)arrowDisplay.subDisplays[0];
    XCTAssertTrue([arrowStack isKindOfClass:[MTStackDisplay class]]);
    XCTAssertTrue([arrowStack.over isKindOfClass:[MTHorizontalGlyphAssemblyDisplay class]]);
    XCTAssertGreaterThanOrEqual(arrowStack.over.width + 0.01, arrowStack.base.width);
}

#pragma mark - MTFontManager +textCTFontForStyle:size:

- (void) testTextCTFontRomanReturnsFont {
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleRoman size:20];
    XCTAssertTrue(font != NULL);
    CTFontSymbolicTraits traits = CTFontGetSymbolicTraits(font);
    XCTAssertFalse((traits & kCTFontTraitBold)   != 0);
    XCTAssertFalse((traits & kCTFontTraitItalic) != 0);
    if (font) CFRelease(font);
}

- (void) testTextCTFontBoldHasBoldTrait {
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleBold size:20];
    XCTAssertTrue(font != NULL);
    XCTAssertTrue((CTFontGetSymbolicTraits(font) & kCTFontTraitBold) != 0);
    if (font) CFRelease(font);
}

- (void) testTextCTFontItalicHasItalicTrait {
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleItalic size:20];
    XCTAssertTrue(font != NULL);
    XCTAssertTrue((CTFontGetSymbolicTraits(font) & kCTFontTraitItalic) != 0);
    if (font) CFRelease(font);
}

- (void) testTextCTFontTypewriterIsMonospace {
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleTypewriter size:20];
    XCTAssertTrue(font != NULL);
    XCTAssertTrue((CTFontGetSymbolicTraits(font) & kCTFontTraitMonoSpace) != 0);
    if (font) CFRelease(font);
}

- (void) testTextCTFontSansFallback {
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleSansSerif size:20];
    XCTAssertTrue(font != NULL);
    CTFontSymbolicTraits traits = CTFontGetSymbolicTraits(font);
    XCTAssertFalse((traits & kCTFontTraitBold)   != 0);
    XCTAssertFalse((traits & kCTFontTraitItalic) != 0);
    if (font) CFRelease(font);
}

- (void) testTextCTFontSizeMatches {
    CGFloat target = 17.5;
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleRoman size:target];
    XCTAssertEqualWithAccuracy(CTFontGetSize(font), target, 0.001);
    if (font) CFRelease(font);
}

#pragma mark - MTTextDisplay construction

- (void) testTextDisplayConstructionLatin {
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleRoman size:20];
    MTTextDisplay *d = [[MTTextDisplay alloc] initWithText:@"abc"
                                                 textStyle:kMTTextStyleRoman
                                                    ctFont:font
                                                     range:NSMakeRange(0, 3)];
    XCTAssertNotNil(d);
    XCTAssertEqualObjects(d.text, @"abc");
    XCTAssertEqual(d.textStyle, kMTTextStyleRoman);
    XCTAssertGreaterThan(d.width, 0);
    XCTAssertEqual(d.range.location, (NSUInteger)0);
    XCTAssertEqual(d.range.length,   (NSUInteger)3);
    if (font) CFRelease(font);
}

- (void) testTextDisplayConstructionEmpty {
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleRoman size:20];
    MTTextDisplay *d = [[MTTextDisplay alloc] initWithText:@""
                                                 textStyle:kMTTextStyleRoman
                                                    ctFont:font
                                                     range:NSMakeRange(0, 0)];
    XCTAssertNotNil(d);
    XCTAssertLessThan(d.width, 0.5);
    if (font) CFRelease(font);
}

- (void) testTextDisplayConstructionChinese {
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleRoman size:20];
    MTTextDisplay *d = [[MTTextDisplay alloc] initWithText:@"你好"
                                                 textStyle:kMTTextStyleRoman
                                                    ctFont:font
                                                     range:NSMakeRange(0, 2)];
    XCTAssertNotNil(d);
    XCTAssertGreaterThan(d.width, 0);
    if (font) CFRelease(font);
}

- (void) testTextDisplayDrawDoesNotCrash {
    CTFontRef font = [MTFontManager textCTFontForStyle:kMTTextStyleBold size:20];
    MTTextDisplay *d = [[MTTextDisplay alloc] initWithText:@"abc"
                                                 textStyle:kMTTextStyleBold
                                                    ctFont:font
                                                     range:NSMakeRange(0, 3)];
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, 100, 50, 8, 0, cs,
                                             kCGImageAlphaPremultipliedLast);
    XCTAssertNoThrow([d draw:ctx]);
    CGContextRelease(ctx);
    CGColorSpaceRelease(cs);
    if (font) CFRelease(font);
}

#pragma mark - Phase 4: Typesetter handles MTTextAtom

- (MTMathList *) listWithTextAtom:(MTTextAtom *)atom {
    MTMathList *list = [[MTMathList alloc] init];
    [list addAtom:atom];
    return list;
}

// Helper: walk every glyph run in the CTLine and assert no glyph index 0
// (`.notdef` in TrueType/OpenType). Re-create the line from the public
// MTTextDisplay properties since the line itself is private.
- (void) assertCTLineHasNoNotdef:(MTTextDisplay *)display {
    CTFontRef font = [MTFontManager textCTFontForStyle:display.textStyle size:20];
    NSAttributedString *as = [[NSAttributedString alloc]
                               initWithString:display.text
                                   attributes:@{(NSString *)kCTFontAttributeName: (__bridge id)font}];
    CTLineRef line = CTLineCreateWithAttributedString(
                        (__bridge CFAttributedStringRef)as);
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    for (CFIndex i = 0; i < CFArrayGetCount(runs); i++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, i);
        CFIndex count = CTRunGetGlyphCount(run);
        CGGlyph glyphs[count];
        CTRunGetGlyphs(run, CFRangeMake(0, count), glyphs);
        for (CFIndex j = 0; j < count; j++) {
            XCTAssertNotEqual(glyphs[j], 0,
                              @"`.notdef` for char index %ld in '%@'",
                              (long)j, display.text);
        }
    }
    CFRelease(line);
    CFRelease(font);
}

- (void) testTypesetterTextDisplayPresent {
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"abc"
                                                  style:kMTTextStyleBold];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:[self listWithTextAtom:atom]
                         font:font
                        style:kMTLineStyleDisplay];
    XCTAssertNotNil(display);
    XCTAssertEqual(display.subDisplays.count, (NSUInteger)1);
    XCTAssertTrue([display.subDisplays.firstObject
                    isKindOfClass:[MTTextDisplay class]]);
    XCTAssertGreaterThan(display.subDisplays.firstObject.width, 0);
}

- (void) testTypesetterTextDisplayEmpty {
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@""
                                                  style:kMTTextStyleRoman];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    XCTAssertNoThrow(([MTTypesetter
        createLineForMathList:[self listWithTextAtom:atom]
                         font:font
                        style:kMTLineStyleDisplay]));
}

- (void) testTypesetterTextDisplayChinese {
    MTTextAtom *atom = [[MTTextAtom alloc] initWithText:@"你好"
                                                  style:kMTTextStyleRoman];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:[self listWithTextAtom:atom]
                         font:font
                        style:kMTLineStyleDisplay];
    MTTextDisplay *text = (MTTextDisplay *)display.subDisplays.firstObject;
    XCTAssertGreaterThan(text.width, 0);
    XCTAssertEqualObjects(text.text, @"你好");
    [self assertCTLineHasNoNotdef:text];
}

- (void) testTypesetterTextNotFusedAcrossAtoms {
    // Two adjacent text atoms must remain separate displays — Rule 14
    // would fuse Ord+Ord, and this test pins down that distinct enum
    // prevents fusion.
    MTTextAtom *a = [[MTTextAtom alloc] initWithText:@"a" style:kMTTextStyleRoman];
    MTTextAtom *b = [[MTTextAtom alloc] initWithText:@"b" style:kMTTextStyleBold];
    MTMathList *list = [[MTMathList alloc] init];
    [list addAtom:a];
    [list addAtom:b];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:list font:font style:kMTLineStyleDisplay];
    XCTAssertEqual(display.subDisplays.count, (NSUInteger)2);
    XCTAssertTrue([display.subDisplays[0] isKindOfClass:[MTTextDisplay class]]);
    XCTAssertTrue([display.subDisplays[1] isKindOfClass:[MTTextDisplay class]]);
}

- (void) testTypesetterTextWithSuperscript {
    MTTextAtom *t = [[MTTextAtom alloc] initWithText:@"abc" style:kMTTextStyleBold];
    MTMathList *sup = [[MTMathList alloc] init];
    [sup addAtom:[MTMathAtomFactory atomForCharacter:'2']];
    t.superScript = sup;

    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:[self listWithTextAtom:t]
                         font:font
                        style:kMTLineStyleDisplay];

    BOOL hasText   = NO;
    BOOL hasScript = NO;
    for (MTDisplay *d in display.subDisplays) {
        if ([d isKindOfClass:[MTTextDisplay class]]) hasText = YES;
        // Scripts emerge as MTMathListDisplay sub-displays (per existing
        // makeScripts: convention).
        if ([d isKindOfClass:[MTMathListDisplay class]]) hasScript = YES;
    }
    XCTAssertTrue(hasText);
    XCTAssertTrue(hasScript);
}

#pragma mark - End-to-end \text* rendering (Phase 5)

- (void) testTextDisplayChineseFromString {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{你好}"];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:list font:font style:kMTLineStyleDisplay];
    XCTAssertEqual(display.subDisplays.count, (NSUInteger)1);
    MTTextDisplay *text = (MTTextDisplay *)display.subDisplays.firstObject;
    XCTAssertGreaterThan(text.width, 0);
    [self assertCTLineHasNoNotdef:text];
}

- (void) testTextDisplayCyrillicBoldFromString {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\textbf{Привет}"];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:list font:font style:kMTLineStyleDisplay];
    MTTextDisplay *text = (MTTextDisplay *)display.subDisplays.firstObject;
    XCTAssertEqual(text.textStyle, kMTTextStyleBold);
    XCTAssertGreaterThan(text.width, 0);
    [self assertCTLineHasNoNotdef:text];
}

- (void) testTextDisplayDevanagariFromString {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{नमस्ते}"];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:list font:font style:kMTLineStyleDisplay];
    MTTextDisplay *text = (MTTextDisplay *)display.subDisplays.firstObject;
    XCTAssertGreaterThan(text.width, 0);
    [self assertCTLineHasNoNotdef:text];
}

- (void) testTextDisplayHebrewFromString {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{שלום}"];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:list font:font style:kMTLineStyleDisplay];
    MTTextDisplay *text = (MTTextDisplay *)display.subDisplays.firstObject;
    XCTAssertGreaterThan(text.width, 0);
    [self assertCTLineHasNoNotdef:text];
}

- (void) testTextDisplayArabicFromString {
    MTMathList *list = [MTMathListBuilder buildFromString:@"\\text{مرحبا}"];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:list font:font style:kMTLineStyleDisplay];
    MTTextDisplay *text = (MTTextDisplay *)display.subDisplays.firstObject;
    XCTAssertGreaterThan(text.width, 0);
    // Per LLD §1 we don't assert RTL ordering — just that all glyphs resolved.
    [self assertCTLineHasNoNotdef:text];
}

- (void) testTextInMixedLine {
    MTMathList *list = [MTMathListBuilder buildFromString:@"x + \\text{ok}"];
    MTFont *font = [MTFontManager fontManager].defaultFont;
    MTMathListDisplay *display = [MTTypesetter
        createLineForMathList:list font:font style:kMTLineStyleDisplay];
    BOOL hasMath = NO;
    BOOL hasText = NO;
    MTCTLineDisplay *math = nil;
    MTTextDisplay *text = nil;
    for (MTDisplay *d in display.subDisplays) {
        if ([d isKindOfClass:[MTCTLineDisplay class]]) {
            hasMath = YES;
            if (!math) math = (MTCTLineDisplay *)d;
        }
        if ([d isKindOfClass:[MTTextDisplay class]]) {
            hasText = YES;
            if (!text) text = (MTTextDisplay *)d;
        }
    }
    XCTAssertTrue(hasMath);
    XCTAssertTrue(hasText);
    XCTAssertEqualWithAccuracy(text.position.y, math.position.y, 0.001);
}

@end
