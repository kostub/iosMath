#!/usr/bin/python
import plistlib
import sys
from fontTools.ttLib import TTFont

def usage(code):
    print 'Usage math_table_to_plist.py <fontfile> <plistfile>'
    sys.exit(code)

def process_font(font_file, out_file):
    font = TTFont(font_file)
    math_table = font['MATH'].table
    constants = get_constants(math_table)
    italic_c = get_italic_correction(math_table)
    variants = get_variants(math_table)
    pl = { "constants": constants,
            "variants" : variants,
            "italic" : italic_c }
    plistlib.writePlist(pl, out_file)

def get_constants(math_table):
    constants = math_table.MathConstants
    if constants is None:
        raise 'Cannot find MathConstants in MATH table'

    int_consts = [ 'ScriptPercentScaleDown',
            'ScriptScriptPercentScaleDown',
            'DelimitedSubFormulaMinHeight',
            'DisplayOperatorMinHeight',
            'RadicalDegreeBottomRaisePercent']
    consts = { c : getattr(constants, c) for c in int_consts }

    record_consts = [ 'MathLeading',
            'AxisHeight',
            'AccentBaseHeight',
            'FlattenedAccentBaseHeight',
            'SubscriptShiftDown',
            'SubscriptTopMax',
            'SubscriptBaselineDropMin',
            'SuperscriptShiftUp',
            'SuperscriptShiftUpCramped',
            'SuperscriptBottomMin',
            'SuperscriptBaselineDropMax',
            'SubSuperscriptGapMin',
            'SuperscriptBottomMaxWithSubscript',
            'SpaceAfterScript',
            'UpperLimitGapMin',
            'UpperLimitBaselineRiseMin',
            'LowerLimitGapMin',
            'LowerLimitBaselineDropMin',
            'StackTopShiftUp',
            'StackTopDisplayStyleShiftUp',
            'StackBottomShiftDown',
            'StackBottomDisplayStyleShiftDown',
            'StackGapMin',
            'StackDisplayStyleGapMin',
            'StretchStackTopShiftUp',
            'StretchStackBottomShiftDown',
            'StretchStackGapAboveMin',
            'StretchStackGapBelowMin',
            'FractionNumeratorShiftUp',
            'FractionNumeratorDisplayStyleShiftUp',
            'FractionDenominatorShiftDown',
            'FractionDenominatorDisplayStyleShiftDown',
            'FractionNumeratorGapMin',
            'FractionNumDisplayStyleGapMin',
            'FractionRuleThickness',
            'FractionDenominatorGapMin',
            'FractionDenomDisplayStyleGapMin',
            'SkewedFractionHorizontalGap',
            'SkewedFractionVerticalGap',
            'OverbarVerticalGap',
            'OverbarRuleThickness',
            'OverbarExtraAscender',
            'UnderbarVerticalGap',
            'UnderbarRuleThickness',
            'UnderbarExtraDescender',
            'RadicalVerticalGap',
            'RadicalDisplayStyleVerticalGap',
            'RadicalRuleThickness',
            'RadicalExtraAscender',
            'RadicalKernBeforeDegree',
            'RadicalKernAfterDegree',
    ]
    consts_2 = { c : getattr(constants, c).Value for c in record_consts }
    consts.update(consts_2)
    return consts

def get_italic_correction(math_table):
    glyph_info = math_table.MathGlyphInfo
    if glyph_info is None:
        raise "Cannot find MathGlyphInfo in MATH table."
    italic = glyph_info.MathItalicsCorrectionInfo
    if italic is None:
        raise "Cannot find Italic Correction in GlyphInfo"

    glyphs = italic.Coverage.glyphs
    count = italic.ItalicsCorrectionCount
    records = italic.ItalicsCorrection
    italic_dict = {}
    for i in xrange(count):
        name = glyphs[i]
        record = records[i]
        if record.DeviceTable is not None:
            raise "Don't know how to process device table for italic correction."
        italic_dict[name] = record.Value
    return italic_dict

def get_variants(math_table):
    variants = math_table.MathVariants
    vglyphs = variants.VertGlyphCoverage.glyphs
    vconstruction = variants.VertGlyphConstruction
    count = variants.VertGlyphCount
    variant_dict = {}
    for i in xrange(count):
        name = vglyphs[i]
        record = vconstruction[i]
        glyph_variants = [x.VariantGlyph for x in
                record.MathGlyphVariantRecord]
        variant_dict[name] = glyph_variants
    return variant_dict

def main():
    if len(sys.argv) != 3:
        usage(1)        
    font_file = sys.argv[1]
    plist_file = sys.argv[2]
    process_font(font_file, plist_file)

if __name__ == '__main__':
    main()
