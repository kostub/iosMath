//
//  MTFont.m
//  iosMath
//
//  Created by Kostub Deshmukh on 5/18/16.
//
//

#import "MTFont.h"

@interface MTFont ()

@property (nonatomic) CGFontRef defaultCGFont;
@property (nonatomic) CTFontRef ctFont;
@property (nonatomic) MTFontMathTable* mathTable;
@property (nonatomic) NSDictionary* rawMathTable;

@end

const int kDefaultFontSize = 20;

@implementation MTFont

- (instancetype) initFontWithName:(NSString*) name
{
    self = [super init];
    if (self ) {
        // CTFontCreateWithName does not load the complete math font, it only has about half the glyphs of the full math font.
        // In particular it does not have the math italic characters which breaks our variable rendering.
        // So we first load a CGFont from the file and then convert it to a CTFont.

        NSLog(@"Loading font %@", name);
        // Uses bundle for class so that this can be access by the unit tests.
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString* fontPath = [bundle pathForResource:name ofType:@"otf"];
        CGDataProviderRef fontDataProvider = CGDataProviderCreateWithFilename([fontPath UTF8String]);
        self.defaultCGFont = CGFontCreateWithDataProvider(fontDataProvider);
        CFRelease(fontDataProvider);
        NSLog(@"Num glyphs: %zd", CGFontGetNumberOfGlyphs(self.defaultCGFont));

        self.ctFont = CTFontCreateWithGraphicsFont(self.defaultCGFont, kDefaultFontSize, nil, nil);

        NSString* mathTablePlist = [bundle pathForResource:name ofType:@"plist"];
        NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:mathTablePlist];
        self.rawMathTable = dict;
        self.mathTable = [[MTFontMathTable alloc] initWithFont:self mathTable:_rawMathTable];
    }
    return self;
}

- (MTFont *)copyFontWithSize:(CGFloat)size
{
    MTFont* copyFont = [[[self class] alloc] init];
    copyFont.defaultCGFont = self.defaultCGFont;
    // Retain the font as we are adding another reference to it.
    CGFontRetain(copyFont.defaultCGFont);
    copyFont.ctFont = CTFontCreateWithGraphicsFont(self.defaultCGFont, size, nil, nil);
    copyFont.rawMathTable = self.rawMathTable;
    copyFont.mathTable = [[MTFontMathTable alloc] initWithFont:copyFont mathTable:copyFont.rawMathTable];
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
    CGFontRelease(self.defaultCGFont);
    CFRelease(self.ctFont);
}

#pragma mark - Variants

static NSString* const kVariants = @"variants";

- (CFArrayRef) copyVerticalVariantsForGlyphWithName:(NSString*) glyphName
{
    NSParameterAssert(glyphName);
    NSDictionary* variants = (NSDictionary*) [_rawMathTable objectForKey:kVariants];
    CFMutableArrayRef glyphArray = CFArrayCreateMutable(NULL, 0, NULL);
    NSArray* variantGlyphs = (NSArray*) [variants objectForKey:glyphName];
    if (!variantGlyphs) {
        // There are no extra variants, so just add the current glyph to it.
        CGGlyph glyph = [self getGlyphWithName:glyphName];
        CFArrayAppendValue(glyphArray, (void*)(uintptr_t)glyph);
        return glyphArray;
    }
    for (NSString* glyphVariantName in variantGlyphs) {
        CGGlyph variantGlyph = [self getGlyphWithName:glyphVariantName];
        CFArrayAppendValue(glyphArray, (void*)(uintptr_t)variantGlyph);
    }
    return glyphArray;
}

- (CGGlyph) getLargerGlyph:(CGGlyph) glyph
{
    NSDictionary* variants = (NSDictionary*) [_rawMathTable objectForKey:kVariants];
    NSString* glyphName = [self getGlyphName:glyph];
    NSArray* variantGlyphs = (NSArray*) [variants objectForKey:glyphName];
    if (!variantGlyphs) {
        // There are no extra variants, so just returnt the current glyph.
        return glyph;
    }
    // Find the first variant with a different name.
    for (NSString* glyphVariantName in variantGlyphs) {
        if (![glyphVariantName isEqualToString:glyphName]) {
            CGGlyph variantGlyph = [self getGlyphWithName:glyphVariantName];
            return variantGlyph;
        }
    }
    // We did not find any variants of this glyph so return it.
    return glyph;
}

@end
