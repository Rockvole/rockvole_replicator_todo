## Set-Up Read Server

### Add a new read server to the primary write server

```shell
./rockvole_helper.sh addserver read@rockvole.com READ
```
<div align="center">CMD: On primary write server, add details of new read server</div>
<hr/>

### Now view the changes on the primary write server tables :

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  1 | 9101025213a41aaa2a21 |      1 |      1 |                   0 |             0 |
|  2 | 1a09a1               |      0 |      7 |                2278 |     278628118 |
|  3 | 91aa95a12a4751a071aa |      0 |      5 |               57901 |     278629198 |
|  4 | 1aa261               |      0 |      7 |               18003 |     278631240 |
|  5 | aa11aaaaa1aa2a01a4a1 |      1 |      3 |                   0 |             0 |
+----+----------------------+--------+--------+---------------------+---------------+
5 rows in set (0.001 sec)
```
<div align="center">MySql: User Table</div>
<hr/>

```roomsql
select * from user_store;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  1 | write@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
|  2 | user1@rockvole.com |    278628118 | NULL | NULL    |                  0 |                      0 |                    0 |
|  3 | admin@rockvole.com |    278629675 | NULL | NULL    |                  0 |                      0 |                    0 |
|  4 | user2@rockvole.com |    278631250 | NULL | NULL    |                  0 |                      0 |                    0 |
|  5 | read@rockvole.com  |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
5 rows in set (0.000 sec)
```
<div align="center">MySql: User Store Table</div>
<hr/>

### Copy the read server details to the read server

```shell
./rockvole_helper.sh setuser 5 read@rockvole.com aa11aaaaa1aa2a01a4a1 READ
```
<div align="center">CMD: copy read server credentials over</div>
<hr/>

### Now view the changes on the read server tables :

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  5 | aa11aaaaa1aa2a01a4a1 |      0 |      3 |                   0 |             0 |
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
select * from configuration where configuration_name='USER-ID';
+--------+--------+--------+--------------------+---------+--------------+--------------+
| id     | subset | warden | configuration_name | ordinal | value_number | value_string |
+--------+--------+--------+--------------------+---------+--------------+--------------+
| 170000 |      0 |      7 | USER-ID            |       0 |            5 | NULL         |
+--------+--------+--------+--------------------+---------+--------------+--------------+
1 row in set (0.00 sec)
```
<div align="center">MySql: configuration USER-ID is set to 5</div>
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
