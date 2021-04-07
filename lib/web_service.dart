import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class WebService {
  SchemaMetaData smd;
  SchemaMetaData smdSys;
  DbTransaction transaction;
  UserTools userTools;
  ConfigurationNameDefaults defaults;

  WebService(
      this.smd, this.smdSys, this.transaction, this.userTools, this.defaults) {}

  Future<TransmitStatus> requestDataFromServer(WaterState waterState) async {
    RemoteStatusDto remoteStatusDto;
    AbstractWarden warden = ClientWardenFactory.getAbstractWarden(
        WardenType.USER, WardenType.READ_SERVER);
    RestGetLatestRowsUtils getRows = RestGetLatestRowsUtils(
        warden, smd, smdSys, transaction, userTools, defaults);
    do {
      List<RemoteDto> remoteDtoList =
          await getRows.requestRemoteDtoListFromServer(waterState);

      remoteStatusDto = await getRows.storeRemoteDtoList(remoteDtoList);
    } while (remoteStatusDto.getStatus() == RemoteStatus.PROCESSED_OK);

    return TransmitStatusDto(TransmitStatus.DOWNLOAD_COMPLETE).transmitStatus;
  }
}
