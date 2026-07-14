return {
	id           = "mk",
	name         = "LaTeXmk",
	description  = "Compile using latexmk",
	author       = "Sylvain Hallé",
	version      = "1.0",
	date         = "2026-07-13",
	url          = "https://sylvainhalle.github.io/PaperShell/themes",
	
	-- Dependencies. List here all module IDs whose presence is required
	-- to use this plugin.
	depends      = {
	},
	
	-- Menu entries.
	menu         = {
		{
			verb    = {"mk", "latexmk"},
			name    = "LaTeXmk",
			icon    = { nerd = "\u{2714}" },
			tooltip = "Compile using latexmk",
			actions = {
				{
					verb = {"c", "compile"},
					name = "Compile",
					help = {"mk compile", "Compiles the paper"},
					tooltip = "Compile the paper",
					call = "compile"
				},
				{
					verb = {"l", "clean"},
					name = "Clean",
					help = {"mk clean", "Cleans the project"},
					tooltip = "Clean the project",
					call = "clean"
				}
			}
		}
	}
}