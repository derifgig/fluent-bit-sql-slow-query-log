# fluent-bit-sql-slow-query-log

Fluent-bit parser for mysql/mariadb sql slow query log

Worked on:

- fluent-bit 3.2
- lua 5.4
- mariadb 10.11.6

## MySQL/Mariadb config

```
slow_query_log = 1
log_slow_query_file = /var/log/mysql/mariadb-slow.log
log_slow_query_time = 0.5
log_slow_verbosity = query_plan
log-queries-not-using-indexes = 0
```

## Fluent-bit Multiline parsers

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

## Fluent-bit pipeline created by ansible

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
  rows_sent= "1",
  query_time= "3.000412",
  user_host= "root[root] @ localhost []",
  time= "241130 16:59:06",
  query= "select sleep(3);",
  rows_examined= "0",
  tread_id= "35577",
  timestamp= "1732978746",
  bytes_sent= "65",
  rows_affected= "0",
  qc_hit= "No",
  lock_time= "0.000000",
}
```

### Timestamp value

This pattern with be transfered to the field `timestamp`, and remove from SQL query;

```sql
SET timestamp=1732978746;
```

## Local test

```bash
lua test-filters.lua
```
