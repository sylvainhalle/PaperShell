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

--[[ A set of functions to display strings in the terminal.
     @author Sylvain Hallé
  ]]

local utf8   = require "utf8"
local utils  = require "utils"

local color = {
	reset         = "\u{001B}[0m",
	bold          = "\u{001B}[1m",
	italic        = "\u{001B}[3m",
	underline     = "\u{001B}[4m",
	reverse       = "\u{001B}[7m",
	strikethrough = "\u{001B}[9m",
	foreground = {
		black   = "\u{001B}[30m",
		red     = "\u{001B}[31m",
		green   = "\u{001B}[32m",
		yellow  = "\u{001B}[33m",
		blue    = "\u{001B}[34m",
		magenta = "\u{001B}[35m",
		cyan    = "\u{001B}[36m",
		white   = "\u{001B}[37m",
		bright  = {
			black   = "\u{001B}[90m",
			red     = "\u{001B}[91m",
			green   = "\u{001B}[92m",
			yellow  = "\u{001B}[93m",
			blue    = "\u{001B}[94m",
			magenta = "\u{001B}[95m",
			cyan    = "\u{001B}[96m",
			white   = "\u{001B}[97m"
		}
	},
	background = {
		black   = "\u{001B}[40m",
		red     = "\u{001B}[41m",
		green   = "\u{001B}[42m",
		yellow  = "\u{001B}[43m",
		blue    = "\u{001B}[44m",
		magenta = "\u{001B}[45m",
		cyan    = "\u{001B}[46m",
		white   = "\u{001B}[47m",
		bright  = {
			black   = "\u{001B}[100m",
			red     = "\u{001B}[101m",
			green   = "\u{001B}[102m",
			yellow  = "\u{001B}[103m",
			blue    = "\u{001B}[104m",
			magenta = "\u{001B}[105m",
			cyan    = "\u{001B}[106m",
			white   = "\u{001B}[107m"
		}
	}
}

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

--[[ Strips a string of all ANSI escape sequences. The function assumes a
     simplified version of the codes, of the form ^[...m.
     @param s The string
     @return The string without the escape sequences
--]]
local function ansi_strip(s)
	return s:gsub("\u{001B}%[%w+m", "")
end

--[[ Truncates a string to a number of *visible* characters.
     @param str The string
     @param len The number of visible characters to retain
     @return The truncated string
--]]
local function ansi_substring(str, length)
	local len = utf8.len(str)
    local in_ansi = false
    local visible_len = 0
    local out = ""
    for i = 1, len do
    	local char = utf8sub(str, i, i)
    	if in_ansi then
    		if char == "m" then
    			in_ansi = false
    		end
    		out = out .. char
    	else
    		out = out .. char
    		if char == "\u{001B}" then
    			in_ansi = true
    		else
    			visible_len = visible_len + 1
    		end
    	end
    	if visible_len >= length then
    		--break
    	end
    end
    return out
end

--[[ Truncates or pads a string to a fixed length.
     @param str The string
     @param length The length
     @param pad_char (Optional) the character used to pad if the string
       is too short
  ]]
local function printpad(str, length, pad_char, a)
    pad_char = pad_char or " "
    local align = a or "left"
    local strip = ansi_strip(str)
    local sv_len = utf8.len(strip)
    if sv_len < length then
        -- Pad if shorter
        local to_fill = length - sv_len
        if align == "left" then
        	return str .. string.rep(pad_char, to_fill)
        elseif align == "right" then
        	return string.rep(pad_char, to_fill) .. str
        elseif align == "center" then
        	local fill_left = math.floor(to_fill / 2)
        	local fill_right = to_fill - fill_left
        	return string.rep(pad_char, fill_left) .. str .. string.rep(pad_char, fill_right)
        end
    else
        -- Return as-is if exactly the right length
        return ansi_substring(str, length)
    end
end

local Printer = {}
Printer.__index = Printer

function Printer:new()
    local obj = {
    	_lines   = {},
    	_curline = "",
    	_indent  = "",
    	_wrap    = 0
    }
    return setmetatable(obj, Printer)
end

function Printer:print(st, ln, pd, a)
	self._curline = self._curline or self._indent
	local s = st or ""
	local len = ln or -1
	local pad = pd or " "
	local align = a or "left"
	if len > 0 then
		self._curline = self._curline .. printpad(s, len, pad, a)
	else
		self._curline = self._curline .. s
	end
	return self
end

function Printer:indent()
	self._indent = self._indent .. "  "
	return self
end

function Printer:outdent()
	if string.len(self._indent) >= 2 then
		self._indent = string.sub(self._indent, 1, string.len(self._indent) - 2)
	end
	return self
end

function Printer:println(s, ln, pd, a)
	self:print(s, a)
	table.insert(self._lines, self._curline)
	self._curline = nil
	return self
end

function Printer:fg()
	return {
		black   = function()
			self:print(color.foreground.black)
			return self
		end,
		red     = function()
			self:print(color.foreground.red)
			return self
		end,
		green   = function() 
			self:print(color.foreground.green)
			return self
			end,
		yellow  = function() 
			self:print(color.foreground.yellow)
			return self
			end,
		blue    = function() 
			self:print(color.foreground.blue)
			return self
			end,
		magenta = function() 
			self:print(color.foreground.magenta)
			return self
			end,
		cyan    = function() 
			self:print(color.foreground.cyan)
			return self
			end,
		white   = function() 
			self:print(color.foreground.white)
			return self
			end
	}
end

function Printer:sfg()
return {
	black   = function()
	return color.foreground.black
	end,
	red     = function()
	return color.foreground.red
	end,
	green   = function() 
	return color.foreground.green
	end,
	yellow  = function() 
	return color.foreground.yellow
	end,
	blue    = function() 
	return color.foreground.blue
	end,
	magenta = function() 
	return color.foreground.magenta
	end,
	cyan    = function() 
	return color.foreground.cyan
	end,
	white   = function() 
	return color.foreground.white
	end
}
end

function Printer:bg()
	return {
		black   = function()
			self:print(color.background.black)
			return self
		end,
		red     = function()
			self:print(color.background.red)
			return self
		end,
		green   = function() 
			self:print(color.background.green)
			return self
			end,
		yellow  = function() 
			self:print(color.background.yellow)
			return self
			end,
		blue    = function() 
			self:print(color.background.blue)
			return self
			end,
		magenta = function() 
			self:print(color.background.magenta)
			return self
			end,
		cyan    = function() 
			self:print(color.background.cyan)
			return self
			end,
		white   = function() 
			self:print(color.background.white)
			return self
			end
	}
end

function Printer:sbg()
return {
	black   = function()
	return color.background.black
	end,
	red     = function()
	return color.background.red
	end,
	green   = function() 
	return color.background.green
	end,
	yellow  = function() 
	return color.background.yellow
	end,
	blue    = function() 
	return color.background.blue
	end,
	magenta = function() 
	return color.background.magenta
	end,
	cyan    = function() 
	return color.background.cyan
	end,
	white   = function() 
	return color.background.white
	end
}
end

function Printer:bd()
	self:print(color.bold)
	return self
end

function Printer:ul()
	self:print(color.bold)
	return self
end

function Printer:it()
	self:print(color.italic)
	return self
end

function Printer:rs()
	self:print(color.reset)
	return self
end

function Printer:sbd()
	return color.bold
	
end

function Printer:sul()
	return color.bold
	
end

function Printer:sit()
	return color.italic
	
end

function Printer:srs()
	return color.reset
	
end

function Printer:lines()
	return self._lines
end

return {
	Printer = Printer,
	color = color,
	stdout = stdout,
	stderr = stderr,
	stdoutln = stdoutln,
	stderrln = stderrln,
	printpad = printpad
}