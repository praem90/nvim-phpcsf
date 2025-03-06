local M = {};
local root = vim.loop.cwd()
local phpcs_path = "$HOME/.config/composer/vendor/bin/phpcs"
local phpcbf_path = "$HOME/.config/composer/vendor/bin/phpcbf"
local phpcs_standard = nil

local Job = require'plenary.job'
local lutils = require('phpcs.utils')

-- Config Variables
M.phpcs_path = vim.g.nvim_phpcs_config_phpcs_path or phpcs_path
M.phpcbf_path = vim.g.nvim_phpcs_config_phpcbf_path or phpcbf_path
M.phpcs_standard = vim.g.nvim_phpcs_config_phpcs_standard or phpcs_standard
M.last_stderr = ''
M.last_stdout = ''
M.nvim_namespace = nil
M.max_line_numbers = 1000

M.phpcs_job_count = 0;

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

    M.nvim_namespace = vim.api.nvim_create_namespace("phpcs")
end

M.cs = function ()
    if vim.fn.executable(M.phpcs_path) == 0 then
    	return
    end

    if M.phpcs_job_count >= 2 then
        return
    end

    M.phpcs_job_count = M.phpcs_job_count + 1

    if M.phpcs_job_count > 1 then
        return
    end

	local bufnr = vim.api.nvim_get_current_buf()

    local report_file = os.tmpname();

    local args = {
        "--stdin-path=" .. vim.api.nvim_buf_get_name(bufnr),
        "--report=json",
        "--report-file=" .. report_file,
    }
    if M.phpcs_standard then
        table.insert(args, "--standard=" .. M.phpcs_standard)
    end
    table.insert(args, "-")

    local opts = {
		command = M.phpcs_path,
  		args = args,
      	writer = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true),
  		on_exit = vim.schedule_wrap(function()
            local file = io.open(report_file, "r")
            if file ~= nil then
                local content = file:read("*a")
                M.publish_diagnostic(content, bufnr)
            end

            M.phpcs_job_count = M.phpcs_job_count - 1

            if M.phpcs_job_count > 0 then
                M.phpcs_job_count = 0
               M.cs()
           end
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
    if vim.fn.executable(M.phpcbf_path) == 0 then
    	return
    end

	new_opts = new_opts or {}
  	new_opts.bufnr = new_opts.bufnr or vim.api.nvim_get_current_buf()

  	if not new_opts.force then
  		if M.max_line_numbers and vim.api.nvim_buf_line_count(new_opts.bufnr) > M.max_line_numbers then
  			-- print("File too large. Ignoring code beautifier" )
  			return
  		end
  	end
    local args = {}
    if M.phpcs_standard then
        table.insert(args, "--standard=" .. M.phpcs_standard)

    end
    table.insert(args, vim.api.nvim_buf_get_name(new_opts.bufnr))

	local opts = {
		command = M.phpcbf_path,
  		args = args,
  		on_exit = vim.schedule_wrap(function(j)
            if j.code ~= 0 then
                vim.cmd("e")
            end
  		end),
      	cwd = vim.fn.getcwd(),
  	}

  	Job:new(opts):start()
end

M.publish_diagnostic = function (results, bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

    local diagnostics = parse_json(results, bufnr)

    vim.diagnostic.set(M.nvim_namespace, bufnr, diagnostics)
end

function parse_json(encoded, bufnr)
    local decoded = vim.json.decode(encoded)
    local diagnostics = {}
    local uri = vim.fn.bufname(bufnr);

    local error_codes = {
        ['error'] = vim.lsp.protocol.DiagnosticSeverity.Error,
        warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
    }

    if not decoded.files[uri] then
        return diagnostics
    end

    for _, message in ipairs(decoded.files[uri].messages) do
        table.insert(diagnostics, {
            severity = error_codes[string.lower(message.type)],
            lnum	 = tonumber(message.line) -1,
            col	 = tonumber(message.column) -1,
            message = message.message
        })
    end

    return diagnostics
end


M.detect_local_paths()

--- Setup and configure nvim-phpcsf
---
--- @param opts table|nil
---     - phpcs (string|nil):
---         PHPCS path
---     - phpcbf (string|nil):
---         PHPCBF path
---     - standard (string|nil):
---         PHPCS standard
M.setup = function (opts)
    if opts == nil then
        M.detect_local_paths()
        return
    end

    if opts.phpcs ~= nil then
        M.phpcs_path = opts.phpcs
    end

    if opts.phpcbf ~= nil then
        M.phpcbf_path = opts.phpcbf
    end

    if opts.standard ~= nil then
        M.phpcs_standard = opts.standard
    end

    if opts.max_line_numbers ~= nil then
        M.max_line_numbers = opts.max_line_numbers
    end
end

return M
