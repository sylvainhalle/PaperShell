return {
	raw     = false,
	filters = {
		{
			id = "undefined-reference",
			title = "Undefined references",
			severity = "warning",
			priority = 100,
			start_pattern = "LaTeX Warning: Reference .- undefined",
			end_pattern = "%.",
			capture_pattern = {
				message = {
					pattern = "^.-Reference `(.+)'.-$",
					name = "%1",
					text = ""
				},
				line    = "^.-on input line%s-(%d+).-$",
				pad     = 24
			},
			entries = {}
		},
		{
			id = "undefined-citation",
			title = "Undefined citations",
			severity = "warning",
			priority = 90,
			start_pattern = "LaTeX Warning: Citation .- undefined",
			end_pattern = "%.",
			capture_pattern = {
				message = { 
					pattern = "^.-Citation `(.+)'.-$",
					name = "%1",
					text = "",
				},
				line    = "^.-on input line%s-(%d+).-$",
				pad     = 24
			},
			entries = {}
		},
		{
			id = "overfull-box",
			title = "Overfull boxes",
			severity = "warning",
			priority = 50,
			start_pattern = "^Overfull \\[hv]box",
			end_pattern = "lines %d+--%d+",
			capture_pattern = {
				message = {
					pattern = "^.-(%d%d%d%d-)%.%d-%s-pt.-$",
					name    = "%1 pt",
					text    = ""
				},
				line    = "^.-at lines (.+)$",
				pad = 12
			},
			entries = {}
		},
		{
			id = "rerun",
			title = "Rerun required",
			severity = "notice",
			priority = 80,
			start_pattern = "Rerun to get",
			end_pattern = "%.",
			entries = {}
		},
		{
			id = "package-warning",
			title = "Package warnings",
			severity = "warning",
			priority = 10,
			start_pattern = "^Package .- Warning:",
			end_pattern = "%.",
			capture_pattern = {
				message = { 
					pattern     = "^Package%s+(.-)%s+Warning:%s*(.-)%.$",
					name        = "%1",
					text        = "%2"
				},
				pad     = 16
			},
			entries = {}
		},
		{
			id = "undefined-sequence",
			title = "Undefined sequences",
			severity = "error",
			priority = 100,
			start_pattern = "^! Undefined control sequence%.",
			end_pattern = "The control sequence at the end of the top line",
			capture_pattern = {
				message = { 
					pattern     = "^.-l%.%d+.-(%S+)\n%s+%S+%s.-$",
					name        = "%1",
					text        = ""
				},
				line    = "^.-l%.(%d+).-$",
				pad     = 24
			},
			entries = {}
		},
		{
			id = "error",
			title = "Errors",
			severity = "error",
			priority = 100,
			start_pattern = "^! LaTeX Error:",
			end_pattern = "You're in trouble",
			capture_pattern = {
				message = { 
					pattern     = "^! LaTeX Error: ([^%.]+)%..-$",
					name        = "%1",
					text        = ""
				},
				line    = "^.-l%.(%d+).-$",
				pad     = 24
			},
			unique = true,
			entries = {}
		}
	}
}
-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: