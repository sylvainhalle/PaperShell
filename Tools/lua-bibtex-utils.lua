--[[
     Utilitaires
]]--

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

function pretty_print(library)
	local out = ""
end

return {
	readfile = readfile,
	writefile = writefile,
	unbrace = unbrace,
	lower = lower,
	trim = trim,
	split = split,
	get_field = get_field,
	get_field_case_insensitive = get_field_case_insensitive,
	set_field_value = set_field_value,
	set_field_name = set_field_name,
	bibtex = bibtex,
	run = run,
	print_table = print_table,
	find_duplicates = find_duplicates,
	find_incomplete = find_incomplete
}