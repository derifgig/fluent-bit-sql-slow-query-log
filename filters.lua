--
-- Parser mysql/mariadb sql sloq query log for fluent-bit
--  + Source records should be combined by multiline
--
--
-- HELPFULL FUNCTIONS
--
function string:split(delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(self, delimiter, from)
	while delim_from do
		table.insert(result, string.sub(self, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = string.find(self, delimiter, from)
	end
	table.insert(result, string.sub(self, from))
	return result
end
--
-- Source data examples:
--   # User@Host: root
--   # Thread_id: 35577
function parse_by_regex(line, regex)
	--print("DEBUG parse_by_regex: source: " .. line .. " RegEx: " .. regex)
	local key, value = line:match(regex)
	if key ~= nil and value ~= nil then
		-- replace specific characters by underscore: @
		key = key:gsub("@", "_")
		key = key:lower()
		-- print("DEBUG parse_by_regex:  " .. key .. " => " .. value)
		return { key = key, value = value }
	end
	-- print("DEBUG parse_by_regex: Error: some value is NIL")
	return nil
end
--
-- MAIN FUNCTION
--
function parse_mysql_slow_log(tag, timestamp, record)
	local new_record = {}
	local new_item
	local source
	local regex
	-- checking source data
	if record["log"] ~= nil then
		source = record["log"]
	else
		record["lua-error"] = 'parse_mysql_slow_log: there is no field "log" in record'
		return 2, timestamp, record
	end
	--
	local source_lines = source:split("\n")
	--
	for line_id, line in pairs(source_lines) do
		new_item = nil
		if line:sub(1, 1) == "#" then
			-- Individual patterns
			-- case: # Time: 241130 16:59:06
			-- case: # User@Host: root[root] @ localhost []
			if line:find("# Time:") or line:find("# User@Host:") then
				regex = "[%a@_]+: .+$"
				regex_one = "([%a@_]+): (.+)"
			-- General common case
			else
				regex = "[%a@_]+: [%a%d%.]+"
				regex_one = "([%a@_]+): ([%a%d%.]+)"
			end
		-- for values SET timestamp=1733016002;
		elseif line:sub(1, 3) == "SET" then
			regex = "%a+=[%d%s%.]+;"
			regex_one = "([%a@_]+)=([%a%d%.]+);"
		else
			-- not parsed lines, possible sql query
			::continue::
		end
		--
		for value_pairs in line:gmatch(regex) do
			new_item = parse_by_regex(value_pairs, regex_one)
			if new_item ~= nil then
				new_record[new_item.key] = new_item.value
				-- Set nil value for parsed item, to skip it in next steps
				source_lines[line_id] = nil
			end
		end
	end
	-- Collect not parsed lines to other table for combine SQL query
	local query_lines = {}
	for line_id, line in pairs(source_lines) do
		if line ~= nil then
			table.insert(query_lines, line)
		end
	end
	--
	new_record["query"] = table.concat(query_lines, "\n")
	-- fluent-bit requirement
	-- 2 - replace existing record with this update
	return 2, timestamp, new_record
end
--
