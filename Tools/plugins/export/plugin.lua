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
local config = dofile(os.getenv("PWD") .. "/plugins/export/config.lua")

-- Return codes
local RET_OK						 = 0

local ExportPlugin = {}
ExportPlugin.__index = ExportPlugin

function ExportPlugin:new(env, ret)
	local obj = {
		_env		= assert(env, "plugin environment is required"),
		_ret		= ret or {},
		_config = config
	}
	return setmetatable(obj, ExportPlugin)
end

function ExportPlugin:should_export(path)
  local b = self._env.files.basename(path)
  if b == "paper.pdf" then return false end
  if b:match("~$") then return false end
  if b:match("%.log$") then return false end
  if b:match("%.out$") then return false end
  if b:match("%.aux$") then return false end
  if b:match("%.blg$") then return false end
  if b:match("%.bbl$") then return false end
  if b:match("%.idx$") then return false end
  if b:match("%.fls$") then return false end
  return true
end

function ExportPlugin:collect_files(root, rel, files)
  rel = rel or ""
  files = files or {}
  local dir = rel == "" and root or self._env.files.join(root, rel)
  for entry in lfs.dir(dir) do
    if entry ~= "." and entry ~= ".." then
      local relpath = rel == "" and entry or self._env.files.join(rel, entry)
      local fullpath = self._env.files.join(root, relpath)
      local attr = lfs.attributes(fullpath)
      if attr and attr.mode == "directory" then
        self:collect_files(root, relpath, files)
      elseif attr and attr.mode == "file" and self:should_export(relpath) then
        table.insert(files, relpath)
      end
    end
  end
  return files
end

function ExportPlugin:create_export_folder(export_dir)
  export_dir = export_dir or self._config.exportdir
  -- Remove previous export directory
  os.execute(string.format('rm -rf "%s"', export_dir))
  assert(lfs.mkdir(export_dir))
  local files = collect_files(".")
  for _, relpath in ipairs(files) do
    self._env.files.copy_file(relpath, export_dir .. "/" .. relpath)
  end
end

function ExportPlugin:prerequisites()
	-- Nothing to do
end

function ExportPlugin:pack()
	local printer = self._env.tui.Printer:new()
  local archive = "paper.zip"
  self:create_export_folder(export_dir)
  if self._env.files.command_exists("zip") then
    self._env.files.run("zip -q -9 -r paper.zip .")
    printer:println("Archive written to " .. archive)
  elseif self._env.file.command_exists("7z") then
    self._env.files.run('7z a -mx9 -tzip paper.zip .')
    printer:println("Archive written to " .. archive)
  else
    printer:println()
    printer:println("No ZIP utility was found.")
    printer:println("Submission sources have been exported to:")
    printer:println("  " .. export_dir)
    printer:println("")
    printer:println("Please create the archive manually.")
  end
  self._ret.success = {
  	code = RET_OK,
  	message = printer:lines()
  }
end

function ExportPlugin:postrequisites()
end

return {
	plugin = ExportPlugin
}

-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: