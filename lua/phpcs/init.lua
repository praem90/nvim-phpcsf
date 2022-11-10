local M = {};

local loop = vim.loop
local root = vim.loop.cwd()
local phpcs_path = "/home/praem90/.config/composer/vendor/bin/phpcs"
local phpcbf_path =	"/home/praem90/.config/composer/vendor/bin/phpcbf"
local phpcs_standard = "PSR2"

local Job = require'plenary.job'
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

M.cs = function ()
	local bufnr = vim.api.nvim_get_current_buf()

	local opts = {
		command = M.phpcs_path,
  		args = {
    		"--stdin-path=" .. vim.api.nvim_buf_get_name(bufnr),
			"--report=emacs",
			"--standard=" .. M.phpcs_standard,
    		"-"
  		},
      	writer = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true),
  		on_exit = vim.schedule_wrap(function(j)
  			M.publish_diagnostic(j:result(), bufnr)
  		end),
  	}

  	Job:new(opts):start()
end

--[[
--  new_opts = {
        bufnr = 0, -- Buffer no. defaults to current
        force = false, -- Ignore file size
        timeout = 1000, -- Timeout in ms for the job. Default 1000ms
    }
]]
M.cbf = function (new_opts)
	new_opts = new_opts or {}
  	new_opts.bufnr = new_opts.bufnr or vim.api.nvim_get_current_buf()

  	if not new_opts.force then
  		if vim.api.nvim_buf_line_count(new_opts.bufnr) > 1000 then
  			print("File too large. Ignoring code beautifier" )
  			return
  		end
  	end

	local opts = {
		command = M.phpcbf_path,
  		args = {
    		"--stdin-path=" .. vim.api.nvim_buf_get_name(new_opts.bufnr),
			"--standard=" .. M.phpcs_standard,
    		"-"
  		},
      	writer = vim.api.nvim_buf_get_lines(new_opts.bufnr, 0, -1, true),
      	cwd = vim.fn.getcwd(),
  	}

  	local results, status = Job:new(opts):sync(new_opts.timeout or 1000)

  	status = tonumber(status)

  	if status <= 1 then
  		vim.api.nvim_buf_set_lines(new_opts.bufnr, 0, -1, true, results)
    	M.cs()
    else
    	error("Failed to run code beautifier")
	end
end

M.publish_diagnostic = function (results, bufnr)
	local method = 'textDocument/publishDiagnostics';

	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local diagnostics = {}

	local error_codes = {
		['error'] = vim.lsp.protocol.DiagnosticSeverity.Error,
		warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
	}

	for _, line in ipairs(results) do
		if not line then goto continue end

		local item = parse_cs_line(line)

		if not item then
            goto continue
		end
		if not  item.lnum   then
            goto continue
		end
		if not  item.col   then
            goto continue
		end
		if not  error_codes[item.code]   then
            goto continue
		end

        table.insert(diagnostics, {
            code = assert(error_codes[item.code], "Invalid Code"),
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

    vim.lsp.handlers[method](nil, result, {method = method, client_id= 1000, bufnr= bufnr})
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

M.detect_local_paths()

return M
