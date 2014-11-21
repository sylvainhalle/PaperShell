A Flexible LaTeX Article Environment
====================================

This repository provides a boilerplate environment for writing LaTeX
articles using the popular templates from Springer, IEEE and ACM. It
provides:

- The up-to-date style and bibliography files of all three publishers
- A script that generates the proper preamble (title, list of authors and
  institution) specific to each style
- A very advanced Makefile (by [Chris
  Monson](https://github.com/shiblon/latex-makefile)) taking care of the
  compilation/cleaning process
- A `.gitignore` file suitable for a single-document LaTeX project

Using this template, switching a paper from any stylesheet to any other
simply amounts to selecting one line to de-comment in the main, `paper.tex`
document.

Why this template?
------------------

If you have been writing lots of Computer Science papers, you may have
been mostly using LaTeX with three different document classes:

- `llncs` for Springer' Lecture Notes in Computer Science series
- `sig-alternate` for ACM conference proceedings
- `IEEEtran` for IEEE conference proceedings and journals

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
sent to another venue with a different publisher.

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

...and in `sig-alternate`:

    \numberofauthors{2}
    \author{%
    \alignauthor Emmett Brown, Marty McFly\\
    \affaddr{Temporal Industries} \\
    \affaddr{Hill Valley, CA 90193} \\
    \alignauthor Biff Tannen\\
    \affaddr{BiffCo inc.} \\
    \affaddr{Hill Valley, CA 90193} \\
    }

Three different sets of commands and syntax for the same data, and all this
while `article.cls` already provides commands doing exactly that, which could
have easily been overridden! Therefore, switching between classes requires
some amount of braindead, yet frustrating copy-pasting from existing files
you have, which arguably becomes quite mind-numbing when you've been doing
that once in a while for the past ten years.

In this project, the paper's title, authors and institutions is written in
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

You then call a script named `generate-preamble.php` to generate include
files with the proper syntax for each of the document classes from that
same data. These files are called `preamble-xxxx.inc.tex`, where xxxx is
the document class.

In the main paper file, called `paper.tex`, it suffices to uncomment the
`\input` line for the desired preamble and compile:

    %\input preamble-ieee.inc.tex
    %\input preamble-lncs.inc.tex
    \input preamble-acm.inc.tex

To change the authors or title, modify `authors.txt` and call
`generate-preamble.php` again. To switch between document classes, select
another `\input` line to uncomment and recompile. Voilà!

Quick Use
---------

0. Unzip (or clone) the contents of this repository in a folder of your
   choice.

1. Modify `article.txt` with the desired title, authors and institutions.
   The file is self-document and tells you how to do it.

2. Call `php generate-preamble.php` to generate the include files, which
   will be placed in the `Source` subfolder.

3. Write your text as usual in `Source/paper.tex`. Uncomment the `\input`
   line corresponding to the document class you wish to use. Figures should
   be placed in the `fig` subfolder.

4. To compile, use `make all`. To remove temporary files, use `make clean`.
   The Makefile has a very comprehensive list of other useful features. To
   read them, run `make help`.

About the Author
----------------

This project is maintained by [Sylvain Hallé](http://leduotang.ca/sylvain),
Associate Professor at [Université du Québec à
Chicoutimi](http://www.uqac.ca), Canada.