--[[
    PaperShell, a flexible LaTeX environment for scientific papers
    Copyright (C) 2015-2026  Sylvain Hallé

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

-- Return codes
local RET_OK						 = 0
local RET_NO_TEXTIDOTE   = 5

local TextidotePlugin = {}
TextidotePlugin.__index = TextidotePlugin

function TextidotePlugin:new(env, ret)
	local obj = {
		_env		= assert(env, "plugin environment is required"),
		_ret		= ret or {},
		_config = config
	}
	return setmetatable(obj, TextidotePlugin)
end

function TextidotePlugin:prerequisites()
	if not self._env.files.command_exists(self._env.settings.textidote) then
		self._ret.error = {
			message = {
				"This action requires TeXtidote to be performed.",
				"You can download TeXtidote at https://github.com/sylvainhalle/textidote"
			},
			code = RET_NO_TEXTIDOTE
		}
	end
end

function TextidotePlugin:textidote_count()
		local command = string.format("cd %s && %s --read-all --clean %s/%s 2> /dev/null", self._env.project_root, self._env.settings.textidote, self._env.outdir, self._env.mainfile)
		local result = self._env.files.run(command)
		local words = 0
		for word in result:gmatch("[^%s]+") do words = words + 1 end
		self._ret.success = {
			message = {
				words .. " word(s)"
			}
		}
end

function TextidotePlugin:textidote_check()
	local command = string.format("cd %s && %s --check %s --read-all --output html %s/%s 2> /dev/null",
			self._env.project_root, self._env.settings.textidote, self._env.settings.language, self._env.outdir, self._env.mainfile)
		local report = self._env.files.run(command)
		local report_filename = self._env.project_root .. "/" .. self._env.settings.report
		self._env.files.write_file(report_filename, report)
		if self._env.arg[0] == "-b" then
			if not open_browser("file://" .. self._env.project_root .. "/" .. self._env.settings.report) then
				self._ret.warning = {
					message = {"Could not open browser"}
				}
			end
		end
end

function TextidotePlugin:postrequisites()
end

return {
	plugin = TextidotePlugin
}

-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: