--[[ https://martin-fieber.de/blog/how-to-test-your-lua/ ]]

local Runner = {
  hasErrors = false
}

function Runner:test(fn)
  local status, err = pcall(fn)
  if not status then
    self.hasErrors = true
    print(err)
  end
end

function Runner:evaluate()
  if self.hasErrors then
    print("Test suite exited with errors")
    os.exit(1)
  else
    print("All tests successful")
  end
end

return Runner