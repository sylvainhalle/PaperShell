-- Source - https://stackoverflow.com/a/9145447
-- Posted by Seth Carnegie, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-07-07, License - CC BY-SA 3.0

--package.path = './mylib/?.lua;' .. package.path

local bibtex = dofile(os.getenv("PWD") .. "/plugins/bibtex-utils/lua-bibtex-parser.lua")
local butils = dofile(os.getenv("PWD") .. "/plugins/bibtex-utils/lua-bibtex-utils.lua")

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
	local lib = bibtex.parse(butils.readfile(get_bib_path(env)))
	local kdups, tdups = butils.find_duplicates(lib)
	local p, c = print_duplicates(env, kdups, tdups)
	ret.success = {
		code = c,
		message = p:lines()
	}
end

local function show_missing_fields(env, ret)
	local lib = bibtex.parse(butils.readfile(get_bib_path(env)))
	local incomplete = butils.find_incomplete(lib)
	local p, c = print_missing_fields(env, incomplete)
	ret.success = {
		code = c,
		message = p:lines()
	}
end

local function clean_bib(env, ret)
	local lib = bibtex.parse(butils.readfile(get_bib_path(env)))
	-- TODO
end


local function postrequisites(env, ret)
end

return {
  prerequisites  = prerequisites,
  postrequisites = postrequisites,
  show_duplicates = show_duplicates,
  show_missing_fields = show_missing_fields
}