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

local bibtex = dofile(os.getenv("PWD") .. "/plugins/bibtex-utils/lua-bibtex-parser.lua")

-- Return codes
local RET_NO_BIB         = 6
local RET_BIB_DUPLICATES = 10
local RET_BIB_INCOMPLETE = 11

local function prerequisites(env, ret)
	local path = env.pwd.."/Source/"..env.settings.mainbib
	if not env.file_exists(path) then
		ret.error = {
			message = {"BibTeX file does not exist"},
			code    = RET_NO_BIB
		}
	end
end

local function trim(s)
  return (s and s:gsub("^%s+", ""):gsub("%s+$", "")) or ""
end

local function in_array(array, elem)
	for _,v in pairs(array) do
		if v == elem then
			return true
		end
	end
	return false
end

local function split(s, sep_pattern)
  local t = {}
  if not s or s == "" then return t end
  local start = 1
  while true do
    local i, j = s:find(sep_pattern, start)
    if not i then
      table.insert(t, trim(s:sub(start)))
      break
    end
    table.insert(t, trim(s:sub(start, i - 1)))
    start = j + 1
  end
  return t
end

local function get_field_case_insensitive(fields_dict, wanted)
  local lower_wanted = string.lower(wanted)
  for k, v in pairs(fields_dict) do
    if string.lower(k) == lower_wanted then
      return v and v.value or nil
    end
  end
  return nil
end

local function set_entry_field(library, entry_key, field_key, field_value)
  local entry = library.entry_dict[entry_key]
  if not entry then return end
  for _, f in ipairs(entry.fields) do
    if f.name == field_key then
      f.value = field_value
      break
    end
  end
end

local function readfile(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local c = f:read("*a")
  f:close()
  return c
end

local function writefile(path, text)
  local f = io.open(path, "w")
  f:write(text)
  f:close()
end

local function run(cmd)
  local p = io.popen(cmd)
  local out = p:read("*a")
  p:close()
  return out
end

-- ========= robust get_field =========
local function get_field(entry, wanted_name)
  if type(entry) ~= "table" then return nil end
  if not wanted_name or wanted_name == "" then return nil end
  local wanted = wanted_name:lower()

  -- 0) parfois à la racine
  for k,v in pairs(entry) do
    if type(k)=="string" and k:lower()==wanted and type(v)=="string" then
      return unbrace(v)
    end
  end

  local f = entry.fields
  if type(f) ~= "table" then return nil end

  -- 1) dictionnaire: clés -> valeurs
  local is_list = (#f > 0 and type(f[1])=="table")
  if not is_list then
    for k,v in pairs(f) do
      if type(k)=="string" and k:lower()==wanted and type(v)=="string" then
        return unbrace(v)
      end
    end
  end

  -- 2) liste { {name=..., value=...}, ... }
  if is_list then
    for _,item in ipairs(f) do
      local name = lower(item.name or item.key)
      if name == wanted then
        local v = item.value or item.val or item.text
        if type(v)=="string" and v~="" then
          return unbrace(v)
        end
      end
    end
  end

  return nil
end

local function unbrace(s)
  if type(s) ~= "string" then return s end
  s = trim(s)
  if s and #s >= 2 then
    local a,b = s:sub(1,1), s:sub(-1,-1)
    if (a == "{" and b == "}") or (a == '"' and b == '"') then
      return s:sub(2, -2)
    end
  end
  return s
end

local function lower(s) 
  return type(s)=="string" and s:lower() or s
end

local function set_field_value(library, entry_key, field_name, field_value)
  local entry = library.entry_dict[entry_key]
  if not entry then return end
  for _, f in ipairs(entry.fields) do
    if (f.name == field_name) then
      f:set_value(field_value)
      break
    end
  end
end

local function set_field_name(library, entry_key, current_field_name, new_field_name)
  local entry = library.entry_dict[entry_key]
  if not entry then return end
  for _, f in ipairs(entry.fields) do
    if (f.name == current_field_name) then
      f:set_name(new_field_name)
      entry.fields_dict[current_field_name] = nil
      entry.fields_dict[new_field_name] = f
      break
    end
  end
end

local format = string.format
local rep = string.rep
local write = io.write

---Recursively print the table, if not table value is just printed.
---@param t any
---@param level? number
local function print_table(t, level)
    level = level or 0
    if type(t) == "table" then
        -- do not print new line on the level 0
        if level ~= 0 then
            write("\n")
        end
        write(rep("\t", level), "{\n")
        level = level + 1

        for key, value in pairs(t) do
            write(rep("\t", level) .. format("[%s] = ", key))
            print_table(value, level)
            write(",\n")
        end

        level = level - 1
        write(rep("\t", level), "}")
    else
        write(tostring(t))
    end
    -- print new line on the level 0
    if level == 0 then
        write("\n")
    end
end

function simplify_string(s)
	s = lower(s)
	s = string.gsub(s, "[.,;:?!]", "")
	s = string.gsub(s, "%s+", " ")
	return s
end

local function find_duplicates(library)
	local seen_keys = {}
	local dup_keys = {}
	local seen_titles = {}
	local dup_titles = {}
	for i = 1, #library.entries do
		local e = library.entries[i]
		local fields = e.fields_dict or {}
		local t = simplify_string(get_field_case_insensitive(fields, "title"))
		if in_array(seen_titles, t) then
			if not in_array(dup_titles, t) then
				table.insert(dup_titles, t)
			end
		else
			table.insert(seen_titles, t)
		end
		if in_array(seen_keys, e.key) then
			if not in_array(dup_keys, e.key) then
				table.insert(dup_keys, e.key)
			end
		else
			table.insert(seen_keys, e.key)
		end
	end
	return dup_keys, dup_titles
end

function find_incomplete(library)
	local incomplete = {}
	for i = 1, #library.entries do
		local e = library.entries[i]
		local fields = e.fields_dict or {}
		local mis = {
			key = e.key,
			author = not get_field_case_insensitive(fields, "author"),
			title = not get_field_case_insensitive(fields, "title"),
			year = not get_field_case_insensitive(fields, "year"),
			pages = not get_field_case_insensitive(fields, "pages")
		}
		table.insert(incomplete, mis)
	end
	return incomplete
end

--[[ Formats the display of a BibTeX file.
     @param library The Library object to format
--]]
function pretty_print(env, library)
	local out = ""
	for i = 1, #library.entries do
		local e = library.entries[i]
		out = out .. "@" .. e.type .. "{" .. e.key .. ",\n"
		for j = 1, #e.fields do
			local item = e.fields[j]
			out = out .. "  " .. padto(env, item.name, 16) .. " = {"
			local lines = wrap(env, env.utils.str_trim(item.value), 58)
			for k,line in ipairs(lines) do
				if k == 1 then
					out = out .. line
				else
					out = out .. string.rep(" ", 22) .. line
				end
				if k == #lines then
					out = out .. "}"
				else
					out = out .. "\n"
				end
			end
			if #lines == 0 then -- A single word
				out = out .. item.value
			end
			if j == #e.fields then
				out = out .. "\n"
			else
				out = out .. ",\n"
			end
		end
		out = out .. "}\n\n"
	end
	return out
end

function padto(env, s, len)
	return s .. string.rep(" ", len - #s)
end

function wrap(env, s, len)
	local words = env.utils.str_split(s, " ")
	local lines = {}
	local curline = ""
	for _,w in ipairs(words) do
		if (#curline + #w) <= len then
			if #curline == 0 then
				curline = w
			else
				curline = curline .. " " .. w
			end
		else
			table.insert(lines, curline)
			curline = w
		end
	end
	table.insert(lines, curline)
	return lines
end

--[[ Displays the duplicate keys or titles found in the paper's
     bib file.
--]]
local function print_duplicates(env, kdups, tdups)
	local p = env.tui.Printer:new()
	if #kdups == 0 and #tdups == 0 then
		p:println("No duplicates found")
		return p, RET_OK
	end
	if #kdups > 0 then
		p:print(#kdups .. " duplicate key(s) found:"):indent():println()
		for _,v in ipairs(kdups) do
			p:println(v)
		end
		p:outdent()
	end
	if #kdups > 0 then
		p:print(#kdups .. " duplicate title(s) found:"):indent():println()
		for _,v in ipairs(tdups) do
			p:println(v)
		end
		p:outdent()
	end
	return p, RET_BIB_DUPLICATES
end

local function print_missing_fields(env, inc)
	local p = env.tui.Printer:new()
	local keys = {"author", "title", "year", "pages"}
	local missing = false
	p:print("", 16)
	for _,k in ipairs(keys) do
		p:bd():print(p:sul() .. k .. p:srs(), 8)
	end
	p:println()
	for _,e in ipairs(inc) do
		p:print(e.key, 16)
		for _,k in ipairs(keys) do
			if e[k] then
				missing = true
				p:bg().red():fg().black()
				p:print("X" .. p:srs(), 8)
			else
				p:print(" ", 8)
			end
		end
		p:println()
	end
	if missing then
		return p, RET_BIB_INCOMPLETE
	end
	return p, RET_OK
end

local function get_bib_path(env)
	return env.pwd.."/Source/"..env.settings.mainbib
end

local function show_duplicates(env, ret)
	local lib = bibtex.parse(readfile(get_bib_path(env)))
	local kdups, tdups = find_duplicates(lib)
	local p, c = print_duplicates(env, kdups, tdups)
	ret.success = {
		code = c,
		message = p:lines()
	}
end

local function show_missing_fields(env, ret)
	local lib = bibtex.parse(readfile(get_bib_path(env)))
	local incomplete = find_incomplete(lib)
	local p, c = print_missing_fields(env, incomplete)
	ret.success = {
		code = c,
		message = p:lines()
	}
end

local function clean_bib(env, ret)
	local lib = bibtex.parse(readfile(get_bib_path(env)))
	local cleaned = pretty_print(env, lib)
	ret.success = {
		code = 0,
		message = env.utils.str_split(cleaned, "\n")
	}
end


local function postrequisites(env, ret)
end

return {
  prerequisites  = prerequisites,
  postrequisites = postrequisites,
  show_duplicates = show_duplicates,
  show_missing_fields = show_missing_fields,
  clean_bib = clean_bib
}