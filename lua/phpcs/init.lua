local M = {};

local phpcs_path = "/home/praem90/.config/composer/vendor/bin/phpcs"
local phpcbf_path =	"/home/praem90/.config/composer/vendor/bin/phpcbf"
local phpcs_standard = "PSR2"

local finders = require('telescope.finders')
local make_entry = require('telescope.make_entry')
local pickers = require('telescope.pickers')
local conf = require('telescope.config').values


function backticks_table(cmd)
	local tab = {}
	local pipe = assert(io.popen(cmd),
		"backticks_table(" .. cmd .. ") failed.")
	local line = pipe:read("*line")
	while line do
		table.insert(tab, line)
		line = pipe:read("*line")
	end
	return tab
end


M.cs = function ()
	local cmd = {
		phpcs_path,
		"--report=emacs",
		"--standard=" .. phpcs_standard,
		vim.fn.expand('%')
	}

    showPicker(cmd)
end


M.cbf = function ()
	local phpcs = {
		phpcbf_path,
		"--standard=" .. phpcs_standard,
		vim.fn.expand('%')
	}
	local output = backticks_table(table.concat(phpcs, " "))
	vim.cmd('e')
end

function showPicker(find_command, opts)
    opts = opts or {};
    opts.entry_maker = gen_from_output(opts)
      opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
    pickers.new(opts, {
        prompt_title = 'PHPCS',
        finder = finders.new_oneshot_job(
          find_command,
          opts
        ),
        previewer = conf.grep_previewer(opts),
        sorter = conf.file_sorter(opts),
    }):find()
end

function gen_from_output(_)
  return function(line)
    local cursor_position = split(line, ':')

    return {
      value = line,
      ordinal = line,
      display = line,
      lnum = cursor_position[2],
      col = cursor_position[3],
      start = cursor_position[2],
	  filename = vim.api.nvim_buf_get_name(cursor_position[1])
    }
  end
end

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

return M
