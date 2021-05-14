local actions = require('telescope.actions')
local action_set = require('telescope.actions.set')
local action_state = require('telescope.actions.state')

local finders = require('telescope.finders')
local pickers = require('telescope.pickers')

local putils = require('telescope.previewers.utils')
local Previewer = require('telescope.previewers.previewer')

local conf = require('telescope.config').values

local lutils = require('utils');


function attach_mappings(prompt_bufnr)
    -- This will replace select no mather on which key it is mapped by default
    action_set.select:replace(function(prompt_bufnr, type)
      local entry = action_state.get_selected_entry()
      actions.close(prompt_bufnr)
      --print(vim.inspect(entry))
      -- Code here
        vim.api.nvim_win_set_cursor(0, {
        	tonumber(entry.lnum),
        	tonumber(entry.col),
        })
    end)

	return true
end

function run_cmd(find_command, opts)
    opts = opts or {}
    opts.buffname = vim.api.nvim_win_get_buf(0)
    pickers.new(opts, {
        prompt_title = 'PHPCS',
        finder = finders.new_table {
            results = lutils.backticks_table(table.concat(find_command, " ")),
            entry_maker = gen_from_output
        },
        on_complete = {
        	function(picker)
        		print(picker.get_selection().value)
        		print('Test call back')
        	end
    	},
        previewer = Previewer:new {
        	preview_fn = preview_function(opts),
        	sorter = conf.generic_sorter(opts),
        },
    	attach_mappings = attach_mappings
    }):find()
end

function preview_function(opts)
    return function(_, entry, status)
        local pr_win = status.preview_win;
        local bufnr = vim.api.nvim_win_get_buf(pr_win)
        local entry_info = gen_from_output(entry.value)

        entry_info.lnum = tonumber(entry_info.lnum)
        entry_info.col = tonumber(entry_info.col)

		local lines = vim.api.nvim_buf_get_lines(opts.buffname, 0, -1, false)

        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_win_set_cursor(pr_win, {entry_info.lnum, 0})
		putils.highlighter(bufnr, 'c')
        vim.api.nvim_buf_add_highlight(bufnr, 0, 'Visual', entry_info.lnum, 0, -1)
    end
end

function gen_from_output(line)
    local cursor_position = lutils.split(line, ':')

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

return {
	show: run_cmd
}
