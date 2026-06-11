//
//  MathExamples.h
//  Shared LaTeX formula strings for example apps.
//
//  No iosMath imports — this file contains only Foundation strings.
//  Display properties (height, alignment, fontSize, etc.) are the
//  responsibility of each app's view controller.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import <Foundation/Foundation.h>

// Suppress the "possibly missing comma" warning that fires when adjacent string
// literals appear inside an @[] array literal. The concatenation is intentional.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-string-concatenation"

NS_ASSUME_NONNULL_BEGIN

/// Curated real-world mathematical formulae for the main example gallery.
static inline NSArray<NSString*>* MathDemoFormulas(void) {
    return @[
        // 0: Quadratic formula
        @"x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}",
        // 1: Cosine addition formula
        @"\\cos(\\theta + \\varphi) = \\cos(\\theta)\\cos(\\varphi) - \\sin(\\theta)\\sin(\\varphi)",
        // 2: Continued fraction (Rogers–Ramanujan)
        @"\\cfrac{1}{\\left(\\sqrt{\\phi \\sqrt{5}}-\\phi\\right) e^{2\\pi/5}} "
         "= 1+\\cfrac{e^{-2\\pi}} {1 +\\cfrac{e^{-4\\pi}} {1+\\cfrac{e^{-6\\pi}} {1+\\cfrac{e^{-8\\pi}} {1+\\cdots} } } }",
        // 3: Standard deviation
        @"\\sigma = \\sqrt{\\frac{1}{N}\\sum_{i=1}^N (x_i - \\mu)^2}",
        // 4: De Morgan's law
        @"\\neg(P\\land Q) \\iff (\\neg P)\\lor(\\neg Q)",
        // 5: Change of base
        @"\\log_b(x) = \\frac{\\log_a(x)}{\\log_a(b)}",
        // 6: Compound interest limit
        @"\\lim_{x\\to\\infty}\\left(1 + \\frac{k}{x}\\right)^x = e^k",
        // 7: Gaussian integral
        @"\\int_{-\\infty}^\\infty \\! e^{-x^2} dx = \\sqrt{\\pi}",
        // 8: AM-GM inequality
        @"\\frac 1 n \\sum_{i=1}^{n}x_i \\geq \\sqrt[n]{\\prod_{i=1}^{n}x_i}",
        // 9: Cauchy's integral formula
        @"f^{(n)}(z_0) = \\frac{n!}{2\\pi i}\\oint_\\gamma\\frac{f(z)}{(z-z_0)^{n+1}}\\,dz",
        // 10: Schrödinger equation
        @"i\\hbar\\frac{\\partial}{\\partial t}\\mathbf\\Psi(\\mathbf{x},t) = "
         "-\\frac{\\hbar}{2m}\\nabla^2\\mathbf\\Psi(\\mathbf{x},t) + V(\\mathbf{x})\\mathbf\\Psi(\\mathbf{x},t)",
        // 11: Cauchy-Schwarz inequality
        @"\\left(\\sum_{k=1}^n a_k b_k \\right)^2 \\le "
         "\\left(\\sum_{k=1}^n a_k^2\\right)\\left(\\sum_{k=1}^n b_k^2\\right)",
        // 12: Stirling numbers of the second kind
        @"{n \\brace k} = \\frac{1}{k!}\\sum_{j=0}^k (-1)^{k-j}\\binom{k}{j}(k-j)^n",
        // 13: Fourier transform
        @"f(x) = \\int\\limits_{-\\infty}^\\infty\\!\\hat f(\\xi)\\,e^{2 \\pi i \\xi x}\\,\\mathrm{d}\\xi",
        // 14: Lorenz system
        @"\\begin{gather}"
         "\\dot{x} = \\sigma(y-x) \\\\"
         "\\dot{y} = \\rho x - y - xz \\\\"
         "\\dot{z} = -\\beta z + xy"
         "\\end{gather}",
        // 15: Cross product as determinant
        @"\\vec \\bf V_1 \\times \\vec \\bf V_2 =  \\begin{vmatrix}"
         "\\hat \\imath &\\hat \\jmath &\\hat k \\\\"
         "\\frac{\\partial X}{\\partial u} &  \\frac{\\partial Y}{\\partial u} & 0 \\\\"
         "\\frac{\\partial X}{\\partial v} &  \\frac{\\partial Y}{\\partial v} & 0"
         "\\end{vmatrix}",
        // 16: Maxwell's equations
        @"\\begin{eqalign}"
         "\\nabla \\cdot \\vec{\\bf{E}} & = \\frac {\\rho} {\\varepsilon_0} \\\\"
         "\\nabla \\cdot \\vec{\\bf{B}} & = 0 \\\\"
         "\\nabla \\times \\vec{\\bf{E}} &= - \\frac{\\partial\\vec{\\bf{B}}}{\\partial t} \\\\"
         "\\nabla \\times \\vec{\\bf{B}} & = \\mu_0\\vec{\\bf{J}} + \\mu_0\\varepsilon_0 \\frac{\\partial\\vec{\\bf{E}}}{\\partial t}"
         "\\end{eqalign}",
        // 17: 2×2 matrix multiplication
        @"\\begin{pmatrix}a & b\\\\ c & d\\end{pmatrix}"
         "\\begin{pmatrix}\\alpha & \\beta \\\\ \\gamma & \\delta\\end{pmatrix} = "
         "\\begin{pmatrix}a\\alpha + b\\gamma & a\\beta + b \\delta \\\\"
         "c\\alpha + d\\gamma & c\\beta + d \\delta \\end{pmatrix}",
        // 18: EM algorithm Q-function
        @"\\frak Q(\\lambda,\\hat{\\lambda}) = "
         "-\\frac{1}{2} \\mathbb P(O \\mid \\lambda ) \\sum_s \\sum_m \\sum_t \\gamma_m^{(s)} (t) +\\\\ "
         "\\quad \\left( \\log(2 \\pi ) + \\log \\left| \\cal C_m^{(s)} \\right| + "
         "\\left( o_t - \\hat{\\mu}_m^{(s)} \\right) ^T \\cal C_m^{(s)-1} \\right) ",
        // 19: Piecewise function
        @"f(x) = \\begin{cases}\\frac{e^x}{2} & x \\geq 0 \\\\1 & x < 0\\end{cases}",
        // 20: Ridge regression — argmin via \underset
        @"\\hat\\theta = \\underset{\\theta}{\\arg\\min}\\, \\|y - X\\theta\\|^2 + \\lambda \\|\\theta\\|^2",
    ];
}

/// Formulae exercising specific typesetter features and edge cases.
static inline NSArray<NSString*>* MathTestFormulas(void) {
    return @[
        // 0: Basic arithmetic
        @"3+2-5 = 0",
        // 1: Infix and prefix operators
        @"12+-3 > +14",
        // 2: Punctuation and parentheses
        @"(-3-5=-8, -6-7=-13)",
        // 3: LaTeX commands
        @"5\\times(-2 \\div 1) = -10",
        // 4: Mixed operators
        @"-h - (5xy+2) = z",
        // 5: Fraction — text mode
        @"\\frac12x + \\frac{3\\div4}2y = 25",
        // 6: Fraction — display mode with inset
        @"\\frac{x+\\frac{12}{5}}{y}+\\frac1z = \\frac{xz+y+\\frac{12}{5}z}{yz}",
        // 7: Nested fraction — text mode
        @"\\frac{x+\\frac{12}{5}}{y}+\\frac1z = \\frac{xz+y+\\frac{12}{5}z}{yz}",
        // 8: Exponents/subscripts — large font (30pt)
        @"\\frac{x^{2+3y}}{x^{2+4y}} = x^y \\times \\frac{z_1^{y+1}}{z_1^{y+1}}",
        // 9: Exponents/subscripts — small font (10pt)
        @"\\frac{x^{2+3y}}{x^{2+4y}} = x^y \\times \\frac{z_1^{y+1}}{z_1^{y+1}}",
        // 10: Simple square root
        @"5+\\sqrt{2}+3",
        // 11: Nested roots and fractions inside root
        @"\\sqrt{\\frac{\\sqrt{\\frac{1}{2}} + 3}{\\sqrt5^x}}+\\sqrt{3x}+x^{\\sqrt2}",
        // 12: General (nth) root
        @"\\sqrt[3]{24} + 3\\sqrt{2}24",
        // 13: Fraction and sum inside root index
        @"\\sqrt[x+\\frac{3}{4}]{\\frac{2}{4}+1}",
        // 14: Named operators without limits
        @"\\sin^2(\\theta)=\\log_3^2(\\pi)",
        // 15: Named operators with limits
        @"\\lim_{x\\to\\infty}\\frac{e^2}{1-x}=\\limsup_{\\sigma}5",
        // 16: Symbol operators with limits — display mode
        @"\\sum_{n=1}^{\\infty}\\frac{1+n}{1-n}=\\bigcup_{A\\in\\Im}C\\cup B",
        // 17: Symbol operators with limits — text mode
        @"\\sum_{n=1}^{\\infty}\\frac{1+n}{1-n}=\\bigcup_{A\\in\\Im}C\\cup B",
        // 18: Named operators with limits — text mode
        @"\\lim_{x\\to\\infty}\\frac{e^2}{1-x}=\\limsup_{\\sigma}5",
        // 19: Integral operators
        @"\\int_{0}^{\\infty}e^x \\,dx=\\oint_0^{\\Delta}5\\Gamma",
        // 20: Italic correction — large integral operators
        @"\\int\\int\\int^{\\infty}\\int_0\\int^{\\infty}_0\\int",
        // 21: Italic correction — superscripts/subscripts
        @"U_3^2UY_3^2U_3Y^2f_1f^2ff",
        // 22: Unknown command (error display)
        @"\\notacommand",
        // 23: Square root of 1
        @"\\sqrt{1}",
        // 24: Root with absolute value index
        @"\\sqrt[|]{1}",
        // 25: Binomial — display mode
        @"{n \\choose k}",
        // 26: Binomial — text mode
        @"{n \\choose k}",
        // 27: Atop with delimiters — display mode
        @"\\left({n \\atop k}\\right)",
        // 28: Atop with delimiters — text mode
        @"\\left({n \\atop k}\\right)",
        // 29: Underline and overline
        @"\\underline{xyz}+\\overline{abc}",
        // 30: Underline/overline with fractions
        @"\\underline{\\frac12}+\\overline{\\frac34}",
        // 31: Nested underline/overline with exponent
        @"\\underline{x^\\overline{y}_\\overline{z}+5}",
        // 32: TeX spacing — thin negative space
        @"\\int\\!\\!\\!\\int_D dx\\,dy",
        // 33: No spacing (contrast with 32)
        @"\\int\\int_D dxdy",
        // 34: Thin space
        @"y\\,dx-x\\,dy",
        // 35: No spacing (contrast with 34)
        @"y dx - x dy",
        // 36: Large spaces (\\  \\quad \\qquad)
        @"hello\\ from \\quad the \\qquad other\\ side",
        // 37: Accents — vec, hat, breve, tilde
        @"\\vec x \\; \\hat y \\; \\breve {x^2} \\; \\tilde x \\tilde x^2 x^2 ",
        // 38: Wide accents
        @"\\hat{xyz} \\; \\widehat{xyz}\\; \\vec{2ab}",
        // 39: Accents over fractions and roots
        @"\\hat{\\frac12} \\; \\hat{\\sqrt 3}",
        // 40: Nested colorboxes with radicals
        @"\\colorbox{#f0f0e0}{\\sqrt{1+\\colorbox{#d0c0d0}{\\sqrt{1+"
         "\\colorbox{#a080c0}{\\sqrt{1+\\colorbox{#7050a0}{\\sqrt{1+"
         "\\colorbox{#403060}{\\colorbox{#102000}{\\sqrt{1+\\cdots}}}}}}}}}}}",
        // 41: Tall matrix
        @"\\begin{bmatrix}a & b\\\\ c & d \\\\ e & f \\\\ g &  h \\\\ i & j\\end{bmatrix}",
        // 42: Script style
        @"x{\\scriptstyle y}z",
        // 43: Math font variants
        @"x \\mathrm x \\mathbf x \\mathcal X \\mathfrak x \\mathsf x \\bm x \\mathtt x \\mathit \\Lambda \\cal g",
        // 44: \mathrm text
        @"\\mathrm{using\\ mathrm}",
        // 45: \text command
        @"\\text{using text}",
        // 46: \text with dollar signs
        @"\\text{Mary has }\\$500 + \\$200.",
        // 47: Colorbox wrapping a matrix
        @"\\colorbox{#888888}{\\begin{pmatrix}"
         "\\colorbox{#ff0000}{a} & \\colorbox{#00ff00}{b} \\\\"
         "\\colorbox{#00aaff}{c} & \\colorbox{#f0f0f0}{d}"
         "\\end{pmatrix}}",
        // 48: Explicit delimiter sizes
        @"\\big( \\Big( \\bigg( \\Bigg(",
        // 49: Explicit delimiter classes
        @"\\bigl( x + y \\bigr) \\quad \\bigm| \\quad \\Bigm\\| \\quad \\big[z\\big]",
        // 50: Explicit delimiters with named boundaries
        @"\\bigl\\langle x \\bigr\\rangle \\quad \\bigl\\lceil y \\bigr\\rceil \\quad \\bigl\\lfloor z \\bigr\\rfloor",
        // 51: Null delimiter
        @"\\bigl. \\frac{a}{b} \\bigr)",
        // 52: Scripts on explicit delimiters
        @"\\bigl( x \\bigr)^2",
        // 53: Script-style explicit delimiters
        @"x{\\scriptstyle \\bigl( y \\bigr)}z",
        // 54: Explicit delimiters vs content-sized delimiters on the same sum
        @"\\bigl( \\sum_{i=1}^n x_i \\bigr) \\quad = \\quad \\left( \\sum_{i=1}^n x_i \\right)",
        // 55: Relation-class explicit delimiters
        @"a \\bigm| b \\quad \\Bigm\\| \\quad c \\biggm\\Vert d",
        // 56: Narrow vector (single-glyph fast path)
        @"\\overrightarrow{x}",
        // 57: Two-letter vector
        @"\\overrightarrow{AB}",
        // 58: Leftward arrow
        @"\\overleftarrow{x}",
        // 59: Both-direction arrow
        @"\\overleftrightarrow{ABC}",
        // 60: Wide base — exercises arrow assembly
        @"\\overrightarrow{ABCDEFGH}",
        // 61: Overbrace stretchy
        @"\\overbrace{a+b+c+d}",
        // 62: Underbrace stretchy
        @"\\underbrace{1+2+3+4+5}",
        // 63: Brace with scripts on top/bottom
        @"\\overbrace{a+b+c}^{n} + \\underbrace{d+e+f}_{m}",
        // 64: Stack with scripts
        @"\\overrightarrow{x}^{2} + \\overrightarrow{y}_{i}",
        // 65: Nested stacks
        @"\\overrightarrow{\\overleftarrow{x}}",
        // 66: Mixed arrow directions
        @"\\overrightarrow{x} \\cdot \\overleftarrow{y}",
        // 67: Nested brace over arrow
        @"\\overbrace{\\overrightarrow{AB}}^{\\text{unit}}",
        // 68: AMS fraction macros — \tfrac, \dfrac, \cfrac
        @"\\tfrac{1}{2} + \\dfrac{1}{2} = \\cfrac{1}{1+\\cfrac{1}{1}}",
        // 69: Nested \cfrac (four levels)
        @"x = \\cfrac{1}{1+\\cfrac{1}{x+\\cfrac{1}{x+\\cfrac{1}{x}}}}",
        // 70: \cfrac with l/c/r alignment
        @"\\cfrac[l]{1}{1+x} \\quad \\cfrac[c]{1}{1+x} \\quad \\cfrac[r]{1}{1+x}",
        // 71: \dbinom and \tbinom
        @"\\dbinom{n}{k} \\quad \\tbinom{n}{k}",
        // 72: AMS multi-integrals — \iint, \iiint, \iiiint
        @"\\iint_S f \\, dA = \\iiint_V g \\, dV = \\iiiint_{\\mathbb{R}^4} h \\, dV",
        // 73: \oiint and \iiint
        @"\\oiint_{\\partial V} \\vec{F} \\cdot d\\vec{A} = \\iiint_V (\\nabla\\cdot\\vec{F}) \\, dV",
        // 74: \varointclockwise and \ointctrclockwise
        @"\\varointclockwise \\, \\ointctrclockwise",
        // 75: Binomial expansion with color
        @"\\color{#ff3399}{(a_1+a_2)^2}=a_1^2+2a_1a_2+a_2^2",
        // 76: Multi-color expression
        @"\\color{#ff3333}{c}\\color{#9933ff}{o}\\color{#ff0080}{l}"
         "+\\color{#99ff33}{\\frac{\\color{#ff99ff}{o}}{\\color{#990099}{r}}}"
         "-\\color{#33ffff}{\\sqrt[\\color{#3399ff}{e}]{\\color{#3333ff}{d}}}",
        // 77: Explicit-sized vs content-sized delimiters
        @"\\left( \\frac{a}{b} \\right) \\quad \\text{vs.} \\quad \\bigl( \\frac{a}{b} \\bigr)",
        // 78: Mixed text + math — labelled definition with a fraction
        @"\\text{velocity} = \\frac{d\\vec{x}}{dt}",
        // 79: Russian-labelled area-of-a-circle formula
        @"\\text{Площадь круга} = \\pi r^2",
        // 80: Chinese-labelled area formula
        @"\\text{面积} = \\pi r^2",
        // 81: Hindi-labelled area formula (Devanagari conjuncts + top matras)
        @"\\text{क्षेत्रफल} = \\pi r^2",
        // 82: Arabic-labelled area formula (RTL run inside an LTR equation)
        @"\\text{المساحة} = \\pi r^2",
        // 83: Hebrew-labelled area formula
        @"\\text{שטח} = \\pi r^2",
        // 84: Textbook-style definition exercising all five \\text* styles
        @"\\textbf{Def.}\\textit{ Let } \\textsf{f}: \\textsf{R} \\to \\textsf{R}, "
         "\\textrm{ where } \\texttt{f}(x) = x^2",
        // 85: Styled non-Latin theorem label preceding a math statement
        @"\\textbf{Теорема:} \\; a^2 + b^2 = c^2 \\quad (\\textit{Пифагор})",
        // 86: \stackrel — Taylor series with a "by definition" relation
        @"f(x) \\stackrel{\\text{def}}{=} \\sum_{n=0}^{\\infty} \\frac{f^{(n)}(0)}{n!} x^n",
        // 87: \stackbin — decorated plus, forced Binary class spacing
        @"a \\stackbin{\\Delta}{+} b",
        // 88: \overset — class inherits from base (Relation, Binary, Ordinary)
        @"a \\overset{!}{=} b \\quad x \\overset{?}{+} y \\quad \\overset{*}{A}",
        // 89: \underset — alternative limit notation under a named operator
        @"\\underset{x \\to 0}{\\lim}\\, \\frac{\\sin x}{x} = 1",
        // 90: Spacing contrast — \stackrel (Relation) vs \overset (Ordinary) on the same Ord base
        @"a \\stackrel{?}{c} b \\quad a \\overset{?}{c} b",
        // 91: Nested stacks — \overset inside the over-arg of \stackrel
        @"a \\stackrel{\\overset{n}{\\to}}{=} b",
    ];
}

NS_ASSUME_NONNULL_END

#pragma clang diagnostic pop
