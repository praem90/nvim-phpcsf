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
M.last_stderr = ''
M.last_stdout = ''

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
  local stdin = loop.new_pipe(true) -- create file descriptor for stdout
  local stdout = loop.new_pipe(false) -- create file descriptor for stdout
  local stderr = loop.new_pipe(false) -- create file descriptor for stdout
  local results = {}
  local bufnr = vim.api.nvim_get_current_buf()

  local function onread(err, data)
      M.read_stdout(err, data)
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

  M.reset_output_str();
  local args = {
    "--stdin-path=" .. vim.api.nvim_buf_get_name(bufnr),
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
	lutils.close_handle(stdout);
	lutils.close_handle(stderr);
	lutils.close_handle(handle);
    M.publish_diagnostic(results, bufnr)
  end
  ))
  loop.read_start(stdout, onread) -- TODO implement onread handler
  loop.read_start(stderr, vim.schedule_wrap(M.read_stderr))

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

  local line_count = #lines
  for i, line in ipairs(lines) do
    stdin:write(line)

    if i == line_count then
      stdin:write('\n', function ()
          stdin:close()
      end)
    else
        stdin:write('\n')
    end
  end

end

M.publish_diagnostic = function (results, bufnr)
	local method = 'textDocument/publishDiagnostics';

	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local diagnostics = {}

	local errorCodes = {
		['error'] = vim.lsp.protocol.DiagnosticSeverity.Error,
		warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
	}

	for _, line in ipairs(results) do
		if not line then goto continue end

		local item = parse_cs_line(line)

		if not item or item.lnum or item.col or errorCodes[item.code] then
            goto continue
		end

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

		::continue::
	end

	local result = {
		uri = vim.uri_from_bufnr(bufnr),
		diagnostics = diagnostics
	}

	vim.lsp.handlers[method](nil, method, result, 1000, bufnr)
end

function parse_cs_line(line)
    local cursor_position = lutils.split(line, ':')
	local code_msg = {}

	table.insert(code_msg, 'warning')

    if not lutils.is_empty(cursor_position[4]) then
    	code_msg = vim.split(cursor_position[4], '-')
	end

	local code = vim.trim(code_msg[1]);

	table.remove(code_msg, 1)

    return {
      lnum = cursor_position[2],
      col = cursor_position[3],
      start = cursor_position[2],
	  code = code,
	  message = lutils.implode('-', code_msg)
    }
end

M.cbf = function ()
	if vim.g.disable_cbf then
		return
	end

    local stdout = loop.new_pipe(false) -- create file descriptor for stdout
    local stderr = loop.new_pipe(false) -- create file descriptor for stdout

    M.reset_output_str();

	local args = {
        "--standard=" .. M.phpcs_standard,
        vim.fn.expand('%')
    }

    handle = loop.spawn(M.phpcbf_path, {
      args = args,
      stdio = {nil, stdout, stderr},
      cwd = vim.fn.getcwd()
    },
    vim.schedule_wrap(function()
      if not handle:is_closing() then handle:close() end
      vim.api.nvim_command(":edit")
    end))

    loop.read_start(stdout, vim.schedule_wrap(M.read_stdout))
    loop.read_start(stderr, vim.schedule_wrap(M.read_stderr))
end

M.get_last_stderr = function ()
    print(M.last_stderr);

    return M.last_stderr
end

M.get_last_stdout = function ()
    print(M.last_stdout);

    return M.last_stdout
end

M.read_stdout = function (err, data)
	if err then
  	  print('ERROR: '.. err)
	end
	if data then
    	M.last_stdout = M.last_stdout .. data
	end
end

M.read_stderr = function (err, data)
	if err then
  	  print('ERROR: '.. err)
	end
	if data then
    	M.last_stderr = M.last_stderr .. data
	end
end

M.reset_output_str = function ()
	M.last_stderr = ''
	M.last_stdout = ''
end


M.detect_local_paths()

return M
