<?php
// You can override any defaults by setting values here
$config = array_merge($config, array(
	
	/*
	 * The style to generate when calling set-style.php. Instead of
	 * providing it at the command line, you can set it by default here
	 * and call the script without any argument.
	 */
	//"style" => "lncs",
	
	/*
	 * The affiliations. This should be an array of arrays, where
	 * the first sub-array corresponds to institution 1 in authors.txt,
	 * the second sub-array corresponds to institution 2, etc. Leave any
	 * of these fields blank to omit them from the paper.
	 * Used only in ACM publications; for other styles, the address
	 * lines in authors.txt are sufficient.
	 */
	//"author-affiliations" => array(
	//	array(
	//		"streetaddress" => "123 Riverside Av.",
	//		"city"          => "Hill Valley",
	//		"state"         => "CA",
	//		"country"       => "USA",
	//		"postcode"      => "91234"
	//	)
	//),
	
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
     *   acmart.cls.
     * - In the Elsevier and IEEE transactions journal style, you can use any
     *   string you like.
     * - You can ignore this parameter for all other styles.
     */
    "journal-name" => "TISSEC",
    
    /*
     * The journal volume. Used only in the ACM and IEEE transactions
     * journal style.
     */
    //"volume" => 9,
    
    /*
     * The journal number. Used only in the ACM and IEEE transactions
     * journal style.
     */
    //"number" => 4,
    
    /*
     * The journal article number. Used only in the ACM journal style
     * and IEEE CS magazine style.
     */
    //"article-number" => 39,
    
    /*
     * The article's publication year (if not the current year).
     * Used only in the ACM, IEEE transactions and IEEE CS magazine styles.
     */
    //"year" => 1955,
    
    /*
     * The article's publication month (if not the current month).
     * Used only in the ACM and IEEE transactions/magazine journal style.
     */
    //"month" => 3,
    
    /*
     * Keywords associated to the article.
     * Used only in the ACM journal, IEEE transactions and LIPICS styles.
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
    //"conference-loc" => "Hill Valley, CA, USA",

    /*
     * If the paper is published in a conference, the date
     * of the conference. Used in ACM conference proceedings
     * and LIPICS.
     */
    //"conference-date" => "July 1955",
    
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
     * The 2012 ACM classification string; used only in LIPICS
     */
    //"acm-class" => "",
    
    /*
     * The 2012 ACM classification number; used only in LIPICS
     */
    //"acm-number" => "",
    
    /*
     * The ACM copyright status. One of none, acmcopyright,
     * acmlicensed, rightsretained, usgov, usgovmixed, cagov,
     * cagovmixed. Has no effect on other stylesheets.
     */
    // "acm-copyright" => "none",
    
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
     * Sets the sub-type of the document, for EasyChair proceedings.
     * Valid values are EPiC, EPiCempty, debug, verbose, notimes, withtimes,
     * a4paper, letterpaper, or the empty string. This setting is ignored in
     * every other document class.
     */
    //"easychair-type" => "",
    
    /*
     * The name of the editor. Used only in IEEE CS magazine style.
     */
    "editor-name" => "Stanford S.\\ Strickland",
    
    /*
     * The editor e-mail. Used only in IEEE CS magazine style.
     */
    "editor-email" => "strickland@hillvalley.edu",
    
    /*
     * Any other string to be appended to the parameters of the
     * \documentclass instruction. You should probably start this string
     * with a comma, since it comes after other options.
     */
    "otheropts" => "",
    
    /*
     * A dummy parameter, just so you don't bother about removing
     * the comma from the last uncommented parameter above. Leave this
     * uncommented at all times.
     */
    "dummy" => "dummy"
));
?>