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

-- Dependencies
local pwd    = debug.getinfo(1,'S').source:match("@(.*)/[^/]*$")
local lfs    = require "lfs"
local config = dofile(pwd .. "/config.lua")

-- Return codes
local RET_OK						 = 0

local MkPlugin = {}
MkPlugin.__index = MkPlugin

function MkPlugin:new(env, ret)
	local obj = {
		_env		= assert(env, "plugin environment is required"),
		_ret		= ret or {},
		_config = config
	}
	return setmetatable(obj, MkPlugin)
end

local function rule_matches(rule, line)
	if rule.matches then
		return rule.matches(line)
	end
	return line:match(rule.start_pattern) ~= nil
end

local function rule_ends(rule, line)
	if rule.ends then
		return rule.ends(line)
	end
	return not rule.end_pattern
			or line:match(rule.end_pattern) ~= nil
end

function MkPlugin:filter_lines(s)
	local rules = self._config.filters
	table.sort(rules, function(a, b)
		return (a.priority or 0) > (b.priority or 0)
	end)
	local lines = self._env.utils.explode("\n", s)
	local active = nil
	for _, line in ipairs(lines) do
		if active then
			local n = #active.entries
			active.entries[n] = active.entries[n] .. "\n" .. line --" " .. line:gsub("%s+", " ")
			if rule_ends(active, line) then
				active = nil
			end
		else
			for _, rule in ipairs(rules) do
				if rule.priority >= 0 and rule_matches(rule, line) then
					table.insert(rule.entries, line)
					if not rule_ends(rule, line) then
						active = rule
					end
					break
				end
			end
		end
	end
	return rules
end

function MkPlugin:runmk(options)
	local s, c = self._env.files.run(string.format("cd %s/Source && latexmk %s 2> /dev/null", self._env.project_root, options or ""))
	if self._config.raw then
		out = self._env.utils.explode("\n", s)
	else
		return self:log(true)
	end
  if c == RET_OK then
  	self._ret.success = {
  		code    = c,
  		message = out
  	}
  else
  	self._ret.error = {
  		code    = c,
  		message = out
  	}
  end
end

function MkPlugin:compile()
	return self:runmk()
end

function MkPlugin:clean()
	return self:runmk("-C")
end

function MkPlugin:force()
	return self:runmk("-g")
end

function MkPlugin:print_entry(re, e, p)
	if re.capture_pattern then
		local name, m = e:gsub(re.capture_pattern.message.pattern, re.capture_pattern.message.name)
		if m == 0 then
			return
		else
			p:print(p:sfg().yellow() .. "* " .. p:srs())
			local text = e:gsub(re.capture_pattern.message.pattern, re.capture_pattern.message.text):gsub("%s+", " ")
			p:print(name .. ": ", re.capture_pattern.pad)
			p:print(text)
		end
		if re.capture_pattern.line then
			p:println(" " .. e:gsub(re.capture_pattern.line, "L%1"))
		else
			p:println("")
		end
	else
		p:println(e)
	end
end

function MkPlugin:log(inside)
	local filename = self._env.pwd .. "/Source/" .. "paper.log"
	if not self._env.files.file_exists(filename) then
		if inside then
			self._ret.success = {
				code = 0,
				message = ""
			}
			return
		else
			self._ret.error = {
				code = 1,
				message = {"File "..filename.." not found"}
			}
			return
		end
	end
	local content = self._env.files.read_file(filename)
	local report = self:filter_lines(content)
	local p = self._env.tui.Printer:new()
	p:ul():println("Summary" .. p:srs()):indent()
	for _, re in pairs(report) do
		if #re.entries > 0 then
			p:print(p:sfg().yellow() .. "* " .. p:srs() .. re.title, 24):println(": "..#re.entries)
		end
	end
	p:outdent():println()
	for _, re in pairs(report) do
		if #re.entries > 0 then
			p:ul():println(re.title .. p:srs()):indent()
			local shown = {}
			for _, e in ipairs(re.entries) do
				self:print_entry(re, e, p)
			end
		end
		p:outdent():println()
	end
	self._ret.success = {
		code = 0,
		message = p:lines()
	}
end

function MkPlugin:prerequisites()
	-- Nothing to do
end

function MkPlugin:postrequisites()
	-- Nothing to do
end

return {
	plugin = MkPlugin
}

-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: