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

/**
 * Representation of a set of BibTeX entries. This class can parse a
 * BibTeX file and make its contents available as an associative array
 * of key-value pairs. Additionally, the class can export this data into
 * a MySQL table.
 * <b>NOTE:</p> this class assumes that the default internal encoding for
 * strings is UTF-8. If not, set the internal encoding to UTF-8 by calling
 * <pre>
 * mb_internal_encoding("UTF-8")
 * </pre>
 */
class Bibliography // {{{
{
  // The array of all entries
  var $m_entries = array();
  
  // The name of the database table when exporting to SQL
  static $db_name = "entries";
  
  /**
   * Constructs a Bibliiography object from data in a given filename
   * @param $filename The filename to read from
   */
  public function __construct($filename = null) // {{{
  {
    if (isset($filename))
    {
      $cont = file_get_contents($filename);
      $this->parse($cont);
    }
  } // }}}
  
  /**
   * Adds an entry from another bibliography to the current one.
   * @param $k The entry's key
   * @param $e The entry to add
   */
  public function addEntry($k, $e) // {{{
  {
    $this->m_entries[$k] = $e;
  } // }}}
  
  /**
   * Gets data for entry with a given BibTeX key
   * @param $key The entry's key
   * @return An associative array containing the entry's data
   */
  public function getEntry($key) // {{{
  {
    return $this->m_entries[$key];
  } // }}}
  
  /**
   * Determines if the bibliography contains a specific entry.
   * @param $key The entry's key
   * @return {@code true} if the entry is present, {@code false} otherwise
   */
  public function containsEntry($key) // {{{
  {
    return isset($this->m_entries[$key]);
  } // }}}
  
  /**
   * Get the list of entries in an associative array whose key is
   * the value of some parameter (e.g. "year")
   * @param $param_name The name of the parameter to group the entries
   * @param $allowed_types Only list entries whose bibtex type is an
   *   element of this array. If not set or empty, all entries will be
   *   considered.
   */
  public function getEntriesByParameter($param_name, $allowed_types = array()) // {{{
  {
    $years_array = array();
    foreach ($this->m_entries as $bibtex_name => $bibtex_entry)
    {
      $type = $bibtex_entry["bibtex_type"];
      if (!empty($allowed_types) && !in_array($type, $allowed_types))
        continue;
      if (!isset($bibtex_entry[$param_name]))
      {
        $pn = "none";
      }
      else
        $pn = $bibtex_entry[$param_name];
      if (!isset($years_array[$pn]))
        $years_array[$pn] = array();
      $years_array[$pn][$bibtex_name] = $bibtex_entry;
    }
    return $years_array;
  } // }}}
  
  /**
   * Gets an entry based on its title. This is useful when combining data
   * from another source with data found in the BibTeX, and the BibTeX
   * identifier for the paper is not known (hence a search based on the
   * title). The method first performs a few translations on the title to
   * make sure it can be found: upper/lowercases are ignored, multiple
   * spaces are converted to a single space, and braces and other characters
   * are ignored.
   * @param $title The title of the paper to look for
   * @param $entry_type The type of entry (article, inproceedings, etc.)
   *   to search
   * @param $key Optional. If given, the BibTeX key of the found entry will be
   *    written into that variable.
   * @return A <em>single</em> entry for the paper, if found
   */
  public function getEntryByTitle($title, $entry_type, &$bibtex_key = null) // {{{
  {
    // A little manicure on the input title
    $title = Bibliography::replaceAccents($title);
    $title = Bibliography::unspace($title);
    $title = Bibliography::removeBraces($title);
    $title = Bibliography::removePunctuation($title);
    $title = strtolower($title);
    // Now search
    foreach ($this->m_entries as $key => $entry)
    {
      if ($entry_type !== "" && $entry["bibtex_type"] !== $entry_type)
        continue; // Wrong type; skip
      if (!isset($entry["title"]))
      	continue; // No title; skip
      $e_title = $entry["title"];
      $e_title = Bibliography::removeBraces($e_title);
      $e_title = Bibliography::removePunctuation($e_title);
      $e_title = strtolower($e_title);
      if ($e_title == $title)
      {
        $bibtex_key = $key;
      	return $entry;
      }
    }
    return null;
  } // }}}
  
  /**
   * Exports the contents of a bibliography to a set of SQL instructions.
   */
   public function toSql() // {{{
  {
    $out = "";
    $out .= "-- This file was autogenerated by a Script With No Name\n";
    $out .= "-- on ".date("Y-m-d").". It represents a set of BibTeX entries.\n\n";
    $schema = $this->getParameterSet();
    $out .= "-- Table schema\n";
    $out .= "CREATE TABLE `".Bibliography::$db_name."` (\n";
    $out .= "  `identifier` varchar(128) NOT NULL,\n";
    foreach ($schema as $p_name)
    {
      $type = Bibliography::guessType($p_name);
      $out .= "  `$p_name` $type DEFAULT NULL,\n";
    }
    $out .= "  PRIMARY KEY (`identifier`)\n";
    $out .= ") ENGINE=MyISAM DEFAULT CHARSET=utf8;\n\n";
    $out .= "-- Entry data\n";
    foreach ($this->m_entries as $bibtex_name => $bibtex_entry)
    {
      $first = true;
      $out .= "INSERT INTO `".Bibliography::$db_name."` SET `identifier` = '".Bibliography::escapeSql($bibtex_name)."'";
      foreach ($bibtex_entry as $k => $v)
      {
        $out .= ", `$k` = '".Bibliography::escapeSql($v)."'";
      }
      $out .= ";\n";
    }
    return $out;
  } // }}}
  
  /**
   * Guess the (SQL) type of a parameter based on its name. If no guess
   * can be made, the type defaults to varchar(128).
   * @param The parameter name
   * @return The guessed data type
   */
  protected static function guessType($name) // {{{
  {
    $type = "";
    switch ($name)
    {
      case "rate":
      case "year":
        $type = "int(11)";
        break;
      default:
        $type = "varchar(128)";
        break;
    }
    return $type;
  } // }}}
  
  /**
   * Escapes MySQL special characters
   * @param $s The string to escape
   * @return The escaped string
   */
  private static function escapeSql($s) // {{{
  {
    $matches = array("\\", "'", "\"" /*,"\0", "\b", "\n", "\r", "\t"*/);
    $replacements = array("\\\\", "\\'", "\\\"", /*"\\0", "\\b", "\\n", "\\r",
      "\\t"*/);
    $st = str_replace($matches, $replacements, $s);
    return $st;
  } // }}}
  
  /**
   * Replaces multiple whitespace characters by a single space
   * @param $s The string to handle
   * @return The transformed string
   */
  public static function unspace($s) // {{{
  {
    return preg_replace("/\\s\\s*/ms", " ", $s);
  } // }}}
  
  /**
   * Replaces LaTeX character sequences for accented letters by their
   * proper UTF-8 symbol.
   * @param $s The string to handle
   * @return The transformed string
   */
  public static function replaceAccents($s) // {{{
  {
    $out = $s;
    $patterns_braces = array(
      "{\\'a}", "{\\`a}", "{\\^a}", "{\\\"a}", "{\\~a}", "{\\aa}", "{\\ae}",
      "{\\'A}", "{\\`A}", "{\\^A}", "{\\\"A}", "{\\~A}", "{\\AA}", "{\\AE}",
      "{\\c{c}}",
      "{\\c{C}}",
      "{\\'e}", "{\\`e}", "{\\^e}", "{\\\"e}",
      "{\\'E}", "{\\`E}", "{\\^E}", "{\\\"E}",
      "{\\'i}", "{\\`i}", "{\\^i}", "{\\\"i}", "\'{\i}",
      "{\\'I}", "{\\`I}", "{\\^I}", "{\\\"I}",
      "{\\~n}",
      "{\\~N}",
      "{\\'o}", "{\\`o}", "{\\^o}", "{\\\"o}", "{\\~o}", "{\\oe}", "{\\o}",
      "{\\'O}", "{\\`O}", "{\\^O}", "{\\\"O}", "{\\~O}", "{\\OE}", "{\\O}",
      "{\\'u}", "{\\`u}", "{\\^u}", "{\\\"u}",
      "{\\'U}", "{\\`U}", "{\\^U}", "{\\\"U}",
      "{\\\"s}", "{!`}", "{?`}", "{\\&}"
      );
    // Same thing without enclosing braces
    $patterns_nobraces = array(
      "\\'a", "\\`a", "\\^a", "\\\"a", "\\~a", "\\aa", "\\ae",
      "\\'A", "\\`A", "\\^A", "\\\"A", "\\~A", "\\AA", "\\AE",
      "\\c{c}",
      "\\c{C}",
      "\\'e", "\\`e", "\\^e", "\\\"e",
      "\\'E", "\\`E", "\\^E", "\\\"E",
      "\\'i", "\\`i", "\\^i", "\\\"i", "\\'i",
      "\\'I", "\\`I", "\\^I", "\\\"I",
      "\\~n",
      "\\~N",
      "\\'o", "\\`o", "\\^o", "\\\"o", "\\~o", "\\oe", "\\o",
      "\\'O", "\\`O", "\\^O", "\\\"O", "\\~O", "\\OE", "\\O",
      "\\'u", "\\`u", "\\^u", "\\\"u",
      "\\'U", "\\`U", "\\^U", "\\\"U",
      "\\\"s", "!`", "?`", "\\&"
      );
    $replacements = array(
      "á", "à", "â", "ä", "ã", "å", "æ",
      "Á", "À", "Â", "Ä", "Ã", "Å", "Æ",
      "ç",
      "Ç",
      "é", "è", "ê", "ë",
      "É", "È", "Ê", "Ë",
      "í", "ì", "î", "ï", "í",
      "Í", "Ì", "Î", "Ï",
      "ñ",
      "Ñ",
      "ó", "ò", "ô", "ö", "õ", "œ", "ø",
      "Ó", "Ò", "Ô", "Ö", "Õ", "Œ", "Ø",
      "ú", "ù", "û", "ü",
      "Ú", "Ù", "Û", "Ü",
      "ß", "¡", "¿", "&");
    $out = str_replace($patterns_braces, $replacements, $out);
    $out = str_replace($patterns_nobraces, $replacements, $out);
    return $out;
  } // }}}
  
  /**
   * Explodes an author name into its first name, von part, last name and
   * jr. part according to BibTeX's rules
   * @param $s The string of the author's name. It is supposed to be decoded
   *   (i.e. the MySQL escape sequences are removed).
   * @return An array with 4 indexes, numbered 0-3, corresponding to the 4
   *   parts of the name
   */
  public static function explodeAuthorName($name) // {{{
  {
    $vons = array("von der", "van der", "von", "van", "du", "de", "de la");
    $jrs = array("Jr.", "Sr.", "II", "III");
    $name_tokens = array();
    $exploded = array("", "", "", "");
    // Enclose every word into braces if not already
    $name_parts = explode(" ", $name);
    foreach ($name_parts as $name_part)
    {
      // We use mb_substr instead of $name_part[0] to be multibyte-safe
      $first = mb_substr($name_part, 0, 1);
      $last = mb_substr($name_part, mb_strlen($name_part) - 1, 1);
      if ($first !== "{" && $last !== "}")
        $name_tokens[] = $name_part;
      if ($first === "{" && $last === "}")
        $name_tokens[] = substr($name_part, 1, mb_strlen($name_part) - 2);
      if ($first === "{" && $last !== "}")
        $temp_name = substr($name_part, 1, mb_strlen($name_part) - 1);
      if ($first !== "}" && $last === "}")
        $name_tokens[] = $temp_name." ".substr($name_part, 0, mb_strlen($name_part) - 1);
    }
    // Now, every token that should be considered as a single word is
    // an element in the array. We proceed according to BibTeX rules.    
    for ($i = 0; $i < count($name_tokens); $i++)
    {
      $token = $name_tokens[$i];
      if (in_array($token, $vons))
      {
        // There is a von part; add it and remove it from the name
        $exploded[1] = $token;
        unset($name_tokens[$i]);
        $name_tokens = array_values($name_tokens);
        $i--;
      }
      if (in_array($token, $jrs))
      {
        // There is a Jr. part; add it and remove it from the name
        $exploded[3] = $token;
        unset($name_tokens[$i]);
        $name_tokens = array_values($name_tokens);
        $i--;
      }
    }
    // The last remaining token is the last name, the rest is the first name
    $exploded[2] = $name_tokens[count($name_tokens) - 1];
    unset($name_tokens[count($name_tokens) - 1]);
    $exploded[0] = implode($name_tokens, " ");
    return $exploded;
  } // }}}
  
  /**
   * Rebuilds the author name from the exploded list of all 4 parts
   * (see explodeAuthorName)
   * @param $parts An array of name parts
   * @param $initial Optional. If set to true, will shorten first name to
   *   initials only
   * @return A string with the rebuilt author name
   */
  public static function implodeAuthorName($parts, $initials = false) // {{{
  {
    $out = "";
    if ($initials === true)
    {
      $first_names = explode(" ", $parts[0]);
      $out_first_name = "";
      foreach ($first_names as $fn)
      {
        $out_first_name .= mb_substr($fn, 0, 1).".";
      }
      $parts[0] = $out_first_name;
    }
    foreach ($parts as $part)
    {
      if (!empty($part))
        $out .= $part." ";
    }
    return trim($out);
  } // }}}
  
  /**
   * Removes occurrences of curly brackets from a string
   * @param $s The string to handle
   * @return The transformed string
   */
  public static function removeBraces($s) // {{{
  {
    $out = $s;
    $out = str_replace(array("{", "}"), array("", ""), $out);
    return $out;
  } // }}}
  
  /**
   * Removes occurrences of punctuation symbols from a string
   * @param $s The string to handle
   * @return The transformed string
   */
  public static function removePunctuation($s) // {{{
  {
    $out = $s;
    $out = str_replace(array(".", ",", ";", ":"), array("", "", "", ""), $out);
    return $out;
  } // }}}
  
  /**
   * Collates all the parameters used in at least one entry in the
   * bibliography
   */
  private function getParameterSet() // {{{
  {
    $parameters = array();
    foreach ($this->m_entries as $bibtex_name => $bibtex_entry)
    {
      $entry_params = array_keys($bibtex_entry);
      $parameters = array_merge($parameters, $entry_params);
    }
    $unique_parameters = array_unique($parameters);
    return $unique_parameters;
  } // }}}
  
  /**
   * Parse the contents of a BibTeX file. The parser takes a shortcut,
   * and detects the end of an entry by looking for a closing curly
   * bracket alone on its line (perhaps surrounded by whitespace
   * characters). Caveat emptor!
   * @param $contents The contents of the BibTeX file
   */
  private function parse($contents) // {{{
  {
    $entries = array();
    preg_match_all("/@(\\w+?)\\{([^,]+?),(.*?)\\n\\s*?\\}\\s*?\\n/ms", 
      $contents, $entries, PREG_SET_ORDER);
    foreach ($entries as $entry)
    {
      $bibtex_type = $entry[1];
      $bibtex_name = $entry[2];
      $bibtex_contents = $entry[3].",\n"; // Newline added so that all entries are followed by one
      preg_match_all("/(\\w+?)\\s*=\\s*\\{(.*?)\\},\\n/ms", 
        $bibtex_contents, $pairs, PREG_SET_ORDER);
      $params = array();
      foreach ($pairs as $pair)
      {
        $k = $pair[1];
        $v = $pair[2];
        $params["raw"][$k] = Bibliography::unspace($v); // We keep the original BibTeX string in the "raw" subarray
        $params[$k] = Bibliography::removeBraces(
          Bibliography::replaceAccents(Bibliography::unspace($v)));
      }
      $params["bibtex_type"] = $bibtex_type;
      $this->m_entries[$bibtex_name] = $params;
    }
  } // }}}
  
  /**
   * Outputs the contents of the bibliography as a BibTeX string
   */
  public function toBibTeX() // {{{
  {
    $out = "";
    $tab_pad = 15;
    foreach ($this->m_entries as $bibtex_name => $data)
    {
      $out .= "@".$data["bibtex_type"]."{".$bibtex_name.",\n";
      foreach ($data["raw"] as $k => $v)
      {
        if ($k === "bibtex_type")
          continue; // We already processed it
        $out .= "  ".$k.str_repeat(" ", $tab_pad - mb_strlen($k))."= {";
        $out .= str_replace("\n", "\n".str_repeat(" ", $tab_pad + 5), wordwrap($v, 55, "\n"));
        $out .= "},\n";
      }
      $out = mb_substr($out, 0, mb_strlen($out) - 2); // Remove last comma
      $out .= "\n}\n\n";
    }
    return $out;
  } // }}}
  
  /**
   * Sets/replaces the value of a field in a BibTeX entry. The new
   * value overwrites the old one both in the formatted and in the
   * "raw" copy of the entry.
   * @param $bibtex_key The ID of the entry to modify
   * @param $p The field name
   * @param $v The field value
   */
  public function setValue($bibtex_key, $p, $v) // {{{
  {
    $entry = $this->m_entries[$bibtex_key];
    $entry[$p] = $v;
    $entry["raw"][$p] = $v;
    $this->m_entries[$bibtex_key] = $entry;
  } // }}}
  
  public static function dotifyName($name) // {{{
  {
    if (strpos($name, "{") !== false)
    {
      // Last name delimited by braces: TO BE IMPLEMENTED LATER
    }
    else
    {
      // Last name is the last word
      $parts = explode(" ", $name);
      $out = "";
      for ($i = 0; $i < count($parts) - 1; $i++)
      {
        $n_part = $parts[$i];
        $out .= $n_part[0].". ";
      }
      $out .= $parts[count($parts) - 1];
      return $out;
    }
  } // }}}
  
  public static function dotifyNames($names) // {{{
  {
    $new_names = array();
    $name_list = explode(" and ", $names);
    foreach ($name_list as $name)
    {
      $new_name = Bibliography::dotifyName($name);
      $new_names[] = $new_name;
    }
    $new_name_string = implode(", ", $new_names);
    return $new_name_string;
  } // }}}
  
} // }}}

// :folding=explicit:wrap=none:
?>
