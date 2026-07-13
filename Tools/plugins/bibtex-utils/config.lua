-- Sample plugin configuration
return {
	textidote = "textidote",
	report    = "textidote.html",
	language  = "en",
	shorten   = {
		journal = {
			["Journal"]                             = "J.",
			["Transactions"]                        = "Trans.",
			["International"]                       = "Intl."
		},
		booktitle = {
			["Lecture Notes in Computer Science"]   = "LNCS",
			["Proceedings"]                         = "Proc."
		},
		publisher = {
			["Association for Computing Machinery"] = "ACM",
			["Springer Verlag"]                     = "Springer"
		}
	}
}
-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: