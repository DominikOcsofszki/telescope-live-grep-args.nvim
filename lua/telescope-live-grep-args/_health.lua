
local health = vim.health or require "health"
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

local extension_info = require("telescope").extensions
local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1

local check_binary_installed = function(package)
  local binaries = package.binaries or { package.name }
  for _, binary in ipairs(binaries) do
    local found = vim.fn.executable(binary) == 1
    if not found and is_win then
      binary = binary .. ".exe"
      found = vim.fn.executable(binary) == 1
    end
    if found then
      local handle = io.popen(binary .. " --version")
      local binary_version = handle:read "*a"
      handle:close()
      return true, binary_version
    end
  end
end

local function lualib_installed(lib_name)
  local res, _ = pcall(require, lib_name)
  return res
end

local optional_dependencies = {
  {
    finder_name = "live-grep",
    package = {
      {
        name = "rg",
        url = "[BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)",
        optional = false,
      },
    },
  },
}

local required_plugins = {
  -- { lib = "plenary", optional = true },
}

local check_required = function ()
  if not next(required_plugins) == nil then
    start "[required] live_grep_args"
  end

  for _, plugin in ipairs(required_plugins) do
    if lualib_installed(plugin.lib) then
      ok(plugin.lib .. " installed.")
    else
      local lib_not_installed = plugin.lib .. " not found."
      if plugin.optional then
        warn(("%s %s"):format(lib_not_installed, plugin.info))
      else
        error(lib_not_installed)
      end
    end
  end

end

local check_dependencies = function ()
  if not next(optional_dependencies) == nil then
    start "[required:external] live_grep_args"
  end

    for _, opt_dep in pairs(optional_dependencies) do
    for _, package in ipairs(opt_dep.package) do
      local installed, version = check_binary_installed(package)
      if not installed then
        local err_msg = ("%s: not found."):format(package.name)
        if package.optional then
          warn(("%s %s"):format(err_msg, ("Install %s for extended capabilities"):format(package.url)))
        else
          error(
            ("%s %s"):format(
              err_msg,
              ("`%s` finder will not function without %s installed."):format(opt_dep.finder_name, package.url)
            )
          )
        end
      else
        local eol = version:find "\n"
        local ver = eol and version:sub(0, eol - 1) or "(unknown version)"
        ok(("%s: found %s"):format(package.name, ver))
      end
    end
  end

end
local M = {}

M.check = function()
  check_required()
  check_dependencies()


end

return M
