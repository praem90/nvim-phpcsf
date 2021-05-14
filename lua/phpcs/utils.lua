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
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

return {
	backticks_table = backticks_table,
	split = split
}
