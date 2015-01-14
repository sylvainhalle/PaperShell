<?php

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
  $out .= "}\n";
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
  $out .= "}\n";
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
  file_put_contents($out_folder."postamble-acm.inc.tex", $out);
} // }}}

// :wrap=none:folding=explicit:
?>
