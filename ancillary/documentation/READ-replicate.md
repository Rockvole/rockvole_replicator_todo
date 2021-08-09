## Replicate Read Server

### On read server, add the write server ip address to the configuration table

```shell
./rockvole_helper.sh changestring USER 0 WRITE-SERVER-URL 9090 192.168.1.140
```
<div align="center">CMD: On read server, add ip address</div>
<hr/>

### Now view the change on the read server database
```roomsql
select * from configuration where configuration_name='WRITE-SERVER-URL';
+--------+--------+--------+--------------------+---------+--------------+---------------+
| id     | subset | warden | configuration_name | ordinal | value_number | value_string  |
+--------+--------+--------+--------------------+---------+--------------+---------------+
| 470000 |      0 |      7 | WRITE-SERVER-URL   |       0 |         9090 | 192.168.1.140 |
+--------+--------+--------+--------------------+---------+--------------+---------------+
1 row in set (0.00 sec)
```
<div align="center">MySql: Configuration Table</div>
<hr/>

### Fetch from the write server
```shell
./rockvole_helper.sh fetchfromserver
```
<div align="center">CMD: On read server, fetch from the write server</div>

<i>Note: This can performed automatically from a batch script each hour / day as required.</i>
<hr/>

### Now view the changes on the read server

```roomsql
select * from task;
+----+------------------+---------------+
| id | task_description | task_complete |
+----+------------------+---------------+
|  1 | Mow Lawn         |             0 |
+----+------------------+---------------+
1 row in set (0.00 sec)
```
<div align="center">MySql: Task Table</div>
<hr/>

```roomsql
select * from task_TR;
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
| id | task_description | task_complete | ts | operation | user_id | user_ts   | comment     | crc  |
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
|  1 | Mow Lawn         |             0 | 12 |         1 |       2 | 278528407 | Insert Task | NULL |
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
1 row in set (0.00 sec)
```
<div align="center">MySql: Task Transactions Table</div>
<hr/>

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  5 | a2aa0aaa10020a7a0229 |      1 |      3 |                   0 |             0 |
|  3 | 02aaa7aa2a916a117a2a |      0 |      5 |               66428 |     278539401 |
|  4 | 1a03a0               |      0 |      7 |               78208 |             0 |
+----+----------------------+--------+--------+---------------------+---------------+
3 rows in set (0.00 sec)
```
<div align="center">MySql: User Table</div>
<hr/>

```roomsql
select * from user_TR;
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts | ts | operation | user_id | user_ts | comment            | crc  |
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
|  5 | a2aa0aaa10020a7a0229 |      0 |      3 |                   0 |             0 |  1 |         1 |      33 |    NULL | Insert into User   |    0 |
|  3 | 32a546               |      0 |      7 |               66428 |             0 |  7 |         1 |       0 |    NULL | Inserting new user | NULL |
|  3 | 02aaa7aa2a916a117a2a |      0 |      5 |               66428 |     278539401 |  9 |         2 |       0 |    NULL | Add PassKey        | NULL |
|  4 | 1a03a0               |      0 |      7 |               78208 |             0 | 10 |         1 |       0 |    NULL | Inserting new user | NULL |
|  5 | a2aa0aaa10020a7a0229 |      1 |      3 |                   0 |             0 | 14 |         1 |      33 |    NULL | Insert into User   |    0 |
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
5 rows in set (0.00 sec)
```
<div align="center">MySql: User Transactions Table</div>
<hr/>

```roomsql
select * from user_store;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  5 | read@rockvole.com  |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
|  2 | user1@rockvole.com |    278528223 | NULL | NULL    |                  0 |                      0 |                    0 |
|  3 | admin@rockvole.com |    278539401 | NULL | NULL    |                  0 |                      0 |                    0 |
|  4 | user2@rockvole.com |    278540031 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
4 rows in set (0.00 sec)
```
<div align="center">MySql: User Store Table</div>
<hr/>

```roomsql
select * from user_store_TR;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count | ts | operation | user_id | user_ts | comment                | crc  |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
|  5 | read@rockvole.com  |            0 | NULL | NULL    |                  0 |                      0 |                    0 |  2 |         1 |      33 |    NULL | Insert into User Store |    0 |
|  2 | user1@rockvole.com |    278528223 | NULL | NULL    |                  0 |                      0 |                    0 |  4 |         1 |       0 |    NULL | Inserting new user     | NULL |
|  3 | admin@rockvole.com |    278539401 | NULL | NULL    |                  0 |                      0 |                    0 |  8 |         1 |       0 |    NULL | Inserting new user     | NULL |
|  4 | user2@rockvole.com |    278540031 | NULL | NULL    |                  0 |                      0 |                    0 | 11 |         1 |       0 |    NULL | Inserting new user     | NULL |
|  5 | read@rockvole.com  |            0 | NULL | NULL    |                  0 |                      0 |                    0 | 15 |         1 |      33 |    NULL | Insert into User Store |    0 |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
5 rows in set (0.00 sec)
```
<div align="center">MySql: User Store Transactions Table</div>
<hr/>

```roomsql
select * from water_line;
+----------+----------------+-------------+-------------+
| water_ts | water_table_id | water_state | water_error |
+----------+----------------+-------------+-------------+
|        1 |            105 |           1 |           0 |
|        2 |            110 |           1 |           0 |
|        3 |            100 |           1 |           0 |
|        4 |            110 |           1 |           0 |
|        7 |            105 |           1 |           0 |
|        8 |            110 |           1 |           0 |
|        9 |            105 |           1 |           0 |
|       10 |            105 |           1 |           0 |
|       11 |            110 |           1 |           0 |
|       12 |           1000 |           1 |           0 |
|       14 |            105 |           1 |           0 |
|       15 |            110 |           1 |           0 |
+----------+----------------+-------------+-------------+
12 rows in set (0.00 sec)
```
<div align="center">MySql: Water Line Table</div>
<hr/>