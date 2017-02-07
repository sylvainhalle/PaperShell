<?php
// You can override any defaults by setting values here
$config = array_merge($config, array(
    /*
     * A short title for the paper, used for running heads. If unspecified,
     * the title from authors.txt will be used
     */
    //"short-title" => "My Short Title",
    
    /*
     * The name (without extension) of the bib file, if not the default
     * "paper.bib".
     */
    //"bib-name" => "report",
    
    /*
     * Whether the paper contains an abstract.
     */
    //"abstract" => false,
    
    /*
     * If you wish to use a different font size than the default,
     * specify it here (in points)
     */
    //"point-size" => 12,
    
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
     * Keywords associated to the article.
     * Used only in the ACM journal style and LIPICS.
     */
    //"keywords" => "science, magic, art",
    
    /*
     * If the paper is published in a conference, the acronym of
     * the conference (e.g. "ICFF '16"). Used only in ACM conference
     * proceedings.
     */
    //"conference" => "OUTATIME '55",
    
    /*
     * If the paper is published in a conference, the long name of
     * the conference. Used only in LIPICS proceedings.
     */
    //"conf-name" => "42nd Conference on Very Important Topics",
    
    /*
     * If the paper is published in a conference, the location
     * of the conference. Used in ACM conference proceedings
     * and LIPICS.
     */
    //"conference-loc" => "November 5--12, 1955",

    /*
     * If the paper is published in a conference, the date
     * of the conference. Used in ACM conference proceedings
     * and LIPICS.
     */
    //"conference-date" => "November 5--12, 1955",
    
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
     * The 1998 ACM classification; used only in LIPICS
     */
    //"acm-class" => "",
    
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
     * The default path for images when using the \includegraphics{}
     * command.
     */
    //"graphicspath" => array("fig/", "whatever/"),
    
    /*
     * Set whether to use the microtype package. No good reason to
     * turn it off unless it clashes with some other package.
     */
    //"microtype" => false,
    
    /*
     * A string for the corresponding address. Used in stvrauth, ignored
     * in other styles
     */
    //"corr-addr" => "",
    
    /*
     * Set whether the paper will be typeset using double spacing.
     * Ignored in all styles except stvrauth.
     */
    //"doublespace" => true,
    
    /*
     * Set whether the hyperref package will be disabled. IEEE requires
     * the camera-ready version to have no bookmarks, so in that case set
     * this to true.
     */
    //"disable-hr" => true,
    
    /*
     * A dummy parameter, just so you don't bother about removing
     * the comma from the last uncommented parameter above. Leave this
     * uncommented at all times.
     */
    "dummy" => "dummy"
));
?>