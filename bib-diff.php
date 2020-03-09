<?php
/*
    CCCVTK, the Canadian Common CV Toolkit
    Copyright (C) 2013-2014 Sylvain Hallé

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
*/

/*
This script compares two BibTeX files, file1.bib and file2.bib, and displays
the keys from file1 that are not present in file2.
*/
if (count($argv) < 3 || strpos("help", $argv[1]) >= 0)
{
  echo "Usage: php bib-diff.php <file1> <file2>\n";
  echo "Displays the BibTeX keys in file1 that are not present in file2\n";
  exit(1);
}
$keys_1 = get_keys(file_get_contents($argv[1]));
$keys_2 = get_keys(file_get_contents($argv[2]));

echo "Here are the keys from the first file not present in the second file:\n\n";
$diff = leo_array_diff($keys_1, $keys_2);
echo implode("\n", $diff);
echo "\n";
exit(0);

function get_keys($file_contents)
{
  $matches = array();
  preg_match_all("/@.*?\\{(.*?),/", $file_contents, $matches);
  return $matches[1];
}

// http://stackoverflow.com/a/6700430
function leo_array_diff($a, $b) {
    $map = array();
    foreach($a as $val) $map[$val] = 1;
    foreach($b as $val) unset($map[$val]);
    return array_keys($map);
}
?>
