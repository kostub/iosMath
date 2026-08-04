//
//  MTFont.m
//  iosMath
//
//  Created by Kostub Deshmukh on 5/18/16.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTFont.h"
#import "MTFont+Internal.h"

@interface MTFont ()

@property (nonatomic, assign) CGFontRef defaultCGFont;
@property (nonatomic, assign) CTFontRef ctFont;
@property (nonatomic, assign) CTFontRef mathitCTFont;
@property (nonatomic, strong) MTFontMathTable* mathTable;
@property (nonatomic, strong) NSDictionary* rawMathTable;

+ (NSBundle*) fontBundle;

@end

CTFontRef MTCreateVerifiedFontWithPostScriptName(NSString* psName, CGFloat size)
{
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef) psName, size, NULL);
    if (!font) { return NULL; }
    NSString* actual = CFBridgingRelease(CTFontCopyPostScriptName(font));
    if ([actual isEqualToString:psName]) {
        return font;
    }
    // CoreText substituted a different face; drawing it silently is a visible
    // corruption, so reject and let the caller fall back (LLD §2.9).
    CFRelease(font);
    return NULL;
}

static CTFontRef MTCreateBundledItalicFont(CGFloat size)
{
    NSString* fontPath = [[MTFont fontBundle] pathForResource:@"lmroman10-italic" ofType:@"otf" inDirectory:@"fonts"];
    if (!fontPath) { return NULL; }
    CGDataProviderRef provider = CGDataProviderCreateWithFilename(fontPath.UTF8String);
    if (!provider) { return NULL; }
    CGFontRef cgFont = CGFontCreateWithDataProvider(provider);
    CFRelease(provider);
    if (!cgFont) { return NULL; }
    CTFontRef ctFont = CTFontCreateWithGraphicsFont(cgFont, size, nil, nil);
    CFRelease(cgFont);
    return ctFont;
}

static CTFontRef MTCreateCompanionForMathFont(NSString* name, CGFloat size)
{
    static NSDictionary<NSString*, NSString*>* companionNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        companionNames = @{
            @"texgyretermes-math": @"TimesNewRomanPS-ItalicMT",
            @"xits-math": @"TimesNewRomanPS-ItalicMT",
            @"texgyrepagella-math": @"Palatino-Italic",
            @"stixtwo-math": @"STIXTwoText-Italic",
            @"firamath": @"HelveticaNeue-Italic",
            @"notosansmath": @"HelveticaNeue-Italic",
        };
    });
    NSString* psName = companionNames[name];
    if (psName) {
        CTFontRef font = MTCreateVerifiedFontWithPostScriptName(psName, size);
        if (font) { return font; }
    }
    // latinmodern-math, newcm-math, and any failed by-name lookup all take
    // the bundled Latin Modern Roman Italic.
    return MTCreateBundledItalicFont(size);
}

@implementation MTFont

- (instancetype)initFontWithName:(NSString *)name size:(CGFloat)size
{
    self = [super init];
    if (self != nil) {
        // CTFontCreateWithName does not load the complete math font, it only has about half the glyphs of the full math font.
        // In particular it does not have the math italic characters which breaks our variable rendering.
        // So we first load a CGFont from the file and then convert it to a CTFont.

        NSBundle* bundle = [MTFont fontBundle];
        NSString* fontPath = [bundle pathForResource:name ofType:@"otf" inDirectory:@"fonts"];
        if (!fontPath) { return nil; }
        CGDataProviderRef fontDataProvider = CGDataProviderCreateWithFilename(fontPath.UTF8String);
        if (!fontDataProvider) { return nil; }
        _defaultCGFont = CGFontCreateWithDataProvider(fontDataProvider);
        CFRelease(fontDataProvider);
        if (!_defaultCGFont) { return nil; }

        _ctFont = CTFontCreateWithGraphicsFont(self.defaultCGFont, size, nil, nil);

        NSString* mathTablePlist = [bundle pathForResource:name ofType:@"plist" inDirectory:@"fonts"];
        NSDictionary* dict = mathTablePlist ? [NSDictionary dictionaryWithContentsOfFile:mathTablePlist] : nil;
        if (!dict) { return nil; }
        self.rawMathTable = dict;
        self.mathTable = [[MTFontMathTable alloc] initWithFont:self mathTable:_rawMathTable];

        _mathitCTFont = MTCreateCompanionForMathFont(name, size);
        NSAssert(_mathitCTFont != NULL, @"Cannot resolve \\mathit companion for %@ — lmroman10-italic.otf missing from bundle?", name);
        if (!_mathitCTFont) {
            // Packaging bug: degrade \mathit to the math font (today's rendering)
            // rather than crash in Release.
            _mathitCTFont = (CTFontRef) CFRetain(_ctFont);
        }
    }
    return self;
}

- (void)setDefaultCGFont:(CGFontRef)defaultCGFont
{
    if (_defaultCGFont != nil) {
        CFRelease(_defaultCGFont);
    }
    if (defaultCGFont != nil) {
        CFRetain(defaultCGFont);
    }
    _defaultCGFont = defaultCGFont;
}

- (void)setCtFont:(CTFontRef)ctFont {
    if (_ctFont != nil) {
        CFRelease(_ctFont);
    }
    if (ctFont != nil) {
        CFRetain(ctFont);
    }
    _ctFont = ctFont;
}

- (void)setMathitCTFont:(CTFontRef)mathitCTFont {
    if (_mathitCTFont != nil) {
        CFRelease(_mathitCTFont);
    }
    if (mathitCTFont != nil) {
        CFRetain(mathitCTFont);
    }
    _mathitCTFont = mathitCTFont;
}

+ (NSBundle*) fontBundle
{
    // SwiftPM exposes processed resources via the generated module bundle.
#if SWIFT_PACKAGE
    return SWIFTPM_MODULE_BUNDLE;
#else
    // For Xcode builds: fonts are added directly to the app/test bundle.
    return [NSBundle bundleForClass:[self class]];
#endif
}

- (MTFont *)copyFontWithSize:(CGFloat)size
{
    MTFont* copyFont = [[[self class] alloc] init];
    copyFont.defaultCGFont = self.defaultCGFont;
    CTFontRef newCtFont = CTFontCreateWithGraphicsFont(self.defaultCGFont, size, nil, nil);
    copyFont.ctFont = newCtFont;
    copyFont.rawMathTable = self.rawMathTable;
    copyFont.mathTable = [[MTFontMathTable alloc] initWithFont:copyFont mathTable:copyFont.rawMathTable];
    CFRelease(newCtFont);
    // Not `size`: CTFontCreateWithGraphicsFont maps 0 to 12pt while
    // CTFontCreateCopyWithAttributes reads it as "keep the current size", so
    // passing it through would leave the companion a different size than the
    // font it accompanies.
    CTFontRef newMathitFont = CTFontCreateCopyWithAttributes(self.mathitCTFont, CTFontGetSize(copyFont.ctFont), NULL, NULL);
    copyFont.mathitCTFont = newMathitFont;
    CFRelease(newMathitFont);
    return copyFont;
}

-(NSString*) getGlyphName:(CGGlyph) glyph
{
    NSString* name = CFBridgingRelease(CGFontCopyGlyphNameForGlyph(self.defaultCGFont, glyph));
    return name;
}

- (CGGlyph)getGlyphWithName:(NSString *)glyphName
{
    return CGFontGetGlyphWithGlyphName(self.defaultCGFont, (__bridge CFStringRef) glyphName);
}

- (CGFloat)fontSize
{
    return CTFontGetSize(self.ctFont);
}

- (void)dealloc
{
    self.defaultCGFont=nil;
    self.ctFont=nil;
    self.mathitCTFont=nil;
}
@end
