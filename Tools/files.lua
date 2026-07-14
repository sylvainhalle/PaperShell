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

--[[ A set of functions to handle files.
     @author Sylvain Hallé
  ]]

-- Dependencies
local lfs    = require "lfs"
local zip    = require "zip"
local utils  = require "utils"

--[[ Gets the base name of a path.
     @param path The path
     @return The base name
  ]]
local function basename(path)
  return path:match("([^/\\]+)$") or path
end

--[[ Joins multiple segments to form a path.
     @return The joined path ]]
local function join(...)
  local parts = {...}
  return table.concat(parts, "/")
end

--[[ Goes up one folder from the current folder
     @param path The current folder
     @return The path of the parent folder
  ]]
local function up(path)
  return path:match("^(.*)/[^/]+$")
end

--[[ Reads data from a file.
     @param path The file to read from
     @return The data in the file
  ]]
local function read_file(path)
  local f = assert(io.open(path, "rb"))
  local data = f:read("*a")
  f:close()
  return data
end

--[[ Writes data to a file.
     @param path The path of the file to write to
     @param data The data to write
  ]]
local function write_file(path, data)
  local output = assert(io.open(path, "wb"))
  output:write(data)
  output:close()
end

--[[ Determines if a file exists.
     @param path The path to look for
     @return true if the file exists, false otherwise
  ]]
local function file_exists(path)
  return lfs.attributes(path, "mode") == "file"
end

--[[ Determines if a directory exists.
     @param path The path to look for
     @return true if the directory exists, false otherwise
  ]]
local function dir_exists(path)
  return lfs.attributes(path, "mode") == "directory"
end

--[[ Function equivalent to `mkdir -p` in POSIX shells.
     @param path The path to create ]]
local function mkdir_p(path)
  local current = ""
  for part in path:gmatch("[^/]+") do
    current = current == "" and part or current .. "/" .. part
    if not dir_exists(current) then
      assert(lfs.mkdir(current))
    end
  end
end

--[[ Unzips an archive to a folder.
     @param file_path The path pointing to the zip file
     @param out_dir The directory where to write its contents
     @return true if the operation was successful, false otherwise
  ]]
local function unzip(file_path, out_dir)
  local archive = zip.open(file_path)
  if archive then
	for file in archive:files() do
	  local filename = file.filename
	  if filename:sub(-1, -1) ~= "/" then
		-- File
		local in_f = archive:open(filename)
		local content = in_f:read("*a")
		in_f:close()
		file_write(out_dir .. "/" .. filename, content)
	  end
	end
	archive:close()
	return true
  end
  return false
end

--[[ Copies a folder and its contents from one directory to another, overwriting existing files.
     @param source: The source directory path.
     @param destination: The destination directory path.
     @return: Returns true if the folder and its contents are successfully copied, false otherwise.
     @see https://codepal.ai/code-generator/query/IAANWQA2/lua-function-copy-folder-contents
  ]]
function copy_folder(source, destination, ignore)
  toignore = ignore or { }
  -- Check if the source directory exists
  local sourceExists = lfs.attributes(source, "mode") == "directory"
  if not sourceExists then
    return false, "Source directory does not exist."
  end
  if (utils.inlist(source, toignore)) then
    return true
  end
  
  -- Check if the destination directory exists, create it if it doesn't
  local destinationExists = lfs.attributes(destination, "mode") == "directory"
  if not destinationExists then
    local success, err = lfs.mkdir(destination)
    if not success then
      return false, "Failed to create destination directory: " .. err
    end
  end

  -- Iterate over the files and subdirectories in the source directory
  for file in lfs.dir(source) do
    if file ~= "." and file ~= ".." then
        local sourcePath = source .. "/" .. file
        local destinationPath = destination .. "/" .. file
        local attributes = lfs.attributes(sourcePath)
        if attributes.mode == "directory" then
            -- Recursively copy subdirectories
            local success, err = copy_folder(sourcePath, destinationPath, toignore)
            if not success then
                return false, "Failed to copy subdirectory: " .. err
            end
        else
            -- Copy files
            local success = copy_file(sourcePath, destinationPath)
            if not success then
                return false, "Failed to copy file: " .. sourcePath
            end
        end
    end
  end
  return true
end

-- https://forum.cockos.com/showpost.php?s=93b9db499b6d6c497bbde2216978a951&p=2360581&postcount=3
function copy_file(old_path, new_path)
  local old_file = io.open(old_path, "rb")
  local new_file = io.open(new_path, "wb")
  local old_file_sz, new_file_sz = 0, 0
  if not old_file or not new_file then
    return false
  end
  while true do
    local block = old_file:read(2^13)
    if not block then 
      old_file_sz = old_file:seek( "end" )
      break
    end
    new_file:write(block)
  end
  old_file:close()
  new_file_sz = new_file:seek( "end" )
  new_file:close()
  return new_file_sz == old_file_sz
end

local function command_exists(cmd)
  return (os.execute("which " .. cmd) == 0)
end

-- https://stackoverflow.com/a/14031974
local function run(cmd)
  local f = assert(io.popen(cmd))
  local s = assert(f:read('a'))
  local rc = {f:close()}
  return s, rc[3] -- 3 being the return code
end

return {
	basename = basename,
	join = join,
	up = up,
	read_file = read_file,
	write_file = write_file,
	file_exists = file_exists,
	dir_exists = dir_exists,
	mkdir_p = mkdir_p,
	unzip = unzip,
	copy_folder = copy_folder,
	copy_file = copy_file,
	command_exists = command_exists,
	run = run
}
-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: