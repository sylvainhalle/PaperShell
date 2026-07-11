return {
	id           = "bibtex-utils",
	name         = "BibTeX utilities",
	description  = "Clean, merge and validate BibTeX files",
	author       = "Sylvain Hallé",
	version      = "1.0",
	date         = "2026-07-06",
	url          = "https://sylvainhalle.github.io/PaperShell/themes",
	
	-- Dependencies. List here all module IDs whose presence is required
	-- to use this plugin.
	depends      = {
	},
	
	-- Menu entries.
	menu         = {
		{
			verb         = {"bb", "bibtex"},
			name         = "BibTeX",
			icon         = { nerd = "\u{1f56e}" },
			tooltip      = "Clean, merge and validate BibTeX files",
			actions = {
				{
					verb = {"d", "duplicates"},
					name = "Duplicates",
					tooltip = "Handle duplicate bib entries",
					actions = {
						{
							verb = {"s", "show"},
							name = "Show",
							help = {"bb duplicates show", "Shows duplicate entries"},
							tooltip = "Show duplicate entries",
							call = "show_duplicates"
						},
						{
							verb = {"d", "delete"},
							name = "Delete",
							help = {"bb duplicates delete", "Deletes duplicate entries"},
							tooltip = "Delete duplicate entries",
							call = "delete_duplicates"
						}
					}
				},
				{
					verb = {"m", "missing"},
					name = "Missing",
					tooltip = "Handle missing fields and entries",
					actions = {
						{
							verb = {"f", "fields"},
							name = "Fields",
							help = {"bb missing fields", "Shows entries with missing fields"},
							tooltip = "Show entries with missing fields",
							call = "show_missing_fields"
						}
					}
				},
				{
					verb = {"c", "clean"},
					name = "Clean",
					help = {"bb clean", "Cleans the bib file"},
					tooltip = "Clean the bib file",
					call = "clean_bib"
				},
				{
					verb = {"s", "shorten"},
					name = "Shorten",
					help = {"bb shorten", "Shortens the values"},
					tooltip = "Shorten the entries",
					call = "shorten"
				},
				{
					verb = {"u", "uncited"},
					name = "Uncited",
					help = {"bb uncited", "Finds uncited entries"},
					tooltip = "Find uncited entries",
					call = "find_uncited"
				}
			}
		}
	}
}