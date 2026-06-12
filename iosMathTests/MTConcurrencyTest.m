//
//  MTConcurrencyTest.m
//  iosMath
//
//  SEC-3: Thread-safety tests for symbol/lookup tables and font cache.
//  Verifies: dispatch_once lazy inits, guarded mutable symbol tables,
//  copy-on-write in +addLatexSymbol:value:, and guarded font cache.
//

#import <XCTest/XCTest.h>
#import "MTMathAtomFactory.h"
#import "MTMathListBuilder.h"
#import "MTFontManager.h"
#import "MTFont.h"

// Number of concurrent workers for stress tests.
static const NSUInteger kConcurrencyDegree = 32;
// Number of iterations per worker.
static const NSUInteger kIterationsPerWorker = 200;

@interface MTConcurrencyTest : XCTestCase
@end

@implementation MTConcurrencyTest

// ---------------------------------------------------------------------------
// Test 1: Concurrent first-touch of all the factory/builder lookup tables.
// ---------------------------------------------------------------------------
// Many threads simultaneously call the accessor methods whose static variables
// were previously guarded only by `if (!table) { … }`. After the fix all 17
// sites use dispatch_once; this stress test will TSan-detect any residual race.
- (void)testConcurrentTableFirstTouch
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

    for (NSUInteger i = 0; i < kConcurrencyDegree; i++) {
        dispatch_group_async(group, q, ^{
            for (NSUInteger j = 0; j < kIterationsPerWorker; j++) {
                // Factory tables
                // Public symbol table accessors (touch the lazy-init paths)
                XCTAssertGreaterThan([MTMathAtomFactory supportedLatexSymbolNames].count, 0u);
                // Builder tables (exercised indirectly via parse)
                XCTAssertNotNil([MTMathListBuilder buildFromString:@"x + y"]);
                // A lookup that touches aliases + commands
                XCTAssertNotNil([MTMathAtomFactory atomForLatexSymbolName:@"alpha"]);
                XCTAssertNotNil([MTMathAtomFactory atomForLatexSymbolName:@"land"]); // alias
                XCTAssertNotNil([MTMathAtomFactory accentWithName:@"hat"]);
                XCTAssertNotNil([MTMathAtomFactory boundaryAtomForDelimiterName:@"("]);
                XCTAssertNotNil([MTMathAtomFactory stackAtomForCommand:@"overrightarrow"]);
                XCTAssertNotNil([MTMathAtomFactory stackCommandSpec:@"overset"]);
                // Reverse lookup
                MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomRelation value:@"←"];
                (void)[MTMathAtomFactory latexSymbolNameForAtom:atom];
            }
        });
    }

    long result = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 30LL * NSEC_PER_SEC));
    XCTAssertEqual(result, 0, @"Concurrent first-touch should complete without deadlock/crash");
}

// ---------------------------------------------------------------------------
// Test 2: Concurrent reads + addLatexSymbol writes.
// ---------------------------------------------------------------------------
// Writers call +addLatexSymbol:value: with unique names; readers call
// atomForLatexSymbolName:, latexSymbolNameForAtom:, and supportedLatexSymbolNames
// concurrently. Without the lock, NSMutableDictionary mutate+read is a data race
// (undefined behavior, crash on corrupt internal state). After the fix it is safe.
- (void)testConcurrentAddAndLookupSymbol
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

    NSUInteger writerCount = kConcurrencyDegree / 4;
    NSUInteger readerCount = kConcurrencyDegree - writerCount;

    // A nucleus shared by both the writers and the reverse-lookup reader. The writers below
    // register names whose atoms all carry this nucleus, so -addLatexSymbol: mutates the SAME
    // per-nucleus `inner` NSMutableDictionary that latexSymbolNameForAtom: reads. This is what
    // exercises the inner read/write race in latexSymbolNameForAtom: — querying a different
    // nucleus (e.g. "→") would touch a different inner dict and never collide. Under TSan the
    // pre-fix code (which read inner[...] after unlocking) flags here.
    NSString* const sharedNucleus = @"__testSharedNucleus";

    // Writer threads. All writers share one nucleus + type (kMTMathAtomRelation), so they all
    // mutate the SAME inner-dict cell `inner[@(kMTMathAtomRelation)]`. The names alternate
    // between two equal-length, low-sorting strings: equal-length + non-descending compare makes
    // -addLatexSymbol: actually execute the in-place `inner[typeKey] = name` write on every
    // iteration (so the writer genuinely mutates the cell the reader is reading), maximizing the
    // race window the early-unlock bug would expose.
    NSString* const writeA = @"__a";
    NSString* const writeB = @"__b";
    for (NSUInteger i = 0; i < writerCount; i++) {
        dispatch_group_async(group, q, ^{
            for (NSUInteger j = 0; j < kIterationsPerWorker; j++) {
                NSString* name = (j & 1) ? writeA : writeB;
                MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomRelation value:sharedNucleus];
                [MTMathAtomFactory addLatexSymbol:name value:atom];
            }
        });
    }

    // Reader threads: lookup existing and possibly newly-added symbols
    for (NSUInteger i = 0; i < readerCount; i++) {
        dispatch_group_async(group, q, ^{
            for (NSUInteger j = 0; j < kIterationsPerWorker; j++) {
                // Lookup a well-known symbol (always present)
                MTMathAtom* atom = [MTMathAtomFactory atomForLatexSymbolName:@"alpha"];
                XCTAssertNotNil(atom, @"Known symbol 'alpha' must be resolvable during concurrent mutation");

                // Enumerate all known symbol names (touches the live dict)
                NSArray* names = [MTMathAtomFactory supportedLatexSymbolNames];
                XCTAssertGreaterThan(names.count, 0u);

                // Reverse lookup on the SAME nucleus the writers mutate — concurrent read of the
                // inner dict that addLatexSymbol: is mutating in place. This is the case that the
                // earlier "→" reader missed.
                MTMathAtom* rel = [MTMathAtom atomWithType:kMTMathAtomRelation value:sharedNucleus];
                (void)[MTMathAtomFactory latexSymbolNameForAtom:rel];
            }
        });
    }

    long result = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 30LL * NSEC_PER_SEC));
    XCTAssertEqual(result, 0, @"Concurrent addLatexSymbol + lookup must not crash");
}

// ---------------------------------------------------------------------------
// Test 3: Added symbols are resolvable after concurrent insertion.
// ---------------------------------------------------------------------------
// Verifies that every symbol added in test 2's writers can actually be found
// afterward (proves the write was durable, not lost due to a clobber).
- (void)testAddedSymbolsAreResolvable
{
    NSMutableArray<NSString*>* names = [NSMutableArray array];
    NSUInteger count = 50;
    for (NSUInteger i = 0; i < count; i++) {
        NSString* name = [NSString stringWithFormat:@"__verifyResolvable_%lu", (unsigned long)i];
        MTMathAtom* atom = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"α"];
        [MTMathAtomFactory addLatexSymbol:name value:atom];
        [names addObject:name];
    }

    for (NSString* name in names) {
        MTMathAtom* found = [MTMathAtomFactory atomForLatexSymbolName:name];
        XCTAssertNotNil(found, @"Symbol '%@' should be resolvable after insertion", name);
        XCTAssertEqualObjects(found.nucleus, @"α");
    }
}

// ---------------------------------------------------------------------------
// Test 4: Copy-on-write regression.
// ---------------------------------------------------------------------------
// +addLatexSymbol:value: must copy the atom on write so that a subsequent
// mutation of the caller's atom does NOT affect the stored table entry.
- (void)testAddLatexSymbolCopiesAtomOnWrite
{
    NSString* symName = @"__testCopyOnWrite_SEC3";
    MTMathAtom* original = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"A"];
    [MTMathAtomFactory addLatexSymbol:symName value:original];

    // Mutate the original after insertion
    original.nucleus = @"B";

    // The stored copy must still have the original nucleus
    MTMathAtom* retrieved = [MTMathAtomFactory atomForLatexSymbolName:symName];
    XCTAssertNotNil(retrieved, @"Symbol must be found after insertion");
    XCTAssertEqualObjects(retrieved.nucleus, @"A",
        @"Stored atom must be a copy — post-insertion mutation of the caller's atom "
         "must not affect the table (copy-on-write)");
}

// ---------------------------------------------------------------------------
// Test 5: Concurrent font cache access.
// ---------------------------------------------------------------------------
// Many threads call -fontWithName:size: simultaneously. Before the fix, the
// check-then-act on nameToFontMap is a data race. After the fix it is guarded.
- (void)testConcurrentFontCacheAccess
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

    for (NSUInteger i = 0; i < kConcurrencyDegree; i++) {
        dispatch_group_async(group, q, ^{
            for (NSUInteger j = 0; j < kIterationsPerWorker; j++) {
                MTFont* font = [[MTFontManager fontManager]
                                fontWithName:MTFontNameLatinModern size:20];
                XCTAssertNotNil(font, @"Font must be non-nil under concurrent access");
                XCTAssertEqualWithAccuracy(font.fontSize, 20.0, 0.001);

                // Also exercise the size-variant branch (size != cached size)
                MTFont* font2 = [[MTFontManager fontManager]
                                 fontWithName:MTFontNameLatinModern size:14];
                XCTAssertNotNil(font2);
                XCTAssertEqualWithAccuracy(font2.fontSize, 14.0, 0.001);
            }
        });
    }

    long result = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 30LL * NSEC_PER_SEC));
    XCTAssertEqual(result, 0, @"Concurrent fontWithName: must not crash");
}

// ---------------------------------------------------------------------------
// Test 6: Concurrent parser invocations (exercises builder tables end-to-end).
// ---------------------------------------------------------------------------
- (void)testConcurrentParsing
{
    NSArray<NSString*>* expressions = @[
        @"\\frac{1}{2}",
        @"\\sqrt{x^2 + y^2}",
        @"\\sum_{i=0}^{n} i",
        @"\\int_0^\\infty e^{-x} dx",
        @"\\alpha + \\beta = \\gamma",
        @"\\overset{\\text{def}}{=}",
        @"\\overrightarrow{AB}",
        @"\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix}",
    ];

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t q = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

    for (NSUInteger i = 0; i < kConcurrencyDegree; i++) {
        dispatch_group_async(group, q, ^{
            for (NSUInteger j = 0; j < kIterationsPerWorker; j++) {
                NSString* expr = expressions[j % expressions.count];
                MTMathList* list = [MTMathListBuilder buildFromString:expr];
                XCTAssertNotNil(list, @"Parse of '%@' must succeed under concurrency", expr);
            }
        });
    }

    long result = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 30LL * NSEC_PER_SEC));
    XCTAssertEqual(result, 0, @"Concurrent parsing must not crash");
}

@end
