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

--[[ A set of functions to handle files.
     @author Sylvain Hallé
  ]]

-- Dependencies
local http   = require "socket.http"

--[[ Downloads a file from an HTTP URL.
     @param url The URL
     @return The contents of the file, or null otherwise
  ]]
local function download(url)
  local response_body, status_code = http.request(url)
    if status_code == 200 then
      return response_body
    end
  return null
end

return {
	download = download
}