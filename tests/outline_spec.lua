local Path = require('plenary.path')
require('plenary.test_harness'):setup_busted()

local assert = require('luassert')

--Utility section -- move this into tests/utils.lua eventually
local function load_in_buffer(script_name)
  local path = Path:new(".", "resources", script_name)
  vim.cmd("silent read " .. tostring(path))
end

-- </ Utility section >

describe('our testing framework', function()
  it('can load test script', function()
    load_in_buffer("easy.py")
    vim.cmd(":%bdelete!")
  end)
end)

describe('outline functions', function()
  it('can build outline', function()
    local buf = vim.api.nvim_win_get_buf(0)
    load_in_buffer("easy.py")
    vim.cmd(":call SideKick()")
  end)
end)


