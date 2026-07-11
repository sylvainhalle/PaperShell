return {
	id           = "textidote",
	name         = "TeXtidote",
	description  = "Check grammar and spelling with TeXtidote",
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
			verb    = {"tx", "textidote"},
			name    = "TeXtidote",
			icon    = { nerd = "\u{2714}" },
			tooltip = "Check grammar and spelling with TeXtidote",
			actions = {
				{
					verb = {"c", "check"},
					name = "Check",
					help = {"tx check [-b]", "Checks spelling and grammar"},
					tooltip = "Check spelling and grammar",
					call = "textidote_check"
				},
				{
					verb = {"wc", "word-count"},
					name = "Word count",
					tooltip = "Count the words in the paper",
					help = {"tx wc", "Counts the words in the paper"},
					call = "textidote_count"
				}
			}
		}
	}
}