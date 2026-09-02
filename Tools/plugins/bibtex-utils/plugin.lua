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

local pwd    = debug.getinfo(1,'S').source:match("@(.*)/[^/]*$")
local bibtex = dofile(pwd .. "/lua-bibtex-parser.lua")
local config = dofile(pwd .. "/config.lua")

-- Return codes
local RET_OK						 = 0
local RET_NO_BIB				 = 6
local RET_BIB_DUPLICATES = 10
local RET_BIB_INCOMPLETE = 11

local BibtexPlugin = {}
BibtexPlugin.__index = BibtexPlugin

function BibtexPlugin:new(env, ret)
	local obj = {
		_env		= assert(env, "plugin environment is required"),
		_ret		= ret or {},
		_config = config
	}
	return setmetatable(obj, BibtexPlugin)
end

function BibtexPlugin:prerequisites()
	local path = self:get_bib_path()
	if not self._env.files.file_exists(path) then
		self._ret.error = {
			message = {"BibTeX file does not exist"},
			code		= RET_NO_BIB
		}
	end
end

function BibtexPlugin:get_field_case_insensitive(fields_dict, wanted)
	local lower_wanted = string.lower(wanted)
	for k, v in pairs(fields_dict) do
		if string.lower(k) == lower_wanted then
			return v and v.value or nil
		end
	end
	return nil
end

function BibtexPlugin:set_entry_field(library, entry_key, field_key, field_value)
	local entry = library.entry_dict[entry_key]
	if not entry then return end
	for _, f in ipairs(entry.fields) do
		if f.name == field_key then
			f.value = field_value
			break
		end
	end
end

-- ========= robust get_field =========
function BibtexPlugin:get_field(entry, wanted_name)
	if type(entry) ~= "table" then return nil end
	if not wanted_name or wanted_name == "" then return nil end
	local wanted = wanted_name:lower()

	-- 0) parfois à la racine
	for k,v in pairs(entry) do
		if type(k)=="string" and k:lower()==wanted and type(v)=="string" then
			return self:unbrace(v)
		end
	end

	local f = entry.fields
	if type(f) ~= "table" then return nil end

	-- 1) dictionnaire: clés -> valeurs
	local is_list = (#f > 0 and type(f[1])=="table")
	if not is_list then
		for k,v in pairs(f) do
			if type(k)=="string" and k:lower()==wanted and type(v)=="string" then
				return self:unbrace(v)
			end
		end
	end

	-- 2) liste { {name=..., value=...}, ... }
	if is_list then
		for _,item in ipairs(f) do
			local name = self:lower(item.name or item.key)
			if name == wanted then
				local v = item.value or item.val or item.text
				if type(v)=="string" and v~="" then
					return self:unbrace(v)
				end
			end
		end
	end

	return nil
end

function BibtexPlugin:unbrace(s)
	if type(s) ~= "string" then return s end
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	if s and #s >= 2 then
		local a,b = s:sub(1,1), s:sub(-1,-1)
		if (a == "{" and b == "}") or (a == '"' and b == '"') then
			return s:sub(2, -2)
		end
	end
	return s
end

function BibtexPlugin:lower(s)
	return type(s) == "string" and s:lower() or s
end

function BibtexPlugin:simplify_string(s)
	if type(s) ~= "string" then return "" end
	s = s:lower()
	s = s:gsub("[.,;:?!]", "")
	s = s:gsub("%s+", " ")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	return s
end

function BibtexPlugin:find_duplicates(library)
	local seen_keys = {}
	local dup_keys = {}
	local seen_titles = {}
	local dup_titles = {}
	for i = 1, #library.entries do
		local e = library.entries[i]
		local fields = e.fields_dict or {}
		local t = self:simplify_string(
			self:get_field_case_insensitive(fields, "title")
		)
		if t ~= "" then
			if self._env.utils.in_table(t, seen_titles) then
				if not self._env.utils.in_table(t, dup_titles) then
					table.insert(dup_titles, t)
				end
			else
				table.insert(seen_titles, t)
			end
		end
		if self._env.utils.in_table(e.key, seen_keys) then
			if not self._env.utils.in_table(e.key, dup_keys) then
				table.insert(dup_keys, e.key)
			end
		else
			table.insert(seen_keys, e.key)
		end
	end
	return dup_keys, dup_titles
end

function BibtexPlugin:find_incomplete(library)
	local incomplete = {}
	for i = 1, #library.entries do
		local e = library.entries[i]
		local fields = e.fields_dict or {}
		local mis = {
			key = e.key,
			author = not self:get_field_case_insensitive(fields, "author"),
			title = not self:get_field_case_insensitive(fields, "title"),
			year = not self:get_field_case_insensitive(fields, "year"),
			pages = not self:get_field_case_insensitive(fields, "pages")
		}
		table.insert(incomplete, mis)
	end
	return incomplete
end

--[[ Formats the display of a BibTeX file.
		 @param library The Library object to format
--]]
function BibtexPlugin:pretty_print(library)
	local out = ""
	for i = 1, #library.entries do
		local e = library.entries[i]
		out = out .. "@" .. e.type .. "{" .. e.key .. ",\n"
		for j = 1, #e.fields do
			local item = e.fields[j]
			out = out .. "	" .. self:padto(item.name, 16) .. " = {"
			local lines = self:wrap(self._env.utils.str_trim(item.value), 58)
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

function BibtexPlugin:padto(s, len)
	return s .. string.rep(" ", math.max(0, len - #s))
end

--[[ Fetches all the keys present in a library.
--]]
function BibtexPlugin:get_keys(library)
	local keys = {}
	for i = 1, #library.entries do
		local e = library.entries[i]
		table.insert(keys, e.key)
	end
	return keys
end

function BibtexPlugin:wrap(s, len)
	local words = self._env.utils.str_split(s, " ")
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
function BibtexPlugin:print_duplicates(kdups, tdups)
	local p = self._env.tui.Printer:new()
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
	if #tdups > 0 then
		p:print(#tdups .. " duplicate title(s) found:"):indent():println()
		for _,v in ipairs(tdups) do
			p:println(v)
		end
		p:outdent()
	end
	return p, RET_BIB_DUPLICATES
end

function BibtexPlugin:print_missing_fields(inc)
	local p = self._env.tui.Printer:new()
	local keys = {"author", "title", "year", "pages"}
	local missing = false
	p:print("", 16)
	for _,k in ipairs(keys) do
		p:bd():ul():print(p:sul() .. k .. p:srs(), #k + 1)
	end
	p:println()
	for _,e in ipairs(inc) do
		p:print(e.key, 16)
		for _,k in ipairs(keys) do
			if e[k] then
				missing = true
				p:print(p:sbg().yellow()..p:sfg().white() .."X" .. p:srs(), #k + 1, " ")
			else
				p:print(" ", #k + 1)
			end
		end
		p:println()
	end
	if missing then
		return p, RET_BIB_INCOMPLETE
	end
	return p, RET_OK
end

function BibtexPlugin:get_bib_path()
	return self._env.pwd.."/Source/"..self._env.settings.mainbib
end

function BibtexPlugin:show_duplicates()
	local lib = bibtex.parse(self._env.files.read_file(self:get_bib_path()))
	local kdups, tdups = self:find_duplicates(lib)
	local p, c = self:print_duplicates(kdups, tdups)
	self._ret.success = {
		code = c,
		message = p:lines()
	}
end

function BibtexPlugin:show_missing_fields()
	local lib = bibtex.parse(self._env.files.read_file(self:get_bib_path()))
	local incomplete = self:find_incomplete(lib)
	local p, c = self:print_missing_fields(incomplete)
	self._ret.success = {
		code = c,
		message = p:lines()
	}
end

function BibtexPlugin:clean_bib()
	local lib = bibtex.parse(self._env.files.read_file(self:get_bib_path()))
	local cleaned = self:pretty_print(lib)
	local lines = self._env.utils.explode("\n", cleaned)
	self._ret.success = {
		code = 0,
		message = lines
	}
end

function BibtexPlugin:shorten_from_table(reps, s)
	local out = s
	for from, to in pairs(reps or {}) do
		out = out:gsub(from, to)
	end
	return out
end

function BibtexPlugin:shorten_ee(s)
	return nil
end

function BibtexPlugin:shorten_booktitle(s)
	local out = self:shorten_from_table(self._config.shorten.booktitle, s)
	local x1, x2 = out:find("[^A-Z][A-Z]+%s+[12]%d%d%d[^%d]")
	if x1 then
		out = out:sub(x1 + 1, x2 - 1)
	end
	return out
end

function BibtexPlugin:shorten_journal(s)
	return self:shorten_from_table(self._config.shorten.journal, s)
end

function BibtexPlugin:shorten_item(item)
	local backup = self._env.utils.deep_copy(item)
	local new_value = item.value
	if item.name == "journal" then
		new_value = self:shorten_journal(item.value)
	end
	if item.name == "booktitle" then
		new_value = self:shorten_booktitle(item.value)
	end
	if item.name == "ee" then
		new_value = self:shorten_ee(item.value)
	end
	if item.value == new_value then
		backup = nil
	else
		backup.name = "_" .. item.name
		if new_value == nil then
			item = nil
		else
			item.value = new_value
		end
	end
	return item, backup
end

function BibtexPlugin:shorten()
	local library = bibtex.parse(self._env.files.read_file(self:get_bib_path()))
	for i = 1, #library.entries do
		local e = library.entries[i]
		local toadd = {}
		local todel = {}
		for j = 1, #e.fields do
			local new_item, backup = self:shorten_item(e.fields[j])
		
			if new_item then
			e.fields[j] = new_item
			else
			table.insert(todel, j)
			end
		
			if backup then
			table.insert(toadd, {
				name	= backup.name,
				value = backup.value
			})
			end
		end
		
		table.sort(todel, function(a, b)
			return a > b
		end)
		
		for _, j in ipairs(todel) do
			table.remove(e.fields, j)
		end
		for _, b in ipairs(toadd) do
			table.insert(e.fields, {
			name	= b.name,
			value = b.value,
			_tokens = {
				{
				value = b.value,
				_raw	= b.value
				}
			}
			})
		end
	end
	local cleaned = self:pretty_print(library)
	local lines = self._env.utils.explode("\n", cleaned)
	self._ret.success = {
		code = 0,
		message = lines
	}
end

--[[ Performs a basic cleanup of a LaTeX source file.
--]]
function BibtexPlugin:coarse_clean(s)
	local lines = self._env.utils.explode("\n", s)
	for i, line in ipairs(lines) do
		lines[i] = line:gsub("^%%.*$", ""):gsub(" %.*$", "")
	end
	return table.concat(lines, "\n")
end

--[[ Finds all entries that have a given key as a cross-reference.
--]]
function BibtexPlugin:find_crossrefs(key, library)
	local refs = {}
	for i = 1, #library.entries do
		local e = library.entries[i]
		for _, f in ipairs(e.fields) do
			if f.name == "crossref" and f.value == key then
				table.insert(refs, e.key)
				break
			end
		end
	end
	return refs
end

--[[ Finds all entries that are neither cited nor cross-referenced in the
		 main paper.
--]]
function BibtexPlugin:find_uncited()
	local library = bibtex.parse(self._env.files.read_file(self:get_bib_path()))
	local paper = self:coarse_clean(self._env.files.read_file(self._env.project_root .. "/Source/" .. self._env.mainfile))
	local found = {}
	for i = 1, #library.entries do
		local e = library.entries[i]
		if not paper:find(e.key) then
			table.insert(found, e.key)
		end
	end
	local uncited = {}
	for _, e in ipairs(found) do
		local xr = self:find_crossrefs(e, library)
		local has_one = false
		for _, r in ipairs(xr) do
			if not self._env.utils.in_table(r, found) then
				has_one = true
				break
			end
		end
		if not has_one then
			table.insert(uncited, e)
		end
	end
	local message = {}
	if #uncited == 0 then
		table.insert(message, "All entries are cited")
	else
		table.insert(uncited, 1, #uncited .. " entries are uncited")
		message = uncited
	end
	self._ret.success = {
		code = 0,
		message = message
	}
end

function BibtexPlugin:diff_bibs()
	local library = bibtex.parse(self._env.files.read_file(self:get_bib_path()))
	local other_arg = self._env.arg[#self._env.arg]
	if not other_arg then
		self._ret.error = {
			code = 2,
			message = {"A BibTeX file must be specified"}
		}
		return
	end
	local other_file = self._env.pwd .. "/" .. other_arg
	if not self._env.files.file_exists(other_file) then
		self._ret.error = {
			code = 4,
			message = {"File " .. other_file .. " not found"}
		}
		return
	end
	local other_library = bibtex.parse(self._env.files.read_file(other_file))
	local in_local = self:get_keys(library)
	local in_other = self:get_keys(other_library)
	local missing_local = {}
	local missing_other = {}
	for _, k in ipairs(in_local) do
		if not self._env.utils.in_table(k, in_other) then
			table.insert(missing_other, k)
		end
	end
	for _, k in ipairs(in_other) do
		if not self._env.utils.in_table(k, in_local) then
			table.insert(missing_local, k)
		end
	end
	local p = self._env.tui.Printer:new()
	p:print(p:sul() .. "Missing in local" .. p:srs(), 16):print(" "):println(p:sul() .. "Missing in other" .. p:srs(), 16)
	for i = 1, math.max(#missing_local, #missing_other) do
		if missing_local[i] then
			p:print(missing_local[i], 16)
		else
			p:print("", 16)
		end
		p:print(" ")
		if missing_other[i] then
			p:print(missing_other[i], 16)
		else
			p:print("", 16)
		end
		p:println("")
	end
	self._ret.success = {
		code = 0,
		message = p:lines()
	}
end

function BibtexPlugin:postrequisites()
end

return {
	plugin = BibtexPlugin
}

-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: