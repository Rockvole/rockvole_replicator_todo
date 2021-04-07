import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import 'database_access.dart';

class WebService {
  SchemaMetaData smd;
  SchemaMetaData smdSys;
  UserTools userTools;
  ConfigurationNameDefaults defaults;

  WebService(
      this.smd, this.smdSys, this.userTools, this.defaults) {}

  Future<TransmitStatus> requestDataFromServer(WaterState waterState) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    RemoteStatusDto remoteStatusDto;
    AbstractWarden warden = ClientWardenFactory.getAbstractWarden(
        WardenType.USER, WardenType.READ_SERVER);
    RestGetLatestRowsUtils getRows = RestGetLatestRowsUtils(
        warden, smd, smdSys, transaction, userTools, defaults);
    await getRows.init();
    do {
      List<RemoteDto> remoteDtoList =
          await getRows.requestRemoteDtoListFromServer(waterState);

      remoteStatusDto = await getRows.storeRemoteDtoList(remoteDtoList);
    } while (remoteStatusDto.getStatus() == RemoteStatus.PROCESSED_OK);

    await db.close();
    return TransmitStatusDto(TransmitStatus.DOWNLOAD_COMPLETE).transmitStatus;
  }
}
