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
function str_split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

function str_trim(s)
	s = s:gsub("^%s+", "")
	s = s:gsub("%s+$", "")
	return s
end

--[[ Determines if an element is in a table
  ]]
function inlist(e, table)
  local b = e:match("([^/]*)$") or e
  for _, x in ipairs(table) do
    if b == x then return true end
  end
  return false
end


return {
	str_split = str_split,
	str_trim  = str_trim,
	in_list   = in_list
}

-- :folding=explicit:wrap=none:mode=lua: