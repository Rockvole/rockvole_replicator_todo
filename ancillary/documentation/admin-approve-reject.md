## Admin Approve / Reject

### Choose whether to Approve or Reject

<img src="images/admin_approvals.png" width="200" />

<i>We will Approve 'Mow Lawn' and Reject 'Trim Hedge'.</i>
<hr/>

### Now view the changes on the server :

```roomsql
select * from task;
+----+------------------+---------------+
| id | task_description | task_complete |
+----+------------------+---------------+
|  1 | Mow Lawn         |             0 |
+----+------------------+---------------+
1 row in set (0.000 sec)
```
<div align="center">MySql : Task Table</div>

<i>Only Mow Lawn is in task table</i>
<hr/>

```roomsql
select * from task_TR;
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
| id | task_description | task_complete | ts | operation | user_id | user_ts   | comment     | crc  |
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
|  1 | Mow Lawn         |             0 | 12 |         1 |       2 | 278528407 | Insert Task | NULL |
|  2 | Trim Hedge       |             0 | 13 |         1 |       2 | 278528414 | Insert Task | NULL |
+----+------------------+---------------+----+-----------+---------+-----------+-------------+------+
2 rows in set (0.000 sec)
```
<div align="center">MySql : Task Transaction Table</div>

<i>In transaction tables, the ts column corresponds to the water_ts in the water_line table.</i>
<hr/>

```roomsql
select * from water_line;
+----------+----------------+-------------+-------------+
| water_ts | water_table_id | water_state | water_error |
+----------+----------------+-------------+-------------+
|        1 |            105 |           1 |           0 |
|        2 |            110 |           1 |           0 |
|        3 |            105 |           1 |           0 |
|        4 |            110 |           1 |           0 |
|        7 |            105 |           1 |           0 |
|        8 |            110 |           1 |           0 |
|        9 |            105 |           1 |           0 |
|       10 |            105 |           1 |           0 |
|       11 |            110 |           1 |           0 |
|       12 |           1000 |           1 |           0 |
|       13 |           1000 |           2 |           0 |
+----------+----------------+-------------+-------------+
11 rows in set (0.000 sec)
```
<div align="center">MySql : Water Line Table</div>
<i>On water_ts = 13, the water_state is 2 which corresponds to SERVER_REJECTED</i>
<hr/>
