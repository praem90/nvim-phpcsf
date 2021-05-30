local M = {};

local loop = vim.loop
local root = vim.loop.cwd()
local phpcs_path = "/home/praem90/.config/composer/vendor/bin/phpcs"
local phpcbf_path =	"/home/praem90/.config/composer/vendor/bin/phpcbf"
local phpcs_standard = "PSR2"

local Picker = require('phpcs.picker')
local lutils = require('phpcs.utils')

-- Config Variables
M.phpcs_path = vim.g.nvim_phpcs_config_phpcs_path or phpcs_path
M.phpcbf_path = vim.g.nvim_phpcs_config_phpcbf_paths or phpcbf_path
M.phpcs_standard = vim.g.nvim_phpcs_config_phpcs_standard or phpcs_standard

M.detect_local_paths = function ()
    if (lutils.file_exists('phpcs.xml')) then
        M.phpcs_standard = root .. '/phpcs.xml'
    end

    if (lutils.file_exists('vendor/bin/phpcs')) then
        M.phpcs_path = root .. '/vendor/bin/phpcs'
    end

    if (lutils.file_exists('vendor/bin/phpcbf')) then
        M.phpcbf_path = root .. '/vendor/bin/phpcbf'
    end
end

M.cs = function (opts)
  opts = opts or {}
  local stdin = loop.new_pipe(false) -- create file descriptor for stdout
  local stdout = loop.new_pipe(false) -- create file descriptor for stdout
  local stderr = loop.new_pipe(false) -- create file descriptor for stdout
  local results = {}

  local function onread(err, data)
    if err then
      print('ERROR: '.. err)
    end
    if data then
      local vals = vim.split(data, "\n")
      for _, d in pairs(vals) do
        if d == "" then goto continue end
        table.insert(results, d)
        ::continue::
      end
    end
  end

  local args = {
	"--report=emacs",
	"--standard=" .. M.phpcs_standard,
    "-"
  }

  handle = loop.spawn(M.phpcs_path, {
    args = args,
    stdio = {stdin,stdout,stderr},
    cwd = vim.fn.getcwd()
  },
  vim.schedule_wrap(function()
    stdout:read_stop()
    stderr:read_stop()
    stdout:close()
    stderr:close()
    handle:close()
    M.publish_diagnostic(results)
  end
  ))
  loop.read_start(stdout, onread) -- TODO implement onread handler
  loop.read_start(stderr, onread)

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  for _, line in ipairs(lines) do
    stdin:write(line .. '\n')
  end

  stdin:close()
end

M.publish_diagnostic = function (results, bufnr)
	local method = 'textDocument/publishDiagnostics';

	local bufnr = bufnr or vim.api.nvim_get_current_buf()

	local diagnostics = {}

	local errorCodes = {
		error = vim.lsp.protocol.DiagnosticSeverity.Error,
		warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
	}

	for _, line in ipairs(results) do
		local item = parse_cs_line(line)

		table.insert(diagnostics, {
			code = assert(errorCodes[item.code], "Invalid Code"),
			range = {
				['start'] = {
					line = tonumber(item.lnum) - 1,
					character = tonumber(item.col) - 1
				},
				['end'] = {
					line = tonumber(item.lnum) - 1,
					character = tonumber(item.col)
				},
			},
			message = item.message
		})
	end

	local result = {
		uri = vim.uri_from_bufnr(bufnr),
		diagnostics = diagnostics
	}

	vim.lsp.handlers[method](nil, method, result, 1000, bufnr)
end

function parse_cs_line(line)
    local cursor_position = lutils.split(line, ':')

    local code_msg = lutils.split(cursor_position[4], '-')

    return {
      lnum = cursor_position[2],
      col = cursor_position[3],
      start = cursor_position[2],
	  code = code_msg[1],
	  message = code_msg[2]
    }
end

M.cbf = function ()
	if vim.g.disable_cbf then
		return
	end

	local cmd = {
		M.phpcbf_path,
		"--standard=" .. M.phpcs_standard,
		vim.fn.expand('%')
	}

	lutils.backticks_table(table.concat(cmd, " "))
	vim.cmd('e')
end


M.detect_local_paths()

return M
