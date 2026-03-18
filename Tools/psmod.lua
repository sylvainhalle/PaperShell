local theme_repo = "https://sylvainhalle.github.io/PaperShell/themes/"
local outdir = "../Source"
local http = require("socket.http")
local utf8 = require("utf8")
local lfs = require("lfs")
local zip = require("zip")

function download_and_unzip(url, out_dir)

    -- Download the file
    local response_body, status_code = http.request(url)
    if status_code == 200 then
        local file_path = out_dir .. "/downloaded_file.zip"
        local file = io.open(file_path, "wb")
        file:write(response_body)
        file:close()

        -- Unzip the file (will need a zip library)
        local archive = zip.open(file_path)
        if archive then
            for file in archive:files() do
              local filename = file.filename
              print(filename)
              if filename:sub(-1, -1) ~= "/" then
                -- File
                local in_f = archive:open(filename)
                local content = in_f:read("*a")
                in_f:close()
                local to_write = io.open(out_dir .. "/" .. filename, "w")
                to_write:write(content)
                to_write:close()
              end
            end
            archive:close()
        else
            print("Failed to unzip the file.")
        end
    else
        print("Download failed with status: " .. status_code)
    end
end

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

function printpad(str, length, pad_char)
    pad_char = pad_char or " "
    local len = utf8.len(str)
    if len > length then
        -- Truncate if longer
        return utf8sub(str, 1, length)
    elseif len < length then
        -- Pad if shorter
        return str .. string.rep(pad_char, length - len)
    else
        -- Return as-is if exactly the right length
        return str
    end
end

print("PaperShell theme manager v3.0")
print("(C) 2026 Sylvain Hallé\n")
if not arg[1] then
  io.stderr:write("ERROR: an action must be specified\n")
  io.stderr:write("Usage: texlua psmod.lua [-h] [[un]install <theme>] [list]")
  os.exit(1)
end
if (arg[1] == "-h" or arg[1] == "--help") then
  print("Usage: texlua psmod.lua [-h] [[un]install <theme>] [list]")
  os.exit(0)
end
local action = arg[1]
if action == "install" then
  if not arg[2] then
    io.stderr:write("ERROR: a theme must be specified\n")
    os.exit(2)
  end
  local url = theme_repo .. arg[2] .. ".zip"
  print(url)
  lfs.mkdir(outdir .. "/sty/" .. arg[2])
  lfs.mkdir(outdir .. "/tpl/" .. arg[2])
  download_and_unzip(url, outdir)
  os.exit(0)
elseif action == "list" then
  print("Themes currently installed:\n")
  for file in lfs.dir(outdir .. "/tpl") do
    local filename = outdir .. "/tpl/" .. file
    local att, err = lfs.attributes(filename)
    if (att and att.mode == "directory" and file ~= "." and file ~= "..") then
      local props = dofile(filename .. "/manifest.lua")
      print("- " .. printpad(props.id, 10) .. printpad(props.version, 6) .. printpad(props.innerversion, 6) .. printpad(props.name, 44))
    end
  end
  os.exit(0)
else
  io.stderr:write("ERROR: unknown action " .. arg[1] .."\n")
  os.exit(2)
end
