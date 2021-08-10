## Replicate Secondary Write Server

### On secondary server, add the primary write server ip address to the configuration table

```shell
./rockvole_helper.sh changestring USER 0 WRITE-SERVER-URL 9090 192.168.1.140
```
<div align="center">CMD: On secondary write server, add ip address</div>
<hr/>

### Now view the change on the secondary write server database
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

### Fetch from the primary write server
```shell
./rockvole_helper.sh fetchfromserver
```
<div align="center">CMD: On secondary write server, fetch from the primary write server</div>

<i>Note: This can be performed automatically from a batch script each hour / day as required.</i>
<hr/>

### Now view the changes on the secondary server

```roomsql
select * from task;
+----+------------------+---------------+
| id | task_description | task_complete |
+----+------------------+---------------+
|  1 | A. Mow Lawn      |             0 |
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
|  1 | A. Mow Lawn      |             0 | 11 |         1 |       2 | 278628321 | Insert Task | NULL |
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
1 row in set (0.00 sec)
```
<div align="center">MySql: Task Transactions Table</div>
<hr/>

```roomsql
select * from user order by id;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  3 | 91aa95a12a4751a071aa |      0 |      5 |               57901 |     278629198 |
|  4 | 1aa261               |      0 |      7 |               18003 |             0 |
|  5 | aa11aaaaa1aa2a01a4a1 |      1 |      3 |                   0 |             0 |
|  6 | 104aaa10941a90a11a15 |      2 |      1 |                   0 |             0 |
+----+----------------------+--------+--------+---------------------+---------------+
4 rows in set (0.00 sec)
```
<div align="center">MySql: User Table</div>
<hr/>

```roomsql
select * from user_TR;
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts | ts | operation | user_id | user_ts | comment            | crc  |
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
|  6 | 104aaa10941a90a11a15 |      0 |      1 |                   0 |             0 |  1 |         1 |      33 |    NULL | Insert into User   |    0 |
|  3 | 31a822               |      0 |      7 |               57901 |             0 |  8 |         1 |       0 |    NULL | Inserting new user | NULL |
|  3 | 91aa95a12a4751a071aa |      0 |      5 |               57901 |     278629198 | 10 |         2 |       0 |    NULL | Add PassKey        | NULL |
|  4 | 1aa261               |      0 |      7 |               18003 |             0 | 13 |         1 |       0 |    NULL | Inserting new user | NULL |
|  5 | aa11aaaaa1aa2a01a4a1 |      1 |      3 |                   0 |             0 | 15 |         1 |      33 |    NULL | Insert into User   |    0 |
|  6 | 104aaa10941a90a11a15 |      2 |      1 |                   0 |             0 | 17 |         1 |      33 |    NULL | Insert into User   |    0 |
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
6 rows in set (0.00 sec)
```
<div align="center">MySql: User Transactions Table</div>
<hr/>

```roomsql
select * from user_store order by id;
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email               | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  2 | user1@rockvole.com  |    278628118 | NULL | NULL    |                  0 |                      0 |                    0 |
|  3 | admin@rockvole.com  |    278629198 | NULL | NULL    |                  0 |                      0 |                    0 |
|  4 | user2@rockvole.com  |    278631240 | NULL | NULL    |                  0 |                      0 |                    0 |
|  5 | read@rockvole.com   |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
|  6 | write2@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+
5 rows in set (0.00 sec)
```
<div align="center">MySql: User Store Table</div>
<hr/>

```roomsql
select * from user_store_TR order by ts;
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
| id | email               | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count | ts | operation | user_id | user_ts | comment                | crc  |
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
|  6 | write2@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |  2 |         1 |      33 |    NULL | Insert into User Store |    0 |
|  2 | user1@rockvole.com  |    278628118 | NULL | NULL    |                  0 |                      0 |                    0 |  4 |         1 |       0 |    NULL | Inserting new user     | NULL |
|  3 | admin@rockvole.com  |    278629198 | NULL | NULL    |                  0 |                      0 |                    0 |  9 |         1 |       0 |    NULL | Inserting new user     | NULL |
|  4 | user2@rockvole.com  |    278631240 | NULL | NULL    |                  0 |                      0 |                    0 | 14 |         1 |       0 |    NULL | Inserting new user     | NULL |
|  5 | read@rockvole.com   |            0 | NULL | NULL    |                  0 |                      0 |                    0 | 16 |         1 |      33 |    NULL | Insert into User Store |    0 |
|  6 | write2@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 | 18 |         1 |      33 |    NULL | Insert into User Store |    0 |
+----+---------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
6 rows in set (0.00 sec)
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
|        8 |            105 |           1 |           0 |
|        9 |            110 |           1 |           0 |
|       10 |            105 |           1 |           0 |
|       11 |           1000 |           1 |           0 |
|       13 |            105 |           1 |           0 |
|       14 |            110 |           1 |           0 |
|       15 |            105 |           1 |           0 |
|       16 |            110 |           1 |           0 |
|       17 |            105 |           1 |           0 |
|       18 |            110 |           1 |           0 |
+----------+----------------+-------------+-------------+
14 rows in set (0.00 sec)
```
<div align="center">MySql: Water Line Table</div>
<hr/>
