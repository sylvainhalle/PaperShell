PaperShell Manual
=================

This file contains the complete documentation.

For a quick introduction, see `README.md`.


Project structure
-----------------

PaperShell generates the files

- `gen/preamble.inc.tex`  
- `gen/midamble.inc.tex`  
- `gen/postamble.inc.tex`

automatically during compilation. Your main document contains:

```latex
\input{gen/preamble.inc.tex}  
\input{gen/midamble.inc.tex}  

... paper content ...

\input{gen/postamble.inc.tex}
```

Switching publisher
-------------------

Change the publisher in `Source/settings.tex` and compile once with LuaLaTeX.


Generated files
---------------

The generated files contain the class declaration,
title block, bibliography configuration,
and style-specific fixes.


Exporting final sources
-----------------------

If your paper is accepted, you may need to send
a clean bundle of sources to the editor.

Run

    php export.php

This will

- inline all `\input` files
- include the bibliography
- copy required files
- create a standalone directory

The exported version compiles with pdfLaTeX.

Option:

    php export.php --flatten


BibTeX helper scripts
---------------------

Cleaning:

    php clean-bibtex.php

Importing citations:

    php import-citations.php file.bib

Diffing bibliographies:

    php bib-diff.php file1.bib file2.bib


Other helper scripts
--------------------

Diff versions:

    ./diff-versions.sh old new target

Archive source:

    ./archive-source.sh


Dependencies
------------

Required:

- LaTeX distribution (such as [TeXLive](https://tug.org/texlive/) or [MikTeX](https://miktex.org)
- [latexmk](https://www.cantab.net/users/johncollins/latexmk/index.html)
- LuaLaTeX (generally included in the LaTeX distribution)

Optional:

- [PHP](https://php.net)
- [latexdiff](https://ctan.org/pkg/latexdiff)
- [Aspell](https://aspell.net) / [TeXtidote](https://github.com/sylvainhalle/textidote)


Notes about publisher styles
----------------------------

PaperShell fixes various issues in publisher styles,
including problems with fonts, bibliography titles,
package incompatibilities, and class bugs.


Design philosophy
-----------------

PaperShell follows these rules:

- Write once
- Switch style easily
- Keep sources plain LaTeX
- Produce editor-friendly bundles
- Work in Overleaf
- Avoid complex build tools