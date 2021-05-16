local M = {};

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

M.cs = function ()
	local cmd = {
		M.phpcs_path,
		"--report=emacs",
		"--standard=" .. M.phpcs_standard,
		vim.fn.expand('%')
	}

    Picker.show(cmd)
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
