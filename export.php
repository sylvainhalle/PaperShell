<?php
/**************************************************************************
  A Flexible LaTeX Article Environment
  Copyright (C) 2015-2022  Sylvain Hallé

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

/*
 * Creates a stand-alone directory with all the sources. This script
 * reads the original source file (paper.tex) and replaces all non-commented
 * \input{...} instructions with the content of the file. It also includes
 * the bibliography (paper.bbl) directly within the file. The resulting,
 * stand-alone LaTeX file is copied to a new folder (Export), along with all
 * necessary auxiliary files (basically everything in the Source folder that
 * is not a .tex file).
 *
 * Normally, what is present in the Export folder is a single compilable .tex
 * file (no \include or \input), class files and images. It is suitable for
 * sending as a bundle e.g. to an editor to compile the camera-ready version.
 *
 * This script does a crude pattern matching to resolve includes. It has
 * a few caveats:
 * 
 * - A construct of the form \scalebox{0.5}{\input{fig/somefile}} currently does
 *   not work (it is replaced by nothing)
 */

// Version string
$version_string = `php generate-preamble.php --show-version`;

// Read config settings
$config = array(
	"tex-name"       => "paper",
	"bib-name"       => "paper",
	"src-folder"     => "Source",
	"num-repeats"    => 3,
	"new-folder"     => "Export",
);
if (file_exists("settings.inc.php"))
{
  include("settings.inc.php");
}

// Basic info
echo "PaperShell v".$version_string."\nA template environment for papers written in LaTeX\n(C) 2015-2021 Sylvain Hallé, Université du Québec à Chicoutimi\nhttps://github.com/sylvainhalle/PaperShell\n";

// Creates directory for stand-alone (deletes and re-creates to clean)
delete_dir($config["new-folder"]);
mkdir($config["new-folder"]);

// Resolve includes in input file
$input_text = file_get_contents($config["src-folder"]."/".$config["tex-name"].".tex");
for ($i = 0; $i < $config["num-repeats"]; $i++)
{
  preg_match_all("/^[^\\%]*\\\\input\\{(.*?)\\}/m", $input_text, $matches);
  foreach ($matches[1] as $include_filename)
  {
  	$actual_filename = $include_filename;
  	if (!ends_with($actual_filename, ".tex"))
  	{
  	  // The .tex extension is optional
  	  $actual_filename .= ".tex";
  	}
    $file_contents = file_get_contents($config["src-folder"]."/".$actual_filename);
    $file_contents = str_replace("$1", "\\$1", $file_contents);
    $file_contents = str_replace("\\", "\\\\", $file_contents);
    $input_text = preg_replace("/^([^\\%]*)\\\\input\\{".$include_filename."\\}/m", "$1".$file_contents, $input_text);
  }
}

// Add bibliography
$bib_filename = $config["src-folder"]."/".$config["tex-name"].".bbl";
if (file_exists($bib_filename))
{
  $input_text = str_replace("\\bibliography{".$config["tex-name"]."}", file_get_contents($bib_filename), $input_text);
}
else
{
  echo "File $bib_filename does not exist. Have you compiled the original paper first?\n";
}
// Comment out \bibliographystyle, we don't need it
$input_text = str_replace("\\bibliographystyle{", "%\\bibliographystyle{", $input_text);

// Puts contents in stand-alone folder
rcopy($config["src-folder"], $config["new-folder"]);
file_put_contents($config["new-folder"]."/".$config["tex-name"].".tex", $input_text);

// Done
echo "\nDone. A stand-alone version of the sources is available in folder `".$config["new-folder"]."`\n";
echo "You should go compile it to make sure everything is OK.\n";
echo "Once done, use the script `zip-export.sh` to create an archive.\n";
exit(0);

/**
 * Deletes a directory recursively
 */
function delete_dir($path) // {{{
{
    if (is_dir($path) === true)
    {
        $files = array_diff(scandir($path), array('.', '..'));
        foreach ($files as $file)
        {
            delete_dir(realpath($path) . '/' . $file);
        }
        return rmdir($path);
    }
    else if (is_file($path) === true)
    {
        return unlink($path);
    }
    return false;
} // }}}

/**
 * Copies files and non-empty directories
 */
function rcopy($src, $dst, $indent="") // {{{
{
  echo $indent."$src -> $dst\n";
  if (file_exists($dst)) rrmdir($dst);
  if (is_dir($src))
  {
    echo $indent."Creating $dst\n";
    mkdir($dst);
    $files = scandir($src);
    foreach ($files as $file)
    {
      if ($file !== "." && $file !== ".." && can_copy($src, $file))
      {
      	rcopy("$src/$file", "$dst/$file", $indent." ");
      }
    }
  }
  else if (file_exists($src)) copy($src, $dst);
} // }}}

/**
 * Removes files and non-empty directories
 */
function rrmdir($dir) // {{{
{
  if (is_dir($dir)) {
    $files = scandir($dir);
    foreach ($files as $file)
    if ($file != "." && $file != "..") rrmdir("$dir/$file");
    rmdir($dir);
  }
  else if (file_exists($dir)) unlink($dir);
} // }}}

/**
 * Determines if a file should be copied to the stand-alone folder
 */
function can_copy($folder, $filename) // {{{
{
  global $config;
  if (substr($filename, strlen($filename) - 1) === "~" || substr($filename, strlen($filename) - 3) === "tmp")
  {
    // Any temp file is not OK
    return false;
  }
  if (starts_with($filename, "labpal"))
  {
  	// LabPal files are OK
  	return true;
  }
  if (is_dir($config["src-folder"]."/".$filename) || strpos($folder, "/") !== false)
  {
    // Anything within a subfolder is OK
    return true;
  }
  $extension = substr($filename, strlen($filename) - 3);
  // In the main folder, anything with these extensions is OK too
  return $extension === "sty" || $extension === "cls"
    || $extension === "bbl"; // || $extension === "bst";
} // }}}

/**
 * Checks if a string starts with something
 * @param $string The string
 * @param $pattern The pattern to look for
 */
function starts_with($string, $pattern) // {{{
{
  if (strlen($string) < strlen($pattern))
  {
  	  return false;
  }
  return substr($string, 0, strlen($pattern)) === $pattern;
} // }}}

/**
 * Checks if a string ends with something
 * @param $string The string
 * @param $pattern The pattern to look for
 */
function ends_with($string, $pattern) // {{{
{
  return substr($string, strlen($string) - strlen($pattern)) === $pattern;
} // }}}

// :wrap=none:folding=explicit:
?>
