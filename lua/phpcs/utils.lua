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

function split(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, all_trim(match))
    end
    return result;
end

function file_exists(filename)
    local stat = vim.loop.fs_stat(vim.loop.cwd() .. '/' ..filename)
    return stat and stat.type == 'file'
end

function all_trim(s)
   return s:match( "^%s*(.-)%s*$" )
end

return {
	backticks_table = backticks_table,
	split = split,
    file_exists = file_exists
}
