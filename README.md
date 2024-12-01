# fluent-bit-sql-slow-query-log

Fluent-bit parser for mysql/mariadb sql slow query log

Worked on:

- fluent-bit 3.2
- lua 5.4
- mariadb 10.11.6

## Multiline filters

```yaml
multiline_parsers:
  - name: "multiline-slow-query-log"
    type: "regex"
    flush_timeout: "1000"
    rules:
      - state: start_state
        regex: "/# Time.*$/"
        next_state: cont
      - state: cont
        regex: "/^.*$/"
        next_state: cont
```

## pipeline created by ansible

```yaml
inputs:
  - name: tail
    tag: sql_slow_query
    path: "/var/log/mysql/mariadb-slow.log"
    db: sql_slow_query.db
    refresh_interval: 10
    rotate_wait: 10
    mem_buf_limit: 1MB
    processors:
      logs:
        - name: multiline
          multiline.key_content: log
          multiline.parser: multiline-slow-query-log
        - name: lua
          script: filters.lua
          call: parse_mysql_slow_log
        - name: modify
          add: hostname "{{inventory_hostname}}"
outputs:
  - name: your-destination
```

## Result

```json
{
  "_timestamp": 1733045809600000,
  "bytes_sent": "65",
  "hostname": "srv-db.my.net",
  "lock_time": "0.000000",
  "qc_hit": "No",
  "query": "select sleep(3);",
  "query_time": "3.000281",
  "rows_affected": "0",
  "rows_examined": "0",
  "rows_sent": "1",
  "thread_id": "58697",
  "time": "241201 11:36:49",
  "timestamp": "1733045809",
  "user_host": "root[root] @ localhost []"
}
```

## Local test

```bash
lua test-filters.lua
```
