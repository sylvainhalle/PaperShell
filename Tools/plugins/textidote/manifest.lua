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
			actions = {
				{
					verb = {"c", "check"},
					help = {"tx check [-b]", "Checks spelling and grammar"},
					call = "textidote_check"
				},
				{
					verb = {"wc", "word-count"},
					help = {"tx wc", "Counts the words in the paper"},
					call = "textidote_count"
				}
			}
		}
	}
}