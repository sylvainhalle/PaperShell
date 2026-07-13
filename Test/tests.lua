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

--[[ Unit tests.
     @author Sylvain Hallé
  ]]

local tr    = require "test-runner"
local utils = dofile("../Tools/utils.lua")

tr:test(function()
	assert(utils.starts_with("foobar", "foo"))
end)

tr:test(function()
	assert(utils.starts_with("foobar", "foobar"))
end)

tr:test(function()
	assert(not utils.starts_with("foobar", "fox"))
end)

tr:test(function()
	assert(not utils.starts_with("foobar", "foobarbe"))
end)

--[[
bibtex = dofile("../Tools/lua-bibtex-parser.lua")
butils = dofile("../Tools/lua-bibtex-utils.lua")

tr:test(function ()
	local lib = bibtex.parse(butils.readfile("bib1.bib"))
	local kdup, tdup = butils.find_duplicates(lib)
	assert(#tdup == 1, "There should be a title duplicate")
end)

tr:test(function ()
	local lib = bibtex.parse(butils.readfile("bib1.bib"))
	local kdup, tdup = butils.find_duplicates(lib)
	
	assert(#kdup == 1, "There should be a key duplicate")
end)
--]]
tr:evaluate()

-- :folding=explicit:wrap=none:mode=lua:tabSize=2:indentSize=2: