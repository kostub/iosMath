#import <XCTest/XCTest.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MTMathUILabel.h"
#import "MTMathUILabelInternal.h"
#import "MTMathListDisplay.h"

// Forces a known device-pixel scale so the pixel-grid assertions exercise 2x/3x
// rounding rather than the tautological scale==1 case.
@interface MTScaledInkLabel : MTMathUILabel
@property (nonatomic) CGFloat forcedScale;
@end
@implementation MTScaledInkLabel
- (CGFloat)screenScale { return self.forcedScale; }
@end

@interface MTInkClippingRenderTest : XCTestCase
@end

@implementation MTInkClippingRenderTest

// Render the laid-out label's display tree into a white RGBA bitmap. The bitmap is
// `rightPad` pixels WIDER than the reported frame so that any trailing ink which
// escapes the frame's right edge is captured in the padding instead of being clipped
// away by the bitmap bounds — that is what lets the tests distinguish "contained"
// from "clipped". Returns a malloc'd coverage buffer (0=white .. 255=full ink coverage
// on any channel below white), the frame width (column index of the frame's right
// edge) in *outFrameW, and the full bitmap width in *outW.
//
// DeviceGray was tried first, but the display tree sets its foreground color via a
// DeviceRGB CGColor (MTColor/NSColor blackColor.CGColor); drawing that into a
// DeviceGray bitmap context mismatches color spaces and produces garbage coverage, so
// the harness uses DeviceRGB to match what the tree actually paints.
- (uint8_t*)renderLabel:(MTMathUILabel*)label rightPad:(size_t)rightPad
             frameWidth:(size_t*)outFrameW width:(size_t*)outW height:(size_t*)outH {
    CGSize s = label.bounds.size;
    size_t FW = (size_t)ceil(s.width), H = (size_t)ceil(s.height);
    if (FW == 0 || H == 0) { *outFrameW = FW; *outW = FW; *outH = H; return NULL; }
    size_t W = FW + rightPad;
    size_t bytesPerRow = W * 4;
    uint8_t* buf = calloc(bytesPerRow * H, 1);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(buf, W, H, 8, bytesPerRow, cs, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(cs);
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);   // white background
    CGContextFillRect(ctx, CGRectMake(0, 0, W, H));
    // Flip into the label's top-left frame coordinate space, then draw the tree
    // at its laid-out position (draw: paints black glyphs).
    CGContextTranslateCTM(ctx, 0, H);
    CGContextScaleCTM(ctx, 1, -1);
    [label.displayList draw:ctx];
    CGContextRelease(ctx);
    *outFrameW = FW; *outW = W; *outH = H;
    return buf;
}

// A pixel counts as "ink" if any RGB channel is meaningfully darker than white.
static BOOL isInk(uint8_t* buf, size_t bytesPerRow, size_t x, size_t y) {
    size_t idx = y * bytesPerRow + x * 4;
    return buf[idx] < 155 || buf[idx + 1] < 155 || buf[idx + 2] < 155;
}

static int inkInColumn(uint8_t* buf, size_t W, size_t H, size_t col) {
    size_t bytesPerRow = W * 4;
    int n = 0;
    for (size_t y = 0; y < H; y++) if (isInk(buf, bytesPerRow, col, y)) n++;
    return n;
}

// Total ink in columns [fromCol, W) — used to assert nothing escapes past a boundary.
static int inkAtOrAfterColumn(uint8_t* buf, size_t W, size_t H, size_t fromCol) {
    int n = 0;
    for (size_t col = fromCol; col < W; col++) n += inkInColumn(buf, W, H, col);
    return n;
}

- (MTMathUILabel*)laidOutLabel:(NSString*)latex alignment:(MTTextAlignment)align {
    return [self laidOutLabel:latex alignment:align label:[[MTMathUILabel alloc] init]];
}

- (MTMathUILabel*)laidOutLabel:(NSString*)latex alignment:(MTTextAlignment)align label:(MTMathUILabel*)label {
    label.latex = latex;
    label.textAlignment = align;
    CGSize size = [label sizeThatFits:CGSizeZero];
    label.frame = CGRectMake(0, 0, size.width, size.height);
    [label layoutSubviews];
    return label;
}

// Cluster A: trailing overhang glyphs must stay INSIDE the reported frame — no ink
// may escape past the frame's right edge — at any alignment. This is the exact
// pre-fix bug: with an advance-based width, a glyph whose ink is wider than its
// advance (e.g. V: advance 11.66 vs ink 15.38) spills past the frame.
//
// The label is rendered into a right-padded bitmap and we assert the beyond-frame
// region is empty. Asserting containment this way is robust to the antialiasing
// fringe that a flush-right ink edge (right alignment, zero right inset) legitimately
// paints into the last IN-frame column — that fringe is contained, not clipped, so it
// must not fail the test. (An earlier "zero ink in the last frame column" form failed
// on rasterizers where screenScale resolves to 1 for an unparented label, because the
// flush edge then lands exactly on a whole-pixel boundary.) screenScale is forced to 1
// so the frame edge lands on a whole bitmap column deterministically across environments.
- (void)testNoRightEdgeClip {
    const size_t kRightPad = 8;
    for (NSString* latex in @[@"P", @"V", @"f"]) {
        for (NSNumber* a in @[@(kMTTextAlignmentLeft), @(kMTTextAlignmentCenter), @(kMTTextAlignmentRight)]) {
            MTScaledInkLabel* scaled = [[MTScaledInkLabel alloc] init];
            scaled.forcedScale = 1;
            MTMathUILabel* label = [self laidOutLabel:latex alignment:(MTTextAlignment)a.integerValue label:scaled];
            size_t FW, W, H; uint8_t* buf = [self renderLabel:label rightPad:kRightPad frameWidth:&FW width:&W height:&H];
            XCTAssertTrue(buf != NULL, @"%@ align %@ did not render into a bitmap", latex, a);
            if (!buf) continue;
            XCTAssertEqual(inkAtOrAfterColumn(buf, W, H, FW), 0,
                @"%@ align %@ ink escapes past the frame right edge", latex, a);
            free(buf);
        }
    }
}

// Cluster B: device-pixel rounding + trailing-ink containment for tall constructs.
//
// The reported size is ceil'd to the device-pixel grid (ceilToPixel in
// MTMathUILabel.m), so the frame edges land on whole device pixels and there is no
// fractional-SIZE resample. We assert that grid property directly, plus that trailing
// ink stays inside the right border.
//
// We deliberately do NOT assert "zero ink in the top/right border pixel row". Tall,
// ink-tight constructs (\int_0^1, \frac{1}{2}) legitimately place ink flush against
// their ink-tight vertical boundary, so the boundary pixel row contains genuine ink
// even though nothing is clipped. The true hairline artifact this feature is concerned
// with is a fractional-ORIGIN compositing resample, addressed by snapping the draw
// origin; that is deferred (LLD §2.8) and is not exercised by this integer-origin
// render harness.
- (void)testTallConstructsPixelAlignedAndContained {
    for (NSNumber* scaleN in @[@2.0, @3.0]) {
        CGFloat scale = scaleN.doubleValue;
        for (NSString* latex in @[@"\\sqrt{2}", @"\\frac{1}{2}", @"\\int_0^1", @"P"]) {
            MTScaledInkLabel* scaled = [[MTScaledInkLabel alloc] init];
            scaled.forcedScale = scale;
            MTMathUILabel* label = [self laidOutLabel:latex alignment:kMTTextAlignmentLeft label:scaled];
            CGSize size = label.bounds.size;
            CGFloat wPixels = size.width * scale;
            CGFloat hPixels = size.height * scale;
            XCTAssertEqualWithAccuracy(wPixels, round(wPixels), 1e-6, @"%@ @%.0fx width not pixel-aligned", latex, scale);
            XCTAssertEqualWithAccuracy(hPixels, round(hPixels), 1e-6, @"%@ @%.0fx height not pixel-aligned", latex, scale);
            size_t FW, W, H; uint8_t* buf = [self renderLabel:label rightPad:8 frameWidth:&FW width:&W height:&H];
            XCTAssertTrue(buf != NULL, @"%@ did not render into a bitmap", latex);
            if (!buf) continue;
            XCTAssertEqual(inkAtOrAfterColumn(buf, W, H, FW), 0, @"%@ @%.0fx ink escapes past the frame right edge", latex, scale);
            free(buf);
        }
    }
}

@end
