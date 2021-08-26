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
|  3 | I. Water Roses   |             0 |
|  1 | A. Mow Lawn      |             0 |
+----+------------------+---------------+
2 rows in set (0.00 sec)
```
<div align="center">MySql: Task Table</div>
<hr/>

```roomsql
select * from task_TR;
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
| id | task_description | task_complete | ts | operation | user_id | user_ts   | comment     | crc  |
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
|  3 | I. Water Roses   |             0 |  7 |         1 |       2 | 279992072 | Insert Task | NULL |
|  1 | A. Mow Lawn      |             0 | 11 |         1 |       2 | 279992047 | Insert Task | NULL |
|  2 | R. Trim Hedge    |             0 | 12 |         1 |       2 | 279992061 | Insert Task | NULL |
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
3 rows in set (0.01 sec)
```
<div align="center">MySql: Task Transactions Table</div>
<hr/>

```roomsql
select * from user order by id;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  3 | 1a01910162120011a190 |      0 |      5 |               80634 |     279994490 |
|  4 | 2a0a02               |      0 |      7 |               28070 |     279996011 |
|  5 | a00a392a7a0a411293a5 |      1 |      3 |               38850 |     279996744 |
|  6 | 7a23aaa2aa4081aa8aa2 |      2 |      1 |               24763 |     279998006 |
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
|  6 | 7a23aaa2aa4081aa8aa2 |      0 |      1 |                   0 |             0 |  1 |         1 |       0 |    NULL | Insert into User   |    0 |
|  3 | aa07aa               |      0 |      7 |               80634 |     279994490 |  8 |         1 |       0 |    NULL | Inserting new user | NULL |
|  3 | 1a01910162120011a190 |      0 |      5 |               80634 |     279994490 | 10 |         2 |       0 |    NULL | Add PassKey        | NULL |
|  4 | 2a0a02               |      0 |      7 |               28070 |     279996011 | 13 |         1 |       0 |    NULL | Inserting new user | NULL |
|  5 | a00a392a7a0a411293a5 |      1 |      3 |               38850 |     279996744 | 15 |         1 |       0 |    NULL | Insert into User   |    0 |
|  6 | 7a23aaa2aa4081aa8aa2 |      2 |      1 |               24763 |     279998006 | 17 |         1 |       0 |    NULL | Insert into User   |    0 |
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
|  2 | user1@rockvole.com  |    279991830 | NULL | NULL    |                  0 |                      0 |                    0 |
|  3 | admin@rockvole.com  |    279994490 | NULL | NULL    |                  0 |                      0 |                    0 |
|  4 | user2@rockvole.com  |    279996011 | NULL | NULL    |                  0 |                      0 |                    0 |
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
|  6 | write2@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |  2 |         1 |       0 |    NULL | Insert into User Store |    0 |
|  2 | user1@rockvole.com  |    279991830 | NULL | NULL    |                  0 |                      0 |                    0 |  4 |         1 |       0 |    NULL | Inserting new user     | NULL |
|  3 | admin@rockvole.com  |    279994490 | NULL | NULL    |                  0 |                      0 |                    0 |  9 |         1 |       0 |    NULL | Inserting new user     | NULL |
|  4 | user2@rockvole.com  |    279996011 | NULL | NULL    |                  0 |                      0 |                    0 | 14 |         1 |       0 |    NULL | Inserting new user     | NULL |
|  5 | read@rockvole.com   |            0 | NULL | NULL    |                  0 |                      0 |                    0 | 16 |         1 |       0 |    NULL | Insert into User Store |    0 |
|  6 | write2@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 | 18 |         1 |       0 |    NULL | Insert into User Store |    0 |
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
|        7 |           1000 |           0 |           0 |
|        8 |            105 |           1 |           0 |
|        9 |            110 |           1 |           0 |
|       10 |            105 |           1 |           0 |
|       11 |           1000 |           1 |           0 |
|       12 |           1000 |           2 |           0 |
|       13 |            105 |           1 |           0 |
|       14 |            110 |           1 |           0 |
|       15 |            105 |           1 |           0 |
|       16 |            110 |           1 |           0 |
|       17 |            105 |           1 |           0 |
|       18 |            110 |           1 |           0 |
+----------+----------------+-------------+-------------+
16 rows in set (0.00 sec)
```
<div align="center">MySql: Water Line Table</div>
<hr/>
