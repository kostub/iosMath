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

@implementation MTMathListBuilder {
    unichar* _chars;
    int _currentChar;
    NSUInteger _length;
    MTInner* _currentInnerAtom;
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
            if (ch == '^' || ch == '}' || ch == '_') {
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
            prevAtom = [sublist.atoms lastObject];
            [list append:sublist];
            if (oneCharOnly) {
                return list;
            }
            continue;
        } else if (ch == '}') {
            NSAssert(!oneCharOnly, @"This should have been handled before");
            NSAssert(stop == 0, @"This should have been handled before");
            // We encountered a closing brace when there is no stop set, that means there was no
            // corresponding opening brace.
            NSString* errorMessage = [NSString stringWithFormat:@"Mismatched braces."];
            [self setError:MTParseErrorMismatchBraces message:errorMessage];
            return nil;
        } else if (ch == '\\') {
            // \ means a command
            NSString* command = [self readCommand];
            MTMathList* done = [self stopCommand:command list:list stopChar:stop];
            if (done) {
                return done;
            } else if (_error) {
                return nil;
            }
            atom = [self atomForCommand:command];
            if (atom == nil) {
                // this was an unknown command,
                // we flag an error and return.
                return nil;
            }
        } else {
            atom = [MTMathAtomFactory atomForCharacter:ch];
            if (!atom) {
                // Not a recognized character
                continue;
            }
        }
        NSAssert(atom != nil, @"Atom shouldn't be nil");
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
}

- (NSString*) readCommand
{
    static NSSet<NSNumber*>* singleCharCommands = nil;
    if (!singleCharCommands) {
        NSArray* singleChars = @[ @'{', @'}', @'$', @'#', @'%', @'_', @'|', @' ', @',', @'>', @';', @'!' ];
        singleCharCommands = [[NSSet alloc] initWithArray:singleChars];
    }
    // a command is a string of all upper and lower case characters.
    NSMutableString* mutable = [NSMutableString string];
    while([self hasCharacters]) {
        unichar ch = [self getNextCharacter];
        // Single char commands
        if (mutable.length == 0 && [singleCharCommands containsObject:@(ch)]) {
            // These are single char commands.
            [mutable appendString:[NSString stringWithCharacters:&ch length:1]];
            break;
        } else if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
            [mutable appendString:[NSString stringWithCharacters:&ch length:1]];
        } else {
            // we went too far
            [self unlookCharacter];
            break;
        }
    }
    return mutable;
}

- (NSString*) readDelimiter
{
    while([self hasCharacters]) {
        unichar ch = [self getNextCharacter];
        // Ignore spaces and nonascii.
        if (ch < 0x21 || ch > 0x7E) {
            // skip non ascii characters and spaces
            continue;
        } else if (ch == '\\') {
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

- (NSString*) getDelimiterValue:(NSString*) delimiterType
{
    NSString* delim = [self readDelimiter];
    if (!delim) {
        NSString* errorMessage = [NSString stringWithFormat:@"Missing delimiter for \\%@", delimiterType];
        [self setError:MTParseErrorMissingDelimiter message:errorMessage];
        return nil;
    }
    NSDictionary<NSString*, NSString*>* delims = [MTMathListBuilder delimiters];
    NSString* delimValue = delims[delim];
    if (!delimValue) {
        NSString* errorMessage = [NSString stringWithFormat:@"Invalid delimiter for \\%@: %@", delimiterType, delim];
        [self setError:MTParseErrorInvalidDelimiter message:errorMessage];
        return nil;
    }
    return delimValue;
}

- (NSString*) accentForCommand:(NSString*) command
{
    NSDictionary<NSString*, NSString*> *accents = [MTMathListBuilder accents];
    return accents[command];
}

- (MTMathAtom*) atomForCommand:(NSString*) command
{
    NSDictionary* aliases = [MTMathListBuilder aliases];
    // First check if this is an alias
    NSString* canonicalCommand = aliases[command];
    if (canonicalCommand) {
        // Switch to the canonical command
        command = canonicalCommand;
    }
    MTMathAtom* atom = [MTMathAtomFactory atomForLatexSymbol:command];
    if (atom) {
        return atom;
    }
    NSString* accent = [self accentForCommand:command];
    if (accent) {
        MTAccent* accentAtom = [[MTAccent alloc] initWithValue:accent];
        accentAtom.innerList = [self buildInternal:true];
        return accentAtom;
    } else if ([command isEqualToString:@"frac"]) {
        // A fraction command has 2 arguments
        MTFraction* frac = [MTFraction new];
        frac.numerator = [self buildInternal:true];
        frac.denominator = [self buildInternal:true];
        return frac;
    } else if ([command isEqualToString:@"binom"]) {
        // A binom command has 2 arguments
        MTFraction* frac = [[MTFraction alloc] initWithRule:NO];
        frac.numerator = [self buildInternal:true];
        frac.denominator = [self buildInternal:true];
        frac.leftDelimiter = @"(";
        frac.rightDelimiter = @")";
        return frac;
    } else if ([command isEqualToString:@"sqrt"]) {
        // A sqrt command with one argument
        MTRadical* rad = [MTRadical new];
        unichar ch = [self getNextCharacter];
        if (ch == '[') {
            // special handling for sqrt[degree]{radicand}
            rad.degree = [self buildInternal:false stopChar:']'];
            rad.radicand = [self buildInternal:true];
        } else {
            [self unlookCharacter];
            rad.radicand = [self buildInternal:true];
        }
        return rad;
    } else if ([command isEqualToString:@"left"]) {
        NSString* delim = [self getDelimiterValue:@"left"];
        if (!delim) {
            return nil;
        }
        // Save the current inner while a new one gets built.
        MTInner* oldInner = _currentInnerAtom;
        _currentInnerAtom = [MTInner new];
        _currentInnerAtom.leftBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:delim];
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
        NSString* errorMessage = [NSString stringWithFormat:@"Invalid command \\%@", command];
        [self setError:MTParseErrorInvalidCommand message:errorMessage];
        return nil;
    }
}

- (MTMathList*) stopCommand:(NSString*) command list:(MTMathList*) list stopChar:(unichar) stopChar
{
    static NSDictionary<NSString*, NSArray*>* fractionCommands = nil;
    if (!fractionCommands) {
        fractionCommands = @{ @"over" : @[],
                              @"atop" : @[],
                              @"choose" : @[ @"(", @")"],
                              @"brack" : @[ @"[", @"]"],
                              @"brace" : @[ @"{", @"}"]};
    }
    if ([command isEqualToString:@"right"]) {
        NSString* delim = [self getDelimiterValue:@"right"];
        if (!delim) {
            return nil;
        }
        if (!_currentInnerAtom) {
            NSString* errorMessage = @"Missing \\left";
            [self setError:MTParseErrorMissingLeft message:errorMessage];
            return nil;
        }
        _currentInnerAtom.rightBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:delim];
        // return the list read so far.
        return list;
    } else if ([fractionCommands objectForKey:command]) {
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
        return fracList;
    }
    return nil;
}

- (void) setError:(MTParseErrors) code message:(NSString*) message
{
    // Only record the first error.
    if (!_error) {
        _error = [NSError errorWithDomain:MTParseError code:code userInfo:@{ NSLocalizedDescriptionKey : message }];
    }
}

+ (NSDictionary*) supportedCommands
{
    static NSDictionary* commands = nil;
    if (!commands) {
        commands = @{
                      @"square" : [MTMathAtomFactory placeholder],
                      
                      // Greek characters
                      @"alpha" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B1"],
                      @"beta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B2"],
                      @"gamma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B3"],
                      @"delta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B4"],
                      @"varepsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B5"],
                      @"zeta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B6"],
                      @"eta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B7"],
                      @"theta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B8"],
                      @"iota" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B9"],
                      @"kappa" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BA"],
                      @"lambda" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BB"],
                      @"mu" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BC"],
                      @"nu" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BD"],
                      @"xi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BE"],
                      @"omicron" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BF"],
                      @"pi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C0"],
                      @"rho" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C1"],
                      @"varsigma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C1"],
                      @"sigma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C3"],
                      @"tau" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C4"],
                      @"upsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C5"],
                      @"varphi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C6"],
                      @"chi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C7"],
                      @"psi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C8"],
                      @"omega" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C9"],
                      // We mark the following greek chars as ordinary so that we don't try
                      // to automatically italicize them as we do with variables.
                      // These characters fall outside the rules of italicization that we have defined.
                      @"epsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\U0001D716"],
                      @"vartheta" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\U0001D717"],
                      @"phi" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\U0001D719"],
                      @"varrho" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\U0001D71A"],
                      @"varpi" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\U0001D71B"],

                      // Capital greek characters
                      @"Gamma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0393"],
                      @"Delta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0394"],
                      @"Theta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0398"],
                      @"Lambda" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039B"],
                      @"Xi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039E"],
                      @"Pi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A0"],
                      @"Sigma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A3"],
                      @"Upsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A5"],
                      @"Phi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A6"],
                      @"Psi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A8"],
                      @"Omega" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A9"],

                      // Open
                      @"lceil" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"\u2308"],
                      @"lfloor" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"\u230A"],
                      @"langle" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"\u27E8"],
                      @"lgroup" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"\u27EE"],

                      // Close
                      @"rceil" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"\u2309"],
                      @"rfloor" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"\u230B"],
                      @"rangle" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"\u27E9"],
                      @"rgroup" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"\u27EF"],

                      // Arrows
                      @"leftarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2190"],
                      @"uparrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2191"],
                      @"rightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2192"],
                      @"downarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2193"],
                      @"leftrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2194"],
                      @"updownarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2195"],
                      @"nwarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2196"],
                      @"nearrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2197"],
                      @"searrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2198"],
                      @"swarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2199"],
                      @"mapsto" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u21A6"],
                      @"Leftarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u21D0"],
                      @"Uparrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u21D1"],
                      @"Rightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u21D2"],
                      @"Downarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u21D3"],
                      @"Leftrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u21D4"],
                      @"Updownarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u21D5"],
                      @"longleftarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u27F5"],
                      @"longrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u27F6"],
                      @"longleftrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u27F7"],
                      @"Longleftarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u27F8"],
                      @"Longrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u27F9"],
                      @"Longleftrightarrow" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u27FA"],


                      // Relations
                      @"leq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:MTSymbolLessEqual],
                      @"geq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:MTSymbolGreaterEqual],
                      @"neq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:MTSymbolNotEqual],
                      @"in" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2208"],
                      @"notin" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2209"],
                      @"ni" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u220B"],
                      @"propto" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u221D"],
                      @"mid" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2223"],
                      @"parallel" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2225"],
                      @"sim" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u223C"],
                      @"simeq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2243"],
                      @"cong" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2245"],
                      @"approx" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2248"],
                      @"asymp" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u224D"],
                      @"doteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2250"],
                      @"equiv" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2261"],
                      @"gg" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u226A"],
                      @"ll" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u226B"],
                      @"prec" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u227A"],
                      @"succ" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u227B"],
                      @"subset" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2282"],
                      @"supset" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2283"],
                      @"subseteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2286"],
                      @"supseteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2287"],
                      @"sqsubset" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u228F"],
                      @"sqsupset" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2290"],
                      @"sqsubseteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2291"],
                      @"sqsupseteq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u2292"],
                      @"models" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u22A7"],
                      @"perp" : [MTMathAtom atomWithType:kMTMathAtomRelation value:@"\u27C2"],

                      // operators
                      @"times" : [MTMathAtomFactory times],
                      @"div"   : [MTMathAtomFactory divide],
                      @"pm"    : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u00B1"],
                      @"dagger" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2020"],
                      @"ddagger" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2021"],
                      @"mp"    : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2213"],
                      @"setminus" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2216"],
                      @"ast"   : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2217"],
                      @"circ"  : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2218"],
                      @"bullet" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2219"],
                      @"wedge" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2227"],
                      @"vee" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2228"],
                      @"cap" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2229"],
                      @"cup" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u222A"],
                      @"wr" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2240"],
                      @"uplus" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u228E"],
                      @"sqcap" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2293"],
                      @"sqcup" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2294"],
                      @"oplus" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2295"],
                      @"ominus" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2296"],
                      @"otimes" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2297"],
                      @"oslash" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2298"],
                      @"odot" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2299"],
                      @"star"  : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u22C6"],
                      @"cdot"  : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u22C5"],
                      @"amalg" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2A3F"],

                      // No limit operators
                      @"log" : [MTMathAtomFactory operatorWithName:@"log" limits:NO],
                      @"lg" : [MTMathAtomFactory operatorWithName:@"lg" limits:NO],
                      @"ln" : [MTMathAtomFactory operatorWithName:@"ln" limits:NO],
                      @"sin" : [MTMathAtomFactory operatorWithName:@"sin" limits:NO],
                      @"arcsin" : [MTMathAtomFactory operatorWithName:@"arcsin" limits:NO],
                      @"sinh" : [MTMathAtomFactory operatorWithName:@"sinh" limits:NO],
                      @"cos" : [MTMathAtomFactory operatorWithName:@"cos" limits:NO],
                      @"arccos" : [MTMathAtomFactory operatorWithName:@"arccos" limits:NO],
                      @"cosh" : [MTMathAtomFactory operatorWithName:@"cosh" limits:NO],
                      @"tan" : [MTMathAtomFactory operatorWithName:@"tan" limits:NO],
                      @"arctan" : [MTMathAtomFactory operatorWithName:@"arctan" limits:NO],
                      @"tanh" : [MTMathAtomFactory operatorWithName:@"tanh" limits:NO],
                      @"cot" : [MTMathAtomFactory operatorWithName:@"cot" limits:NO],
                      @"coth" : [MTMathAtomFactory operatorWithName:@"coth" limits:NO],
                      @"sec" : [MTMathAtomFactory operatorWithName:@"sec" limits:NO],
                      @"csc" : [MTMathAtomFactory operatorWithName:@"csc" limits:NO],
                      @"arg" : [MTMathAtomFactory operatorWithName:@"arg" limits:NO],
                      @"ker" : [MTMathAtomFactory operatorWithName:@"ker" limits:NO],
                      @"dim" : [MTMathAtomFactory operatorWithName:@"dim" limits:NO],
                      @"hom" : [MTMathAtomFactory operatorWithName:@"hom" limits:NO],
                      @"exp" : [MTMathAtomFactory operatorWithName:@"exp" limits:NO],
                      @"deg" : [MTMathAtomFactory operatorWithName:@"deg" limits:NO],

                      // Limit operators
                      @"lim" : [MTMathAtomFactory operatorWithName:@"lim" limits:YES],
                      @"limsup" : [MTMathAtomFactory operatorWithName:@"lim sup" limits:YES],
                      @"liminf" : [MTMathAtomFactory operatorWithName:@"lim inf" limits:YES],
                      @"max" : [MTMathAtomFactory operatorWithName:@"max" limits:YES],
                      @"min" : [MTMathAtomFactory operatorWithName:@"min" limits:YES],
                      @"sup" : [MTMathAtomFactory operatorWithName:@"sup" limits:YES],
                      @"inf" : [MTMathAtomFactory operatorWithName:@"inf" limits:YES],
                      @"det" : [MTMathAtomFactory operatorWithName:@"det" limits:YES],
                      @"Pr" : [MTMathAtomFactory operatorWithName:@"Pr" limits:YES],
                      @"gcd" : [MTMathAtomFactory operatorWithName:@"gcd" limits:YES],

                      // Large operators
                      @"prod" : [MTMathAtomFactory operatorWithName:@"\u220F" limits:YES],
                      @"coprod" : [MTMathAtomFactory operatorWithName:@"\u2210" limits:YES],
                      @"sum" : [MTMathAtomFactory operatorWithName:@"\u2211" limits:YES],
                      @"int" : [MTMathAtomFactory operatorWithName:@"\u222B" limits:NO],
                      @"oint" : [MTMathAtomFactory operatorWithName:@"\u222E" limits:NO],
                      @"bigwedge" : [MTMathAtomFactory operatorWithName:@"\u22C0" limits:YES],
                      @"bigvee" : [MTMathAtomFactory operatorWithName:@"\u22C1" limits:YES],
                      @"bigcap" : [MTMathAtomFactory operatorWithName:@"\u22C2" limits:YES],
                      @"bigcup" : [MTMathAtomFactory operatorWithName:@"\u22C3" limits:YES],
                      @"bigodot" : [MTMathAtomFactory operatorWithName:@"\u2A00" limits:YES],
                      @"bigoplus" : [MTMathAtomFactory operatorWithName:@"\u2A01" limits:YES],
                      @"bigotimes" : [MTMathAtomFactory operatorWithName:@"\u2A02" limits:YES],
                      @"biguplus" : [MTMathAtomFactory operatorWithName:@"\u2A04" limits:YES],
                      @"bigsqcup" : [MTMathAtomFactory operatorWithName:@"\u2A06" limits:YES],

                      // Latex command characters
                      @"{" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"{"],
                      @"}" : [MTMathAtom atomWithType:kMTMathAtomClose value:@"}"],
                      @"$" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"{"],
                      @"&" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"&"],
                      @"#" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"#"],
                      @"%" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"%"],
                      @"_" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"_"],
                      @" " : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@" "],
                      @"backslash" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\\"],

                      // Punctuation
                      // Note: \colon is different from : which is a relation
                      @"colon" : [MTMathAtom atomWithType:kMTMathAtomPunctuation value:@":"],
                      @"cdotp" : [MTMathAtom atomWithType:kMTMathAtomPunctuation value:@"\u00B7"],

                      // Other symbols
                      @"degree" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u00B0"],
                      @"neg" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u00AC"],
                      @"|" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2016"],
                      @"vert" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"|"],
                      @"prime" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2032"],
                      @"ldots" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2026"],
                      @"prime" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2032"],
                      @"hbar" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u210F"],
                      @"Im" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2111"],
                      @"ell" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2113"],
                      @"wp" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2118"],
                      @"Re" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u211C"],
                      @"aleph" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2135"],
                      @"forall" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2200"],
                      @"exists" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2203"],
                      @"emptyset" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2205"],
                      @"nabla" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2207"],
                      @"infty" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u221E"],
                      @"angle" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2220"],
                      @"top" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u22A4"],
                      @"bot" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u22A5"],
                      @"vdots" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u22EE"],
                      @"cdots" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u22EF"],
                      @"ddots" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u22F1"],
                      @"triangle" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u25B3"],
                      @"imath" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\U0001D6A4"],
                      @"jmath" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\U0001D6A5"],
                      @"partial" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\U0001D715"],
                      
                      // Spacing
                      @"," : [[MTMathSpace alloc] initWithSpace:3],
                      @">" : [[MTMathSpace alloc] initWithSpace:4],
                      @";" : [[MTMathSpace alloc] initWithSpace:5],
                      @"!" : [[MTMathSpace alloc] initWithSpace:-3],
                      @"quad" : [[MTMathSpace alloc] initWithSpace:18],  // quad = 1em = 18mu
                      @"qquad" : [[MTMathSpace alloc] initWithSpace:36], // qquad = 2em
                      };
        
    }
    return commands;
}

+ (NSDictionary*) aliases
{
    static NSDictionary* aliases = nil;
    if (!aliases) {
        aliases = @{
                     @"lnot" : @"neg",
                     @"land" : @"wedge",
                     @"lor" : @"vee",
                     @"ne" : @"neq",
                     @"le" : @"leq",
                     @"ge" : @"geq",
                     @"lbrace" : @"{",
                     @"rbrace" : @"}",
                     @"Vert" : @"|",
                     @"gets" : @"leftarrow",
                     @"to" : @"rightarrow",
                     @"iff" : @"Longleftrightarrow",
                     };
    }
    return aliases;
}

+ (NSDictionary<NSString*, NSString*>*) accents
{
    static NSDictionary* accents = nil;
    if (!accents) {
        accents = @{
                    @"grave" : @"\u0300",
                    @"acute" : @"\u0301",
                    @"hat" : @"\u0302",  // In our implementation hat and widehat behave the same.
                    @"tilde" : @"\u0303", // In our implementation tilde and widetilde behave the same.
                    @"bar" : @"\u0304",
                    @"breve" : @"\u0306",
                    @"dot" : @"\u0307",
                    @"ddot" : @"\u0308",
                    @"check" : @"\u030C",
                    @"vec" : @"\u20D7",
                    @"widehat" : @"\u0302",
                    @"widetilde" : @"\u0303",
                    };
    }
    return accents;
}

+(NSDictionary<NSString*, NSString*> *) delimiters
{
    static NSDictionary* delims = nil;
    if (!delims) {
        delims = @{
                   @"." : @"", // . means no delimiter
                   @"(" : @"(",
                   @")" : @")",
                   @"[" : @"[",
                   @"]" : @"]",
                   @"<" : @"\u2329",
                   @">" : @"\u232A",
                   @"/" : @"/",
                   @"\\" : @"\\",
                   @"|" : @"|",
                   @"lgroup" : @"\u27EE",
                   @"rgroup" : @"\u27EF",
                   @"||" : @"\u2016",
                   @"Vert" : @"\u2016",
                   @"vert" : @"|",
                   @"uparrow" : @"\u2191",
                   @"downarrow" : @"\u2193",
                   @"updownarrow" : @"\u2195",
                   @"Uparrow" : @"21D1",
                   @"Downarrow" : @"21D3",
                   @"Updownarrow" : @"21D5",
                   @"backslash" : @"\\",
                   @"rangle" : @"\u232A",
                   @"langle" : @"\u2329",
                   @"rbrace" : @"}",
                   @"}" : @"}",
                   @"{" : @"{",
                   @"lbrace" : @"{",
                   @"lceil" : @"\u2308",
                   @"rceil" : @"\u2309",
                   @"lfloor" : @"\u230A",
                   @"rfloor" : @"\u230B",
                   };
    }
    return delims;
}

+ (NSDictionary*) textToCommands
{
    static NSDictionary* textToCommands = nil;
    if (!textToCommands) {
        NSDictionary* commands = [self supportedCommands];
        NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithCapacity:commands.count];
        for (NSString* command in commands) {
            MTMathAtom* atom = commands[command];
            mutableDict[atom.nucleus] = command;
        }
        textToCommands = [mutableDict copy];
    }
    return textToCommands;
}

+ (NSDictionary*) delimToCommand
{
    static NSDictionary* delimToCommands = nil;
    if (!delimToCommands) {
        NSDictionary* delims = [self delimiters];
        NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithCapacity:delims.count];
        for (NSString* command in delims) {
            NSString* delim = delims[command];
            NSString* existingCommand = mutableDict[delim];
            if (existingCommand) {
                if (command.length > existingCommand.length) {
                    // Keep the shorter command
                    continue;
                } else if (command.length == existingCommand.length) {
                    // If the length is the same, keep the alphabetically first
                    if ([command compare:existingCommand] == NSOrderedDescending) {
                        continue;
                    }
                }
            }
            // In other cases replace the command.
            mutableDict[delim] = command;
        }
        delimToCommands = [mutableDict copy];
    }
    return delimToCommands;
}

+ (NSDictionary*) accentToCommands
{
    static NSDictionary* accentToCommands = nil;
    if (!accentToCommands) {
        NSDictionary* accents = [self accents];
        NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithCapacity:accents.count];
        for (NSString* command in accents) {
            NSString* acc = accents[command];
            NSString* existingCommand = mutableDict[acc];
            if (existingCommand) {
                if (command.length > existingCommand.length) {
                    // Keep the shorter command
                    continue;
                } else if (command.length == existingCommand.length) {
                    // If the length is the same, keep the alphabetically first
                    if ([command compare:existingCommand] == NSOrderedDescending) {
                        continue;
                    }
                }
            }
            // In other cases replace the command.
            mutableDict[acc] = command;
        }
        accentToCommands = [mutableDict copy];
    }
    return accentToCommands;
}

+ (NSDictionary*) spaceToCommands
{
    static NSDictionary* spaceToCommands = nil;
    if (!spaceToCommands) {
        spaceToCommands = @{
                            @3 : @",",
                            @4 : @">",
                            @5 : @";",
                            @(-3) : @"!",
                            @18 : @"quad",
                            @36 : @"qquad",
                    };
    }
    return spaceToCommands;
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

+ (NSString*) delimToString:(NSString*) delim
{
    NSString* command = self.delimToCommand[delim];
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
    NSDictionary* textToCommands = [self textToCommands];
    NSMutableString* str = [NSMutableString string];
    for (MTMathAtom* atom in ml.atoms) {
        if (atom.type == kMTMathAtomFraction) {
            MTFraction* frac = (MTFraction*) atom;
            if (frac.hasRule) {
                [str appendFormat:@"\\frac{%@}{%@}", [self mathListToString:frac.numerator], [self mathListToString:frac.denominator]];
            } else {
                NSString* command = nil;
                if (!frac.leftDelimiter && !frac.rightDelimiter) {
                    command = @"atop";
                } else if ([frac.leftDelimiter isEqualToString:@"("] && [frac.rightDelimiter isEqualToString:@")"]) {
                    command = @"choose";
                } else if ([frac.leftDelimiter isEqualToString:@"{"] && [frac.rightDelimiter isEqualToString:@"}"]) {
                    command = @"brace";
                } else if ([frac.leftDelimiter isEqualToString:@"["] && [frac.rightDelimiter isEqualToString:@"]"]) {
                    command = @"brack";
                } else {
                    command = [NSString stringWithFormat:@"atopwithdelims%@%@", frac.leftDelimiter, frac.rightDelimiter];
                }
                [str appendFormat:@"{%@ \\%@ %@}", [self mathListToString:frac.numerator], command, [self mathListToString:frac.denominator]];
            }
        } else if (atom.type == kMTMathAtomRadical) {
            [str appendString:@"\\sqrt"];
            MTRadical* rad = (MTRadical*) atom;
            if (rad.degree) {
                [str appendFormat:@"[%@]", [self mathListToString:rad.degree]];
            }
            [str appendFormat:@"{%@}", [self mathListToString:rad.radicand]];
        } else if (atom.type == kMTMathAtomInner) {
            MTInner* inner = (MTInner*) atom;
            if (inner.leftBoundary || inner.rightBoundary) {
                if (inner.leftBoundary) {
                    [str appendFormat:@"\\left%@ ", [self delimToString:inner.leftBoundary.nucleus]];
                } else {
                    [str appendString:@"\\left. "];
                }
                [str appendString:[self mathListToString:inner.innerList]];
                if (inner.rightBoundary) {
                    [str appendFormat:@"\\right%@ ", [self delimToString:inner.rightBoundary.nucleus]];
                } else {
                    [str appendString:@"\\right. "];
                }
            } else {
                [str appendFormat:@"{%@}", [self mathListToString:inner.innerList]];
            }
        } else if (atom.type == kMTMathAtomOverline) {
            [str appendString:@"\\overline"];
            MTOverLine* over = (MTOverLine*) atom;
            [str appendFormat:@"{%@}", [self mathListToString:over.innerList]];
        } else if (atom.type == kMTMathAtomUnderline) {
            [str appendString:@"\\underline"];
            MTUnderLine* under = (MTUnderLine*) atom;
            [str appendFormat:@"{%@}", [self mathListToString:under.innerList]];
        } else if (atom.type == kMTMathAtomAccent) {
            MTAccent* accent = (MTAccent*) atom;
            NSDictionary* accentToCommands = [MTMathListBuilder accentToCommands];
            [str appendFormat:@"\\%@{%@}", accentToCommands[accent.nucleus], [self mathListToString:accent.innerList]];
        } else if (atom.type == kMTMathAtomSpace) {
            MTMathSpace* space = (MTMathSpace*) atom;
            NSDictionary* spaceToCommands = [MTMathListBuilder spaceToCommands];
            NSString* command = spaceToCommands[@(space.space)];
            if (command) {
                [str appendFormat:@"\\%@ ", command];
            } else {
                [str appendFormat:@"\\mkern%.1fmu", space.space];
            }
        } else if (atom.nucleus.length == 0) {
            [str appendString:@"{}"];
        } else if ([atom.nucleus isEqualToString:@"\u2236"]) {
            // math colon
            [str appendString:@":"];
        } else if ([atom.nucleus isEqualToString:@"\u2212"]) {
            // math minus
            [str appendString:@"-"];
        } else {
            NSString* command = textToCommands[atom.nucleus];
            if (command) {
                [str appendFormat:@"\\%@ ", command];
            } else {
                [str appendString:atom.nucleus];
            }
        }
        
        if (atom.superScript) {
            [str appendFormat:@"^{%@}", [self mathListToString:atom.superScript]];
        }
        
        if (atom.subScript) {
            [str appendFormat:@"_{%@}", [self mathListToString:atom.subScript]];
        }
    }
    return [str copy];
}

@end
