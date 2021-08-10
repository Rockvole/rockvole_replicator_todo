## Set-Up Write Server

### Add a new write server to the primary write server

```shell
./rockvole_helper.sh addserver write2@rockvole.com WRITE
```
<div align="center">CMD: On primary write server, add details of new write server</div>
<hr/>

### Now view the changes on the primary write server tables :

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  1 | 72a2a0a6123a29aaa815 |      1 |      1 |                   0 |             0 |
|  2 | a2a1a1               |      0 |      7 |               14996 |     278528223 |
|  3 | 02aaa7aa2a916a117a2a |      0 |      5 |               66428 |     278539401 |
|  4 | 1a03a0               |      0 |      7 |               78208 |     278540031 |
|  5 | a2aa0aaa10020a7a0229 |      1 |      3 |                   0 |             0 |
|  6 | a0a01a56aaaaa6584a00 |      2 |      1 |                   0 |             0 |
+----+----------------------+--------+--------+---------------------+---------------+
6 rows in set (0.000 sec)
```
<div align="center">MySql: User Table</div>
<hr/>

```roomsql
select * from user_store;
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email               | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  1 | write@rockvole.com  |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
|  2 | user1@rockvole.com  |    278528223 | NULL | NULL    |                  0 |                      0 |                    0 |
|  3 | admin@rockvole.com  |    278540265 | NULL | NULL    |                  0 |                      0 |                    0 |
|  4 | user2@rockvole.com  |    278541368 | NULL | NULL    |                  0 |                      0 |                    0 |
|  5 | read@rockvole.com   |    278545149 | NULL | NULL    |                  0 |                      0 |                    0 |
|  6 | write2@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+
6 rows in set (0.000 sec)
```

### Copy the new write server details to the secondary write server

```shell
./rockvole_helper.sh setuser 6 write2@rockvole.com a0a01a56aaaaa6584a00 WRITE
```
<div align="center">CMD: copy secondary write server credentials over</div>
<hr/>

### Now view the changes on the secondary write server tables :

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  6 | a0a01a56aaaaa6584a00 |      0 |      1 |                   0 |             0 |
+----+----------------------+--------+--------+---------------------+---------------+
1 row in set (0.00 sec)
```
<div align="center">MySql: User Table</div>
<hr/>

```roomsql
select * from user_store;
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email               | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  6 | write2@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+
1 row in set (0.00 sec)
```
<div align="center">MySql: User Store Table</div>
<hr/>

## Make the secondary write server the current server

```shell
./rockvole_helper.sh setserverid 6
```
<div align="center">CMD: set current server id to 5</div>
<hr/>

### Now view the changes on the secondary write server tables :

```roomsql
select * from configuration where configuration_name='USER-ID';
+--------+--------+--------+--------------------+---------+--------------+--------------+
| id     | subset | warden | configuration_name | ordinal | value_number | value_string |
+--------+--------+--------+--------------------+---------+--------------+--------------+
| 170000 |      0 |      7 | USER-ID            |       0 |            6 | NULL         |
+--------+--------+--------+--------------------+---------+--------------+--------------+
1 row in set (0.00 sec)
```
<div align="center">MySql: configuration USER-ID is set to 6</div>
<hr/>

```roomsql
show tables;
+----------------------+
| Tables_in_default_db |
+----------------------+
| configuration        |
| user                 |
| user_TR              |
| user_store           |
| user_store_TR        |
| water_line           |
+----------------------+
6 rows in set (0.00 sec)
```
