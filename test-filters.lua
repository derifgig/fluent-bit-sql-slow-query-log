--
require("filters")
--
function table_print(tbl, indent)
	if not indent then
		indent = 0
	end
	local toprint = string.rep(" ", indent) .. "{\r\n"
	indent = indent + 2
	for k, v in pairs(tbl) do
		toprint = toprint .. string.rep(" ", indent)
		if type(k) == "number" then
			toprint = toprint .. "[" .. k .. "] = "
		elseif type(k) == "string" then
			toprint = toprint .. k .. "= "
		end
		if type(v) == "number" then
			toprint = toprint .. v .. ",\r\n"
		elseif type(v) == "string" then
			toprint = toprint .. '"' .. v .. '",\r\n'
		elseif type(v) == "table" then
			toprint = toprint .. table_print(v, indent + 2) .. ",\r\n"
		else
			toprint = toprint .. '"' .. tostring(v) .. '",\r\n'
		end
	end
	toprint = toprint .. string.rep(" ", indent - 2) .. "}"
	return toprint
end
--
local s
local tests = {}

s = [[# Time: 241130 16:59:06
# User@Host: root[root] @ localhost []
# # Tread_id: 35577  Schema:   QC_hit: No
# Query_time: 3.000412  Lock_time: 0.000000  Rows_sent: 1  Rows_examined: 0
# Rows_affected: 0  Bytes_sent: 65
SET timestamp=1732978746;
select sleep(3);]]

table.insert(tests, s)

s = [[# Time: 241201  3:16:31
# User@Host: zabbix[zabbix] @ localhost []
# Thread_id: 51148  Schema: zabbix  QC_hit: No
# Query_time: 18.415585  Lock_time: 0.000033  Rows_sent: 5233088  Rows_examined: 5233088
# Rows_affected: 0  Bytes_sent: 180244019
# Full_scan: Yes  Full_join: No  Tmp_table: No  Tmp_table_on_disk: No
# Filesort: No  Filesort_on_disk: No  Merge_passes: 0  Priority_queue: No
SET timestamp=1733015791;
SELECT /*!40001 SQL_NO_CACHE */ `itemid`, `clock`, `num`, `value_min`, `value_avg`, `value_max` FROM `trends_uint`;]]

table.insert(tests, s)

s = [[# Time: 241201  3:20:02
# User@Host: cloud[cloud] @ localhost []
# Thread_id: 51222  Schema: cloud  QC_hit: No
# Query_time: 0.656467  Lock_time: 0.000139  Rows_sent: 0  Rows_examined: 35202
# Rows_affected: 0  Bytes_sent: 75
use cloud;
SET timestamp=1733016002;
SELECT `a`.`name` FROM `oc_filecache` `a` LEFT JOIN `oc_filecache` `b` ON `a`.`name` = `b`.`fileid` WHERE (`a`.`storage` = '1') AND (`b`.`fileid` IS NULL) AND (`a`.`path` LIKE 'appdata\\_ocq08ldz19hv/preview/_/_/_/_/_/_/_/%') AND (`a`.`mimetype` = '2');]]

table.insert(tests, s)
--
local record = {}
local new_record
for k, v in pairs(tests) do
	record["log"] = v
	_, _, new_record = parse_mysql_slow_log(tag, timestamp, record)
	print(table_print(new_record))
end
