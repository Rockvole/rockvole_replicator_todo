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
  late AbstractWarden warden;

  WebService(
      this.smd, this.smdSys, this.userTools, this.defaults) {
    bool isAdmin = false;
    if (isAdmin)
      warden = ClientWardenFactory.getAbstractWarden(
          WardenType.ADMIN, WardenType.WRITE_SERVER);
    else
      warden = ClientWardenFactory.getAbstractWarden(
          WardenType.USER, WardenType.READ_SERVER);
  }

  Future<AuthenticationDto?> authenticateUser(String passKey,
      WaterState stateType, bool userInitiated) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    late RemoteDto remoteDto;
    late int currentTs;
    RestGetAuthenticationUtils authenticationUtils = RestGetAuthenticationUtils(
        warden.localWardenType,
        warden.remoteWardenType,
        smd,
        smdSys,
        transaction,
        userTools,
        defaults,
        null);

    try {
      currentTs = TimeUtils.getNowCustomTs();
      remoteDto = await authenticationUtils.requestAuthenticationFromServer(
          stateType, 1);
      print(remoteDto.toString());
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) print("UI $e");
    }
    AuthenticationDto? authenticationDto;
    switch (remoteDto.water_table_id) {
      case RemoteStatusDto.C_TABLE_ID:
        RemoteStatusDto remoteStateDto = remoteDto as RemoteStatusDto;
        TransmitStatusDto transmitStatusDto = TransmitStatusDto(
            TransmitStatus.REMOTE_STATE_ERROR,
            userInitiated: userInitiated);
        transmitStatusDto.remoteStatus = remoteStateDto.getStatus()!;
        break;
      case AuthenticationDto.C_TABLE_ID:
        authenticationDto = remoteDto as AuthenticationDto;
        break;
      default:
        print("UNKNOWN=" + remoteDto.water_table_id.toString());
    }
    await db.close();
    return authenticationDto;
  }

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
