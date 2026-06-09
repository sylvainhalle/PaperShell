-- Theme manager for PaperShell 3
-- (C) 2026  Sylvain Hallé

-- Default settings
local theme_repo = "https://sylvainhalle.github.io/PaperShell/themes/"
local outdir     = "../Source"
local localdir   = "~/.local/share/papershell"

-- Dependencies
local http = require("socket.http")
local utf8 = require("utf8")
local lfs = require("lfs")
local zip = require("zip")

-- Dynamic settings
local pwd = os.getenv("PWD") or io.popen("cd"):read()

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

function inlist(e, table)
  local basename = e:match("([^/]*)$") or e
  for _, x in ipairs(table) do
    if basename == x then return true end
  end
  return false
end

-- This function copies a folder and its contents from one directory to another, overwriting existing files.
-- @param source: The source directory path.
-- @param destination: The destination directory path.
-- @return: Returns true if the folder and its contents are successfully copied, false otherwise.
-- @see https://codepal.ai/code-generator/query/IAANWQA2/lua-function-copy-folder-contents
function copyFolder(source, destination, ignore)
  toignore = ignore or { }
  -- Check if the source directory exists
  local sourceExists = lfs.attributes(source, "mode") == "directory"
  if not sourceExists then
    return false, "Source directory does not exist."
  end
  if (inlist(source, toignore)) then
    return true
  end
  
  -- Check if the destination directory exists, create it if it doesn't
  local destinationExists = lfs.attributes(destination, "mode") == "directory"
  if not destinationExists then
    local success, err = lfs.mkdir(destination)
    if not success then
      return false, "Failed to create destination directory: " .. err
    end
  end

  -- Iterate over the files and subdirectories in the source directory
  for file in lfs.dir(source) do
    if file ~= "." and file ~= ".." then
        local sourcePath = source .. "/" .. file
        local destinationPath = destination .. "/" .. file
        local attributes = lfs.attributes(sourcePath)
        if attributes.mode == "directory" then
            -- Recursively copy subdirectories
            local success, err = copyFolder(sourcePath, destinationPath, toignore)
            if not success then
                return false, "Failed to copy subdirectory: " .. err
            end
        else
            -- Copy files
            local success, err = os.rename(sourcePath, destinationPath)
            if not success then
                return false, "Failed to copy file: " .. err
            end
        end
    end
  end
  return true
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

function instantiate(folder)
  local success, err = copyFolder(pwd .. "/..", folder, {"docs", ".git"})
  if success then
    print("Folder and its contents copied successfully.")
  else
    io.stderr:write("Failed to copy folder and its contents:", err)
    print(localdir)
  end
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

function printusage(stream)
  stream:write("Usage: psmod [-h] [action]\n\n")
  stream:write("Possible actions:\n")
  stream:write("  init <folder>        Creates an empty project in folder\n")
  stream:write("  list                 Lists available themes\n")
  stream:write("  install <theme>      Downloads and installs theme\n")
  stream:write("  uninstall <theme>    Uninstalls theme\n")
end

print("PaperShell theme manager v3.0")
print("(C) 2026 Sylvain Hallé\n")
local offset = 0
local fromdir = pwd
if not arg[1] then
  io.stderr:write("ERROR: an action must be specified\n")
  printusage(io.stderr)
  os.exit(1)
end
if arg[1] == "--from" then
  -- Launched from the symbolic link
  fromdir = arg[2]
  offset = 2
end
if not arg[offset + 1] then
  io.stderr:write("ERROR: an action must be specified\n")
  printusage(io.stderr)
  os.exit(1)
end
if (arg[offset + 1] == "-h" or arg[offset + 1] == "--help") then
  printusage(io.stdout)
  os.exit(0)
end
local action = arg[offset + 1]
if action == "install" then
  if not arg[offset + 2] then
    io.stderr:write("ERROR: a theme must be specified\n")
    os.exit(2)
  end
  local url = theme_repo .. arg[offset + 2] .. ".tpl.zip"
  print(url)
  lfs.mkdir(outdir .. "/sty/" .. arg[offset + 2])
  lfs.mkdir(outdir .. "/tpl/" .. arg[offset + 2])
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
elseif action == "init" then
  if not arg[offset + 2] then
    io.stderr:write("ERROR: a folder name must be specified\n")
    os.exit(2)
  end
  print("Creating empty project in " .. fromdir .. "/" .. arg[offset + 2] .. "\n")
  instantiate(fromdir .. "/" .. arg[offset + 2])
else
  io.stderr:write("ERROR: unknown action " .. arg[offset + 1] .."\n")
  os.exit(2)
end
