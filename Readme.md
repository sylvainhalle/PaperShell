PaperShell — A Flexible LaTeX Article Environment
=================================================

PaperShell is a boilerplate environment for writing LaTeX articles using the
templates of many publishers (Springer, IEEE, ACM, AAAI, Elsevier, etc.) while
keeping a **single source document independent of the target style**.

<p><a href="https://www.overleaf.com/docs?snip_uri=https://github.com/sylvainhalle/PaperShell/archive/refs/heads/v3.zip"><img src="open-overleaf-16.png?raw=true" alt="Open in Overleaf"/></a></p>

The project provides:

- Up-to-date class and bibliography files for many publishers
- A Lua-based template system that generates the proper preamble automatically
- Direct compatibility with Overleaf
- A build process based on `latexmk`
- Scripts to export editor-ready sources
- Helper scripts for bibliography cleanup, diffs, and packaging

Compared to older versions, PaperShell no longer requires external scripts to
switch styles. This is now handled internally by LuaLaTeX.
Optional PHP scripts are still provided for maintenance tasks such as exporting
sources or updating bundled styles, but they are not required for writing or
compiling a paper.

Why this environment?
---------------------

PaperShell follows these principles:

- Write the paper once
- Switch publisher without rewriting the document
- Keep generated files plain LaTeX
- Make final sources editor-friendly
- Work with Overleaf
- Avoid external build tools when possible

If you have written many Computer Science papers, you have probably used several
different document classes:

- `aaai` for AAAI journals
- `acmart` for ACM conferences and journals
- `easychair` for [EasyChair EPiC Series and Kalpa Publications series](https://easychair.org/publications/for_authors)
- `elsarticle` for Elsevier journals
- `eptcs` for the *Electronic Proceedings in Theoretical Computer Science*
- `IEEEtran` for IEEE conference proceedings and journals
- `lipics` for the *Leibniz International Proceedings in Informatics*
- `llncs` for Springer's *Lecture Notes in Computer Science* series
- `sig-alternate` for ACM conference proceedings
- `stvrauth` and similar for Wiley Journals
- `svjour` for Springer journals
- `usenix2019_v3` for USENIX publications

Alas, it turns out these stylesheets are not directly interchangeable.
Rather than nicely overriding the behaviour of LaTeX's original commands
from the `article` document class, each class defines its own
commands to, e.g., set the title, authors and institution of a document
--and none of them works the same way. For example, here is how to declare
authors and institutions in `llncs`:

    \author{Emmett Brown\inst{1} \and Marty McFly\inst{1} \and Biff Tannen\inst{2}}
    \institute{%
    Temporal Industries \\
    Hill Valley, CA 90193 \\
    \and
    BiffCo inc. \\
    Hill Valley, CA 90193 \\
    }

...in `IEEEtran`:

    \author{%
    \IEEEauthorblockN{Emmett Brown, Marty McFly}
    \IEEEauthorblockA{%
    Temporal Industries\\
    Hill Valley, CA 90193\\
    }
    \IEEEauthorblockN{Biff Tannen}
    \IEEEauthorblockA{%
    BiffCo inc.\\
    Hill Valley, CA 90193\\
    }
    }

...in `acmart`:

    \author{Emmett Brown}
    \affiliation{
      \institution{Temporal Industries}
      \streetaddress{Hill Valley}
      \state{CA}
      \postcode{90193}
    }
    \author{Biff Tannen}
    \affiliation{
      \institution{BiffCo inc.}
      \streetaddress{Hill Valley}
      \state{CA}
      \postcode{90193}
    }

...and in `elsarticle`:

    \author{Emmett Brown\fnref{label1}}
    \author{Marty McFly\fnref{label1}}
    \author{Biff Tannen\fnref{label2}}
    \fntext{Temporal Industries, Hill Valley, CA 90193}
    \fntext{BiffCo inc., Hill Valley, CA 90193}


Switching from one class to another usually requires tedious rewriting. On the contrary,
PaperShell separates paper content, publisher style and preamble generation,
so that the same document can be compiled with multiple styles.


What changed in the new version
-------------------------------

Previous versions of PaperShell used PHP scripts to generate the preamble.
The current version uses LuaLaTeX instead.

Advantages:

- Styles can be switched directly from Overleaf
- No external script is required for normal compilation
- The generated files are plain LaTeX
- Final sources can be compiled with pdfLaTeX
- Simpler build process (`latexmk` only)

LuaLaTeX is only required to generate the preamble.  
Once generated, the document is ordinary LaTeX.


Quick Use
----------

PaperShell generates the files


gen/preamble.inc.tex
gen/midamble.inc.tex
gen/postamble.inc.tex


automatically during compilation.

Your main document simply contains:


\input{gen/preamble.inc.tex}
\input{gen/midamble.inc.tex}

... paper content ...

\input{gen/postamble.inc.tex}


Changing the publisher only requires changing the configuration and recompiling.


Quick start
-----------

0. [Download and unzip](https://github.com/sylvainhalle/PaperShell/releases/latest)
   the PaperShell empty project in a folder of your choice.

1. Edit the setup block in the file `settings.tex` with the desired metadata.
   The file is self-documented and tells you how to do it.

2. Compile once with LuaLaTeX: `latexmk -lualatex paper.tex`. If you do not change
   the style and the metadata of the paper (title, authors, etc.), all other compilations
   can be done "normally" with `latexmk -pdf paper.tex` (which uses `pdflatex` instead
   of `lualatex`).

3. Write your text as usual in `Source/paper.tex`. Figures should
   be placed in the `fig` subfolder. Write your abstract in
   `Source/abstract.tex`, and put any other imports and declarations in
   `Source/includes.tex`. Write anything that should go after the
   bibliography (such as appendices) in `Source/appendices.tex`.

4. To switch style, change `publisher` and recompile with LuaLaTeX (as in step 2).

Extras
------

As an extra, the generated preamble files add a few commands that fix bugs
in some document classes.

- The preamble for IEEE journal fixes a [problem with a redefinition of the
  `\markboth` command](http://tex.stackexchange.com/a/88864) that would
  otherwise prevent the document from compiling
- The postamble for Elsevier fixes the fact that the bibliography [does not have a section
  title](http://tex.stackexchange.com/questions/188625/no-references-title-using-elsevier-document-class)
- The EPTCS BibTeX file incorrectly handles `doi` fields that contain an underscore. PaperShell contains a fixed version.
- The LIPIcs style is incompatible with the `subfig` package.
  PaperShell contains a fixed version.
- The Springer Nature journal style has a [bug causing Tikz to break compilation](https://tex.stackexchange.com/q/615012). PaperShell contains a fixed version.
- The Springer Nature journal style also redefines the `\href` command of the `hyperref` package in a way that the link's text is never shown. PaperShell has a version where this redefinition is commented out.

It also takes care of using fonts properly:

- The original style files load obsolete font packages; PaperShell overrides
  them with newer ones with much nicer math support (e.g. `lmodern` and
  `mathptmx` instead of `cmr` and `times`)
- In all styles, the Helvetica font (used in `\textsf`) [is larger than the
  text's normal font](http://www.hep.caltech.edu/~fcp/psnfss2e).
  PaperShell fixes this issue by scaling down Helvetica.

Overleaf usage
--------------

PaperShell works directly in Overleaf. To switch style:

1. Change the publisher in the setup block
2. Compile once with LuaLaTeX
3. Compile again normally

After generation, the project can be compiled with pdfLaTeX,
which is useful for final submission to editors.


Exporting final sources
----------------------

If your paper is accepted (yay!), you may need to send the sources to the
editor so they can produce the final, "camera-ready version". Just zipping
your PaperShell `Source` folder will confuse a few of them, especially if
they have scripts trying to compile it automatically (many of them just
try to compile the first .tex file they find, which won't be the right one
in most cases).

From the root folder, you can call

    php export.php

Creates a stand-alone directory with all the sources. This script
reads the original source file (paper.tex using the defaults) and
replaces all non-commented
`\input{...}` instructions with the content of the file. It also includes
the bibliography (paper.bbl) directly within the file (so no need to
call BibTeX). The resulting,
stand-alone LaTeX file is copied to a new folder (`Export`), along with all
necessary auxiliary files (basically everything in the Source folder that
is not a .tex file). The exported version does not require LuaLaTeX and can be compiled with
pdflatex.

Normally, what is present in the `Export` folder is a single compilable .tex
file (no `\include` or `\input`), plus class files and images. It is suitable
for sending as a bundle e.g. to an editor to compile the camera-ready
version. You can also bundle the whole thing (except the main .pdf file and
auxiliary files) in a single zip file using `zip-export.sh`.

As an option, the `export.php` script can also create a "flat" structure with no folders (some publishers ask for this when submitting source files). Use the `--flatten` command line option when invoking the script.

BibTeX helper scripts
--------------------

The project comes with a couple of (PHP) scripts that help manage BibTeX bibliographies.

### Cleaning up a BibTeX file

You can uniformize the presentation of BibTeX entries (indentation, etc.) and
remove duplicate entries by passing it into a script. In the root folder of
your project, type:

    php clean-bibtex.php

This will read and parse `Source/paper.bib` and re-output a cleaned up version
at `Source/paper-clean.bib`. If everything looks good, you can then overwrite
the original `paper.bib` with this new file.

### Importing BibTeX entries

From an external bib file, you can automatically import in your current paper
all bib entries that are cited in `paper.tex`, but are not present in
`paper.bib`. In the root folder of your project, type:

    php import-citations.php filename

Where `filename` is the path to the bib file to read from. This way, you can,
for example, extract from a [JabRef](https://jabref.org) bibliography the
entries you actually use in your text, without the need for manual copy-pasting
of the BibTeX code.

### `diff`ing two bibliographies

Given two bib files, it is possible to show the list of entries that are present
in the first but not in the second. In the root folder of your project, type:

    php bib-diff.php file1.bib file2.bib

Other helper scripts
-------------------

A few other functionalities are implemented as shell scripts (with the `.sh`
extension).

### Highlight differences between two versions of a paper

To calculate the difference of two versions of a paper using the PaperShell
template, type:

    ./diff-versions.sh <old> <new> <target>

where:

- `old` is the root PaperShell folder of the "old" version of the paper
- `new` is the root PaperShell folder of the "old" version of the paper
- `target` is the name of the target folder that will contain the diff
  document (created if does not exist)

The script produces a file called `changes.pdf`, where the differences between
the versions are highlighted similar to the "track changes" feature in Microsoft
Word (it uses [latexdiff](https://ctan.org/pkg/latexdiff) in the background).

### Archive the `Source` folder

To archive the content of the `Source` folder, excluding files that are not
versioned (as specified by `.gitignore`), type:

    ./archive-source.sh

This will produce an archive called `Source.tar.gz` in the project's root
folder.

Dependencies
------------

Required:

- LaTeX distribution ([TeX Live](https://tug.org/texlive/) / [MikTeX](https://miktex.org))
- [latexmk](https://ctan.org/tex-archive/support/latexmk)
- LuaLaTeX (for style generation; typically comes with a LaTeX distribution)

Optional:

- [PHP](https://php.net) (for export / packaging / maintenance scripts)
- latexdiff (for diffing versions)
- [Aspell](http://aspell.net/) / [TeXtidote](https://github.com/sylvainhalle/textidote) (spell checking)


About the Author
----------------

This project is maintained by [Sylvain Hallé](https://leduotang.ca/sylvain),
Full Professor at [Université du Québec à
Chicoutimi](http://www.uqac.ca), Canada.

<!-- :wrap=soft:maxLineLen=80: -->