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
local http   = require "socket.http"
local lfs    = require "lfs"
local zip    = require "zip"
local tui    = require "tui"
local files  = require "files"
local net    = require "net"
local utils  = require "utils"

-- Version string
local VERSION_STRING     = "3.0"

-- Return codes
local RET_OK             = 0
local RET_MISSING_ACTION = 1
local RET_ARGS           = 2
local RET_NO_ROOT        = 3
local RET_ALREADY_EXISTS = 4
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

--[[ Recursively finds the root folder of the project, starting from a given
     folder.
     @param dir The current folder
     @return The path of the root folder, or false if no root is found
  ]]
local function find_root_rec(dir)
  if not dir then
    return false
  end
  if files.file_exists(dir .. "/.papershell") then
    return dir
  end
  return find_root_rec(files.up(dir))
end

-- Plugin verbs
local env = {
  arg = arg,
  offset = 1,
  settings = CONFIG,
  pwd = pwd,
  outdir = CONFIG.outdir,
  mainfile = CONFIG.mainfile,
  run = run,
  open_browser = open_browser,
  tui      = tui,
  files    = files,
  net      = net,
  utils    = utils
}

-- Find a project root
local project_root = find_root_rec(lfs.currentdir())
env.project_root = project_root
if not project_root then
  tui.stderrln("ERROR: not a PaperShell project (or any parent up to mount point /)")
  os.exit(RET_NO_ROOT)
end

-- Extract a few settings
local override = dofile(project_root .. "/.papershell")
for k,v in pairs(override) do
  CONFIG[k] = v
end

--[[ }}} ]]

--[[ ***** Miscellaneous utilities ***** {{{ ]]--

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

--[[ ***** Plugins ***** {{{ ]]--

local PLUGINS = {}
local root = pwd.."/Tools/plugins/"
for v in lfs.dir(root) do
	if files.file_exists(root .. v .. "/manifest.lua") then
		local man = dofile(root .. v .. "/manifest.lua") or {}
		if man.id and files.file_exists(root .. v .. "/plugin.lua") then
			local plg = dofile(root .. v .. "/plugin.lua")
			local plgi = plg.plugin:new(env, {})
			--utils.print_table(plgi)
			PLUGINS[man.id] = {
				manifest = man,
				plugin   = plg.plugin:new(env, {})
			}
		end
	end
end
--utils.print_table(PLUGINS)

-- }}} ]]



--[[ Downloads a theme as a ZIP, and files.unzips it in the appropriate folders
     @param url The URL to download from
     @param out_dir The folder where to files.unzip the theme
     @return true on success, false otherwise
  ]]
function download_and_unzip(url, out_dir)
  local response_body = net.download(url)
  if response_body then
	local file_path = out_dir .. "/downloaded_file.zip"
	files.write_file(file_path, response_body)
	return files.unzip(file_path, out_dir)
  end
  return false
end


--[[ Creates a new empty project in a folder.
      @param folder The folder where to create the project
  ]]
function instantiate(folder)
  local success, err = files.copy_folder(pwd, folder, {"docs", ".git", "Test"})
  if success then
    tui.stdoutln("Folder and its contents copied successfully.")
  else
    tui.stderrln("Failed to copy folder and its contents:", err)
  end
end

function printusage_rec(e, stream)
	if e.help then
		stream:write(tui.printpad(e.help[1], 20))
		stream:write(e.help[2].."\n")
	elseif e.actions then
		for _,v in ipairs(e.actions) do
			printusage_rec(v, stream)
		end
	end
end

function domenu(items, top)
	for i,e in ipairs(items) do
		io.stdout:write(tui.color.bold .. tui.color.foreground.yellow .. "(" .. i .. ")" .. tui.color.reset .. " ")
		io.stdout:write(tui.printpad(e.name, 16))
		if e.icon then
			if e.icon.nerd then
				io.stdout:write(e.icon.nerd .. "  ")
			elseif e.icon.normal then
				io.stdout:write(e.icon.normal .. "  ")
			end
		else
			io.stdout:write("   ")
		end
		if e.tooltip then
			io.stdout:write(tui.color.italic .. tui.color.foreground.bright.black .. e.tooltip .. tui.color.reset	)
		end
		io.stdout:write("\n")
	end
	io.stdout:write("\n")
	io.stdout:write(tui.color.reverse .. "Enter a choice (0 to ")
	if top then
		io.stdout:write("quit) >>" .. tui.color.reset .." ")
	else
		io.stdout:write("go back) >>" .. tui.color.reset .. " ")
	end
	local s = io.read("*n")
	return s
end

local function invoke(plugin, call)
  local ret = {}
  plugin._ret = ret

  local f

  if type(call) == "string" then
    f = plugin[call]
  elseif type(call) == "function" then
    f = call
  end

  if type(f) ~= "function" then
    tui.stderrln(
      "ERROR: plugin function not found: " .. tostring(call)
    )
    return nil
  end

  if type(plugin.prerequisites) == "function" then
    plugin:prerequisites()
  end

  if not ret.error then
    f(plugin)
  end

  if type(plugin.postrequisites) == "function" then
    plugin:postrequisites()
  end

  return ret
end

function tui_topmenu(plugins)
	local ordered_items = {}
	local ordered_plugins = {}
	for _,m in pairs(plugins) do
		for _,e in ipairs(m.manifest.menu) do
			table.insert(ordered_items, e)
			table.insert(ordered_plugins, m)
		end
	end
	while true do
		io.stdout:write("\n")
		io.stdout:write("\u{f015} Home\n")
		local choice = domenu(ordered_items, true)
		if choice == 0 then
			return nil
		end
		if ordered_items[choice].call then
			return {
				plugin = ordered_plugins[choice].plugin,
				call   = ordered_items[choice].call
			}
		end
		if ordered_items[choice].actions then
			local v = tui_menu(ordered_plugins[choice], "\u{f015} Home " .. tui.color.foreground.bright.red .. ">".. tui.color.reset .. " " .. ordered_items[choice].name, ordered_items[choice].actions)
			if v ~= nil then
				return v
			end
		end
	end
end

function tui_menu(plugin, crumbs, m)
	local ordered_items = {}
	for _,e in pairs(m) do
		table.insert(ordered_items, e)
	end
	io.stdout:write("\n")
	io.stdout:write(crumbs .. "\n")
	while true do
		local choice = domenu(ordered_items)
		if choice > 0 then
			if ordered_items[choice].call then
				return {
						plugin = plugin.plugin,
						call   = ordered_items[choice].call
				}
			end
			if ordered_items[choice].actions then
				local v = tui_menu(plugin, crumbs .. tui.color.foreground.bright.red .. " > " .. tui.color.reset .. ordered_items[choice].name, ordered_items[choice].actions)
				if v ~= nil then
					return v
				end
			end
		else
			return nil
		end
	end
end

function printusage(stream)
  stream:write("Usage: papershell [-h | verb [noun...]]\n\n")
  stream:write("Possible verbs:\n")
  stream:write("  init [folder]           Creates an empty project in folder\n")
  stream:write("  th list                 Lists available themes\n")
  stream:write("  th install <theme>      Downloads and installs theme\n")
  stream:write("  th uninstall <theme>    Uninstalls theme\n")
  for id, p in pairs(PLUGINS) do
  stream:write("  " .. p.manifest.name .. "\n")
  for _, m in ipairs(p.manifest.menu) do
    printusage_rec(m, stream)
  end
end
  
  --stream:write("  tx check [-b]           Checks spelling and grammar (*)\n")
  --stream:write("  tx wc                   Counts the words in the paper (*)\n")
  stream:write("  ld <f> [g]              Difference between two versions (#)\n")
  stream:write("  bb dupes [show|delete]  Finds duplicates in bib file and shows/deletes them\n")
  stream:write("\n")
  stream:write("  (*) Requires TeXtidote  (#) Requires latexdiff\n")
  stream:write("  Type `man papershell` for more details.\n")
end

--[[ ***** Main loop ***** {{{ ]]--

local function verb_matches(verbs, word)
  if type(verbs) == "string" then
  	if verbs == word then
  		return word
  	else
  		return nil
  	end
  end
  for _, v in ipairs(verbs or {}) do
    if utils.starts_with(word, v) then
    	return v
    end
  end
  return nil
end

local function dispatch_plugin_rec(plugin, entry, arg_index)
	-- Leaf: call the designated function
	if entry.call then
		return invoke(plugin.plugin, entry.call)
	end
    -- Internal node: consume next command word
	if entry.actions then
    	local word = arg[arg_index]
    	if not word then
    		if entry.actions then
	    		local f = tui_menu(plugin, "", entry.actions)
	    		if f ~= nil then
	    			return invoke(plugin.plugin, f)
	    		end
	    	end
	    else
	    	for _, child in ipairs(entry.actions) do
	    		local match = verb_matches(child.verb, word)
	    	   	if match then
	    	   		local arg_suffix = string.sub(word, #match + 1, #word)
	    	   		if #arg_suffix > 0 then
	    	   			arg[arg_index] = arg_suffix
	    	   			return dispatch_plugin_rec(plugin, child, arg_index)
	    	   		else
	    	   			return dispatch_plugin_rec(plugin, child, arg_index + 1)
	    	   		end
	    	   	end
	    	end
	    end
	else
	    tui.stderrln("ERROR: missing plugin action")
	    return RET_ARGS
   	end
   	
    tui.stderrln("ERROR: malformed plugin menu entry")
    return nil
end

local function dispatch_plugin(action)
	for _, plugin in pairs(PLUGINS) do
    	for _, entry in ipairs(plugin.manifest.menu or {}) do
    		local match = verb_matches(entry.verb, action)
    		if match then
    			local arg_suffix = string.sub(action, #match + 1, #action)
    			if #arg_suffix > 0 then
	    			arg[env.offset + 1] = arg_suffix
	    			return dispatch_plugin_rec(plugin, entry, env.offset + 1)
	    		else
	    			if arg[env.offset + 2] then
	    				return dispatch_plugin_rec(plugin, entry, env.offset + 2)
	    			elseif entry.actions then
	    				local f = tui_menu(plugin, "", entry.actions)
	    				if f ~= nil then
	    					return invoke(f.plugin, f.call)
	    				end
	    			end
	    		end
	    	end
	    end
    end
    return nil
end

tui.stdoutln(tui.color.reset .. "PaperShell theme manager v" .. VERSION_STRING)
tui.stdoutln("(C) 2015-2026 Sylvain Hallé")
tui.stdoutln()

local offset = 0

-- Init is handled separately, as it does not need to look for a project root
if arg[offset + 1] == "init" then
  local fld = arg[offset + 2] or "."
  local target = lfs.currentdir() .. "/" .. fld
  if files.file_exists(target .. "/.papershell") then
    tui.stderrln("ERROR: a PaperShell project is already instantiated")
    os.exit(RET_ALREADY_EXISTS)
  end
  tui.stdoutln("Creating empty project in " .. target .. "\n")
  instantiate(lfs.currentdir() .. "/" .. fld)
  os.exit(0)
end

-- Help
if (arg[offset + 1] == "-h" or arg[offset + 1] == "--help") then
  printusage(io.tui.stdout)
  os.exit(RET_OK)
end

-- Check version
if CONFIG.version < VERSION_STRING then
  tui.stdoutln("WARNING: the project was instantiated with an earlier version of")
  tui.stdoutln("         PaperShell. You may consider updating it.")
end
if CONFIG.version > VERSION_STRING then
  tui.stdoutln("WARNING: the current installed version of PaperShell is older than the one")
  tui.stdoutln("         used to instantiate this project. You may consider updating it.")
end

-- Other arguments
local action = nil
local ret = nil
if not arg[offset + 1] then
	-- Interactive mode
	local selection = tui_topmenu(PLUGINS)
	if selection then
  	ret = invoke(selection.plugin, selection.call)
  end
else
	action = arg[offset + 1]
	
	-- Theme verbs remain hard-coded for now
	if action == "th" or action == "theme" then
	  offset = offset + 1
	  action = arg[offset + 1]
	  -- Installation of a theme
	  if action == "install" then
		if not arg[offset + 2] then
		  tui.stderrln("ERROR: a theme must be specified")
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
		tui.stdoutln("Themes currently installed:")
		for file in lfs.dir(outdir .. "/tpl") do
		  local filename = outdir .. "/tpl/" .. file
		  local att, err = lfs.attributes(filename)
		  if (att and att.mode == "directory" and file ~= "." and file ~= "..") then
			local props = dofile(filename .. "/manifest.lua")
			tui.stdoutln("- " .. tui.printpad(props.id, 10) .. tui.printpad(props.version, 6) .. tui.printpad(props.innerversion, 6) .. tui.printpad(props.name, 44))
		  end
		end
		os.exit(RET_OK)
	  end
	  tui.stderrln("ERROR: unknown action " .. action)
	  os.exit(RET_ARGS)
	end
	ret = dispatch_plugin(action, env)
end

if ret ~= nil then
  if ret.success then
  	local msg = ret.success.message or {}
    for _,l in ipairs(msg) do
      tui.stdoutln(l)
    end
    os.exit(RET_OK)
  end
  if ret.error then
  	local msg = ret.error.message or {}
    for _,l in ipairs(msg) do
      tui.stderrln(l)
    end
  	os.exit(ret.error.code)
  end
  os.exit(ret.code or RET_OK)
end

-- ?!?
os.exit(RET_MISSING_ACTION)

--[[ }}} ]]

-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: