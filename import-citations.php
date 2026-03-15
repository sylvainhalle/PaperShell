<?php
/**************************************************************************
  A Flexible LaTeX Article Environment
  Copyright (C) 2015-2025  Sylvain Hallé

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
require_once("bibtex-bib.lib.php");

/*
 * Retrieves all citations in paper.tex, finds those that are not present in
 * paper.bib, and imports them from another bib file specified as a command line
 * argument. The entries found are printed to the standard output.
 *
 * You can send them to the clipboard by piping the output to xclip, e.g.:
 *
 * php import-citations.php somefile.bib | xclip
 */
if (count($argv) < 2)
	die("No bib file specified");
$paper = file_get_contents("Source/paper.tex");
$bibfile = new Bibliography("Source/paper.bib");
$bibsource = new Bibliography($argv[1]);
if (!preg_match_all("/cite\\{(.*?)\\}/ms", $paper, $citations))
	die("No citation");
$outbib = new Bibliography();
foreach ($citations[1] as $citation)
{
	$parts = explode(",", $citation);
	foreach ($parts as $key)
	{
		$key = trim($key);
		if (!$bibfile->containsEntry($key) && $bibsource->containsEntry($key))
		{
			$bibdata = $bibsource->getEntry($key);
			$outbib->addEntry($key, $bibdata);
		}
	}
}
echo $outbib->toBibtex();
?>