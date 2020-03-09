%---------------------------------------------------------------------------
%Please  be  aware that the use of this LaTeX class file is governed by the
%following conditions:
%
% based on the original LaTeX ARTICLE DOCUMENT STYLE
% Copyright (C) 1988, 1989 by Leslie Lamport
%
% Copyright (c) 2010 John Wiley & Sons, Ltd, The Atrium, Southern Gate, Chichester,
% West Sussex, PO19 8SQ UK.   All rights reserved.
%
%Rules of Use
%
%% You are NOT ALLOWED to change this file.
%
%
%This class file is made available for use by authors who wish to prepare an
%article for publication in
%SOFTWARE TESTING, VERIFICATION AND RELIABILITY
%published by John Wiley & Sons Ltd. The user may not exploit any part of
%the class file commercially.
%
%This class file is provided on an `as is'  basis, without warranties of any
%kind, either expressed or implied, including but not limited to warranties of
%title, or  implied warranties of merchantablility or fitness for  a
%particular purpose. There will be no duty on the author[s] of the software
%or John Wiley & Sons Ltd to correct any errors or defects in the software.
%Any statutory rights you may have remain unaffected by your acceptance of
%these rules of use.
%---------------------------------------------------------------------------
%
% Created by Alistair Smith, Sunrise Setting Ltd, 13 May 2010
%
% stvrauth.cls --- For Softw. Test. Verif. Reliab.

\def\update{2010/05/13 v2.00}

\newcommand{\journalname}{SOFTWARE TESTING, VERIFICATION AND RELIABILITY}
\newcommand{\journalnamelc}{Software Testing, Verification and Reliability}
\newcommand{\journalabb}{Softw. Test. Verif. Reliab.}
\newcommand{\journalclass}{stvrauth.cls}
\newcommand{\journalclassshort}{stvrauth}
\newcommand{\DOI}{stvr}

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{stvrauth}[\update\ \journalclass]

%\newcommand\hmmax{0}

\newif\if@timesfont
\DeclareOption{times}{%
\@timesfonttrue}

\newif\if@doublespace
\DeclareOption{doublespace}{%
\@doublespacetrue}

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions
\LoadClass{article}
\if@timesfont
\RequirePackage{times}
\fi
\if@doublespace
\RequirePackage[onehalfspacing]{setspace}
\fi

\RequirePackage{graphicx}
\RequirePackage{pifont,latexsym,ifthen,rotating,calc,textcase,booktabs,color}
\RequirePackage{amsfonts,amssymb,amsbsy,amsmath,amsthm}
%\RequirePackage{bm}
\RequirePackage[errorshow]{tracefnt}

\@twosidetrue
\flushbottom
\frenchspacing

\textwidth 34pc
\textheight 645pt
%\setlength\columnsep{24pt}

%Trim sizes
\setlength\voffset{-1in}
\setlength\hoffset{-1in}
\topmargin -1mm
\setlength\oddsidemargin{33mm}%back margin on odd pages
\setlength\evensidemargin{33mm}%fore margin on even pages
\setlength\paperwidth{210mm}
\setlength\paperheight{276mm}
%Needed to set PDF page size
\special{papersize=210mm,276mm}

\parskip \z@
\parindent 1em
\headheight 50pt
\headsep    20pt 
\footskip 24pt 

\hyphenpenalty=1000
\pretolerance=8000
\tolerance=9500
\hbadness=8000
\vbadness=9000
\displaywidowpenalty=0
\clubpenalty=10000
\widowpenalty=10000
\lefthyphenmin=3%
\righthyphenmin=3%
\brokenpenalty=10000%

\thinmuskip = 3mu
\medmuskip = 4mu
\thickmuskip = 5mu

\setcounter{topnumber}{10}
\def\topfraction{1}
\setcounter{bottomnumber}{10}
\def\bottomfraction{0.8}
\setcounter{totalnumber}{10}
\def\textfraction{0}
\renewcommand{\floatpagefraction}{0.95}
\setcounter{dbltopnumber}{10}
\renewcommand{\dblfloatpagefraction}{0.95}
\renewcommand{\dbltopfraction}{1}

\renewcommand{\normalsize}{\fontsize{10.3}{12pt}\selectfont}
\renewcommand{\small}{\fontsize{9.5}{10pt}\selectfont}
\renewcommand{\footnotesize}{\fontsize{8.5}{9pt}\selectfont}
\renewcommand{\scriptsize}{\fontsize{8.5}{9.5pt}\selectfont}
\renewcommand{\tiny}{\fontsize{6.5}{7pt}\selectfont}
\renewcommand{\large}{\fontsize{11.5}{12pt}\selectfont}
\renewcommand{\Large}{\fontsize{14}{18pt}\selectfont}
\renewcommand{\LARGE}{\fontsize{17}{22pt}\selectfont}
\renewcommand{\huge}{\fontsize{20}{25pt}\selectfont}
\renewcommand{\Huge}{\fontsize{25}{30pt}\selectfont}

\newcommand{\titlesize}{\fontsize{15.3}{16pt}\selectfont}
\newcommand{\tabsize}{\fontsize{9}{9.5pt}\selectfont}

\newbox\absbox
\def\abstract{\lrbox\absbox\minipage{\textwidth}%
  \small\normalfont%
  \centerline{{SUMMARY}}\par\vspace{8pt}%
  }
\def\endabstract{\copyrightline\endminipage\endlrbox}

\def\keywords#1{%
  \gdef\@keywords{\small{KEY WORDS:}\hspace{0.75em}\parbox[t]{28pc}{#1}}}
\let\@keywords\@empty

\skip\footins 22pt plus  8pt
%\gdef\footnoterule{}
\def\footnoterule{\kern-3\p@
  \hrule \@width 60pt \kern 2.6\p@}

\renewcommand{\thefootnote}{\fnsymbol{footnote}}
\long\def\@makefntext#1{\parindent 1em%
\noindent{$\m@th^{\@thefnmark}$}#1}

\def\corraddr#1{%
  \gdef\@corraddr{%
    \footnotetext[1]{Correspondence to: #1\stepcounter{footnote}}}}
\let\@corraddr\@empty
\def\corrauth{\footnotemark[1]}

\def\address#1{%
  \gdef\@address{{\footnotesize\itshape #1}}}
\let\@address\@empty

\def\cgsn#1#2{%
\gdef\@cgsn{%
\footnotetext[0]{\\
Contract/grant sponsor: #1; contract/grant
number: #2}}}

\def\cgs#1{%
\gdef\@cgs{%
\footnotetext[0]{\\
Contract/grant sponsor: #1}}}

\let\@cgsn\@empty
\let\@cgs\@empty

\def\affilnum#1{${}^{#1}$}
\def\affil#1{${}^{#1}$}
\def\comma{${}^{\text{,}}$}

\renewcommand\maketitle{\par
  \begingroup
     \if@twocolumn
      \ifnum \col@number=\@ne
        \@maketitle
      \else
        \twocolumn[\@maketitle]%
       \fi
    \else
      \newpage
      \global\@topnum\z@   % Prevents figures from going at top of page.
      \@maketitle
    \fi
    \thispagestyle{title}\label{FirstPage}\@corraddr\@cgs\@cgsn
  \endgroup
  %\setcounter{footnote}{0}%
  \global\let\address\relax
  \global\let\thanks\relax
  \global\let\maketitle\relax
  \global\let\@maketitle\relax
  \global\let\@thanks\@empty
  \global\let\@author\@empty
  \global\let\@date\@empty
  \global\let\@title\@empty
  \global\let\@address\@empty
  \global\let\corraddr\relax
  \global\let\title\relax
  \global\let\author\relax
  \global\let\date\relax
  \global\let\and\relax
}
\def\@maketitle{\vspace*{6pt}%
\null%
\begin{center}
    {\titlesize\@title \par}%
    \vskip 1.5em %
    \vskip 5pt
    {\large
      \lineskip .5em%
      \@author
      \par}%
      \vskip 11pt
{\footnotesize
      \lineskip .5em%
      %
        {\raggedright\emph\@address}
      \par}%
\end{center}    
    \vskip 31pt%
    {\noindent\usebox\absbox\par}
    {\lineskip 1.5em%
      %
      {\noindent\footnotesize Received \dots}\par}
    {\vspace{11pt}%
      %
      {\noindent\@keywords}\par}
      \vspace{12pt}
        \par%
  }
 
\def\startpage{\pageref{FirstPage}}
\def\endpage{\pageref{LastPage}}
\def\volumeyear{0000}
\def\volumenumber{00}

\gdef\copyrightline{Copyright \copyright\ \volumeyear\ John Wiley \& Sons, Ltd.}
\def\runningheads#1#2{\markboth{\uppercase{#1}}{\uppercase{#2}}}

\def\ps@title{%
\def\@oddhead{%
\parbox[t]{\textwidth}{%
\begin{tabular}[t]{@{}l@{}}%
{\footnotesize\journalname}\\[-3pt]
{\footnotesize\emph{\journalabb} \volumeyear; \textbf{\volumenumber}:\startpage--\endpage}\\[-3pt]
{\footnotesize Published online in Wiley InterScience (www.interscience.wiley.com). DOI: 10.1002/\DOI}
\end{tabular}}}%
\let\@evenhead\@oddhead
\def\@oddfoot{\parbox[t]{\textwidth}{%
{\footnotesize\copyrightline\hfill\\
\textit{Prepared using \textsf{\journalclass} [Version: \update]\hfill}%
}}}
\let\@evenfoot\@oddfoot}

\def\ps@wpage{
\let\@mkboth\@gobbletwo
\def\@evenhead{\normalsize \thepage\hfill\footnotesize{\leftmark}\hfill\normalsize\phantom{\thepage}}
\def\@oddhead{\normalsize \phantom{\thepage}\hfill\footnotesize{\rightmark}\hfill\normalsize\thepage}
\def\@evenfoot{\parbox[t]{\textwidth}{{\footnotesize \copyrightline}%
\hfill\footnotesize{\it \journalabb\ }(\volumeyear)\\ %
\footnotesize\textit{Prepared using \textsf{\journalclass}}\hfill DOI: 10.1002/\DOI}}
\def\@oddfoot{\@evenfoot}
}

\renewcommand{\@seccntformat}[1]{{\csname the#1\endcsname.}\hspace{0.5em}}

\newdimen\@bls                              
\@bls=\baselineskip

\renewcommand\section{\@startsection {section}{1}{\z@}%
                                   {2\@bls  plus .3\@bls minus .1\@bls}%
                                   {1\@bls\@afterindentfalse}%
                                   {\centering\normalfont\normalsize\protect\MakeTextUppercase}}
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
                                     {\@bls plus .3\@bls minus .1\@bls}%
                                     {6pt\@afterindentfalse}%
                                     {\normalfont\normalsize\raggedright\itshape}}
\renewcommand\subsubsection{\@startsection{subsubsection}{3}{\z@}%
                                     {\@bls plus .2\@bls}%
                                     {-5pt}%
                                     {\normalfont\normalsize\itshape}}

\def\enumerate{\ifnum \@enumdepth >3 \@toodeep\else
      \advance\@enumdepth \@ne
      \edef\@enumctr{enum\romannumeral\the\@enumdepth}\list
      {\csname label\@enumctr\endcsname}{\usecounter
        {\@enumctr}\itemsep 0pt\parsep 0pt
         \def\makelabel##1{\hss\llap{##1}}}\fi}

\let\endenumerate =\endlist

\def\itemize{\ifnum \@itemdepth >3 \@toodeep\else \advance\@itemdepth \@ne
\edef\@itemitem{labelitem\romannumeral\the\@itemdepth}%
\list{\csname\@itemitem\endcsname}{\itemsep 0pt\parsep 0pt
\def\makelabel##1{\hss\llap{##1}}}\fi}

\let\enditemize =\endlist

\renewcommand{\thetable}{\Roman{table}}

\usepackage{caption}
\DeclareCaptionLabelSeparator{jwperiod}{.\hspace*{0.5ex}}
\captionsetup[figure]{font=small,labelfont=rm,labelsep=jwperiod,justification=centerlast,singlelinecheck=true}
\captionsetup[table]{position=top,font=small,labelfont=rm,labelsep=jwperiod,justification=centerlast,singlelinecheck=true}

\def\thmhead@plain#1#2#3{%
  \thmname{#1}\thmnumber{\@ifnotempty{#1}{ }{#2}}%
  \thmnote{ {\the\thm@notefont(#3)}}}

\newtheoremstyle{wiley}
{6pt plus 2pt minus 2pt}% space above
{6pt plus 2pt minus 2pt}% space below
{}% Body font
{}% Indent amount
{\itshape}% Theorem head font
{}% Punctuation after theorem head
{\newline}% Space after theorem head
{}% Theorem head spec

\renewenvironment{proof}[1][\proofname]{\par
  \pushQED{\qed}%
  \normalfont \topsep6\p@\@plus6\p@\relax
  \trivlist
  \item[\hskip\labelsep
        \itshape
    #1\@addpunct{}]\mbox{}\newline\ignorespaces
}{%
  \popQED\endtrivlist\@endpefalse
}

\theoremstyle{wiley}

\def\ack{\vspace{2\@bls plus .3\@bls minus .1\@bls}
\noindent{\footnotesize\centerline{ACKNOWLEDGEMENT}}\\[6pt]\small\noindent}%

\def\acks{\vspace{2\@bls plus .3\@bls minus .1\@bls}
\noindent{\footnotesize\centerline{ACKNOWLEDGEMENTS}}\\[6pt]\small\noindent}%

\renewcommand\refname{REFERENCES}

\renewenvironment{thebibliography}[1]{%
\vspace{2\@bls plus .3\@bls minus .1\@bls}
\noindent{\footnotesize\centerline{\refname}}\\[-3pt]
\list{{\arabic{enumi}}}{\def\makelabel##1{\hss{##1.}}\topsep=0\p@\parsep=0\p@
\partopsep=0\p@\itemsep=0\p@
\labelsep=1ex\itemindent=0\p@
\settowidth\labelwidth{\footnotesize[#1]}%
\leftmargin\labelwidth
\advance\leftmargin\labelsep
\advance\leftmargin -\itemindent
\usecounter{enumi}}\footnotesize
\def\newblock{\ }
\sloppy\clubpenalty4000\widowpenalty4000
\sfcode`\.=1000\relax}{\endlist}

%\def\biog{\section*{Author's Biography}\small}
%\def\biogs{\section*{Authors' Biographies}\small}

\AtEndDocument{%
\label{LastPage}}

\hyphenation{com-mu-ni-ca-tions}

\pagestyle{wpage}
\normalsize
\sloppy
