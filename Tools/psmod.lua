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
local http = require("socket.http")
local utf8 = require("utf8")
local lfs = require("lfs")
local zip = require("zip")

-- Default settings
local theme_repo = "https://sylvainhalle.github.io/PaperShell/themes/"
local outdir     = "../Source"
local localdir   = "~/.local/share/papershell"

-- Dynamic settings
local pwd = os.getenv("PWD") or io.popen("cd"):read()

--[[ ***** File utilities ***** {{{ ]]--

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
	  print(filename)
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
  if (inlist(source, toignore)) then
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

--[[ Extracts a substring from a UTF-8 string.
     @param s The string
     @param i The start index in the string
     @param j The end index in the string
     @return The substring
  ]]
local function utf8sub(s, i, j)
  i = i or 1
  j = j or -1
  local start = utf8.offset(s, i)
  if not start then return "" end
  local stop
  if j < 0 then
    stop = #s
  else
    stop = utf8.offset(s, j + 1)
    stop = stop and (stop - 1) or #s
  end
  return string.sub(s, start, stop)
end

--[[ }}} ]]

--[[ ***** Network utilities ***** {{{ ]]--

--[[ Downloads a file from an HTTP URL.
     @param url The URL
     @return The contents of the file, or null otherwise
  ]]
local function download(url)
  local response_body, status_code = http.request(url)
    if status_code == 200 then
      return response_body
    end
  return null
end

local function should_export(path)
  local b = basename(path)
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

--[[ }}} ]]

--[[ ***** TUI utilities ***** {{{ ]]--

local function stdout(content)
  io.stdout:write(content or "")
end

local function stdoutln(content)
  stdout((content or "") .. "\n")
end

local function stderr(content)
  io.stderr:write(content or "")
end

local function stderrln(content)
  stderr((content or "") .. "\n")
end

--[[ Truncates or pads a string to a fixed length.
     @param str The string
     @param length The length
     @param pad_char (Optional) the character used to pad if the string
       is too short
  ]]
function printpad(str, length, pad_char)
    pad_char = pad_char or " "
    local len = utf8.len(str)
    if len > length then
        -- Truncate if longer
        return utf8sub(str, 1, length)
    elseif len < length then
        -- Pad if shorter
        return str .. string.rep(pad_char, length - len)
    else
        -- Return as-is if exactly the right length
        return str
    end
end

--[[ }}} ]]

--[[ ***** Miscellaneous utilities ***** {{{ ]]--

--[[ Determines if an element is in a table
  ]]
function inlist(e, table)
  local basename = e:match("([^/]*)$") or e
  for _, x in ipairs(table) do
    if basename == x then return true end
  end
  return false
end

--[[ Recursively finds the root folder of the project, starting from a given
     folder.
     @param dir The current folder
     @return The path of the root folder, or false if no root is found
  ]]
local function find_root_rec(dir)
  if not dir then
    return false
  end
  if file_exists(dir .. "/.papershell") then
    return dir
  end
  return find_root_rec(up(dir))
end

--[[ Finds the root folder of the current project. The root is defined by
     the folder that contains the file .papershell.
     @return The path of the root folder, or false if no root is found
  ]]
local function find_root()
  return find_root_rec(pwd)
end

--[[ }}} ]]

local function collect_files(root, rel, files)
  rel = rel or ""
  files = files or {}

  local dir = rel == "" and root or join(root, rel)

  for entry in lfs.dir(dir) do
    if entry ~= "." and entry ~= ".." then
      local relpath = rel == "" and entry or join(rel, entry)
      local fullpath = join(root, relpath)
      local attr = lfs.attributes(fullpath)

      if attr and attr.mode == "directory" then
        collect_files(root, relpath, files)
      elseif attr and attr.mode == "file" and should_export(relpath) then
        table.insert(files, relpath)
      end
    end
  end
  return files
end

local function export_project(export_dir)
  local archive = "paper.zip"
  print("Exporting submission sources")
  create_export_folder(export_dir)
  if command_exists("zip") then
    print("Creating " .. archive)
    run('cd Export && zip -9 -r ../paper.zip .')
    print("Archive written to " .. archive)
  elseif command_exists("7z") then
    print("Creating " .. archive)
    run('7z a -tzip paper.zip Export/*')
    print("Archive written to " .. archive)
  else
    print()
    print("No ZIP utility was found.")
    print("Submission sources have been exported to:")
    print("  " .. export_dir)
    print()
    print("Please create the archive manually.")
  end
end

--[[ Downloads a theme as a ZIP, and unzips it in the appropriate folders
     @param url The URL to download from
     @param out_dir The folder where to unzip the theme
     @return true on success, false otherwise
  ]]
function download_and_unzip(url, out_dir)
  local response_body = download(url)
  if response_body then
	local file_path = out_dir .. "/downloaded_file.zip"
	write_file(file_path, response_body)
	return unzip(file_path, out_dir)
  end
  return false
end


--[[ Creates a new empty project in a folder.
      @param folder The folder where to create the project
  ]]
function instantiate(folder)
  local success, err = copy_folder(pwd .. "/..", folder or ".", {"docs", ".git"})
  if success then
    stdoutln("Folder and its contents copied successfully.")
  else
    stderrln("Failed to copy folder and its contents:", err)
  end
end



function printusage(stream)
  stream:write("Usage: papershell [-h] [action]\n\n")
  stream:write("Possible actions:\n")
  stream:write("  init <folder>        Creates an empty project in folder\n")
  stream:write("  list                 Lists available themes\n")
  stream:write("  install <theme>      Downloads and installs theme\n")
  stream:write("  uninstall <theme>    Uninstalls theme\n")
  stream:write("  export               Exports sources to archive\n")
end

--[[ ***** Main loop ***** {{{ ]]--

stdoutln("PaperShell theme manager v3.0")
stdoutln("(C) 2026 Sylvain Hallé")
stdoutln()

local offset = 0
-- Init is handled separately, as it does not need to look for a project root
if arg[offset + 1] == "init" then
  local fld = arg[offset + 2] or "."
  if not arg[offset + 2] then
    stderrln("ERROR: a folder name must be specified")
    os.exit(2)
  end
  print("Creating empty project in " .. project_root .. "/" .. fld .. "\n")
  instantiate(project_root .. "/" .. fld)
end

-- Find a project root
local project_root = find_root_rec(lfs.currentdir())
if not project_root then
  stderrln("ERROR: not a PaperShell project (or any parent up to mount point /)")
  os.exit(3)
end

-- Other arguments
if not arg[offset + 1] then
  stderrln("ERROR: an action must be specified")
  printusage(io.stderr)
  os.exit(1)
end
if (arg[offset + 1] == "-h" or arg[offset + 1] == "--help") then
  printusage(io.stdout)
  os.exit(0)
end
local action = arg[offset + 1]

-- Installation of a theme
if action == "install" then
  if not arg[offset + 2] then
    stderrln("ERROR: a theme must be specified")
    os.exit(2)
  end
  local url = theme_repo .. arg[offset + 2] .. ".tpl.zip"
  print(url)
  lfs.mkdir(outdir .. "/sty/" .. arg[offset + 2])
  lfs.mkdir(outdir .. "/tpl/" .. arg[offset + 2])
  download_and_unzip(url, outdir)
  os.exit(0)
end

-- List of themes
if action == "list" then
  print("Themes currently installed:\n")
  for file in lfs.dir(outdir .. "/tpl") do
    local filename = outdir .. "/tpl/" .. file
    local att, err = lfs.attributes(filename)
    if (att and att.mode == "directory" and file ~= "." and file ~= "..") then
      local props = dofile(filename .. "/manifest.lua")
      print("- " .. printpad(props.id, 10) .. printpad(props.version, 6) .. printpad(props.innerversion, 6) .. printpad(props.name, 44))
    end
  end
  os.exit(0)
end

-- Export sources
if action == "export" then
  if arg[offset + 3] then
    fld = ""
  else
    export_project(project_root .. "/" .. "Export")
  end
  os.exit(0)
end

-- ?!?
stderrln("ERROR: unknown action " .. arg[offset + 1])
os.exit(2)

--[[ }}} ]]

-- :folding=explicit:wrap=none:mode=lua: