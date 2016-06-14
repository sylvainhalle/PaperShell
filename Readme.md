A Flexible LaTeX Article Environment
====================================

This repository provides a boilerplate environment for writing LaTeX
articles using the popular templates from Springer, IEEE, ACM, AAAI and
Elsevier. It provides:

- The up-to-date style and bibliography files of many different publishers
  (journals and conferences)
- A script that generates the proper preamble (title, list of authors and
  institution) specific to each style
- A very advanced Makefile (by [Chris
  Monson](https://github.com/shiblon/latex-makefile)) taking care of the
  compilation/cleaning process
- Scripts (for both Windows and Linux) to perform spell checking of the
  LaTeX source with [GNU Aspell](http://aspell.net). The words added to the
  dictionary while checking are also versioned with the project.
- A script that can "flatten" your sources into a single compilable .tex file
  (with all includes and bibliography) and export all resources in a
  stand-alone folder (ideal for exporting the camera-ready sources to an
  editor)
- A `.gitignore` file suitable for a single-document LaTeX project

Using this template, switching a paper from any stylesheet to any other
simply amounts to selecting one line to de-comment in the main, `paper.tex`
document.

Why this template?
------------------

If you have been writing lots of (Computer Science) papers, you may have
been mostly using LaTeX with a couple of different document classes:

- `aaai` for AAAI journals
- `acmsmall` for ACM journals
- `elsarticle` for Elsevier journals
- `eptcs` for the Electronic Proceedings in Theoretical Computer Science
- `IEEEtran` for IEEE conference proceedings and journals
- `llncs` for Springer's *Lecture Notes in Computer Science* series
- `sig-alternate` for ACM conference proceedings
- `stvrauth` and similar for Wiley Journals
- `svjour` for Springer journals

First off, this repository provides a well-structured template project where
all these classes are included, so you can pick the one you wish when
starting to write. Moreover, it comes with a very powerful Makefile that
does all sorts of nifty things, such as suppressing useless output from
LaTeX and colouring (yes, colouring) its meaningful output (errors in red,
etc.).

Moreover, there might be various reasons for which you might want to switch
an existing document from one class to the other. For example, you started
writing a paper without deciding where to send it, only to find that the
conference you've chosen has a different publisher than the paper's current
style. Or, a paper sent to a conference (and perhaps rejected) needs to be
sent to another venue with a different publisher. (Note that in the past,
it used to be the *publisher's* job to format your manuscript to their
taste. But that's another story.)

Alas, it turns out these stylesheets are not directly interchangeable.
Rather than nicely overriding the behaviour of LaTeX's original commands
from the `article` document class, each class decided to invent its own
commands to, e.g., define the title, authors and institution of a document
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

...in `sig-alternate`:

    \numberofauthors{2}
    \author{%
    \alignauthor Emmett Brown, Marty McFly\\
    \affaddr{Temporal Industries} \\
    \affaddr{Hill Valley, CA 90193} \\
    \alignauthor Biff Tannen\\
    \affaddr{BiffCo inc.} \\
    \affaddr{Hill Valley, CA 90193} \\
    }

...and in `elsarticle`:

    \author{Emmett Brown\fnref{label1}}
    \author{Marty McFly\fnref{label1}}
    \author{Biff Tannen\fnref{label2}}
    \fntext{Temporal Industries, Hill Valley, CA 90193}
    \fntext{BiffCo inc., Hill Valley, CA 90193}

Four different sets of commands and syntax for the same data ---and all this
while `article.cls` already provides commands doing exactly that, which
could have easily been overridden! To make things even worse, the class
elsarticle does not even use `\maketitle` to print the title, which must be
enclosed (along with the abstract) within a `frontmatter` environment *after*
the `\begin{document}`. Therefore, switching between classes
requires some amount of braindead, yet frustrating copy-pasting from
existing files you have, which arguably becomes quite mind-numbing when
you've been doing that once in a while for the past ten years.

In this project, the paper's title, authors and institutions are written in
a separate file called `authors.txt`:

    Applications of the Flux Capacitor
    
    Emmett Brown (1)
    Marty McFly (1)
    Biff Tannen (2)
    
    1
    Temporal Industries
    Hill Valley, CA 95420
    
    2
    BiffCo inc.
    Hill Valley, CA 95420

(You can optionally separate first and last names with braces, e.g.
`{Marty} {McFly}`. This is used in the EPTCS style for writing
abbreviated author names, e.g. "E. Brown, M. McFly, B. Tannen", etc.)

You then call a script named `generate-preamble.php` to generate include
files with the proper syntax for each of the document classes from that
same data. These files are called `preamble-xxxx.inc.tex`, where xxxx is
the document class.

In the main paper file, called `paper.tex`, it suffices to uncomment the
`\input` line for the desired preamble and compile:

    %\input{preamble-ieee-journal.inc.tex}
    %\input{preamble-ieee.inc.tex}
    %\input{preamble-lncs.inc.tex}
    \input{preamble-acm.inc.tex}
    ...

To change the authors or title, modify `authors.txt` and run
`generate-preamble.php` again. To switch between document classes, select
another `\input` line to uncomment and recompile. Voilà!

Quick Use
---------

0. [Download and unzip](https://github.com/sylvainhalle/PaperShell/releases/latest)
   the PaperShell empty project in a folder of your choice.

1. Modify `article.txt` with the desired title, authors and institutions.
   The file is self-documented and tells you how to do it.

2. Call `php generate-preamble.php` to generate the include files, which
   will be placed in the `Source` subfolder. (This requires
   [PHP](http://php.net/) to be installed in your path.)

3. Write your text as usual in `Source/paper.tex`. Uncomment the `\input`
   line corresponding to the document class you wish to use. Figures should
   be placed in the `fig` subfolder. Write your abstract in
   `Source/abstract.tex`, and put any other imports and declarations in
   `Source/includes.tex`. Write anything that should go after the
   bibliography (such as appendices) in `Source/appendices.tex`.

4. To compile, use `make all`. To remove temporary files, use `make clean`.
   The Makefile has a very comprehensive list of other useful features. To
   read them, run `make help`.

5. To spell check, type `./aspell-check.sh` (in Linux) or `aspell-check.bat`
   (in Windows) from the project's top folder. Any additions to the
   personal dictionary will be reflected in changes to files
   `.aspell.en.prepl` and `.aspell.en.pws`, which are versioned with the
   rest of the project. See the file `aspell-check.readme` for instructions.

Extras
------

As an extra, the generated preamble files add a few commands that fix bugs
in some document classes.

- The preamble for IEEE journal fixes a [problem with a redefinition of the
  `\markboth` command](http://tex.stackexchange.com/a/88864) that would
  otherwise prevent the document from compiling
- The postamble for Elsevier fixes the fact that the bibliography [does not have a section
  title](http://tex.stackexchange.com/questions/188625/no-references-title-using-elsevier-document-class)
- The ACM conference template can optionally be
  [fixed](http://jeffe.cs.illinois.edu/pubs/tex/fixacm.sty) to improve some
  of its "brain-damaged and ugly" fomatting rules (not my words here!)
- The EPTCS BibTeX file incorrectly handles `doi` fields that contain an underscore.
  Since we don't know a workaround, the template uses the `plain` bibliography
  style rather than `eptcs`.


Exporting your sources
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
is not a .tex file).
 *
Normally, what is present in the Export folder is a single compilable .tex
file (no `\include` or `\input`), plus class files and images. It is suitable
for sending as a bundle e.g. to an editor to compile the camera-ready
version.

Overriding defaults
-------------------

Default settings can be overridden by giving values to parameters found
in `settings.inc.php`. All these settings are documented in detail in the
file. Make sure to call `generate-preamble.php` again after you change the
file.

In the case of ACM journals, you also have to overwrite `acm-ccs.tex` and
`acm-bottom.tex` with appropriate content.

### Changing the paper's filename

By default, the main paper is called `paper.tex`. We recommend that you leave
it that way: the whole point of using this environment is to use the same
commands and structure for all your papers, so customizing it for each paper
kind of defeats that. If you *must* change it to something else:

1. Make sure the filename does not contain spaces, or the `make` command
   will not do anything.
2. Make sure to change `paper.tex` by your filename in
   `Source/Variables.ini`.

About the Author
----------------

This project is maintained by [Sylvain Hallé](http://leduotang.ca/sylvain),
Associate Professor at [Université du Québec à
Chicoutimi](http://www.uqac.ca), Canada.
