-- Return codes
local RET_NO_TEXTIDOTE   = 5

local function prerequisites(env, ret)
	if not env.command_exists(env.settings.textidote) then
		ret.error = {
			message = {
				"This action requires TeXtidote to be performed.",
				"You can download TeXtidote at https://github.com/sylvainhalle/textidote"
			},
			code = RET_NO_TEXTIDOTE
		}
	end
end

local function textidote_count(env, ret)
    local command = string.format("cd %s && %s --read-all --clean %s/%s 2> /dev/null", env.project_root, env.settings.textidote, env.outdir, env.mainfile)
    local result = env.run(command)
    local words = 0
    for word in result:gmatch("[^%s]+") do words = words + 1 end
    ret.success = {
    	message = {
    		words .. " word(s)"
    	}
    }
end

local function textidote_check(env, ret)
	local command = string.format("cd %s && %s --check %s --read-all --output html %s/%s 2> /dev/null",
      env.project_root, env.settings.textidote, env.settings.language, env.outdir, env.mainfile)
    local report = env.run(command)
    local report_filename = env.project_root .. "/" .. env.settings.report
    env.write_file(report_filename, report)
    if env.arg[0] == "-b" then
      if not open_browser("file://" .. env.project_root .. "/" .. env.settings.report) then
        ret.warning = {
        	message = {"Could not open browser"}
        }
      end
    end
end

local function postrequisites(env, ret)
end

return {
  prerequisites  = prerequisites,
  postrequisites = postrequisites,
  textidote_count = textidote_count,
  textidote_check = textidote_check
}