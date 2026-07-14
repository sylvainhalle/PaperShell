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
local lfs    = require "lfs"
local config = dofile(os.getenv("PWD") .. "/plugins/mk/config.lua")

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

function MkPlugin:compile()
	local s, c = self._env.files.run(string.format("cd %s/Source && latexmk", self._env.project_root))
	if self._config.raw then
		out = self._env.utils.explode("\n", s)
	else
		out = self:filter_lines(s)
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

function MkPlugin:clean()
	local s, c = self._env.files.run(string.format("cd %s/Source && latexmk -c", self._env.project_root))
	if self._config.raw then
		out = self._env.utils.explode("\n", s)
	else
		out = self:filter_lines(s)
	end
  if c == RET_OK then
  	self._ret.success = {
  		code = c,
  		message = out
  	}
  else
  	self._ret.error = {
  		code = c,
  		message = out
  	}
  end
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