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


static NSSet* kRelations = nil;
NSString *const MTParseError = @"ParseError";

static void initializeGlobalsIfNeeded() {
    if (!kRelations) {
        kRelations = [NSSet setWithObjects:@"=", @">", @"<", @":", nil];  // colon is here because tex does that
    }
}
@implementation MTMathListBuilder {
    unichar* _chars;
    int _currentChar;
    NSUInteger _length;
}

- (id)initWithString:(NSString *)str
{
    self = [super init];
    if (self) {
        _error = nil;
        initializeGlobalsIfNeeded();
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
    MTMathList* list = [MTMathList new];
    [self buildInternal:list oneCharOnly:false];
    if ([self hasCharacters] && !_error) {
        // something went wrong most likely braces mismatched
        NSLog(@"Mismatched braces: %@", [NSString stringWithCharacters:_chars length:_length]);
        _error = [NSError errorWithDomain:MTParseError code:MTParseErrorMismatchBraces userInfo:nil];
    }
    if (_error) {
        return nil;
    }
    return list;
}

- (void)buildInternal:(MTMathList*) list oneCharOnly:(BOOL) oneCharOnly
{
    [self buildInternal:list oneCharOnly:oneCharOnly stopChar:0];
}

- (void)buildInternal:(MTMathList*) list oneCharOnly:(BOOL) oneCharOnly stopChar:(unichar) stop
{
    NSAssert(!(oneCharOnly && (stop > 0)), @"Cannot set both oneCharOnly and stopChar.");
    MTMathAtom* prevAtom = nil;
    while([self hasCharacters]) {
        MTMathAtom* atom = nil;
        unichar ch = [self getNextCharacter];
        NSString *chStr = [NSString stringWithCharacters:&ch length:1];
        if (oneCharOnly) {
            if (ch == '^' || ch == '}' || ch == '_') {
                // this is not the character we are looking for.
                // They are meant for the caller to look at.
                [self unlookCharacter];
                return;
            }
        }
        // If there is a stop character, keep scanning till we find it
        if (stop > 0 && ch == stop) {
            return;
        }
        
        if (ch < 0x21 || ch > 0x7E) {
            // skip non ascii characters and spaces
            continue;
        } else if (ch == '^') {
            NSAssert(!oneCharOnly, @"This should have been handled before");
            
            if (!prevAtom) {
                // add an empty node
                prevAtom = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@""];
                [list addAtom:prevAtom];
            }
            // this is a superscript for the previous atom
            if (!prevAtom.superScript) {
                MTMathList* superScript = [MTMathList new];
                prevAtom.superScript = superScript;
            }
            // note: if the next char is the stopChar it will be consumed by the ^ and so it doesn't count as stop
            [self buildInternal:prevAtom.superScript oneCharOnly:true];
            continue;
        } else if (ch == '_') {
            NSAssert(!oneCharOnly, @"This should have been handled before");
            
            if (!prevAtom) {
                // add an empty node
                prevAtom = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@""];
                [list addAtom:prevAtom];
            }
            // this is a subscript for the previous atom
            if (!prevAtom.subScript) {
                MTMathList* subScript = [MTMathList new];
                prevAtom.subScript = subScript;
            }
            // note: if the next char is the stopChar it will be consumed by the _ and so it doesn't count as stop
            [self buildInternal:prevAtom.subScript oneCharOnly:true];
            continue;
        } else if (ch == '{') {
            // this puts us in a recursive routine, and sets oneCharOnly to false and no stop character
            [self buildInternal:list oneCharOnly:false];
            if (oneCharOnly) {
                return;
            }
            continue;
        } else if (ch == '}') {
            NSAssert(!oneCharOnly, @"This should have been handled before");
            return;
        } else if (ch == '\\') {
            // \ means a command
            NSString* command = [self readCommand];
            atom = [self atomForCommand:command];
            if (atom == nil) {
                // this was an unknown command,
                // we flag an error and return.
                return;
            }
        } else if (ch == '$' || ch == '%' || ch == '#' || ch == '&' || ch == '~' || ch == '\'') {
            // These are latex control characters that have special meanings. We don't support them.
            continue;
        } else if (ch == '(' || ch == '[') {
            atom = [MTMathAtom atomWithType:kMTMathAtomOpen value:chStr];
        } else if (ch == ')' || ch == ']') {
            atom = [MTMathAtom atomWithType:kMTMathAtomClose value:chStr];
        } else if (ch == ',' || ch == ';') {
            atom = [MTMathAtom atomWithType:kMTMathAtomPunctuation value:chStr];
        } else if ([kRelations containsObject:chStr]) {
            atom = [MTMathAtom atomWithType:kMTMathAtomRelation value:chStr];
        } else if (ch == '+' || ch == '-' || ch == '*') {
            atom = [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:chStr];
        } else if (ch == '.' || (ch >= '0' && ch <= '9')) {
            atom = [MTMathAtom atomWithType:kMTMathAtomNumber value:chStr];
        } else if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
            atom = [MTMathAtom atomWithType:kMTMathAtomVariable value:chStr];
        } else if (ch == '!' || ch == '"' || ch == '/' || ch == '?' || ch == '@' || ch == '`' || ch == '|') {
            // just an ordinary character. The following are allowed ordinary chars
            // ! ? | / ` @ "
            atom = [MTMathAtom atomWithType:kMTMathAtomOrdinary value:chStr];
        } else {
            NSAssert(false, @"Unknown ascii character %@. Should have been accounted for.", @(ch));
        }
        NSAssert(atom, @"Atom shouldn't be nil");
        [list addAtom:atom];
        prevAtom = atom;
        
        if (oneCharOnly) {
            // we consumed our onechar
            return;
        }
    }
    if (stop > 0) {
        // we never found our stop character
        NSLog(@"Expected character not found: %d", stop);
        _error = [NSError errorWithDomain:MTParseError code:MTParseErrorCharacterNotFound userInfo:nil];
    }
}

- (NSString*) readCommand
{
    // a command is a string of all lowercase characters.
    NSMutableString* mutable = [NSMutableString string];
    while([self hasCharacters]) {
        unichar ch = [self getNextCharacter];
        // Single char commands
        if (mutable.length == 0 && (ch == '{' || ch == '}' || ch == '$' || ch == '&' || ch == '#' || ch == '%' || ch == '_')) {
            // These are single char commands.
            [mutable appendString:[NSString stringWithCharacters:&ch length:1]];
            break;
        } else if (ch >= 'a' && ch <= 'z') {
            [mutable appendString:[NSString stringWithCharacters:&ch length:1]];
        } else {
            // we went too far
            [self unlookCharacter];
            break;
        }
    }
    return mutable;
}

- (MTMathAtom*) atomForCommand:(NSString*) command
{
    NSDictionary* commands = [MTMathListBuilder supportedCommands];
    MTMathAtom* atom = commands[command];
    if (atom) {
        // Return a copy of the atom since atoms are mutable.
        return [atom copy];
    } else if ([command isEqualToString:@"frac"]) {
        // A fraction command has 2 arguments
        MTFraction* frac = [MTFraction new];
        frac.numerator = [MTMathList new];
        frac.denominator = [MTMathList new];
        [self buildInternal:frac.numerator oneCharOnly:true];
        [self buildInternal:frac.denominator oneCharOnly:true];
        return frac;
    } else if ([command isEqualToString:@"sqrt"]) {
        // A sqrt command with one argument
        MTRadical* rad = [MTRadical new];
        rad.radicand = [MTMathList new];
        unichar ch = [self getNextCharacter];
        if (ch == '[') {
            // special handling for sqrt[degree]{radicand}
            rad.degree = [MTMathList new];
            [self buildInternal:rad.degree oneCharOnly:false stopChar:']'];
            [self buildInternal:rad.radicand oneCharOnly:true];
        } else {
            [self unlookCharacter];
            [self buildInternal:rad.radicand oneCharOnly:true];
        }
        return rad;
    } else {
        NSLog(@"Invalid command %@", command);
        _error = [NSError errorWithDomain:MTParseError code:MTParseErrorInvalidCommand userInfo:nil];
        return nil;
    }
}

+ (NSDictionary*) supportedCommands
{
    static NSDictionary* commands = nil;
    if (!commands) {
        commands = @{
                      @"square" : [MTMathAtomFactory placeholder],
                      
                      // Other symbols
                      @"infty" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u221E"],
                      @"angle" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u2220"],
                      @"degree" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\u00B0"],
                      
                      // Greek characters
                      @"alpha" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B1"],
                      @"beta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B2"],
                      @"gamma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B3"],
                      @"delta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B4"],
                      @"epsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B5"],
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
                      @"sigma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C2"],
                      @"tau" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C3"],
                      @"upsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C4"],
                      @"phi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C5"],
                      @"chi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C6"],
                      @"psi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C7"],
                      @"omega" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C8"],
                      
                      // Capital greek characters
                      @"Alpha" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0391"],
                      @"Beta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0392"],
                      @"Gamma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0393"],
                      @"Delta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0394"],
                      @"Epsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0395"],
                      @"Zeta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0396"],
                      @"Eta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0397"],
                      @"Theta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0398"],
                      @"Iota" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0399"],
                      @"Kappa" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039A"],
                      @"Lambda" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039B"],
                      @"Mu" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039C"],
                      @"Nu" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039D"],
                      @"Xi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039E"],
                      @"Omicron" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039F"],
                      @"Pi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A0"],
                      @"Rho" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A1"],
                      @"Sigma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A3"],
                      @"Tau" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A4"],
                      @"Upsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A5"],
                      @"Phi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A6"],
                      @"Chi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A7"],
                      @"Psi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A8"],
                      @"Omega" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A9"],
                      
                      // Relations
                      @"leq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:MTSymbolLessEqual],
                      @"geq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:MTSymbolGreaterEqual],
                      @"ne"  : [MTMathAtom atomWithType:kMTMathAtomRelation value:MTSymbolNotEqual],
                      @"neq" : [MTMathAtom atomWithType:kMTMathAtomRelation value:MTSymbolNotEqual],
                      // operators
                      @"times" : [MTMathAtomFactory times],
                      @"div"   : [MTMathAtomFactory divide],
                      // No limit operators
                      @"log" : [MTMathAtomFactory operatorWithName:@"log"],
                      @"lg" : [MTMathAtomFactory operatorWithName:@"lg"],
                      @"ln" : [MTMathAtomFactory operatorWithName:@"ln"],
                      @"sin" : [MTMathAtomFactory operatorWithName:@"sin"],
                      @"arcsin" : [MTMathAtomFactory operatorWithName:@"arcsin"],
                      @"sinh" : [MTMathAtomFactory operatorWithName:@"sinh"],
                      @"cos" : [MTMathAtomFactory operatorWithName:@"cos"],
                      @"arccos" : [MTMathAtomFactory operatorWithName:@"arccos"],
                      @"cosh" : [MTMathAtomFactory operatorWithName:@"cosh"],
                      @"tan" : [MTMathAtomFactory operatorWithName:@"tan"],
                      @"arctan" : [MTMathAtomFactory operatorWithName:@"arctan"],
                      @"tanh" : [MTMathAtomFactory operatorWithName:@"tanh"],
                      @"cot" : [MTMathAtomFactory operatorWithName:@"cot"],
                      @"coth" : [MTMathAtomFactory operatorWithName:@"coth"],
                      @"sec" : [MTMathAtomFactory operatorWithName:@"sec"],
                      @"csc" : [MTMathAtomFactory operatorWithName:@"csc"],
                      // Latex command characters
                      @"{" : [MTMathAtom atomWithType:kMTMathAtomOpen value:@"{"],
                      @"}" : [MTMathAtom atomWithType:kMTMathAtomClose value:@"}"],
                      @"$" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"{"],
                      @"&" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"&"],
                      @"#" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"#"],
                      @"%" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"%"],
                      @"_" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"_"],
                      @"backslash" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\\"],
                      };
        
    }
    return commands;
}

+ (NSDictionary*) textToCommands
{
    static NSDictionary* textToCommands = nil;
    if (!textToCommands) {
        NSDictionary* commands = [self supportedCommands];
        NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithCapacity:commands.count];
        for (NSString* command in commands) {
            MTMathAtom* atom = commands[command];
            [mutableDict setObject:command forKey:atom.nucleus];
        }
        textToCommands = [mutableDict copy];
    }
    return textToCommands;
}

+ (MTMathList *)buildFromString:(NSString *)str
{
    MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:str];
    return builder.build;
}

+ (NSString *)mathListToString:(MTMathList *)ml
{
    NSDictionary* textToCommands = [self textToCommands];
    NSMutableString* str = [NSMutableString string];
    for (MTMathAtom* atom in ml.atoms) {
        NSString* command = textToCommands[atom.nucleus];
        if (command) {
            [str appendFormat:@"\\%@ ", command];
        } else if (atom.type == kMTMathAtomFraction) {
            MTFraction* frac = (MTFraction*) atom;
            [str appendFormat:@"\\frac{%@}{%@}", [self mathListToString:frac.numerator], [self mathListToString:frac.denominator]];
        } else if (atom.type == kMTMathAtomRadical) {
            [str appendString:@"\\sqrt"];
            MTRadical* rad = (MTRadical*) atom;
            if (rad.degree) {
                [str appendFormat:@"[%@]", [self mathListToString:rad.degree]];
            }
            [str appendFormat:@"{%@}", [self mathListToString:rad.radicand]];
        } else {
            [str appendString:atom.nucleus];
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
