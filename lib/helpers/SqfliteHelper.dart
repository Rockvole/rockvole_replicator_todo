import '../pools/SqflitePool.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';

class SqfliteHelper {
  // --------------------------------------------------------------------------------------- DATABASE
  static Future<DbTransaction> getSqfliteDbTransaction(String localDatabase, String? location) async {
    late AbstractPool pool;
    late DbTransaction transaction;
    try {
      pool = SqflitePool(location,localDatabase);
      transaction = DbTransaction(pool);
      await transaction.beginTransaction();
    } catch (e) {
      print("WS $e");
    }
    return transaction;
  }
}