## Create Admin Phone

### Save user and refresh

<img src="images/admin_add_email.png" width="200" />
<hr/>

### On server, we upgrade the user to admin

```shell
./rockvole_helper.sh upgradeuser admin@rockvole.com
```
<div align="center">Command Line</div>
<hr/>

### Database is shown which reflects the changes

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  1 | 72a2a0a6123a29aaa815 |      1 |      1 |                   0 |             0 |
|  2 | a2a1a1               |      0 |      7 |               14996 |     278528223 |
|  3 |                      |      0 |      5 |               66428 |     278539401 |
+----+----------------------+--------+--------+---------------------+---------------+
3 rows in set (0.001 sec)
```
<div align="center">Mysql: User Table</div>

<i>In user table, our new user is id=3. Warden is now 5 which is ADMIN</i>

<i>The pass_key has been cleared so that on the next request a new admin pass_key will be generated.</i>
<hr/>

```roomsql
select * from user_store;
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
| id | email              | last_seen_ts | name | surname | records_downloaded | changes_approved_count | changes_denied_count |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
|  1 | write@rockvole.com |            0 | NULL | NULL    |                  0 |                      0 |                    0 |
|  2 | user1@rockvole.com |    278528223 | NULL | NULL    |                  0 |                      0 |                    0 |
|  3 | admin@rockvole.com |    278539401 | NULL | NULL    |                  0 |                      0 |                    0 |
+----+--------------------+--------------+------+---------+--------------------+------------------------+----------------------+
3 rows in set (0.000 sec)
```
<div align="center">Mysql: User Store Table</div>
<hr/>

### Press refresh on the phone and Admin user is now Admin

<img src="images/admin_now_admin.png" width="200" />
<hr/>

### User table now contains admin password

```roomsql
select * from user;
+----+----------------------+--------+--------+---------------------+---------------+
| id | pass_key             | subset | warden | request_offset_secs | registered_ts |
+----+----------------------+--------+--------+---------------------+---------------+
|  1 | 72a2a0a6123a29aaa815 |      1 |      1 |                   0 |             0 |
|  2 | a2a1a1               |      0 |      7 |               14996 |     278528223 |
|  3 | 02aaa7aa2a916a117a2a |      0 |      5 |               66428 |     278539401 |
+----+----------------------+--------+--------+---------------------+---------------+
3 rows in set (0.001 sec)
```
<div align="center">Mysql: User Table</div>

