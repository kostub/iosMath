//
//  MathList.h
//  iosMath
//
//  Created by Kostub Deshmukh on 8/26/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

@class MTMathList;

@interface MTMathAtom : NSObject<NSCopying>

typedef enum
{
    kMTMathAtomOrdinary = 0,       // A number or text in ordinary format - Ord in TeX
    kMTMathAtomNumber,             // A number
    kMTMathAtomVariable,           // A variable (i.e. text in italic format)
    kMTMathAtomLargeOperator,      // A large operator such as (sin/cos, integral etc.) - Op in TeX
    kMTMathAtomBinaryOperator,     // A binary operator - Bin in TeX
    kMTMathAtomUnaryOperator,      // A unary operator
    kMTMathAtomRelation,           // A relation, e.g. = > < etc. - Rel in TeX
    kMTMathAtomOpen,               // Open brackets - Open in TeX
    kMTMathAtomClose,              // Close brackets - Close in TeX
    kMTMathAtomFraction,           // An inner fraction e.g 1/2 - Inner in TeX
    kMTMathAtomRadical,            // A radical operator e.g. sqrt(2)
    kMTMathAtomPunctuation,        // Punctuation such as , - Punct in TeX
    kMTMathAtomPlaceholder,        // A placeholder square for future input
} MTMathAtomType;

+ (instancetype) atomWithType: (MTMathAtomType) type value:(NSString*) value;

- (NSString*) stringValue;

@property (nonatomic) MTMathAtomType type;
@property (nonatomic, copy) NSString* nucleus;
@property (nonatomic) MTMathList* superScript;
@property (nonatomic) MTMathList* subScript;

// If this atom was formed by fusion of multiple atoms, then this stores the list of atoms that were fused to create this one.
// This is ued in the finalizing and preprocessing steps.
@property (nonatomic, readonly) NSArray* fusedAtoms;

// The index range in the MTMathList this MTMathAtom tracks. This is used by the finalizing and preprocessing steps
// which fuse MTMathAtoms to track the position of the current MTMathAtom in the original list.
@property (nonatomic, readonly) NSRange indexRange;

// Fuse the given atom with this one by combining their nucleii.
- (void) fuse:(MTMathAtom*) atom;

// Makes a deep copy of the atom
- (id)copyWithZone:(NSZone *)zone;

@end

@interface MTFraction : MTMathAtom

@property (nonatomic) MTMathList* numerator;
@property (nonatomic) MTMathList* denominator;

@end

@interface MTRadical : MTMathAtom

// Denotes the term under the square root sign
@property (nonatomic) MTMathList* radicand;

// Denotes the degree of the radical, i.e. the value to the top left of the radical sign
// This can be null if there is no degree.
@property (nonatomic) MTMathList* degree;

@end

// A representation of a list of math objects. This list can be constructed directly or built with
// the help of the MTMathListBuilder. It is not required that the mathematics represented make sense
// (i.e. this can represent something like "x 2 = +". This list can be used for display using MTLine
// or can be a list of tokens to be used by a parser after finalizedMathList is called.
@interface MTMathList : NSObject<NSCopying>

// A list of MathAtoms
@property (nonatomic, readonly) NSArray* atoms;

- (void) addAtom:(MTMathAtom*) atom;

- (void) insertAtom:(MTMathAtom *)atom atIndex:(NSUInteger) index;

// deletes the last atom from the list
- (void) removeLastAtom;
- (void) removeAtomAtIndex:(NSUInteger) index;
- (void) removeAtomsInRange:(NSRange) range;

// converts the MTMathList to a string form
- (NSString*) stringValue;

// Create a new math list as a final expression and update atoms
// by combining like atoms that occur together and converting unary operators to binary operators.
// This function does not modify the current MTMathList
- (MTMathList*) finalized;

// Makes a deep copy of the list
- (id)copyWithZone:(NSZone *)zone;

@end
