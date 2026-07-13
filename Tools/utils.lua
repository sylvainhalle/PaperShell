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


-- Source - https://stackoverflow.com/a/7615129
-- Posted by user973713, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-07-08, License - CC BY-SA 4.0
local function str_split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

--[[ Checks if a string is a prefix of another string.
     @param string The string
     @param prefix The prefix to look for
--]]
local function starts_with(string, prefix)
	if #prefix > #string then
		return false
	end
	return string.sub(string, 1, #prefix) == prefix
end

-- Source - https://stackoverflow.com/a/641993
-- Posted by Doub, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-07-10, License - CC BY-SA 3.0
local function shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

--[[ Creates a deep (i.e. recursive) copy of an object.
     @param obj Any
     @param copies? The object to copy into
     @return The copy of the object
--]]
local function deep_copy(obj, copies)
  if type(obj) ~= "table" then
    return obj
  end

  copies = copies or {}
  if copies[obj] then
    return copies[obj]
  end

  local copy = {}
  copies[obj] = copy

  for k, v in pairs(obj) do
    copy[deep_copy(k, copies)] = deep_copy(v, copies)
  end

  return setmetatable(copy, getmetatable(obj))
end

--[[ Splits a string into an array of strings, breaking at each occurrence
     of a specified character.
     @param div The dividing character
     @param str The string to split
--]]
local function explode(div,str) -- credit: http://richard.warburton.it
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end

--[[ Trims a string of its leading and trailing spaces.
     @param s The string to trim
     @return The trimmed string
--]]
function str_trim(s)
	s = s:gsub("^%s+", "")
	s = s:gsub("%s+$", "")
	return s
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

--[[ Determines if an element is in a table
  ]]
local function in_list(e, table)
  local b = e:match("([^/]*)$") or e
  for _, x in ipairs(table) do
    if b == x then return true end
  end
  return false
end

--[[ Determines if an element is in a table
  ]]
local function in_table(e, table)
  for _, x in ipairs(table) do
    if e == x then return true end
  end
  return false
end

---Recursively prints a table, if not table value is just printed.
---@param t any
---@param level? number
local function print_table(t, level, seen)
    level = level or 0
    seen = seen or {}
    if seen[t] then
    	io.write(string.rep("  ", level), "<cycle>")
    	return
    end
    seen[t] = true
    if type(t) == "table" then
        -- do not print new line on the level 0
        if level ~= 0 then
            io.write("\n")
        end
        io.write(string.rep("  ", level), "{\n")
        level = level + 1

        for key, value in pairs(t) do
            io.write(string.rep("  ", level) .. string.format("[%s] = ", key))
            print_table(value, level, seen)
            io.write(",\n")
        end

        level = level - 1
        io.write(string.rep("  ", level), "}")
    else
        io.write(tostring(t))
    end
    -- print new line on the level 0
    if level == 0 then
        io.write("\n")
    end
end

return {
	starts_with  = starts_with,
	str_split    = str_split,
	split        = split,
	str_trim     = str_trim,
	in_list      = in_list,
	in_table     = in_table,
	explode      = explode,
	print_table  = print_table,
	shallow_copy = shallow_copy,
	deep_copy    = deep_copy
}

-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: