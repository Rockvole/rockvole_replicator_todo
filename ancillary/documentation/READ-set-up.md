## Set-Up Read Server

### Add a new read server to the write server

```shell
./rockvole_helper.sh addserver read@rockvole.com READ
```
<div align="center">CMD: On write server, add details of new read server</div>
<hr/>

### Now view the changes on the write server tables :

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  1 | 41004347aa0310209084 |      1 |      1 |                   0 |             0 |
|  2 | 40259a               |      0 |      7 |                9453 |     277683963 |
|  3 | 83902a1387aa56aaa7a1 |      0 |      5 |               21501 |     278026768 |
|  4 | 7a22a1               |      0 |      7 |               40588 |     278110705 |
|  5 | a3aa01220a7aa0060040 |      1 |      3 |                   0 |             0 |
+----+----------------------+--------+--------+---------------------+---------------+
5 rows in set (0.000 sec)
```
<div align="center">MySql: User Table</div>
<hr/>

```roomsql
select * from user_store;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  1 | write@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
|  2 | user1@rockvole.com |    277683963 | NULL | NULL    |                  0 |                      0 |                    0 |
|  3 | admin@rockvole.com |    278195307 | NULL | NULL    |                  0 |                      0 |                    0 |
|  4 | user2@rockvole.com |    278196390 | NULL | NULL    |                  0 |                      0 |                    0 |
|  5 | read@rockvole.com  |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
5 rows in set (0.000 sec)
```
<div align="center">MySql: User Store Table</div>
<hr/>

### Copy the read server details to the read server

```shell
./rockvole_helper.sh setuser 5 read@rockvole.com a3aa01220a7aa0060040 READ
```
<div align="center">CMD: copy read server credentials over</div>
<hr/>

### Now view the changes on the read server tables :

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  5 | a3aa01220a7aa0060040 |      0 |      3 |                   0 |             0 |
+----+----------------------+--------+--------+---------------------+---------------+
1 row in set (0.00 sec)
```
<div align="center">MySql: User Table</div>
<hr/>

```roomsql
select * from user_store;
+----+-------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email             | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+-------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  5 | read@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+-------------------+--------------+------+---------+--------------------+------------------------+----------------------+
1 row in set (0.00 sec)
```
<div align="center">MySql: User Store Table</div>
<hr/>

## Make the read server the current server
```shell
./rockvole_helper.sh setserverid 5
```
<div align="center">CMD: set current server id to 5</div>
<hr/>

### Now view the changes on the read server tables :

```roomsql
select * from configuration;
+---------+--------+--------+-----------------------------+---------+--------------+--------------+
| id      | subset | warden | configuration_name          | ordinal | value_number | value_string |
+---------+--------+--------+-----------------------------+---------+--------------+--------------+
| 1670000 |      0 |      7 | HOME-COUNTRY-ONLY           |       0 |            0 | NULL         |
| 1170000 |      0 |      7 | FIELDS-NEXT-SYNC-CHANGES-TS |       0 |         NULL | NULL         |
| 1270000 |      0 |      7 | FIELDS-SYNC-INTERVAL-MINS   |       0 |            6 | NULL         |
|  570000 |      0 |      7 | READ-SERVER-URL             |       0 |         9090 | localhost    |
|  570001 |      0 |      7 | READ-SERVER-URL             |       1 |         9090 | localhost    |
|  270000 |      0 |      7 | ROWS-LIMIT                  |       0 |          100 | NULL         |
|  870000 |      0 |      7 | ROWS-NEXT-SYNC-CHANGES-TS   |       0 |         NULL | NULL         |
| 1070000 |      0 |      7 | ROWS-SYNC-INTERVAL          |       0 |            0 | Manual       |
| 1070001 |      0 |      7 | ROWS-SYNC-INTERVAL          |       1 |          720 | 12 Hours     |
| 1070002 |      0 |      7 | ROWS-SYNC-INTERVAL          |       2 |         1440 | 1 Day        |
|  970000 |      0 |      7 | ROWS-SYNC-INTERVAL-MINS     |       0 |         1440 | NULL         |
| 1470000 |      0 |      7 | SEND-CHANGES-DELAY          |       0 |          120 | 2 Hours      |
| 1470001 |      0 |      7 | SEND-CHANGES-DELAY          |       1 |          360 | 6 Hours      |
| 1470002 |      0 |      7 | SEND-CHANGES-DELAY          |       2 |         1440 | 1 Day        |
| 1370000 |      0 |      7 | SEND-CHANGES-DELAY-MINS     |       0 |          120 | NULL         |
| 1570000 |      0 |      7 | SEND-CHANGES-DELAY-OPTS     |       0 |            0 | NULL         |
|  670000 |      0 |      7 | SERVER-TIME-OFFSET          |       0 |            0 | NULL         |
|  770000 |      0 |      7 | SYNC-WIFI-ONLY              |       0 |            1 | NULL         |
|  170000 |      0 |      7 | USER-ID                     |       0 |            5 | NULL         |
|  470000 |      0 |      7 | WRITE-SERVER-URL            |       0 |         9090 | localhost    |
+---------+--------+--------+-----------------------------+---------+--------------+--------------+
20 rows in set (0.00 sec)
```
<div align="center">MySql: configuration USER-ID is set to 5</div>
<hr/>
