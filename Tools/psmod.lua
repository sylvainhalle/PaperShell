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

-- Dynamic settings
local pwd = os.getenv("PAPERSHELL_HOME") or ".."

-- Dependencies
local http   = require("socket.http")
local utf8   = require("utf8")
local lfs    = require("lfs")
local zip    = require("zip")
local bibtex = dofile("lua-bibtex-parser.lua")
local butils = dofile("lua-bibtex-utils.lua")

-- Version string
local VERSION_STRING     = "3.0"

-- Return codes
local RET_OK             = 0
local RET_MISSING_ACTION = 1
local RET_ARGS           = 2
local RET_NO_ROOT        = 3
local RET_ALREADY_EXISTS = 4
local RET_NO_TEXTIDOTE   = 5
local RET_NO_BIB         = 6
local RET_BIB_DUPLICATES = 10
local RET_BIB_INCOMPLETE = 11
local RET_WTF            = 255

-- Default settings
local CONFIG = {
	themerepo = "https://sylvainhalle.github.io/PaperShell/themes/",
	textidote = "textidote",
	report    = "textidote.html",
	outdir    = "Source",
	mainfile  = "paper.tex",
	mainbib   = "paper.bib",
	language  = "en"
}
local outdir     = "../Source"

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

--[[ }}} ]]

--[[ ***** OS utilities ***** {{{ ]]--

--[[ Opens a website in the default web browser.
     @param url: The URL of the website to be opened.
     @return true if the browser could be opened, false otherwise
     @from https://codepal.ai/code-generator/query/ErowAxhU/lua-function-open-website
  ]]
function open_browser(url)
  local separator = package.config:sub(1,1)
  
    -- Check the operating system and open the website accordingly.
    if separator == "/" then
        os.execute("xdg-open " .. url)
    else
        os.execute("open " .. url)
    end
    return true
end

--[[ }}} ]]

--[[ ***** BibTeX utilities ***** {{{ ]]--

--[[ Displays the duplicate keys or titles found in the paper's
     bib file.
--]]
function show_duplicates(kdups, tdups)
	if #kdups == 0 and #tdups == 0 then
		stdoutln("No duplicates found")
		return RET_OK
	end
	if #kdups > 0 then
		stdoutln(#kdups .. "duplicate key(s) found:")
		for _,v in ipairs(kdups) do
			stdoutln("  " .. v)
		end
	end
	if #kdups > 0 then
		stdoutln(#kdups .. "duplicate title(s) found:")
		for _,v in ipairs(tdups) do
			stdoutln("  " .. v)
		end
	end
	return RET_BIB_DUPLICATES
end

function show_missing_fields(inc)
	local keys = {"author", "title", "year", "pages"}
	local missing = false
	stdout(printpad("", 16))
	for _,k in ipairs(keys) do
		stdout(printpad(k, 8))
	end
	stdoutln()
	for _,e in ipairs(inc) do
		stdout(printpad(e.key, 16))
		for _,k in ipairs(keys) do
			if e[k] then
				missing = true
				stdout(printpad("X", 8))
			else 
				stdout(printpad(" ", 8))
			end
		end
		stdoutln()
	end
	if missing then
		return RET_BIB_INCOMPLETE
	end
	return RET_OK
end

--[[ }}} ]]--

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

local function command_exists(cmd)
  return (os.execute("which " .. cmd) == 0)
end

local function run(cmd)
  local f = assert(io.popen(cmd))
  local s = assert(f:read('*a'))
  f:close()
  return s
end

local function create_export_folder(export_dir)
  export_dir = export_dir or "Export"

  -- Remove previous export directory
  os.execute(string.format('rm -rf "%s"', export_dir))

  assert(lfs.mkdir(export_dir))

  local files = collect_files(".")

  for _, relpath in ipairs(files) do
    copy_file(relpath, export_dir .. "/" .. relpath)
  end

  stdoutln(string.format("Exported %d file(s) to %s", #files, export_dir))
end

local function export_project(export_dir)
  local archive = "paper.zip"
  stdoutln("Exporting submission sources")
  create_export_folder(export_dir)
  if command_exists("zip") then
    stdoutln("Creating " .. archive)
    run("zip -q -9 -r paper.zip .")
    stdoutln("Archive written to " .. archive)
  elseif command_exists("7z") then
    stdoutln("Creating " .. archive)
    run('7z a -mx9 -tzip paper.zip .')
    stdoutln("Archive written to " .. archive)
  else
    stdoutln()
    stdoutln("No ZIP utility was found.")
    stdoutln("Submission sources have been exported to:")
    stdoutln("  " .. export_dir)
    stdoutln()
    stdoutln("Please create the archive manually.")
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
  local success, err = copy_folder(pwd, folder, {"docs", ".git", "Test"})
  if success then
    stdoutln("Folder and its contents copied successfully.")
  else
    stderrln("Failed to copy folder and its contents:", err)
  end
end

function printusage(stream)
  stream:write("Usage: papershell [-h | verb [noun...]]\n\n")
  stream:write("Possible verbs:\n")
  stream:write("  init [folder]           Creates an empty project in folder\n")
  stream:write("  export                  Exports sources to archive\n")
  stream:write("  mk [-c]                 Runs latexmk on main document\n")
  stream:write("                          (-c cleans the project)\n")
  stream:write("  th list                 Lists available themes\n")
  stream:write("  th install <theme>      Downloads and installs theme\n")
  stream:write("  th uninstall <theme>    Uninstalls theme\n")
  stream:write("  tx check [-b]           Checks spelling and grammar (*)\n")
  stream:write("  tx wc                   Counts the words in the paper (*)\n")
  stream:write("  ld <f> [g]              Difference between two versions (#)\n")
  stream:write("  bb dupes [show|delete]  Finds duplicates in bib file and shows/deletes them\n")
  stream:write("\n")
  stream:write("  (*) Requires TeXtidote  (#) Requires latexdiff\n")
  stream:write("  Type `man papershell` for more details.\n")
end

--[[ ***** Main loop ***** {{{ ]]--

stdoutln("PaperShell theme manager v" .. VERSION_STRING)
stdoutln("(C) 2015-2026 Sylvain Hallé")
stdoutln()

local offset = 0

-- Init is handled separately, as it does not need to look for a project root
if arg[offset + 1] == "init" then
  local fld = arg[offset + 2] or "."
  local target = lfs.currentdir() .. "/" .. fld
  if file_exists(target .. "/.papershell") then
    stderrln("ERROR: a PaperShell project is already instantiated")
    os.exit(RET_ALREADY_EXISTS)
  end
  stdoutln("Creating empty project in " .. target .. "\n")
  instantiate(lfs.currentdir() .. "/" .. fld)
  os.exit(0)
end

-- Help
if (arg[offset + 1] == "-h" or arg[offset + 1] == "--help") then
  printusage(io.stdout)
  os.exit(RET_OK)
end

-- Find a project root
local project_root = find_root_rec(lfs.currentdir())
if not project_root then
  stderrln("ERROR: not a PaperShell project (or any parent up to mount point /)")
  os.exit(RET_NO_ROOT)
end

-- Extract a few settings
local override = dofile(project_root .. "/.papershell")
for k,v in pairs(override) do
  CONFIG[k] = v
end

-- Check version
if CONFIG.version < VERSION_STRING then
  stdoutln("WARNING: the project was instantiated with an earlier version of")
  stdoutln("         PaperShell. You may consider updating it.")
end
if CONFIG.version > VERSION_STRING then
  stdoutln("WARNING: the current installed version of PaperShell is older than the one")
  stdoutln("         used to instantiate this project. You may consider updating it.")
end

-- Other arguments
if not arg[offset + 1] then
  stderrln("ERROR: an action must be specified")
  printusage(io.stderr)
  os.exit(RET_MISSING_ACTION)
end
local action = arg[offset + 1]

-- Run latexmk
if action == "mk" then
  if arg[offset + 2] == "-c" then
    return os.execute(string.format("cd %s && latexmk -c", project_root))
  else
    return os.execute(string.format("cd %s && latexmk", project_root))
  end
end

-- Export sources
if action == "export" then
  export_project(project_root .. "/" .. (arg[offset + 3] or "Export"))
  os.exit(RET_OK)
end

-- Theme verbs
if action == "th" or action == "theme" then
  offset = offset + 1
  action = arg[offset + 1]
  -- Installation of a theme
  if action == "install" then
    if not arg[offset + 2] then
      stderrln("ERROR: a theme must be specified")
      os.exit(RET_ARGS)
    end
    local url = CONFIG.themerepo .. arg[offset + 2] .. ".tpl.zip"
    lfs.mkdir(project_root .. "/" .. outdir .. "/sty/" .. arg[offset + 2])
    lfs.mkdir(outdir .. "/tpl/" .. arg[offset + 2])
    download_and_unzip(url, outdir)
    os.exit(RET_OK)
  end
    
  -- List of themes
  if action == "list" then
    stdoutln("Themes currently installed:")
    for file in lfs.dir(outdir .. "/tpl") do
      local filename = outdir .. "/tpl/" .. file
      local att, err = lfs.attributes(filename)
      if (att and att.mode == "directory" and file ~= "." and file ~= "..") then
        local props = dofile(filename .. "/manifest.lua")
        stdoutln("- " .. printpad(props.id, 10) .. printpad(props.version, 6) .. printpad(props.innerversion, 6) .. printpad(props.name, 44))
      end
    end
    os.exit(RET_OK)
  end
  stderrln("ERROR: unknown action " .. action)
  os.exit(RET_ARGS)
end

-- TeXtidote verbs
if action == "tx" or action == "textidote" then
  offset = offset + 1
  action = arg[offset + 1]
  -- The next actions require TeXtidote, so we first check it is installed
  if not command_exists(CONFIG.textidote) then
    stderrln("This action requires TeXtidote to be performed.")
    stderrln("You can download TeXtidote at https://github.com/sylvainhalle/textidote")
    os.exit(RET_NO_TEXTIDOTE)
  end

  -- Count words with textidote
  if action == "wc" then
    local command = string.format("cd %s && %s --read-all --clean %s/%s 2> /dev/null", project_root, CONFIG.textidote, CONFIG.outdir, CONFIG.mainfile)
    local result = run(command)
    local words = 0
    for word in result:gmatch("[^%s]+") do words=words+1 end
    stdoutln(words .. " word(s)")
    os.exit(RET_OK)
  end

  -- Check grammar with textidote
  if action == "check" then
    local command = string.format("cd %s && %s --check %s --read-all --output html %s/%s 2> /dev/null",
      project_root, CONFIG.textidote, CONFIG.language, CONFIG.outdir, CONFIG.mainfile)
    local report = run(command)
    local report_filename = project_root .. "/" .. CONFIG.report
    write_file(report_filename, report)
    if arg[offset + 2] == "-b" then
      if not open_browser("file://" .. project_root .. "/" .. CONFIG.report) then
        stderrln("Could not open browser")
      end
    end
    os.exit(RET_OK)
  end
  stderrln("ERROR: unknown action " .. action)
  os.exit(RET_ARGS)
end

-- BibTeX verbs
if action == "bb" or action == "bibtex" then
  offset = offset + 1
  action = arg[offset + 1]
  -- All actions require an existing bib file
  local path = pwd.."/Source/"..CONFIG.mainbib
  if not file_exists(path) then
  	stderrln("ERROR: bib file does not exist")
  	os.exit(RET_NO_BIB)
  end
  local lib = bibtex.parse(butils.readfile(path))
  if action == "dupes" then
  	local sub_action = arg[offset + 2]
  	if sub_action == "s" or sub_action == "show" then
  		local kdups, tdups = butils.find_duplicates(lib)
  		os.exit(show_duplicates(kdups, tdups))
  	elseif sub_action == "d" or sub_action == "delete" then
  		os.exit(RET_OK)
  	else
  		stderrln("ERROR: unknown sub-action " .. sub_action)
  		os.exit(RET_ARGS)
  	end
  elseif action == "missing" then
  	local sub_action = arg[offset + 2]
  	if sub_action == "f" or sub_action == "fields" then
  		local incomplete = butils.find_incomplete(lib)
  		os.exit(show_missing_fields(incomplete))
  	else
  		stderrln("ERROR: unknown sub-action " .. sub_action)
  		os.exit(RET_ARGS)
  	end
  elseif action == "clean" then
  	os.exit(pretty_print(lib))
  end
  stderrln("ERROR: unknown action " .. action)
  os.exit(RET_ARGS)
end

-- ?!?
stderrln("ERROR: unknown action " .. arg[offset + 1])
os.exit(RET_MISSING_ACTION)

--[[ }}} ]]

-- :folding=explicit:wrap=none:mode=lua: