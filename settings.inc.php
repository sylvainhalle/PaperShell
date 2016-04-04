<?php
// You can override any defaults by setting values here
$config = array_merge($config, array(
    /*
     * The name (without extension) of the bib file, if not the default
     * "paper.bib".
     */
    //"bib-name" => "report",
    
    /*
     * The name of the journal to compile for.
     * - In the ACM journal style, you must use a journal name found in
     *   acmsmall.cls.
     * - In the Elsevier journal style, you can use any string you like.
     * - You can ignore this parameter for all other styles.
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
    //"year" => 1955,
    
    /*
     * The article's publication month (if not the current month).
     * Used only in the ACM journal style.
     */
    //"month" => 3,
    
    /*
     * If the paper is published in a conference, the acronym of
     * the conference (e.g. "ICFF '16"). Used only in ACM conference
     * proceedings.
     */
    //"conference" => "OUTATIME '55",
    
    /*
     * If the paper is published in a conference, the dates and
     * location of the conference. Used only in ACM conference
     * proceedings.
     */
    //"conference-loc" => "November 5--12, 1955, Hill Valley, CA",
    
    /*
     * Copyright information to be overridden. Used only in ACM conference
     * proceedings.
     */
    //"copyright" => "0-89791-88-6/97/05",
    
    /*
     * The article's DOI
     */
    //"doi" => "0000001.0000001",
    
    /*
     * The journal's ISSN
     */
    //"issn" => "1234-56789",
    
    /*
     * The journal's ISBN
     */
    //"isbn" => "1234-56789",
    
    /*
     * Whether the preamble of an ACM conference paper will include the
     * package fixacm.sty, which is not standard. Has no effect in
     * other styles.
     */
    //"fix-acm" => true,
    
    /*
     * Whether to use the Computer Modern font or the Times font. This
     * only works for Springer LNCS, and is ignored in all other styles.
     */
    //"use-times" => true,
    
    /*
     * A bibliography style. Use it to override the bib style provided
     * by each editor. Leave it to the empty string otherwise.
     */
    //"bib-style" => "abbrv",
    
    /*
     * A dummy parameter, just so you don't bother about removing
     * the comma from the last uncommented parameter above. Leave this
     * uncommented at all times.
     */
    "dummy" => "dummy"
));
?>