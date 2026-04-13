###########################################################################
############          Latin Modern Collection of Fonts         ############
###########################################################################

Font: Latin Modern Math
Authors: Bogus\l{}aw Jackowski, Piotr Strzelczyk and Piotr Pianowski
Version: 1.959
Date: 5 IX 2014

License:
  % Copyright 2012--2014 for the Latin Modern math extensions by B. Jackowski,
  % P. Strzelczyk and P. Pianowski (on behalf of TeX Users Groups).
  %
  % This work can be freely used and distributed under
  % the GUST Font License (GFL -- see GUST-FONT-LICENSE.txt)
  % which is actually an instance of the LaTeX Project Public License
  % (LPPL -- see http://www.latex-project.org/lppl.txt).
  %
  % This work has the maintenance status "maintained". The Current Maintainer
  % of this work is Bogus\l{}aw Jackowski, Piotr Strzelczyk and Piotr Pianowski.
  %
  % This work consists of the files listed
  % in the MANIFEST-Latin-Modern-Math.txt file.
 
###########################################################################
############          A BRIEF DESCRIPTION OF THE FONT          ############
###########################################################################

Latin Modern Math is a math companion for the Latin Modern family
of fonts (see http://www.gust.org.pl/projects/e-foundry/latin-modern) in
the OpenType format.

The math OTF fonts should contain a special table, MATH, described in the 
confidential Microsoft document "The MATH table and OpenType Features 
for Math Processing". Moreover, they should contain a broad collection
of special characters (see "Draft Unicode Technical Report #25.
UNICODE SUPPORT FOR MATHEMATICS" by Barbara Beeton, Asmus Freytag,
and Murray Sargent III). In particular, math OTF fonts are expected
to contain the following scripts: a basic serif script (regular, bold, 
italic and bold italic), a calligraphic script (regular and bold), 
a double-struck script, a fraktur script (regular and bold), a sans-serif 
script (regular, bold, oblique and bold oblique), and a monospaced script.

The basic script is, obviously, Latin Modern. Some scripts, however,
are borrowed from other fonts (the current selection, however, may
be subject to change), belonging, however, to the "TeX circle":

  * the calligraphic and fraktur alphabets are excerpted from the renowned
    Euler family (http://en.wikipedia.org/wiki/AMS_Euler);

  * the double struck script is excerpted from Alan Jeffrey's bbold font
    (http://www.tug.org/texlive/Contents/live/texmf-dist/doc/latex/bbold/bbold.pdf)

  * the sans serif and monospaced alphabets are excerpted from 
    the Latin Modern Sans and Latin Modern Mono fonts
    (http://www.gust.org.pl/projects/e-foundry/latin-modern);
    sans serif bold Greek symbols (required by the already mentioned
    "Unicode Technical Report #25") were prepared using D.E. Knuth's
    font sources with some manual tuning

The main math component, that is, the math extension, was programmed
from scratch, with an attempt to retain the visual compatiblility
with the original D.E. Knuth's fonts. In particular, all symbols
(with a few exceptions) appearing in the D.E. Knuth's "canonical" fonts
have the same width (rounded) as the corresponding Knuthian ones.

Note that the members of all the mentioned alphabets, except
the main roman alphabet, should be considerd symbols, not letters;
symbols are not expected to occur in a text stream; instead,
they are expected to appear lonely, perhaps with some embellishments
like subscripts, superscripts, primes, dots above and below, etc.

To produce the font, MetaType1 and the FontForge library were used:
the Type1 PostScript font containing all relevant characters was
generated with the MetaType1 engine, and the result was converted
into the OTF format with all the necessary data structures by
a Python script employing the FontForge library.

Recent changes (ver. 1.958 --> ver. 1.959) comprised
mainly interline settings in OTF tables (HHEA and
OS/2) and the correction of unicode slots assigned to
the contour integrals (glyphs `clockwise contour
integral', u+2232, and `anticlockwise contour
integral', u+2233, used to have swapped slots).

                   *    *    *

The TeX Gyre Math Project was launched and is supported by
TeX USERS GROUPS (CS TUG, DANTE eV, GUST, NTG, TUG India, TUG, UK TUG).
Hearty thanks to the representatives of these groups and also
to all people who helped with their work, comments, ideas,
remarks, bug reports, objections, hints, consolations, etc.
