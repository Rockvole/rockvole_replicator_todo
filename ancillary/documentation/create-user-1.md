## Create User 1

### Add email address in app and press refresh

<img src="images/user1_add_email.png" width="400" />
<hr/>

### Now view the changes on the server :

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  1 | 831a117210a2aaa84187 |      1 |      1 |               24789 |     279991557 |
|  2 | 168a2a               |      0 |      7 |                7430 |     279991830 |
+----+----------------------+--------+--------+---------------------+---------------+
2 rows in set (0.001 sec)
```
<div align="center">MySql: User Table</div>
<hr/>

```roomsql
select * from user_TR;
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts | ts | operation | user_id | user_ts | comment            | crc  |
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
|  1 | 831a117210a2aaa84187 |      1 |      1 |               24789 |     279991557 |  1 |         1 |       0 |    NULL | Insert into User   |    0 |
|  2 | 168a2a               |      0 |      7 |                7430 |     279991830 |  3 |         1 |       0 |    NULL | Inserting new user | NULL |
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
2 rows in set (0.000 sec)
```
<div align="center">MySql: User Transaction Table</div>
<hr/>

```roomsql
select * from user_store;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  1 | write@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
|  2 | user1@rockvole.com |    279991830 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
2 rows in set (0.000 sec)
```
<div align="center">MySql: User Store Table</div>
<hr/>

```roomsql
select * from user_store_TR;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count | ts | operation | user_id | user_ts | comment                | crc  |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
|  1 | write@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |  2 |         1 |       0 |    NULL | Insert into User Store |    0 |
|  2 | user1@rockvole.com |    279991830 | NULL | NULL    |                  0 |                      0 |                    0 |  4 |         1 |       0 |    NULL | Inserting new user     | NULL |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
2 rows in set (0.001 sec)
```
<div align="center">MySql: User Store Transaction Table</div><br/>
