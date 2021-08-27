import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rockvole_db_replicator/rockvole_sqflite.dart';

class SqflitePool extends AbstractPool {
  static final String C_EXT = ".db";

  SqflitePool(String? dir, String dbn) {
    setUpPool(dir, dbn, 10);

    tools = MysqlStrings(getDBType());
  }

  void closeConnection({Database? conn}) {
    if (conn != null) conn.close();
  }

  String getPoolName(String? dir, String? dbn) {
    if (dir == null)
      directory = "database";
    else
      directory = dir;
    if (dbn == null)
      dataBaseName = C_DEFAULT_DBNAME + C_EXT;
    else
      dataBaseName = dbn + C_EXT;
    return getDBType().toString() + ":" + directory.toString() + "/" + dataBaseName.toString();
  }

  DBType getDBType() => DBType.Sqflite;

  Future<AbstractDatabase> getConnection() async {
    AbstractDatabase db = SqfliteDatabase.filename(dataBaseName!) as AbstractDatabase;
    await db.connect();
    return db;
  }

  @override
  bool supportsPool() {
    return false;
  }
}
