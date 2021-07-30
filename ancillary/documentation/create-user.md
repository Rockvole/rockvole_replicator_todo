## Create User

#### Add email address in app and press refresh

<img src="images/user1_add_email.png" width=""200" />

#### Now view the changes on the server :

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  1 | 41004347aa0310209084 |      1 |      1 |                   0 |             0 |
|  2 | 40259a               |      0 |      7 |                9453 |     277683963 |
+----+----------------------+--------+--------+---------------------+---------------+
2 rows in set (0.000 sec)
```
<div align="center">MySql: User Table</div><br/>

```roomsql
select * from user_TR;
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts | ts | operation | user_id | user_ts | comment            | crc  |
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
|  1 | 41004347aa0310209084 |      1 |      1 |                   0 |             0 |  1 |         1 |      33 |    NULL | Insert into User   |    0 |
|  2 | 40259a               |      0 |      7 |                9453 |             0 |  3 |         1 |       0 |    NULL | Inserting new user | NULL |
+----+----------------------+--------+--------+---------------------+---------------+----+-----------+---------+---------+--------------------+------+
2 rows in set (0.000 sec)
```
<div align="center">MySql: User Transaction Table</div><br/>

```roomsql
select * from user_store;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  1 | write@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
|  2 | user1@rockvole.com |    277683963 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
2 rows in set (0.000 sec)
```
<div align="center">MySql: User Store Table</div><br/>

```roomsql
select * from user_store_TR;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count | ts | operation | user_id | user_ts | comment                | crc  |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
|  1 | write@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |  2 |         1 |      33 |    NULL | Insert into User Store |    0 |
|  2 | user1@rockvole.com |    277683963 | NULL | NULL    |                  0 |                      0 |                    0 |  4 |         1 |       0 |    NULL | Inserting new user     | NULL |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+----+-----------+---------+---------+------------------------+------+
2 rows in set (0.010 sec)
```
<div align="center">MySql: User Store Transaction Table</div><br/>
