<?php
/**************************************************************************
  A Flexible LaTeX Article Environment
  Copyright (C) 2015-2015  Sylvain Hallé

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **************************************************************************/

// Read author-title file
$input_filename = "authors.txt";
$out_folder = "Source/";
$lines = explode("\n", file_get_contents($input_filename));

{ // Parse file {{{
  $has_title = false;
  $current_affiliation = 1;
  $title = "";
  $affiliations = array();
  $authors = array();
  foreach ($lines as $line)
  { // {{{
    $line = trim($line);
    if (empty($line) || $line[0] === "#")
    {
      continue;
    }
    if (!$has_title)
    {
      $title = $line;
      $has_title = true;
      continue;
    }
    $matches = array();
    if (preg_match("/^(.*)\\((\\d+)\\)$/", $line, $matches))
    {
      $authors[trim($matches[1])] = trim($matches[2]);
    }
    elseif (preg_match("/^\\d+$/", $line))
    {
      $current_affiliation = $line;
    }
    else
    {
      if (!isset($affiliations[$current_affiliation]))
      {
        $affiliations[$current_affiliation] = array();
      }
      $affiliations[$current_affiliation][] = $line;
    }
  }
} // }}}

// Now that authors and affiliations are known, generate the preamble
// specific to each stylesheet

{ // Springer LNCS {{{
  
  // Preamble
  $out = "";
  $out .= <<<EOD
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This is an auto-generated file. DO NOT EDIT!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\documentclass{llncs}

% Usual packages
\usepackage[utf8]{inputenc}  % UTF-8 input encoding
\usepackage[T1]{fontenc}     % Type1 fonts
\usepackage{lmodern}         % Improved Computer Modern font
\usepackage{microtype}       % Better handling of typo
\usepackage[english]{babel}  % Hyphenation
\usepackage{graphicx}        % Import graphics
\usepackage{cite}            % Better handling of citations
\usepackage{hyperref}        % Better handling of references in PDFs
\usepackage{comment}         % To comment out blocks of text
EOD;

  $out .= "\n\n% Title\n";
  $out .= "\\title{".$title."}\n\n";
  
  $out .= "% Authors and affiliations\n";
  $out .= "\\author{";
  $first = true;
  foreach ($authors as $name => $aff)
  {
    if ($first)
    {
      $first = false;
    }
    else
    {
      $out .= " \\and ";
    }
    $out .= $name."\\inst{".$aff."}";
  }
  $out .= "}\n";
  $out .= "\\institute{%\n";
  $first = true;
  foreach ($affiliations as $key => $lines)
  {
    if ($first)
    {
      $first = false;
    }
    else
    {
      $out .= "\\and\n";
    }
    foreach ($lines as $line)
    {
      $out .= $line." \\\\\n";
    }
  }
  $out .= "}\n\n";
  $out .= "\\input includes.tex\n\n";
  $out .= "\\begin{document}\n\n";
  $out .= "\\maketitle\n";
  $out .= "\\input abstract.tex\n";
  file_put_contents($out_folder."preamble-lncs.inc.tex", $out);
  
  // Postamble
  $out = "";
  $out .= <<<EOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This is an auto-generated file. DO NOT EDIT!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOD;
  $out .= "\n\\bibliographystyle{splncs03}\n";
  $out .= "\\bibliography{paper}\n";
  $out .= "\\end{document}\n";
  file_put_contents($out_folder."postamble-lncs.inc.tex", $out);
} // }}}

{ // IEEE Conference Proceedings {{{
  
  // Preamble
  $out = "";
  $out .= <<<EOD
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This is an auto-generated file. DO NOT EDIT!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\documentclass[conference]{IEEEtran}

% Usual packages
\usepackage[utf8]{inputenc}  % UTF-8 input encoding
\usepackage[T1]{fontenc}     % Type1 fonts
\usepackage{mathptmx}        % Times with math support
\usepackage{microtype}       % Better handling of typo
\usepackage[english]{babel}  % Hyphenation
\usepackage{graphicx}        % Import graphics
\usepackage{cite}            % Better handling of citations
\usepackage{hyperref}        % Better handling of references in PDFs
\usepackage{comment}         % To comment out blocks of text
EOD;

  $out .= "\n\n% Title\n";
  $out .= "\\title{".$title."}\n\n";
  
  // Group all authors with same affiliation
  $authors_aff = array();
  foreach ($authors as $name => $aff)
  {
    if (!isset($authors_aff[$aff]))
    {
      $authors_aff[$aff] = array();
    }
    $authors_aff[$aff][] = $name;
  }
  $out .= "% Authors and affiliations\n";
  $out .= "\\author{%\n";
  foreach ($authors_aff as $aff => $names)
  {
    $first = true;
    $out .= "\\IEEEauthorblockN{";
    foreach ($names as $name)
    {
      if ($first)
      {
        $first = false;
      }
      else
      {
        $out .= ", ";
      }
      $out .= $name;
    }
    $out .= "}\n";
    $out .= "\\IEEEauthorblockA{%\n";
    foreach ($affiliations[$aff] as $line)
    {
      $out .= $line."\\\\\n";
    }
    $out .= "}\n";
  }
  $out .= "}\n\n";
  $out .= "\\input includes.tex\n\n";
  $out .= "\\begin{document}\n\n";
  $out .= "\\maketitle\n";
  $out .= "\\input abstract.tex\n";
  file_put_contents($out_folder."preamble-ieee.inc.tex", $out);
  
  // IEEE Journal: just replace conf by journal in documentclass
  $out = str_replace("\\documentclass[conference]", "\\documentclass[journal]", $out);
  $out .= "\n% Fixing bug in the definition of \\markboth in IEEEtran class\n% See http://tex.stackexchange.com/a/88864\n\\makeatletter\n\\let\\l@ENGLISH\\l@english\n\\makeatother\n";
  file_put_contents($out_folder."preamble-ieee-journal.inc.tex", $out);
  
  // Postamble
  $out = "";
  $out .= <<<EOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This is an auto-generated file. DO NOT EDIT!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOD;
  $out .= "\n\\bibliographystyle{abbrv}\n";
  $out .= "\\bibliography{paper}\n";
  $out .= "\\end{document}\n";
  file_put_contents($out_folder."postamble-ieee.inc.tex", $out);
  
  // IEEE Journal: samething
  file_put_contents($out_folder."postamble-ieee-journal.inc.tex", $out);
} // }}}

{ // ACM {{{
  
  // Preamble
  $out = "";
  $out .= <<<EOD
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This is an auto-generated file. DO NOT EDIT!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\documentclass{sig-alternate}
\pdfpagewidth=8.5truein
\pdfpageheight=11truein

% Usual packages
\usepackage[utf8]{inputenc}  % UTF-8 input encoding
\usepackage[T1]{fontenc}     % Type1 fonts
\usepackage{lmodern}         % Improved Computer Modern
\usepackage{microtype}       % Better handling of typo
\usepackage[english]{babel}  % Hyphenation
\usepackage{graphicx}        % Import graphics
\usepackage{cite}            % Better handling of citations
\usepackage{hyperref}        % Better handling of references in PDFs
\usepackage{comment}         % To comment out blocks of text

% Fix ACM's awkward 2-column justification rules
\sloppy

% Paper Metadata
\conferenceinfo{OUTATIME'55,} {November 5--12, 1955, Hill Valley, CA.}
\CopyrightYear{1955}
\crdata{978-1-4503-0116-9/10/09}
\clubpenalty=10000
\widowpenalty = 10000
EOD;

  $out .= "\n\n% Title\n";
  $out .= "\\title{".$title."}\n\n";
  
  // Group all authors with same affiliation
  $authors_aff = array();
  foreach ($authors as $name => $aff)
  {
    if (!isset($authors_aff[$aff]))
    {
      $authors_aff[$aff] = array();
    }
    $authors_aff[$aff][] = $name;
  }
  $out .= "% Authors and affiliations\n";
  $out .= "\\numberofauthors{".count($affiliations)."}\n";
  $out .= "\\author{%\n";
  foreach ($authors_aff as $aff => $names)
  {
    $first = true;
    $out .= "\\alignauthor ";
    foreach ($names as $name)
    {
      if ($first)
      {
        $first = false;
      }
      else
      {
        $out .= ", ";
      }
      $out .= $name;
    }
    $out .= "\\\\\n";
    foreach ($affiliations[$aff] as $line)
    {
      $out .= "\\affaddr{".$line."} \\\\\n";
    }
  }
  $out .= "}\n";
  $out .= "\\input includes.tex\n\n";
  $out .= "\\begin{document}\n\n";
  $out .= "\\maketitle\n";
  $out .= "\\input abstract.tex\n";
  file_put_contents($out_folder."preamble-acm.inc.tex", $out);
  
  // Postamble
  $out = "";
  $out .= <<<EOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This is an auto-generated file. DO NOT EDIT!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOD;
  $out .= "\n\\bibliographystyle{abbrv}\n";
  $out .= "\\bibliography{paper}\n";
  $out .= "\\balancecolumns\n";
  $out .= "\\end{document}\n";
  file_put_contents($out_folder."postamble-acm.inc.tex", $out);
} // }}}

{ // Elsevier article {{{
  
  // Preamble
  $out = "";
  $out .= <<<EOD
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This is an auto-generated file. DO NOT EDIT!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\documentclass[preprint,12pt]{elsarticle}

% Usual packages
\usepackage[utf8]{inputenc}  % UTF-8 input encoding
\usepackage[T1]{fontenc}     % Type1 fonts
\usepackage{lmodern}         % Improved Computer Modern font
\usepackage{microtype}       % Better handling of typo
\usepackage[english]{babel}  % Hyphenation
\usepackage{graphicx}        % Import graphics
\usepackage{hyperref}        % Better handling of references in PDFs
\usepackage{comment}         % To comment out blocks of text
\biboptions{sort&compress}   % Sort and compress citations

\journal{Nuclear Physics B}

% User-defined includes
\input includes.tex

\begin{document}

\begin{frontmatter}
EOD;

  $out .= "\n\n% Title\n";
  $out .= "\\title{".$title."}\n\n";
  
  // Group all authors with same affiliation
  $out .= "% Authors and affiliations\n";
  foreach ($authors as $name => $aff)
  {
    $out .= "\\author{";
    $out .= $name."\\fnref{label".$aff."}";
    $out .= "}\n";
  }
  foreach ($affiliations as $key => $lines)
  {
    $out .= "\\fntext[label$key]{";
    $first = true;
    foreach ($lines as $line)
    {
      if ($first)
      {
        $first = false;
      }
      else
      {
        $out .= ", ";
      }
      $out .= $line;
    }
    $out .= "}\n";
  }
  $out .= "\\input abstract.tex\n";
  $out .= "\\end{frontmatter}\n";
  file_put_contents($out_folder."preamble-elsarticle.inc.tex", $out);
  
  // Postamble
  $out = "";
  $out .= <<<EOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This is an auto-generated file. DO NOT EDIT!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOD;
  $out .= "\n\\bibliographystyle{elsarticle-num}\n";
  $out .= "\\bibliography{paper}\n";
  $out .= "\\end{document}\n";
  file_put_contents($out_folder."postamble-elsarticle.inc.tex", $out);
} // }}}

// }}}

// :wrap=none:folding=explicit:
?>
