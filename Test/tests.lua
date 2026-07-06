local tr = require "test-runner"

meta = dofile("../Tools/metaphone.lua")
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

tr:evaluate()