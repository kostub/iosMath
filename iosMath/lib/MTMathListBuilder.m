//
//  MTMathListBuilder.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTMathListBuilder.h"
#import "MTMathAtomFactory.h"

NSString *const MTParseError = @"ParseError";

@interface MTEnvProperties : NSObject

@property (nonatomic, readonly) NSString* envName;
@property (nonatomic) BOOL ended;
@property (nonatomic) NSInteger numRows;

@end

@implementation MTEnvProperties

- (instancetype)initWithName:(NSString*) name
{
    self = [super init];
    if (self) {
        _envName = name;
        _numRows = 0;
        _ended = NO;
    }
    return self;
}

@end

// Maximum recursion depth for -buildInternal:oneCharOnly:stopChar:.
// 150 is comfortably deeper than any realistic human-authored expression yet
// far below the thousands of frames needed to overflow a 1 MB stack.
static const NSInteger kMTMaxRecursionDepth = 150;

@implementation MTMathListBuilder {
    unichar* _chars;
    int _currentChar;
    NSUInteger _length;
    MTInner* _currentInnerAtom;
    MTEnvProperties* _currentEnv;
    MTFontStyle _currentFontStyle;
    BOOL _spacesAllowed;
    NSInteger _recursionDepth;
    // Set to YES by stopCommand when a TeX group-transformation command (\over,
    // \atop, \choose, \brack, \brace) fires inside a {…} group. Checked in the
    // {…} branch to decide whether to wrap as MTMathGroup. Cleared at the top of
    // every buildInternal call so the check is always fresh.
    BOOL _groupWasTransformedByStopCommand;
}

- (instancetype)initWithString:(NSString *)str
{
    self = [super init];
    if (self) {
        _error = nil;
        _chars = malloc(sizeof(unichar)*str.length);
        _length = str.length;
        [str getCharacters:_chars range:NSMakeRange(0, str.length)];
        _currentChar = 0;
        _currentFontStyle = kMTFontStyleDefault;
        _recursionDepth = 0;
    }
    return self;
}

- (void)dealloc
{
    free(_chars);
}

- (BOOL) hasCharacters
{
    return _currentChar < _length;
}

// gets the next character and moves the pointer ahead
- (unichar) getNextCharacter
{
    NSAssert([self hasCharacters], @"Retrieving character at index %d beyond length %lu", _currentChar, (unsigned long)_length);
    return _chars[_currentChar++];
}

- (void) unlookCharacter
{
    NSAssert(_currentChar > 0, @"Unlooking when at the first character.");
    _currentChar--;
}

// Reads an optional [l|c|r] argument for \cfrac. If the next character is '[',
// consumes one letter (l|c|r), then ']', writes the corresponding
// MTFractionAlignment to *outAlignment, returns YES. If the bracket body is
// anything else, calls -setError: and still returns YES (consumption happened);
// the caller should bail on _error. If the next character is not '[', restores
// the position and returns NO.
- (BOOL) readOptionalAlignment:(MTFractionAlignment*)outAlignment
{
    if (![self hasCharacters]) {
        return NO;
    }
    unichar ch = [self getNextCharacter];
    if (ch != '[') {
        [self unlookCharacter];
        return NO;
    }
    // Read one alignment letter
    if (![self hasCharacters]) {
        [self setError:MTParseErrorInvalidCommand
               message:@"Unterminated optional alignment for \\cfrac"];
        return YES;
    }
    unichar letter = [self getNextCharacter];
    MTFractionAlignment alignment;
    switch (letter) {
        case 'l': alignment = kMTFractionAlignmentLeft;   break;
        case 'c': alignment = kMTFractionAlignmentCenter; break;
        case 'r': alignment = kMTFractionAlignmentRight;  break;
        default: {
            NSString* errorMessage = [NSString stringWithFormat:
                @"Invalid alignment for \\cfrac: '%C' (expected l, c, or r)", letter];
            [self setError:MTParseErrorInvalidCommand message:errorMessage];
            return YES;
        }
    }
    // Require closing ']'
    if (![self hasCharacters]) {
        [self setError:MTParseErrorInvalidCommand
               message:@"Unterminated optional alignment for \\cfrac"];
        return YES;
    }
    unichar close = [self getNextCharacter];
    if (close != ']') {
        NSString* errorMessage = [NSString stringWithFormat:
            @"Expected ']' to close \\cfrac alignment, got '%C'", close];
        [self setError:MTParseErrorInvalidCommand message:errorMessage];
        return YES;
    }
    if (outAlignment) {
        *outAlignment = alignment;
    }
    return YES;
}

- (MTMathList *)build
{
    MTMathList* list = [self buildInternal:false];
    if ([self hasCharacters] && !_error) {
        // something went wrong most likely braces mismatched
        NSString* errorMessage = [NSString stringWithFormat:@"Mismatched braces: %@", [NSString stringWithCharacters:_chars length:_length]];
        [self setError:MTParseErrorMismatchBraces message:errorMessage];
    }
    if (_error) {
        return nil;
    }
    return list;
}

- (MTMathList*) buildInternal:(BOOL) oneCharOnly
{
    return [self buildInternal:oneCharOnly stopChar:0];
}

- (MTMathList*)buildInternal:(BOOL) oneCharOnly stopChar:(unichar) stop
{
    if (_recursionDepth >= kMTMaxRecursionDepth) {
        [self setError:MTParseErrorNestingTooDeep message:@"LaTeX nesting too deep"];
        return nil;
    }
    _recursionDepth++;
    _groupWasTransformedByStopCommand = NO;
    @try {
    MTMathList* list = [MTMathList new];
    NSAssert(!(oneCharOnly && (stop > 0)), @"Cannot set both oneCharOnly and stopChar.");
    MTMathAtom* prevAtom = nil;
    while([self hasCharacters]) {
        if (_error) {
            // If there is an error thus far then bail out.
            return nil;
        }
        MTMathAtom* atom = nil;
        unichar ch = [self getNextCharacter];
        if (oneCharOnly) {
            if (ch == '^' || ch == '}' || ch == '_' || ch == '&') {
                // this is not the character we are looking for.
                // They are meant for the caller to look at.
                [self unlookCharacter];
                return list;
            }
        }
        // If there is a stop character, keep scanning till we find it
        if (stop > 0 && ch == stop) {
            return list;
        }
        
        if (ch == '^') {
            NSAssert(!oneCharOnly, @"This should have been handled before");
            
            if (!prevAtom || prevAtom.superScript || !prevAtom.scriptsAllowed) {
                // If there is no previous atom, or if it already has a superscript
                // or if scripts are not allowed for it, then add an empty node.
                prevAtom = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@""];
                [list addAtom:prevAtom];
            }
            // this is a superscript for the previous atom
            // note: if the next char is the stopChar it will be consumed by the ^ and so it doesn't count as stop
            prevAtom.superScript = [self buildInternal:true];
            continue;
        } else if (ch == '_') {
            NSAssert(!oneCharOnly, @"This should have been handled before");
            
            if (!prevAtom || prevAtom.subScript || !prevAtom.scriptsAllowed) {
                // If there is no previous atom, or if it already has a subcript
                // or if scripts are not allowed for it, then add an empty node.
                prevAtom = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@""];
                [list addAtom:prevAtom];
            }
            // this is a subscript for the previous atom
            // note: if the next char is the stopChar it will be consumed by the _ and so it doesn't count as stop
            prevAtom.subScript = [self buildInternal:true];
            continue;
        } else if (ch == '{') {
            // this puts us in a recursive routine, and sets oneCharOnly to false and no stop character
            MTMathList* sublist = [self buildInternal:false stopChar:'}'];
            if (!sublist) {
                // inner error already set (e.g. missing closing brace); propagate.
                return nil;
            }
            BOOL transformed = _groupWasTransformedByStopCommand;
            if (oneCharOnly || transformed) {
                // Field brace (^{…}, _{…}, \frac{…}, command argument): the {…}
                // *is* the field. Flatten and return it as the field — unchanged.
                // Also: a group-transforming command (\over, \atop, \choose,
                // \brack, \brace) fired inside this group. The resulting fraction
                // replaces the group in the parent list (TeX behavior) — do NOT
                // wrap in MTMathGroup. Fall through to continue after appending.
                [list append:sublist];
                if (oneCharOnly) {
                    return list;
                }
                continue;
            }
            // Grouping brace in the main list: wrap as an Ord subformula so style
            // nodes are scoped, scripts target the whole group, and Bin/Ord
            // reclassification stops at the brace boundary
            // (== TeX Ord-noad-with-sub_mlist / KaTeX ordgroup).
            MTMathGroup* group = [[MTMathGroup alloc] init];
            group.innerList = sublist;
            atom = group;
            // fall through to the shared append path below: it sets prevAtom = group
            // (so {x}^2 scripts the group) and finalize assigns the indexRange.
        } else if (ch == '}') {
            NSAssert(!oneCharOnly, @"This should have been handled before");
            NSAssert(stop == 0, @"This should have been handled before");
            // We encountered a closing brace when there is no stop set, that means there was no
            // corresponding opening brace.
            NSString* errorMessage = @"Mismatched braces.";
            [self setError:MTParseErrorMismatchBraces message:errorMessage];
            return nil;
        } else if (ch == '\\') {
            // \ means a command
            NSString* command = [self readCommand];
            MTMathList* done = [self stopCommand:command list:list stopChar:stop oneChar:oneCharOnly];
            if (done) {
                return done;
            } else if (_error) {
                return nil;
            }
            if ([self applyModifier:command atom:prevAtom]) {
                continue;
            }
            // Recognize \text* commands first — they consume their {…}
            // body raw, so they must be handled before the legacy
            // font-style dispatch (and before the six \text* keys are
            // removed from MTMathAtomFactory.fontStyles).
            MTTextStyle textStyle = [MTMathAtomFactory textStyleWithName:command];
            if (textStyle != (MTTextStyle)NSNotFound) {
                NSString* body = [self readTextArgument];
                if (!body) {
                    return nil; // error already set
                }
                MTTextAtom* textAtom = [[MTTextAtom alloc] initWithText:body
                                                                  style:textStyle];
                [list addAtom:textAtom];
                prevAtom = textAtom;
                if (oneCharOnly) {
                    return list;
                }
                continue;
            }
            MTFontStyle fontStyle = [MTMathAtomFactory fontStyleWithName:command];
            if (fontStyle != NSNotFound) {
                BOOL oldSpacesAllowed = _spacesAllowed;
                // Text has special consideration where it allows spaces without escaping.
                _spacesAllowed = [command isEqualToString:@"text"];
                MTFontStyle oldFontStyle = _currentFontStyle;
                _currentFontStyle = fontStyle;
                MTMathList* sublist = [self buildInternal:true];
                // Restore the font style.
                _currentFontStyle = oldFontStyle;
                _spacesAllowed = oldSpacesAllowed;

                prevAtom = [sublist.atoms lastObject];
                [list append:sublist];
                if (oneCharOnly) {
                    return list;
                }
                continue;
            }
            atom = [self atomForCommand:command];
            if (atom == nil) {
                // this was an unknown command,
                // we flag an error and return
                // (note setError will not set the error if there is already one, so we flag internal error
                // in the odd case that an _error is not set.
                [self setError:MTParseErrorInternalError message:@"Internal error"];
                return nil;
            }
        } else if (ch == '&') {
            // used for column separation in tables
            NSAssert(!oneCharOnly, @"This should have been handled before");
            if (_currentEnv) {
                return list;
            } else {
                // Create a new table with the current list and a default env
                MTMathAtom* table = [self buildTable:nil firstList:list row:NO];
                return [MTMathList mathListWithAtoms:table, nil];
            }
        } else if (ch == '\'') {
            // Prime shorthand. Mirrors the ^ branch: builds a list of \prime
            // atoms and attaches them as a superscript on prevAtom.
            if (oneCharOnly) {
                // We're filling a single-char slot (^X / _X / \fontStyle{X}).
                // Emit one \prime atom and let the caller consume it.
                MTMathAtom* primeAtom = [MTMathAtomFactory atomForLatexSymbolName:@"prime"];
                NSAssert(primeAtom != nil, @"\\prime must be registered");
                primeAtom.fontStyle = _currentFontStyle;
                [list addAtom:primeAtom];
                return list;
            }
            if (!prevAtom || prevAtom.superScript || !prevAtom.scriptsAllowed) {
                // No host atom, host already has a superscript, or host
                // forbids scripts: allocate an empty Ord to hang primes on.
                // Same pattern as the ^ branch above.
                prevAtom = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@""];
                [list addAtom:prevAtom];
            }
            MTMathList* primes = [MTMathList new];
            MTMathAtom* primeAtom = [MTMathAtomFactory atomForLatexSymbolName:@"prime"];
            NSAssert(primeAtom != nil, @"\\prime must be registered");
            primeAtom.fontStyle = _currentFontStyle;
            [primes addAtom:primeAtom];
            // Greedy collect more consecutive primes.
            while ([self hasCharacters]) {
                unichar peek = [self getNextCharacter];
                if (peek == '\'') {
                    MTMathAtom* extra = [MTMathAtomFactory atomForLatexSymbolName:@"prime"];
                    extra.fontStyle = _currentFontStyle;
                    [primes addAtom:extra];
                } else {
                    [self unlookCharacter];
                    break;
                }
            }
            // \futurelet merge with trailing ^: f'^2  ->  superscript = [\prime, 2]
            if ([self hasCharacters]) {
                unichar peek = [self getNextCharacter];
                if (peek == '^') {
                    MTMathList* tail = [self buildInternal:true];
                    [primes append:tail];
                } else {
                    [self unlookCharacter];
                }
            }
            prevAtom.superScript = primes;
            continue;
        } else if (_spacesAllowed && ch == ' ') {
            // If spaces are allowed then spaces do not need escaping with a \ before being used.
            atom = [MTMathAtomFactory atomForLatexSymbolName:@" "];
        } else if (ch == '~') {
            // Tilde is a non-breaking space in LaTeX; render it as an ordinary space.
            atom = [MTMathAtomFactory atomForLatexSymbolName:@" "];
        } else {
            atom = [MTMathAtomFactory atomForCharacter:ch];
            if (!atom) {
                // Characters TeX silently discards: whitespace (catcode 10/5,
                // ignored in math mode) and NUL (catcode 9). Note that other
                // control characters are *not* spaces in TeX (form feed is \par,
                // vertical tab is an ordinary "other" character), so they fall
                // through to the error below, as they should.
                if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == '\0') {
                    continue;
                }
                // Any other unrecognized character is an error: a non-ASCII literal
                // (e.g. π, ×, ≤) or a special character with no meaning in math mode
                // (% is a comment, # a macro parameter, $ toggles math mode). Callers
                // should use the corresponding LaTeX command (e.g. \pi, \%, \#).
                // ch is a single UTF-16 code unit; we just report its value (an
                // above-BMP character reports its leading surrogate, which is fine
                // for an error message).
                [self setError:MTParseErrorInvalidCharacter
                       message:[NSString stringWithFormat:@"Unknown character U+%04X is not a valid LaTeX input character in math mode. Use the corresponding LaTeX command instead.", ch]];
                return nil;
            }
        }
        NSAssert(atom != nil, @"Atom shouldn't be nil");
        atom.fontStyle = _currentFontStyle;
        [list addAtom:atom];
        prevAtom = atom;
        
        if (oneCharOnly) {
            // we consumed our onechar
            return list;
        }
    }
    if (stop > 0) {
        if (stop == '}') {
            // We did not find a corresponding closing brace.
            [self setError:MTParseErrorMismatchBraces message:@"Missing closing brace"];
        } else {
            // we never found our stop character
            NSString* errorMessage = [NSString stringWithFormat:@"Expected character not found: %d", stop];
            [self setError:MTParseErrorCharacterNotFound message:errorMessage];
        }
    }
    return list;
    } @finally {
        _recursionDepth--;
    }
}

- (NSString*) readString
{
    // a string of all upper and lower case characters.
    NSMutableString* mutable = [NSMutableString string];
    while([self hasCharacters]) {
        unichar ch = [self getNextCharacter];
        if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
            [mutable appendString:[NSString stringWithCharacters:&ch length:1]];
        } else {
            // we went too far
            [self unlookCharacter];
            break;
        }
    }
    return mutable;
}

- (void) skipTextArgumentSpaces
{
    static NSCharacterSet* whitespace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    });

    while ([self hasCharacters]) {
        unichar ch = [self getNextCharacter];
        if (![whitespace characterIsMember:ch]) {
            [self unlookCharacter];
            return;
        }
    }
}

- (NSString*) readUnbracedTextTokenStartingWith:(unichar)c
                                   escapableSet:(NSCharacterSet*)escapable
{
    if (c == '\\') {
        if (![self hasCharacters]) {
            [self setError:MTParseErrorMismatchBraces
                   message:@"Trailing \\ after \\text*"];
            return nil;
        }

        NSString* command = [self readCommand];
        if (command.length == 1) {
            unichar escaped = [command characterAtIndex:0];
            if (escaped == ' ') {
                return @" ";
            }
            if ([escapable characterIsMember:escaped]) {
                return command;
            }
        }

        MTMathAtom* atom = [MTMathAtomFactory atomForLatexSymbolName:command];
        if (atom && atom.nucleus.length > 0) {
            return atom.nucleus;
        }

        [self setError:MTParseErrorInvalidCommand
               message:[NSString stringWithFormat:
                        @"Unsupported command \\%@ as \\text* argument",
                        command]];
        return nil;
    }

    if (c == '$') {
        [self setError:MTParseErrorInvalidCommand
               message:@"$ is not allowed inside \\text*"];
        return nil;
    }
    if (c == '^' || c == '_' || c == '}' || c == '&') {
        [self unlookCharacter];
        [self setError:MTParseErrorCharacterNotFound
               message:@"Missing argument for \\text*"];
        return nil;
    }

    NSMutableString* token = [NSMutableString stringWithCharacters:&c length:1];
    if (c >= 0xD800 && c <= 0xDBFF && [self hasCharacters]) {
        unichar low = [self getNextCharacter];
        if (low >= 0xDC00 && low <= 0xDFFF) {
            [token appendFormat:@"%C", low];
        } else {
            [self unlookCharacter];
        }
    }
    return token;
}

// Reads the argument following a \text* command.  Braced bodies are
// captured raw — every code point flows through unchanged except for the
// backslash escapes accepted by `[MTTextAtom latexEscapableCharacterSet]`,
// which unescape to their literal character.  Balanced nested {...}
// groups are accepted as TeX-style grouping (the braces are stripped, the
// inner content is captured).  Without braces, LaTeX compatibility is
// preserved by consuming a single following text token.
- (NSString*) readTextArgument
{
    [self skipTextArgumentSpaces];
    NSCharacterSet* escapable = [MTTextAtom latexEscapableCharacterSet];
    if (![self hasCharacters]) {
        [self setError:MTParseErrorCharacterNotFound
               message:@"Missing argument for \\text*"];
        return nil;
    }

    unichar first = [self getNextCharacter];
    if (first != '{') {
        return [self readUnbracedTextTokenStartingWith:first escapableSet:escapable];
    }

    NSMutableString* body = [NSMutableString string];
    NSInteger depth = 0;
    while ([self hasCharacters]) {
        unichar c = [self getNextCharacter];
        if (c == '\\') {
            if (![self hasCharacters]) {
                [self setError:MTParseErrorMismatchBraces
                       message:@"Trailing \\ inside \\text*"];
                return nil;
            }
            unichar esc = [self getNextCharacter];
            if (esc == ' ') {
                // \<space> is a forced literal space in LaTeX text mode.
                [body appendString:@" "];
            } else if ([escapable characterIsMember:esc]) {
                [body appendFormat:@"%C", esc];
            } else {
                [self setError:MTParseErrorInvalidCommand
                       message:[NSString stringWithFormat:
                                @"Unsupported escape \\%C in \\text* body",
                                esc]];
                return nil;
            }
            continue;
        }
        if (c == '{') {
            // Balanced group — opening brace is grouping, not content.
            depth += 1;
            continue;
        }
        if (c == '}') {
            if (depth == 0) {
                return body; // matched the outer {
            }
            depth -= 1;
            continue;
        }
        if (c == '$') {
            // Math-in-text is out of scope.
            [self setError:MTParseErrorInvalidCommand
                   message:@"$ is not allowed inside \\text*"];
            return nil;
        }
        [body appendFormat:@"%C", c];
    }
    [self setError:MTParseErrorMismatchBraces
           message:@"Unmatched { in \\text* body"];
    return nil;
}

- (NSString*) readColor
{
    if (![self expectCharacter:'{']) {
        // We didn't find an opening brace, so no env found.
        [self setError:MTParseErrorCharacterNotFound message:@"Missing {"];
        return nil;
    }

    // Ignore spaces and nonascii.
    [self skipSpaces];

    // Read the entire token up to the closing brace or whitespace.
    // We deliberately do NOT restrict the charset here so that invalid
    // inputs (e.g. named colors like "red") are captured whole and can
    // produce a clear validation error instead of a confusing "Missing }".
    NSMutableString* mutable = [NSMutableString string];
    while([self hasCharacters]) {
        unichar ch = [self getNextCharacter];
        if (ch == '}') {
            // Put the closing brace back; expectCharacter below will consume it.
            [self unlookCharacter];
            break;
        }
        [mutable appendString:[NSString stringWithCharacters:&ch length:1]];
    }

    if (![self expectCharacter:'}']) {
        // We didn't find a closing brace, so invalid format.
        [self setError:MTParseErrorCharacterNotFound message:@"Missing }"];
        return nil;
    }

    // Validate: color must be '#' followed by exactly 3 or 6 hex digits.
    // This keeps the grammar consistent with colorFromHexString: which requires
    // a leading '#'.  Named colors and bare hex strings are not supported.
    //
    // NOTE: 3-digit #RGB is accepted here at parse time, but correct *rendering*
    // of #RGB depends on colorFromHexString: handling the 3-digit shorthand.
    // The current decoder is 6-digit-only (scanHexInt on "f00" yields 0xF00 and
    // is masked as if it were #000F00), so #RGB currently renders the wrong
    // color until that decoder fix (REN-7) lands.  We deliberately keep
    // accepting #RGB rather than rejecting it: the previous parser also
    // accepted and mis-rendered #RGB identically, so this is parse-correct /
    // render-deferred, not a regression.
    BOOL valid = NO;
    NSUInteger len = mutable.length;
    if (len == 4 || len == 7) {
        unichar first = [mutable characterAtIndex:0];
        if (first == '#') {
            valid = YES;
            for (NSUInteger i = 1; i < len && valid; i++) {
                unichar c = [mutable characterAtIndex:i];
                BOOL isHex = ((c >= '0' && c <= '9') ||
                              (c >= 'a' && c <= 'f') ||
                              (c >= 'A' && c <= 'F'));
                if (!isHex) {
                    valid = NO;
                }
            }
        }
    }

    if (!valid) {
        NSString* msg = [NSString stringWithFormat:@"Invalid color: %@", mutable];
        [self setError:MTParseErrorInvalidCommand message:msg];
        return nil;
    }

    return mutable;
}

// Reads a TeX length dimension (e.g. "1em", "-0.5em", "3mu") from the char stream.
// Grammar: [ws] ['{'] [ws] [sign] (digits[.digits] | .digits) [ws] unit [ws] ['}']
// where unit ∈ {em, mu}.  On success, writes the value in mu to *outMu and returns YES.
// On any malformed or unsupported input, sets _error (MTParseErrorInvalidCommand) and
// returns NO.  em is converted to mu via factor 18; mu is stored as-is.
// allowEm = NO means only mu is accepted (for \mkern/\mskip/\mspace).
- (BOOL) readDimensionIntoMu:(CGFloat*)outMu allowEm:(BOOL)allowEm command:(NSString*)cmd
{
    // Skip any leading whitespace.
    [self skipSpaces];

    // Check for an optional opening brace.
    BOOL braced = NO;
    if ([self hasCharacters]) {
        unichar c = [self getNextCharacter];
        if (c == '{') {
            braced = YES;
        } else {
            [self unlookCharacter];
        }
    }
    // Skip whitespace after optional '{'.
    [self skipSpaces];

    // Parse optional sign.
    CGFloat sign = 1;
    if ([self hasCharacters]) {
        unichar c = [self getNextCharacter];
        if (c == '-') {
            sign = -1;
        } else if (c == '+') {
            sign = 1;
        } else {
            [self unlookCharacter];
        }
    }

    // Parse mantissa: digits[.digits] | .digits  (require at least one digit overall).
    NSMutableString* num = [NSMutableString string];
    BOOL sawDigit = NO, sawDot = NO;
    while ([self hasCharacters]) {
        unichar c = [self getNextCharacter];
        if (c >= '0' && c <= '9') {
            sawDigit = YES;
            [num appendString:[NSString stringWithCharacters:&c length:1]];
        } else if (c == '.' && !sawDot) {
            sawDot = YES;
            [num appendString:@"."];
        } else {
            [self unlookCharacter];
            break;
        }
    }
    if (!sawDigit) {
        [self setError:MTParseErrorInvalidCommand
               message:[NSString stringWithFormat:@"\\%@ expects a length", cmd]];
        return NO;
    }
    // Skip whitespace between number and unit.
    [self skipSpaces];

    // Read exactly two characters for the unit.
    NSMutableString* unit = [NSMutableString string];
    for (int i = 0; i < 2 && [self hasCharacters]; i++) {
        unichar c = [self getNextCharacter];
        [unit appendString:[NSString stringWithCharacters:&c length:1]];
    }

    CGFloat factor;
    if ([unit isEqualToString:@"em"]) {
        if (!allowEm) {
            [self setError:MTParseErrorInvalidCommand
                   message:[NSString stringWithFormat:@"\\%@ expects mu units", cmd]];
            return NO;
        }
        factor = 18;
    } else if ([unit isEqualToString:@"mu"]) {
        factor = 1;
    } else {
        [self setError:MTParseErrorInvalidCommand
               message:[NSString stringWithFormat:@"\\%@ expects em or mu units, got: %@", cmd, unit]];
        return NO;
    }

    // If braced, skip whitespace and consume the closing '}'.
    if (braced) {
        [self skipSpaces];
        if (![self hasCharacters] || [self getNextCharacter] != '}') {
            [self setError:MTParseErrorInvalidCommand
                   message:[NSString stringWithFormat:@"\\%@ missing closing brace", cmd]];
            return NO;
        }
    }

    *outMu = sign * num.doubleValue * factor;
    return YES;
}

- (void) skipSpaces
{
    while ([self hasCharacters]) {
        unichar ch = [self getNextCharacter];
        if (ch < 0x21 || ch > 0x7E) {
            // skip non ascii characters and spaces
            continue;
        } else {
            [self unlookCharacter];
            return;
        }
    }
}

#define MTAssertNotSpace(ch) NSAssert((ch) >= 0x21 && (ch) <= 0x7E, @"Expected non space character %c", (ch));

- (BOOL) expectCharacter:(unichar) ch
{
    MTAssertNotSpace(ch);
    [self skipSpaces];
    
    if ([self hasCharacters]) {
        unichar c = [self getNextCharacter];
        MTAssertNotSpace(c);
        if (c == ch) {
            return YES;
        } else {
            [self unlookCharacter];
            return NO;
        }
    }
    return NO;
}

- (NSString*) readCommand
{
    static NSSet<NSNumber*>* singleCharCommands = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray* singleChars = @[ @'{', @'}', @'$', @'#', @'%', @'_', @'|', @' ', @',', @'>', @';', @'!', @'\\' ];
        singleCharCommands = [[NSSet alloc] initWithArray:singleChars];
    });
    if ([self hasCharacters]) {
        // Check if we have a single character command.
        unichar ch = [self getNextCharacter];
        // Single char commands
        if ([singleCharCommands containsObject:@(ch)]) {
            return [NSString stringWithCharacters:&ch length:1];
        } else {
            // not a known single character command
            [self unlookCharacter];
        }
    }
    // otherwise a command is a string of all upper and lower case characters.
    return [self readString];
}

- (NSString*) readDelimiter
{
    // Ignore spaces and nonascii.
    [self skipSpaces];
    while([self hasCharacters]) {
        unichar ch = [self getNextCharacter];
        MTAssertNotSpace(ch);
        if (ch == '\\') {
            // \ means a command
            NSString* command = [self readCommand];
            if ([command isEqualToString:@"|"]) {
                // | is a command and also a regular delimiter. We use the || command to
                // distinguish between the 2 cases for the caller.
                return @"||";
            }
            return command;
        } else {
            return [NSString stringWithCharacters:&ch length:1];
        }
    }
    // We ran out of characters for delimiter
    return nil;
}

- (NSString*) readEnvironment
{
    if (![self expectCharacter:'{']) {
        // We didn't find an opening brace, so no env found.
        [self setError:MTParseErrorCharacterNotFound message:@"Missing {"];
        return nil;
    }
    
    // Ignore spaces and nonascii.
    [self skipSpaces];
    NSString* env = [self readString];
    
    if (![self expectCharacter:'}']) {
        // We didn't find an closing brace, so invalid format.
        [self setError:MTParseErrorCharacterNotFound message:@"Missing }"];
        return nil;
    }
    return env;
}

- (MTMathAtom*) getBoundaryAtom:(NSString*) delimiterType
{
    NSString* delim = [self readDelimiter];
    if (!delim) {
        NSString* errorMessage = [NSString stringWithFormat:@"Missing delimiter for \\%@", delimiterType];
        [self setError:MTParseErrorMissingDelimiter message:errorMessage];
        return nil;
    }
    MTMathAtom* boundary = [MTMathAtomFactory boundaryAtomForDelimiterName:delim];
    if (!boundary) {
        NSString* errorMessage = [NSString stringWithFormat:@"Invalid delimiter for \\%@: %@", delimiterType, delim];
        [self setError:MTParseErrorInvalidDelimiter message:errorMessage];
        return nil;
    }
    return boundary;
}

// Maps each phantom/smash/lap command to its MTMathBox flag set.
// keys: kW=keepWidth, kH=keepHeight, kD=keepDepth, draw=drawChild, hAlign, acceptsTB, synthParen
+ (NSDictionary<NSString*, NSDictionary*>*) boxCommands
{
    static NSDictionary* commands = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        commands = @{
            @"phantom":   @{@"kW":@YES, @"kH":@YES, @"kD":@YES, @"draw":@NO},
            @"hphantom":  @{@"kW":@YES, @"kH":@NO,  @"kD":@NO,  @"draw":@NO},
            @"vphantom":  @{@"kW":@NO,  @"kH":@YES, @"kD":@YES, @"draw":@NO},
            @"mathstrut": @{@"kW":@NO,  @"kH":@YES, @"kD":@YES, @"draw":@NO, @"synthParen":@YES},
            @"smash":     @{@"kW":@YES, @"kH":@NO,  @"kD":@NO,  @"draw":@YES, @"acceptsTB":@YES},
            @"llap":      @{@"kW":@NO,  @"kH":@YES, @"kD":@YES, @"draw":@YES, @"hAlign":@(kMTBoxHAlignRight)},
            @"rlap":      @{@"kW":@NO,  @"kH":@YES, @"kD":@YES, @"draw":@YES, @"hAlign":@(kMTBoxHAlignLeft)},
            @"clap":      @{@"kW":@NO,  @"kH":@YES, @"kD":@YES, @"draw":@YES, @"hAlign":@(kMTBoxHAlignCenter)},
            @"mathllap":  @{@"kW":@NO,  @"kH":@YES, @"kD":@YES, @"draw":@YES, @"hAlign":@(kMTBoxHAlignRight)},
            @"mathrlap":  @{@"kW":@NO,  @"kH":@YES, @"kD":@YES, @"draw":@YES, @"hAlign":@(kMTBoxHAlignLeft)},
            @"mathclap":  @{@"kW":@NO,  @"kH":@YES, @"kD":@YES, @"draw":@YES, @"hAlign":@(kMTBoxHAlignCenter)},
        };
    });
    return commands;
}

- (MTMathAtom*) atomForCommand:(NSString*) command
{
    MTMathAtom* atom = [MTMathAtomFactory atomForLatexSymbolName:command];
    if (atom) {
        return atom;
    }
    NSDictionary<NSString*, NSDictionary*>* bigTable = [MTMathListBuilder largeDelimiterCommands];
    NSDictionary* bigSpec = bigTable[command];
    if (bigSpec) {
        MTMathAtom* boundary = [self getBoundaryAtom:command];
        if (!boundary) {
            // Error already set by getBoundaryAtom:.
            return nil;
        }
        MTMathAtomType mathClass = (MTMathAtomType)[bigSpec[@"class"] unsignedIntegerValue];
        MTDelimiterSize size = (MTDelimiterSize)[bigSpec[@"size"] unsignedIntegerValue];
        return [[MTLargeDelimiter alloc] initWithDelimiterNucleus:boundary.nucleus
                                                        mathClass:mathClass
                                                             size:size];
    }
    NSDictionary<NSString*, NSDictionary*>* fracTable = [MTMathListBuilder fractionMacroCommands];
    NSDictionary* fracSpec = fracTable[command];
    if (fracSpec) {
        BOOL hasRule = [fracSpec[@"hasRule"] boolValue];
        MTFractionStyle style = (MTFractionStyle)[fracSpec[@"style"] unsignedIntegerValue];
        MTFraction* frac = hasRule ? [MTFraction new] : [[MTFraction alloc] initWithRule:NO];
        frac.styleOverride = style;
        if ([fracSpec[@"acceptsAlign"] boolValue]) {
            MTFractionAlignment alignment = kMTFractionAlignmentCenter;
            if ([self readOptionalAlignment:&alignment]) {
                if (_error) {
                    return nil;
                }
                frac.numeratorAlignment = alignment;
            }
        }
        if ([fracSpec[@"continued"] boolValue]) {
            frac.isContinuedFraction = YES;
        }
        frac.numerator = [self buildInternal:true];
        frac.denominator = [self buildInternal:true];
        NSString* leftDelim = fracSpec[@"leftDelim"];
        NSString* rightDelim = fracSpec[@"rightDelim"];
        if (leftDelim) {
            frac.leftDelimiter = leftDelim;
        }
        if (rightDelim) {
            frac.rightDelimiter = rightDelim;
        }
        return frac;
    }
    MTAccent* accent = [MTMathAtomFactory accentWithName:command];
    if (accent) {
        // The command is an accent
        accent.innerList = [self buildInternal:true];
        return accent;
    } else if ([command isEqualToString:@"sqrt"]) {
        // A sqrt command with one argument
        MTRadical* rad = [MTRadical new];
        // Guard against a lone "\sqrt" at the end of input: only read a
        // character if one is available.
        if ([self hasCharacters]) {
            unichar ch = [self getNextCharacter];
            if (ch == '[') {
                // special handling for sqrt[degree]{radicand}
                rad.degree = [self buildInternal:false stopChar:']'];
            } else {
                [self unlookCharacter];
            }
        }
        rad.radicand = [self buildInternal:true];
        return rad;
    } else if ([command isEqualToString:@"left"]) {
        // Save the current inner while a new one gets built.
        MTInner* oldInner = _currentInnerAtom;
        _currentInnerAtom = [MTInner new];
        _currentInnerAtom.leftBoundary = [self getBoundaryAtom:@"left"];
        if (!_currentInnerAtom.leftBoundary) {
            return nil;
        }
        _currentInnerAtom.innerList = [self buildInternal:false];
        if (!_currentInnerAtom.rightBoundary) {
            // A right node would have set the right boundary so we must be missing the right node.
            NSString* errorMessage = @"Missing \\right";
            [self setError:MTParseErrorMissingRight message:errorMessage];
            return nil;
        }
        // reinstate the old inner atom.
        MTInner* newInner = _currentInnerAtom;
        _currentInnerAtom = oldInner;
        return newInner;
    } else if ([command isEqualToString:@"overline"]) {
        // The overline command has 1 arguments
        MTOverLine* over = [MTOverLine new];
        over.innerList = [self buildInternal:true];
        return over;
    } else if ([command isEqualToString:@"underline"]) {
        // The underline command has 1 arguments
        MTUnderLine* under = [MTUnderLine new];
        under.innerList = [self buildInternal:true];
        return under;
    } else {
        MTMathStackCommandSpec* spec = [MTMathAtomFactory stackCommandSpec:command];
        if (spec) {
            MTMathStack* stack = [MTMathStack new];
            stack.over  = spec.overConstruction;   // static glyph row or nil
            stack.under = spec.underConstruction;
            MTMathList* base = nil;
            for (NSNumber* role in spec.argRoles) {
                MTMathList* arg = [self buildInternal:true];
                if (_error) {
                    return nil;
                }
                switch (role.unsignedIntegerValue) {
                    case kMTStackArgBase:
                        base = arg;
                        stack.innerList = arg;
                        break;
                    case kMTStackArgOver:
                        stack.over = [MTMathStackConstruction mathListWithList:arg];
                        break;
                    case kMTStackArgUnder:
                        stack.under = [MTMathStackConstruction mathListWithList:arg];
                        break;
                }
            }
            stack.displayClass = spec.inheritsClass
                ? [MTMathAtomFactory inheritedDisplayClassForBase:base]
                : spec.displayClass;
            return stack;
        }
    }
    if ([command isEqualToString:@"begin"]) {
        NSString* env = [self readEnvironment];
        if (!env) {
            return nil;
        }
        MTMathAtom* table = [self buildTable:env firstList:nil row:NO];
        return table;
    } else if ([command isEqualToString:@"color"]) {
        // A color command has 2 arguments
        NSString* colorStr = [self readColor];
        if (!colorStr) {
            // readColor already set the error.
            return nil;
        }
        MTMathColor* mathColor = [[MTMathColor alloc] init];
        mathColor.colorString = colorStr;
        mathColor.innerList = [self buildInternal:true];
        return mathColor;
    } else if ([command isEqualToString:@"colorbox"]) {
        // A colorbox command has 2 arguments
        NSString* colorStr = [self readColor];
        if (!colorStr) {
            // readColor already set the error.
            return nil;
        }
        MTMathColorbox* mathColorbox = [[MTMathColorbox alloc] init];
        mathColorbox.colorString = colorStr;
        mathColorbox.innerList = [self buildInternal:true];
        return mathColorbox;
    }

    // Spacing commands: \kern, \hspace[*], \hskip, \mkern, \mskip, \mspace.
    // The table maps each command name to @YES (em or mu allowed) or @NO (mu only).
    NSNumber* allowEm = [MTMathListBuilder spacingCommands][command];
    if (allowEm) {
        // \hspace* is identical to \hspace; the '*' is left in the stream by the
        // lexer (readString stops at '*' since it is not alphabetic), so consume it.
        // TeX tolerates whitespace before the '*' (e.g. "\hspace *{1em}"), so skip
        // spaces first; any skipped run is harmless when no '*' follows because
        // readDimensionIntoMu:allowEm:command: also skips leading whitespace.
        if ([command isEqualToString:@"hspace"]) {
            [self skipSpaces];
            if ([self hasCharacters]) {
                unichar c = [self getNextCharacter];
                if (c != '*') {
                    [self unlookCharacter];
                }
            }
        }
        CGFloat mu = 0;
        if (![self readDimensionIntoMu:&mu allowEm:allowEm.boolValue command:command]) {
            return nil;   // _error already set by readDimensionIntoMu:
        }
        return [[MTMathSpace alloc] initWithSpace:mu];
    }

    NSDictionary* boxSpec = [MTMathListBuilder boxCommands][command];
    if (boxSpec) {
        MTMathBox* box = [MTMathBox new];
        box.keepWidth  = [boxSpec[@"kW"] boolValue];
        box.keepHeight = [boxSpec[@"kH"] boolValue];
        box.keepDepth  = [boxSpec[@"kD"] boolValue];
        box.drawChild  = [boxSpec[@"draw"] boolValue];
        box.hAlign     = (MTBoxHAlign)[boxSpec[@"hAlign"] unsignedIntegerValue];

        if ([boxSpec[@"synthParen"] boolValue]) {
            // \mathstrut: no argument; synthetic inner list with a single open paren.
            MTMathList* inner = [MTMathList new];
            MTMathAtom* paren = [MTMathAtomFactory atomForCharacter:'('];
            [inner addAtom:paren];
            box.innerList = inner;
            return box;
        }

        if ([boxSpec[@"acceptsTB"] boolValue] && [self hasCharacters]) {
            // \smash[t]/[b]: optional [t]/[b] before the {X} argument (\sqrt[…] pattern).
            unichar ch = [self getNextCharacter];
            if (ch == '[') {
                NSMutableString* opt = [NSMutableString string];
                BOOL foundClose = NO;
                while ([self hasCharacters]) {
                    unichar c = [self getNextCharacter];
                    if (c == ']') { foundClose = YES; break; }
                    [opt appendString:[NSString stringWithCharacters:&c length:1]];
                }
                if (!foundClose) {
                    // Mirror \sqrt[…]: a missing ']' is a parse error, not a silent recovery.
                    [self setError:MTParseErrorCharacterNotFound message:@"Expected character not found: ]"];
                    return nil;
                }
                NSString* o = [opt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ([o isEqualToString:@"t"]) { box.keepHeight = NO; box.keepDepth = YES; }
                else if ([o isEqualToString:@"b"]) { box.keepHeight = YES; box.keepDepth = NO; }
                // any other value: ignore, leave smash-both flags (no crash).
            } else {
                [self unlookCharacter];
            }
        }

        box.innerList = [self buildInternal:true];
        return box;
    }

    {
        NSString* errorMessage = [NSString stringWithFormat:@"Invalid command \\%@", command];
        [self setError:MTParseErrorInvalidCommand message:errorMessage];
        return nil;
    }
}

- (MTMathList*) stopCommand:(NSString*) command list:(MTMathList*) list stopChar:(unichar) stopChar oneChar:(BOOL) oneChar
{
    static NSDictionary<NSString*, NSArray*>* fractionCommands = nil;
    static dispatch_once_t fractionCommandsOnce;
    dispatch_once(&fractionCommandsOnce, ^{
        fractionCommands = @{ @"over" : @[],
                              @"atop" : @[],
                              @"choose" : @[ @"(", @")"],
                              @"brack" : @[ @"[", @"]"],
                              @"brace" : @[ @"{", @"}"]};
    });
    if ([command isEqualToString:@"right"]) {
        if (!_currentInnerAtom) {
            NSString* errorMessage = @"Missing \\left";
            [self setError:MTParseErrorMissingLeft message:errorMessage];
            return nil;
        }
        _currentInnerAtom.rightBoundary = [self getBoundaryAtom:@"right"];
        if (!_currentInnerAtom.rightBoundary) {
            return nil;
        }
        // return the list read so far.
        return list;
    } else if ([fractionCommands objectForKey:command]) {
        if (oneChar) {
            // REN-6: \over/\atop/\choose/\brack/\brace are illegal in a one-character
            // argument slot (e.g. x^\over y). TeX rejects this too. Users who want a
            // fraction in a script must use explicit braces: x^{a \over b}.
            NSString* errorMessage = [NSString stringWithFormat:
                @"\\%@ cannot be used in a one-character argument; "
                @"wrap it in braces, e.g. x^{a \\%@ b}", command, command];
            [self setError:MTParseErrorInvalidCommand message:errorMessage];
            return nil;
        }
        MTFraction* frac = nil;
        if ([command isEqualToString:@"over"]) {
            frac = [[MTFraction alloc] init];
        } else {
            frac = [[MTFraction alloc] initWithRule:NO];
        }
        NSArray* delims = [fractionCommands objectForKey:command];
        if (delims.count == 2) {
            frac.leftDelimiter = delims[0];
            frac.rightDelimiter = delims[1];
        }
        frac.numerator = list;
        frac.denominator = [self buildInternal:NO stopChar:stopChar];
        if (_error) {
            return nil;
        }
        MTMathList* fracList = [MTMathList new];
        [fracList addAtom:frac];
        // Signal to the {…} branch that this group was transformed by a TeX
        // group-transformation command (\over / \atop / \choose / \brack / \brace).
        // The fraction should be inserted into the parent list directly (not wrapped
        // in MTMathGroup), mirroring TeX's behavior where these commands replace the
        // enclosing group with a generalized fraction.
        _groupWasTransformedByStopCommand = YES;
        return fracList;
    } else if ([command isEqualToString:@"\\"] || [command isEqualToString:@"cr"]) {
        if (_currentEnv) {
            // Stop the current list and increment the row count
            _currentEnv.numRows++;
            return list;
        } else {
            // Create a new table with the current list and a default env
            MTMathAtom* table = [self buildTable:nil firstList:list row:YES];
            return [MTMathList mathListWithAtoms:table, nil];
        }
    } else if ([command isEqualToString:@"end"]) {
        if (!_currentEnv) {
            NSString* errorMessage = @"Missing \\begin";
            [self setError:MTParseErrorMissingBegin message:errorMessage];
            return nil;
        }
        NSString* env = [self readEnvironment];
        if (!env) {
            return nil;
        }
        if (![env isEqualToString:_currentEnv.envName])
        {
            NSString* errorMessage = [NSString stringWithFormat:@"Begin environment name %@ does not match end name: %@", _currentEnv.envName, env];
            [self setError:MTParseErrorInvalidEnv message:errorMessage];
            return nil;
        }
        // Finish the current environment.
        _currentEnv.ended = YES;
        return list;
    }
    return nil;
}

// Applies the modifier to the atom. Returns true if modifier applied.
- (BOOL) applyModifier:(NSString*) modifier atom:(MTMathAtom*) atom
{
    if ([modifier isEqualToString:@"limits"]) {
        if (atom.type != kMTMathAtomLargeOperator) {
            NSString* errorMessage = [NSString stringWithFormat:@"limits can only be applied to an operator."];
            [self setError:MTParseErrorInvalidLimits message:errorMessage];
        } else {
            MTLargeOperator* op = (MTLargeOperator*) atom;
            op.limits = YES;
        }
        return true;
    } else if ([modifier isEqualToString:@"nolimits"]) {
        if (atom.type != kMTMathAtomLargeOperator) {
            NSString* errorMessage = [NSString stringWithFormat:@"nolimits can only be applied to an operator."];
            [self setError:MTParseErrorInvalidLimits message:errorMessage];
            return YES;
        } else {
            MTLargeOperator* op = (MTLargeOperator*) atom;
            op.limits = NO;
        }
        return true;
    }
    return false;
}

- (void) setError:(MTParseErrors) code message:(NSString*) message
{
    // Only record the first error.
    if (!_error) {
        _error = [NSError errorWithDomain:MTParseError code:code userInfo:@{ NSLocalizedDescriptionKey : message }];
    }
}

- (MTMathAtom*) buildTable:(NSString*) env firstList:(MTMathList*) firstList row:(BOOL) isRow
{
    // Save the current env till an new one gets built.
    MTEnvProperties* oldEnv = _currentEnv;
    _currentEnv = [[MTEnvProperties alloc] initWithName:env];
    NSInteger currentRow = 0;
    NSInteger currentCol = 0;
    NSMutableArray<NSMutableArray<MTMathList*>*>* rows = [NSMutableArray array];
    rows[0] = [NSMutableArray array];
    if (firstList) {
        rows[currentRow][currentCol] = firstList;
        if (isRow) {
            _currentEnv.numRows++;
            currentRow++;
            rows[currentRow] = [NSMutableArray array];
        } else {
            currentCol++;
        }
    }
    while (!_currentEnv.ended && [self hasCharacters]) {
        MTMathList* list = [self buildInternal:NO];
        if (!list) {
            // If there is an error building the list, bail out early.
            return nil;
        }
        rows[currentRow][currentCol] = list;
        currentCol++;
        if (_currentEnv.numRows > currentRow) {
            currentRow = _currentEnv.numRows;
            if (rows.count > currentRow) {
                rows[currentRow] = [NSMutableArray array];
            } else {
                [rows addObject:[NSMutableArray array]];
            }
            currentCol = 0;
        }
    }
    if (!_currentEnv.ended && _currentEnv.envName) {
        [self setError:MTParseErrorMissingEnd message:@"Missing \\end"];
        return nil;
    }
    NSError* error;
    MTMathAtom* table = [MTMathAtomFactory tableWithEnvironment:_currentEnv.envName rows:rows error:&error];
    if (!table && !_error) {
        _error = error;
        return nil;
    }
    // reinstate the old env.
    _currentEnv = oldEnv;
    return table;
}

+ (NSDictionary*) spaceToCommands
{
    static NSDictionary* spaceToCommands = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        spaceToCommands = @{
                            @3 : @",",
                            @4 : @">",
                            @5 : @";",
                            @(-3) : @"!",
                            @18 : @"quad",
                            @36 : @"qquad",
                    };
    });
    return spaceToCommands;
}

+ (NSDictionary<NSString*, NSDictionary*>*) largeDelimiterCommands
{
    static NSDictionary<NSString*, NSDictionary*>* largeDelimiterCommands = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSNumber* ord = @(kMTMathAtomOrdinary);
        NSNumber* open = @(kMTMathAtomOpen);
        NSNumber* close = @(kMTMathAtomClose);
        NSNumber* rel = @(kMTMathAtomRelation);
        NSNumber* s1 = @(kMTDelimiterSize1);
        NSNumber* s2 = @(kMTDelimiterSize2);
        NSNumber* s3 = @(kMTDelimiterSize3);
        NSNumber* s4 = @(kMTDelimiterSize4);
        largeDelimiterCommands = @{
            @"big"   : @{ @"class": ord,   @"size": s1 },
            @"Big"   : @{ @"class": ord,   @"size": s2 },
            @"bigg"  : @{ @"class": ord,   @"size": s3 },
            @"Bigg"  : @{ @"class": ord,   @"size": s4 },
            @"bigl"  : @{ @"class": open,  @"size": s1 },
            @"Bigl"  : @{ @"class": open,  @"size": s2 },
            @"biggl" : @{ @"class": open,  @"size": s3 },
            @"Biggl" : @{ @"class": open,  @"size": s4 },
            @"bigr"  : @{ @"class": close, @"size": s1 },
            @"Bigr"  : @{ @"class": close, @"size": s2 },
            @"biggr" : @{ @"class": close, @"size": s3 },
            @"Biggr" : @{ @"class": close, @"size": s4 },
            @"bigm"  : @{ @"class": rel,   @"size": s1 },
            @"Bigm"  : @{ @"class": rel,   @"size": s2 },
            @"biggm" : @{ @"class": rel,   @"size": s3 },
            @"Biggm" : @{ @"class": rel,   @"size": s4 },
        };
    });
    return largeDelimiterCommands;
}

+ (NSDictionary<NSString*, NSDictionary*>*) fractionMacroCommands
{
    static NSDictionary<NSString*, NSDictionary*>* fractionMacroCommands = nil;
    static dispatch_once_t fractionOnceToken;
    dispatch_once(&fractionOnceToken, ^{
        fractionMacroCommands = @{
            @"frac"   : @{ @"hasRule": @YES,
                           @"style":   @(kMTFractionStyleAuto) },
            @"binom"  : @{ @"hasRule":    @NO,
                           @"leftDelim":  @"(",
                           @"rightDelim": @")",
                           @"style":      @(kMTFractionStyleAuto) },
            @"dfrac"  : @{ @"hasRule": @YES,
                           @"style":   @(kMTFractionStyleDisplay) },
            @"tfrac"  : @{ @"hasRule": @YES,
                           @"style":   @(kMTFractionStyleText) },
            @"dbinom" : @{ @"hasRule":    @NO,
                           @"leftDelim":  @"(",
                           @"rightDelim": @")",
                           @"style":      @(kMTFractionStyleDisplay) },
            @"tbinom" : @{ @"hasRule":    @NO,
                           @"leftDelim":  @"(",
                           @"rightDelim": @")",
                           @"style":      @(kMTFractionStyleText) },
            @"cfrac"  : @{ @"hasRule":      @YES,
                           @"style":       @(kMTFractionStyleDisplay),
                           @"continued":   @YES,
                           @"acceptsAlign":@YES },
        };
    });
    return fractionMacroCommands;
}

+ (NSDictionary*) styleToCommands
{
    static NSDictionary* styleToCommands = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        styleToCommands = @{
                            @(kMTLineStyleDisplay) : @"displaystyle",
                            @(kMTLineStyleText) : @"textstyle",
                            @(kMTLineStyleScript) : @"scriptstyle",
                            @(kMTLineStyleScriptScript) : @"scriptscriptstyle",
                            };
    });
    return styleToCommands;
}

// Maps each spacing command to whether em units are allowed (YES => em or mu; NO => mu only).
+ (NSDictionary<NSString*, NSNumber*>*) spacingCommands
{
    static NSDictionary* commands = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        commands = @{
            @"kern":    @YES,   // em or mu
            @"hspace":  @YES,   // also handles \hspace* (the '*' is consumed in the dispatch)
            @"hskip":   @YES,
            @"mkern":   @NO,    // mu only
            @"mskip":   @NO,
            @"mspace":  @NO,
        };
    });
    return commands;
}

+ (MTMathList *)buildFromString:(NSString *)str
{
    MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:str];
    return builder.build;
}

+ (MTMathList *)buildFromString:(NSString *)str error:(NSError *__autoreleasing *)error
{
    MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:str];
    MTMathList* output = [builder build];
    if (builder.error) {
        if (error) {
            *error = builder.error;
        }
        return nil;
    }
    return output;
}

+ (NSString*) delimToString:(MTMathAtom*) delim
{
    NSString* command = [MTMathAtomFactory delimiterNameForBoundaryAtom:delim];
    if (command) {
        NSArray<NSString*>* singleChars = @[ @"(", @")", @"[", @"]", @"<", @">", @"|", @".", @"/"];
        if ([singleChars containsObject:command]) {
            return command;
        } else if ([command isEqualToString:@"||"]) {
            return @"\\|"; // special case for ||
        } else {
            return [NSString stringWithFormat:@"\\%@", command];
        }
    }
    return @"";
}

+ (NSString *)mathListToString:(MTMathList *)ml
{
    NSMutableString* str = [NSMutableString string];
    MTFontStyle currentfontStyle = kMTFontStyleDefault;
    for (MTMathAtom* atom in ml.atoms) {
        if (currentfontStyle != atom.fontStyle) {
            if (currentfontStyle != kMTFontStyleDefault) {
                // close the previous font style.
                [str appendString:@"}"];
            }
            if (atom.fontStyle != kMTFontStyleDefault) {
                // open new font style
                NSString* fontStyleName = [MTMathAtomFactory fontNameForStyle:atom.fontStyle];
                [str appendFormat:@"\\%@{", fontStyleName];
            }
            currentfontStyle = atom.fontStyle;
        }
        [atom appendLaTeXToString:str];

        if (atom.superScript) {
            [str appendFormat:@"^{%@}", [self mathListToString:atom.superScript]];
        }
        
        if (atom.subScript) {
            [str appendFormat:@"_{%@}", [self mathListToString:atom.subScript]];
        }
    }
    if (currentfontStyle != kMTFontStyleDefault) {
        [str appendString:@"}"];
    }
    return [str copy];
}

@end
