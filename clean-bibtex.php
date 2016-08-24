<?php
/**************************************************************************
  A Flexible LaTeX Article Environment
  Copyright (C) 2015-2016  Sylvain Hallé

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
 * Cleans a bibliography by parsing it and re-outputting it. This should
 * normally uniformize the presentation of references in the file and
 * take care of removing duplicate entries.
 */
$version_string = "1.0";
echo "Clean BibTeX v".$version_string."\n(C) 2015-2016 Sylvain Hallé, Université du Québec à Chicoutimi\nhttps://github.com/sylvainhalle/PaperShell\n";
$in_filename = "Source/paper.bib";
$out_filename = "Source/paper.clean.bib";
$bib = new Bibliography($in_filename);
echo "\nCleaning up $in_filename...\n";
file_put_contents($out_filename, $bib->toBibTeX());
echo "Done. The output file is $out_filename\n\n";
?>
