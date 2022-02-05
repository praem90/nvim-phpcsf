local M = {}
local loop = vim.loop
local lutils = require('phpcs.utils')

M.exec = function (opts)
  local stdin = loop.new_pipe(true) -- create file descriptor for stdout
  local stdout = loop.new_pipe(false) -- create file descriptor for stdout
  local stderr = loop.new_pipe(false) -- create file descriptor for stdout
  local results = {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local function onread(err, data)
    if err then
      print('ERROR: '.. err)
    end
    if data then
      local vals = vim.split(data, "\n")
      for _, d in pairs(vals) do
        table.insert(results, d )
        ::continue::
      end
    end
  end

  handle = loop.spawn(
  	  opts.cmd,
  	  {
      	  args = opts.args,
      	  stdio = {stdin,stdout,stderr},
      	  cwd = vim.fn.getcwd()
  	  },

  	  vim.schedule_wrap(function(code, signal)
      	  stdout:read_stop()
      	  stderr:read_stop()
	  	  lutils.close_handle(stdout);
	  	  lutils.close_handle(stderr);
	  	  lutils.close_handle(handle);

    	  if opts.callback then opts.callback(results, bufnr) end
  	  end)
  )

  loop.read_start(stdout, onread) -- TODO implement onread handler
  loop.read_start(stderr, vim.schedule_wrap(M.read_stderr))

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

  local line_count = #lines
  for i, line in ipairs(lines) do
    stdin:write(line)

    if i == line_count then
      stdin:write('', function ()
          stdin:close()
      end)
    else
        stdin:write('\n')
    end
  end

end

M.get_last_stderr = function ()
    return M.last_stderr
end

M.get_last_stdout = function ()
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

return M
