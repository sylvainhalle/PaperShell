local lpeg = require("lpeg")


---@class Exception
---@field level string
---@field message string
---@field line integer
---@field column integer
local Exception = {
  _class = "Exception"
}

---@param level string
---@param message string
---@param line integer
---@param column integer
---@return Exception
function Exception:new(level, message, line, column)
  ---@type Exception
  local exception = {
    level = level,
    message = message,
    line = line,
    column = column,
  }
  setmetatable(exception, self)
  self.__index = self

  return exception
end


---@comment Each field token is either a nonnegative number, a
---@comment macro name (like `jan'), or a brace-balanced string delimited by
---@comment either |double_quote|s or braces.
---@class FieldToken
---@field _raw string
---@field value string?
---@field left_delimitter string?
---@field right_delimitter string?
---@field left_space string?
---@field right_space string?
local FieldToken = {
  _class = "FieldToken",
  _base_class = "FieldToken",
}
FieldToken.__index = FieldToken

function FieldToken:__tostring()
  return self._raw
end

---@param string_dict table<string, string>?
---@return string
---@return Exception?
function FieldToken:evaluate(string_dict)
  return self.value, nil
end


---@class NumberToken: FieldToken
local NumberToken = {
  _class = "NumberToken"
}
setmetatable(NumberToken, FieldToken)

function NumberToken:new(raw)
  assert(string.match(raw, "^%s*%d+%s*$"))
  ---@type NumberToken
  local number_token = {
    raw = raw,
    value = string.match(raw, "%d+")
  }
  setmetatable(number_token, self)
  self.__index = self
  return number_token
end


---@class MacroToken: FieldToken
---@field name string
local MacroToken = {
  _class = "MacroToken"
}
setmetatable(MacroToken, FieldToken)

---@param name string
---@return MacroToken
function MacroToken:new(name)
  ---@type MacroToken
  local macro_token = {
    _raw = name,
    name = string.lower(name),
    value = "",
  }
  setmetatable(macro_token, self)
  self.__index = self
  return macro_token
end

---@param string_dict table<string, string>
---@return string
---@return Exception?
function MacroToken:evaluate(string_dict)
  if not string_dict then
    error("Nil string dict")
  end
  self.value = string_dict[self.name]
  local warning = nil
  if not self.value then
    self.value = ""
    warning = Exception:new("warning", "Cannot find string name", 0, 0)
  end
  return self.value, warning
end


---@class Braced: FieldToken
local Braced = {
  _class = "Braced"
}
setmetatable(Braced, FieldToken)

---@param value string
---@return Braced
function Braced:new(value)
  -- assert brace-balanced string
  ---@type Braced
  local braced_token = {
    _raw = value,
    value = string.gsub(value, "%s+", " ")
  }
  setmetatable(braced_token, self)
  self.__index = self
  return braced_token
end

---@return string
function Braced:__tostring()
  return string.format("{%s}", self._raw)
end


---@class Quoted: FieldToken
local Quoted = {
  _class = "Quoted"
}
setmetatable(Quoted, FieldToken)

---@param value string
---@return Quoted
function Quoted:new(value)
  -- assert brace-balanced string
  assert(not string.match(value, '"'))
  ---@type Quoted
  local quoted_token = {
    _raw = value,
    value = string.gsub(value, "%s+", " ")
  }
  setmetatable(quoted_token, self)
  self.__index = self
  return quoted_token
end

function Quoted:__tostring()
  return string.format('"%s"', self._raw)
end


---@param value string
---@return FieldToken
function FieldToken:new(value)
  if string.match(value, "^%s*%d+%s*$") then
    return NumberToken:new(value)
  else
    return Braced:new(value)
  end
end

---@param tokens FieldToken[]
---@param string_dict table<string, string>
---@return string
---@return Exception[]
local function evaluate_field_tokens(tokens, string_dict)
  local value = ""
  local warnings = {}
  for _, token in pairs(tokens) do
    local token_value, warning = token:evaluate(string_dict)
    value = value .. token_value
    if warning then
      table.insert(warnings, warning)
    end
  end
  return value, warnings
end

---@param tokens FieldToken[]
---@return string
local function get_tokens_raw(tokens)
  local raw = ""
  local raw_list = {}
  for i, token in pairs(tokens) do
    if i > 1 and not token.left_space then
      token.left_space = " "
      token._raw = " " .. token._raw
    elseif i < #tokens and not token.right_space then
      token.right_space = " "
      token._raw = token._raw .. " "
    end
    table.insert(raw_list, token._raw)
  end
  return table.concat(raw_list, "#")
end


---@class Field
---@field _tokens FieldToken[]
---@field name string
---@field value string
local Field = {
  _class = "Field",
}

---@param name string
---@param value string|FieldToken[]
---@return Field
function Field:new(name, value)
  ---@type Field
  local field = {
    _tokens = {},
    name = name,
    value = "",
  }
  setmetatable(field, self)
  self.__index = self

  field:set_value(value)

  return field
end

function Field:__tostring()
  local res = string.format("%s = {%s}", self.name, get_tokens_raw(self._tokens))
  return res
end

---@param name string
function Field:set_name(name)
  self.name = name
end

---@param value string|FieldToken[]
function Field:set_value(value)
  if type(value) == "string" then
    self.value = value
    self._tokens = {Braced:new(value)}
  elseif type(value) == "table" then
    self._tokens = {}
    self.value = ""
    for _, token in ipairs(value) do
      table.insert(self._tokens, token)
      self.value = self.value .. token.value
    end
  end
end

function Field:evaluate(string_dict)
  self.value = evaluate_field_tokens(self._tokens, string_dict)
end


---@class Library
---@field exceptions Exception[]
---@field blocks Block[]
---@field failed_blocks FailedBlock[]
---@field comments Comment[]
---@field preamble string
---@field preambles Preamble[]
---@field strings String[]
---@field string_dict table<string, string>
---@field entries Entry[]
---@field entry_dict table<string, Entry>
---@field metadata String[]
local Library = {
  _class = "Library"
}

---@param string_dict table<string, string>?
---@return Library
function Library:new(string_dict)
  ---@type Library
  local library = {
    exceptions = {},

    blocks = {},
    failed_blocks = {},

    comments = {},

    preamble = "",
    preambles = {},

    strings = {},
    string_dict = {},

    entries = {},
    entry_dict = {},
    
    metadata = "",
  }
  setmetatable(library, self)
  self.__index = self

  return library
end


function Library:add(block)

end

function Library:tostring(block)

end

function Library:__tostring()
  local bib_string = ""
  bib_string = bib_string .. tostring(self.preamble or "")
  for k, v in pairs(self.entry_dict) do
    bib_string = bib_string .. tostring(v) .. "\n\n"
  end
  for i = 0, #self.comments do
    bib_string = bib_string .. tostring(self.comments[i] or "") .. "\n\n"
  end
  return bib_string
end


---@class Block
---@field _raw string
local Block = {
  _class = "Block",
}

function Block:new()
  ---@type Block
  local block = {
    _raw = "",
  }
  setmetatable(block, self)
  self.__index = self

  return block
end


---@class FailedBlock: Block
local FailedBlock = Block:new()
FailedBlock._class = "FailedBlock"


---@class Comment: Block
local Comment = {
  _class = "Comment"
}
setmetatable(Comment, Block)

---@param raw string
function Comment:new(raw)
  local comment = {
  	_raw = raw
  }
  setmetatable(comment, self)
  self.__index = self
  return comment
end


function Comment:__tostring()
  return self._raw
end


---@class Preamble: Block
---@field _tokens FieldToken[]
---@field _raw string
---@field value string
local Preamble = Block:new()
Preamble._class = "preamble"

---@param value string|FieldToken[]
---@return Preamble
function Preamble:new(value, string_dict)
  ---@type Preamble
  local preamble = {
    _tokens = {},
    _raw = "",
    value = "",
  }
  setmetatable(preamble, self)
  self.__index = self

  preamble:set_value(value, string_dict)

  return preamble
end

---@param value string|FieldToken[]
function Preamble:set_value(value, string_dict)
  if type(value) == "string" then
    local token = FieldToken:new(value)
    self._tokens = {token}
    self._raw = token._raw
  elseif type(value) == "table" then
    self._tokens = {}
    for _, token in ipairs(value) do
      table.insert(self._tokens, token)
    end
    self._raw = get_tokens_raw(self._tokens)
  end
  self.value = evaluate_field_tokens(self._tokens, string_dict)
end


---@class String: Block
---@field _tokens FieldToken[]
---@field name string
---@field value string
local String = Block:new()
String._class = "String"

---@param name string
---@param value string|FieldToken[]
---@return String
function String:new(name, value)
  ---@type String
  local string_command = {
    _tokens = {},
    _raw_name = name,
    name = string.lower(name),
    value = "",
  }
  setmetatable(string_command, self)
  self.__index = self

  string_command:set_value(value)

  return string_command
end

---@param name string
function String:set_name(name)
  self._raw_name = name
  self.name = string.lower(name)
end

---@param value string|FieldToken[]
function String:set_value(value)
  if type(value) == "string" then
    local token = Braced:new(value)
    self._tokens = {token}
  elseif type(value) == "table" then
    self._tokens = {}
    for _, token in ipairs(value) do
      table.insert(self._tokens, token)
    end
  end
  self:evaluate()
end

function String:evaluate(string_dict)
  self.value = evaluate_field_tokens(self._tokens, string_dict)
  return self.value
end


---@class Entry: Block
---@field type string
---@field key string
---@field fields Field[]
---@field fields_dict table<string, Field>
local Entry = Block:new()
Entry._class = "Entry"

---@param entry_type string
---@param key string
---@param fields Field[]|table<string, string>
---@return Entry
function Entry:new(entry_type, key, fields)
  ---@type Entry
  local entry = {
    type = entry_type,
    key = key,
    fields = {},
    fields_dict = {},
  }
  setmetatable(entry, self)
  self.__index = self

  if #fields > 0 then
    ---@cast fields Field[]
    for _, field in ipairs(fields) do
      assert(type(field) == "table" and field._class == "Field")
      table.insert(entry.fields, field)
      if entry.fields_dict[field.name] then
        error("Duplicate field name: " .. field.name)
      end
      entry.fields_dict[field.name] = field
    end
  else
    ---@cast fields table<string, string>
    for name, value in pairs(fields) do
      assert(type(name) == "string")
      assert(type(value) == "string")
      local field = Field:new(name, value)
      table.insert(self.fields, field)
      self.fields_dict[field.name] = field
    end
  end

  return entry
end

function Entry:__tostring()
  local field_str_list = {}
  for _, field in ipairs(self.fields) do
    table.insert(field_str_list, "  " .. tostring(field) .. ",\n")
  end
  local fields_str = table.concat(field_str_list, "")
  local res = string.format("@%s{%s,\n%s}", self.type, self.key, fields_str)
  return res
end


local P = lpeg.P
local R = lpeg.R
local S = lpeg.S
local C = lpeg.C
local Cc = lpeg.Cc
local Cf = lpeg.Cf
local Cg = lpeg.Cg
local Cmt = lpeg.Cmt
local Cp = lpeg.Cp
local Ct = lpeg.Ct
local V = lpeg.V


-- Learned from <http://boston.conman.org/2020/06/05.1>.
local function case_insensitive_pattern(str)
  local char = R("AZ", "az") / function (c) return P(c:lower()) + P(c:upper()) end
               + P(1) / function (c) return P(c) end
  return Cf(char^1, function (a, b) return a * b end):match(str)
end


local function calcline (s, i)
  if i == 1 then return 1, 1 end
  s = s:sub(1,i)
  if s:sub(#s, #s) == "\n" then
    s = s:sub(1, #s - 1)
  end
  local rest, line = s:gsub("[^\n]*\n", "")
  return 1 + line, #rest
end

local function match_error(pattern, message)
  return Cmt(pattern, function (subject, pos, captured)
    local lino, col = calcline(subject, pos)
    return true, {
      token_type = "error_message",
      message = string.format(message, captured),
      line = lino,
      col = col,
    }
  end)
end


local function get_bibtex_grammar()
  local ws = S(" \t\r\n")^0

  local error_patterns = {
    ExpectingEqualSign = match_error(#P(1), 'I was expecting an "="'),
    ExpectingBraceOrParen = match_error(#P(1), "I was expecting a `{' or a `('"),
    ExpectingCommaOrBrace = match_error(#P(1), "I was expecting a `,' or a `}'"),
    IllegalEndDatabase = match_error(-1, "Illegal end of database file"),
    MissingBraceInPreamble = match_error(#P(1), 'Missing "}" in preamble command'),
    MissingFieldPart = match_error(#P(1), "You're missing a field part"),
    MissingStringName = match_error(#P(1), "You're missing a string name"),
    IllegalCharFollowsEntryType = match_error(#(1 - S"{(" - ws), '"%s" immediately follows an entry type'),
  }

  local comment = (1 - P"@")^0

  local comment_cmd = case_insensitive_pattern("comment")
  local balanced = P{ "{" * V(1)^0 * "}" + (1 - S"{}") }
  local ident = (- R"09") * (R"\x20\x7F" - S" \t\"#%'(),={}")^1

  local piece = Ct(P"{" * C(balanced^0)  * P"}" * Cg(Cc"braced", "token_type"))
                + Ct(P'"' * C((balanced - P'"')^0) * (
                    P'"' * Cg(Cc"quoted", "token_type")
                    + error_patterns.IllegalEndDatabase
                  ))
                + Ct(C(R("09")^1) * Cg(Cc"number", "token_type"))
                + Ct(C(ident) * Cg(Cc"macro", "token_type"))
  local value = piece * (ws * P"#" * ws * piece)^0

  local preamble_body = value
  local preamble = Ct(Cg(Cc"preamble", "block_type")
                      * case_insensitive_pattern("preamble") * ws * (
                        P"{" * ws * (
                          preamble_body * ws * (
                            P"}"
                            + error_patterns.MissingBraceInPreamble
                            + error_patterns.IllegalEndDatabase
                          )
                          + error_patterns.MissingFieldPart
                          + error_patterns.IllegalEndDatabase
                        )
                        + P"(" * ws * (
                          preamble_body * ws * (
                            P")"
                            + error_patterns.MissingBraceInPreamble
                            + error_patterns.IllegalEndDatabase
                          )
                          + error_patterns.MissingFieldPart
                          + error_patterns.IllegalEndDatabase
                        )
                        + error_patterns.ExpectingBraceOrParen
                        + error_patterns.IllegalEndDatabase
                      ))

  local string_body = Cg(ident, "name") * ws * (
                        P"=" * ws * (
                          value
                          + error_patterns.MissingFieldPart
                          + error_patterns.IllegalEndDatabase
                        )
                        + error_patterns.ExpectingEqualSign
                        + error_patterns.IllegalEndDatabase
                      )
  local string_cmd = Ct(Cg(Cc"string", "block_type")
                        * case_insensitive_pattern("string") * ws * (
                          P"{" * ws * (
                            string_body * ws * (
                              P"}"
                              + error_patterns.IllegalEndDatabase
                              + error_patterns.MissingBraceInPreamble
                            )
                            + error_patterns.MissingStringName
                            + error_patterns.IllegalEndDatabase
                          )
                          + P"(" * ws * (
                            string_body * ws * (
                              P")"
                              + error_patterns.IllegalEndDatabase
                              + error_patterns.MissingBraceInPreamble
                            )
                            + error_patterns.MissingStringName
                            + error_patterns.IllegalEndDatabase
                          )
                          + error_patterns.ExpectingBraceOrParen
                          + error_patterns.IllegalEndDatabase
                        ))

  local key = (1 - S", \t}\r\n")^0
  local key_paren = (1 - S", \t\r\n")^0
  local field_value_pair = Ct(C(ident) * Cg(Cc"field_name", "token_type")) * ws * P"=" * ws * value  -- * record_success_position()

  local entry_body = (P"," * ws * field_value_pair)^0 * (P",")^-1
  local entry = Ct(Cg(Cc"entry", "block_type") * (Cg(ident, "type") * ws * (
                  P"{" * ws * (
                    Cg(key, "key") * ws * (
                      entry_body^-1 * ws * (
                        P"}"
                        + error_patterns.ExpectingCommaOrBrace
                        + error_patterns.IllegalEndDatabase
                      )
                    )
                  )
                  + P"(" * ws * (
                    Cg(key_paren, "key") * ws * (
                      entry_body^-1 * ws * (
                        P")"
                        + error_patterns.ExpectingCommaOrBrace
                        + error_patterns.IllegalEndDatabase
                      )
                    )
                  ))))

  local command_or_entry = P"@" * ws * (comment_cmd + preamble + string_cmd + entry)

  -- The P(-1) causes nil parsing result in case of error.
  local bibtex_grammar = Ct(comment * (command_or_entry * comment)^0) * P(-1)
  return bibtex_grammar
end

local bibtex_grammar = get_bibtex_grammar()


---@param token table
---@return FieldToken[]|Exception
local function convert_to_field_token(token)
  local field_token
  if token.token_type == "number" then
    field_token = NumberToken:new(token[1])
  elseif token.token_type == "macro" then
    field_token = MacroToken:new(token[1])
  elseif token.token_type == "braced" then
    field_token = Braced:new(token[1])
  elseif token.token_type == "quoted" then
    field_token = Quoted:new(token[1])
  elseif token.token_type == "error_message" then
    return Exception:new("error", token.message, token.line, token.column)
  end
  return field_token
end


---@param content string
function Library:load(content, string_dict)
  local ir = bibtex_grammar:match(content)
  if not ir then
    error("nil")
  end
  for _, block in ipairs(ir) do
    if block.block_type == "comment" then
      table.insert(self.comments, Comment:new(block[1]))

    elseif block.block_type == "preamble" then
      self:_load_preamble_block(block, string_dict)

    elseif block.block_type == "string" then
      self:_load_string_block(block)

    elseif block.block_type == "entry" then
      self:_load_entry_block(block)
    end
  end

  self:_evaluate_preamble()
end

function Library:_evaluate_preamble()
  self.preamble = ""
  for _, preamble in ipairs(self.preambles) do
    self.preamble = self.preamble .. preamble.value
  end
  return self.preamble
end

function Library:_load_preamble_block(block, string_dict)
  local field_tokens = {}
  for _, token in ipairs(block) do
    if token.token_type == "error_message" then
      block.block_type = "bad_block"
      table.insert(self.exceptions, Exception:new("error", token.message, token.line, token.column))
      break
    else
      table.insert(field_tokens, convert_to_field_token(token))
    end
  end
  local preamble = Preamble:new(field_tokens, string_dict)
  table.insert(self.preambles, preamble)
  table.insert(self.blocks, preamble)
end

function Library:_load_string_block(block)
  local field_tokens = {}
  for _, token in ipairs(block) do
    if token.token_type == "error_message" then
      block.block_type = "bad_block"
      table.insert(self.exceptions, Exception:new("error", token.message, token.line, token.column))
      break
    else
      table.insert(field_tokens, convert_to_field_token(token))
    end
  end
  if block.name and #field_tokens > 0 then
    local string_cmd = String:new(block.name, field_tokens, self)
    string_cmd:evaluate()
    table.insert(self.strings, string_cmd)
    table.insert(self.blocks, string_cmd)

    self.string_dict[string_cmd.name] = string_cmd.value
  end
end

function Library:_load_entry_block(block)
  local fields = {}

  local field_name = ""
  local field_tokens = {}
  for _, token in ipairs(block) do
    if token.token_type == "error_message" then
      table.insert(self.exceptions, Exception:new("error", token.message, token.line, token.column))
      block.block_type = "bad_block"
      break
    elseif token.token_type == "field_name" then
      if #field_tokens > 0 then
        local field = Field:new(field_name, field_tokens)
        field:evaluate(self.string_dict)
        table.insert(fields, field)
        field_tokens = {}
      end
      field_name = token[1]
    else
      local field_token = convert_to_field_token(token)
      table.insert(field_tokens, field_token)
    end
  end
  if #field_tokens > 0 then
    local field = Field:new(field_name, field_tokens)
    field:evaluate(self.string_dict)
    table.insert(fields, field)
  end
  -- if block.block_type ~= "bad_block" then
  local entry = Entry:new(block.type, block.key, fields, self)
  table.insert(self.entries, entry)
  self.entry_dict[entry.key] = entry
  table.insert(self.blocks, entry)
end


local function parse(content_str, string_dict)
  local comments = {}
  for w in content_str:gmatch("@Comment{.*}\n") do
    local comment = Comment:new(w)
    table.insert(comments, comment)
  end
  local library = Library:new(string_dict)
  library:load(content_str, string_dict)
  library.comments = comments
  return library
end


-- local function tostring(library)
-- end


return {
  Library = Library,
  Comment = Comment,
  Preamble = Preamble,
  String = String,
  Entry = Entry,
  Exception = Exception,
  Field = Field,
  FieldToken = FieldToken,
  NumberToken = NumberToken,
  MacroToken = MacroToken,
  Braced = Braced,
  Quoted = Quoted,
  parse = parse,
}
