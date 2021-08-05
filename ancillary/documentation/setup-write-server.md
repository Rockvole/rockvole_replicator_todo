## Set-Up Write Server

### Add the server details to the database
```shell
./rockvole_helper.sh addserver write@rockvole.com WRITE
```
<div align="center">Command Line</div>
<hr/>

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  1 | 41004347aa0310209084 |      1 |      1 |                   0 |             0 |
+----+----------------------+--------+--------+---------------------+---------------+
1 row in set (0.000 sec)
```
<div align="center">MySql</div>
<hr/>

```roomsql
select * from user_store;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  1 | write@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
1 row in set (0.000 sec)
```
<div align="center">MySql</div>
<hr/>

```roomsql
select * from configuration;
+---------+--------+--------+-----------------------------+---------+--------------+--------------+
| id      | subset | warden | configuration_name          | ordinal | value_number | value_string |
+---------+--------+--------+-----------------------------+---------+--------------+--------------+
|  170000 |      0 |      7 | USER-ID                     |       0 |            1 | NULL         |
|  270000 |      0 |      7 | ROWS-LIMIT                  |       0 |          100 | NULL         |
|  470000 |      0 |      7 | WRITE-SERVER-URL            |       0 |         9090 | localhost    |
|  570000 |      0 |      7 | READ-SERVER-URL             |       0 |         9090 | localhost    |
|  570001 |      0 |      7 | READ-SERVER-URL             |       1 |         9090 | localhost    |
|  670000 |      0 |      7 | SERVER-TIME-OFFSET          |       0 |            0 | NULL         |
|  770000 |      0 |      7 | SYNC-WIFI-ONLY              |       0 |            1 | NULL         |
|  870000 |      0 |      7 | ROWS-NEXT-SYNC-CHANGES-TS   |       0 |         NULL | NULL         |
|  970000 |      0 |      7 | ROWS-SYNC-INTERVAL-MINS     |       0 |         1440 | NULL         |
| 1070000 |      0 |      7 | ROWS-SYNC-INTERVAL          |       0 |            0 | Manual       |
| 1070001 |      0 |      7 | ROWS-SYNC-INTERVAL          |       1 |          720 | 12 Hours     |
| 1070002 |      0 |      7 | ROWS-SYNC-INTERVAL          |       2 |         1440 | 1 Day        |
| 1170000 |      0 |      7 | FIELDS-NEXT-SYNC-CHANGES-TS |       0 |         NULL | NULL         |
| 1270000 |      0 |      7 | FIELDS-SYNC-INTERVAL-MINS   |       0 |            6 | NULL         |
| 1370000 |      0 |      7 | SEND-CHANGES-DELAY-MINS     |       0 |          120 | NULL         |
| 1470000 |      0 |      7 | SEND-CHANGES-DELAY          |       0 |          120 | 2 Hours      |
| 1470001 |      0 |      7 | SEND-CHANGES-DELAY          |       1 |          360 | 6 Hours      |
| 1470002 |      0 |      7 | SEND-CHANGES-DELAY          |       2 |         1440 | 1 Day        |
| 1570000 |      0 |      7 | SEND-CHANGES-DELAY-OPTS     |       0 |            0 | NULL         |
| 1670000 |      0 |      7 | HOME-COUNTRY-ONLY           |       0 |            0 | NULL         |
+---------+--------+--------+-----------------------------+---------+--------------+--------------+
20 rows in set (0.000 sec)
```

<i>Note: The USER-ID is 1 by default, so we do not need to do <code>./rockvole_helper.sh setserverid 1</code></i>
