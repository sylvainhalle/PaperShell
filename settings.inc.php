<?php
// You can override any defaults by setting values here
$config = array_merge($config, array(
    /*
     * The name (without extension) of the bib file, if not the default
     * "paper.bib".
     */
    //"bib-name" => "report",
    
    /*
     The name of the journal to compile for.
     - In the ACM journal style, you must use a journal name found in
       acmsmall.cls.
     - In the Elsevier journal style, you can use any string you like.
     - You can ignore this parameter for all other styles.
     */
    "journal-name" => "acmtissec",
    
    /*
     * The journal volume. Used only in the ACM journal style.
     */
    //"volume" => 9,
    
    /*
     * The journal number. Used only in the ACM journal style.
     */
    //"number" => 4,
    
    /*
     * The journal article number. Used only in the ACM journal style.
     */
    //"article-number" => 39,
    
    /*
     * The article's publication year (if not the current year).
     * Used only in the ACM journal style.
     */
    //"year" => 39,
    
    /*
     * The article's publication month (if not the current month).
     * Used only in the ACM journal style.
     */
    //"month" => 3,
    
    /*
     * The article's DOI
     */
    //"doi" => "0000001.0000001",
    
    /*
     * The journal's ISSN
     */
    //"issn" => "1234-56789",
    
    /*
     * A dummy parameter, just so you don't bother about removing
     * the comma from the last uncommented parameter above. Leave this
     * uncommented at all times.
     */
    "dummy" => "dummy"
));
?>