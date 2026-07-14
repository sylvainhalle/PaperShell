return {
	id           = "export",
	name         = "Export",
	description  = "Package the paper in a self-contained bundle",
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
			verb    = {"ex", "export"},
			name    = "Export",
			icon    = { nerd = "\u{2714}" },
			tooltip = "Package the paper in a self-contained bundle",
			actions = {
				{
					verb = {"p", "pack"},
					name = "Pack",
					help = {"ex pack", "Packs all required files in an archive"},
					tooltip = "Pack all required files in an archive",
					call = "pack"
				}
			}
		}
	}
}