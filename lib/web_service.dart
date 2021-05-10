import 'package:event_bus/event_bus.dart';
import 'package:rockvole_db/rockvole_data.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:rockvole_replicator_todo/dao/TaskMixin.dart';

import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';

class WebService {
  static int C_VERSION = 1;
  SchemaMetaData smd;
  SchemaMetaData smdSys;
  UserTools userTools;
  ConfigurationNameDefaults defaults;
  late AbstractWarden warden;
  EventBus eventBus;
  TransmitStatusDto transmitStatusDto =
      TransmitStatusDto(TransmitStatus.DOWNLOAD_STARTED);
  bool taskTableReceived = false;

  WebService(
      this.smd, this.smdSys, this.userTools, this.defaults, this.eventBus) {
    taskTableReceived = false;
  }

  Future<void> init() async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    if (await userTools.isAdmin(smd, transaction))
      warden = ClientWardenFactory.getAbstractWarden(
          WardenType.ADMIN, WardenType.WRITE_SERVER);
    else
      warden = ClientWardenFactory.getAbstractWarden(
          WardenType.USER, WardenType.READ_SERVER);
    await db.close();
  }

  Future<AuthenticationDto?> authenticateUser(
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
    await authenticationUtils.init();
    try {
      currentTs = TimeUtils.getNowCustomTs();
      remoteDto = await authenticationUtils.requestAuthenticationFromServer(
          stateType, C_VERSION);
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

  Future<TransmitStatus> downloadRows(
      WaterState waterState, int totalCount) async {
    if (totalCount == 0) {
      transmitStatusDto =
          TransmitStatusDto(TransmitStatus.NO_NEW_RECORDS_FOUND);
      eventBus.fire(transmitStatusDto);
    } else {
      int remainingCount = totalCount;
      int downloadedCount = 0;
      transmitStatusDto = TransmitStatusDto(TransmitStatus.DOWNLOAD_STARTED);
      eventBus.fire(transmitStatusDto);
      AbstractDatabase db = await DataBaseAccess.getConnection();
      DbTransaction transaction = await DataBaseAccess.getTransaction();

      RestGetLatestRowsUtils getRows = RestGetLatestRowsUtils(
          warden, smd, smdSys, transaction, userTools, defaults);
      await getRows.init();
      RemoteStatusDto remoteStatusDto;
      do {
        transmitStatusDto = TransmitStatusDto(TransmitStatus.RECORDS_REMAINING,
            message: remainingCount.toString() + " records to download",
            completedRecords: downloadedCount,
            totalRecords: totalCount,
            userInitiated: false);
        eventBus.fire(transmitStatusDto);
        List<RemoteDto> remoteDtoList =
            await getRows.requestRemoteDtoListFromServer(waterState);
        if (getRows.wasTableReceived(TaskMixin.C_TABLE_ID)) {
          taskTableReceived = true;
        }

        remoteStatusDto = await getRows.storeRemoteDtoList(remoteDtoList);
        remainingCount = remainingCount - remoteDtoList.length;
        downloadedCount = downloadedCount + remoteDtoList.length;
      } while (remoteStatusDto.getStatus() == RemoteStatus.PROCESSED_OK);
      transmitStatusDto = TransmitStatusDto(TransmitStatus.DOWNLOAD_COMPLETE,
          message: totalCount.toString() + " records downloaded",
          completedRecords: totalCount,
          totalRecords: totalCount,
          userInitiated: false);
      eventBus.fire(transmitStatusDto);
      await db.close();
    }
    return transmitStatusDto.transmitStatus;
  }

  Future<void> sendChanges(
      TransmitStatusDto? transmitStatusDto, bool sendNow) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    late RemoteDto remoteDto;

    WaterLineDao waterLineDao = WaterLineDao.sep(smdSys, transaction);
    await waterLineDao.init();
    late RestPostNewRowUtils restPostNewRowUtils;
    try {
      restPostNewRowUtils = RestPostNewRowUtils(
          warden.localWardenType,
          warden.remoteWardenType,
          smd,
          smdSys,
          transaction,
          userTools,
          defaults);
      await restPostNewRowUtils.init();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        print("UI $e");
    }
    int? sendMins = await userTools.getConfigurationInteger(
        smd, transaction, ConfigurationNameEnum.SEND_CHANGES_DELAY_MINS);
    ClientWarden clientWarden =
        ClientWarden(warden.localWardenType, waterLineDao);
    List<WaterLineDto> waterLineList;
    try {
      waterLineList = await clientWarden.getWaterLineListToSend();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT) print("UI $e");
      return;
    }
    int cts = TimeUtils.getNowCustomTs();
    WaterLineDto waterLineDto;
    Iterator<WaterLineDto> waterLineDtoIter = waterLineList.iterator;
    List<RemoteDto> remoteDtoList = [];

    // Iterate to compile list of entries to send
    while (waterLineDtoIter.moveNext()) {
      waterLineDto = waterLineDtoIter.current;
      try {
        remoteDto = await RemoteDtoFactory.getRemoteDtoFromWaterLineDto(
            waterLineDto, warden.localWardenType, smdSys, transaction, false);
        if (sendNow ||
            (cts - (sendMins! * 60) >= remoteDto.hcDto.user_ts!) ||
            remoteDto.waterLineDto!.water_state == WaterState.CLIENT_APPROVED ||
            remoteDto.waterLineDto!.water_state == WaterState.CLIENT_REJECTED) {
          remoteDtoList.add(remoteDto);
        }
      } on SqlException catch (e) {
        if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
            e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
            e.sqlExceptionEnum == SqlExceptionEnum.PARTITION_NOT_FOUND)
          print("UI $e");
      }
    }
    // Send the list of compiled entries
    bool sentItem = false;
    Iterator<RemoteDto> remoteDtoIter = remoteDtoList.iterator;
    int totalCount = remoteDtoList.length;
    int remainingCount = totalCount;
    int sentCount = 0;
    EntryReceivedDto entryReceivedDto;
    try {
      while (remoteDtoIter.moveNext()) {
        remoteDto = remoteDtoIter.current;
        if (!sentItem) {
          transmitStatusDto = TransmitStatusDto(TransmitStatus.UPLOAD_STARTED);
          sentItem = true;
        }
        if (remoteDtoList.length > 1) {
          transmitStatusDto = TransmitStatusDto(
              TransmitStatus.RECORDS_REMAINING,
              message: remainingCount.toString() + " records to send",
              completedRecords: sentCount,
              totalRecords: totalCount,
              userInitiated: false);
        }
        try {
          entryReceivedDto = await restPostNewRowUtils.sendRemoteDtoToServer(
              remoteDto, C_VERSION) as EntryReceivedDto;
          print("PostNewRow: $remoteDto|| Received: $entryReceivedDto");
          if (remoteDto.hcDto.operation == OperationType.INSERT) {
            //refreshPageOttoDto.add(entryReceivedDto.getOriginalTableType(), entryReceivedDto.getOriginalId(), entryReceivedDto.getNewId());
          }
        } on TransmitStatusException catch (e1) {
          print(e1.cause.toString() + "||$remoteDto");
          if (e1.remoteStatus != null) {
            switch (e1.remoteStatus) {
              case RemoteStatus.EMAIL_ALREADY_EXISTS:
                //RevertChangesOttoDto revertChangesOttoDto = new RevertChangesOttoDto(remoteDto.getHcDto().getTs());
                //FoodApplication.getEventBus().post(revertChangesOttoDto);
                throw TransmitStatusException(null,
                    cause: "E-Mail Address Already Exists",
                    remoteStatus: e1.remoteStatus,
                    sourceName: e1.sourceName);
              case RemoteStatus.DUPLICATE_ENTRY:
                try {
                  await waterLineDao.updateWaterLine(
                      remoteDto.waterLineDto!.water_ts!,
                      null,
                      WaterState.CLIENT_SENT,
                      null);
                  continue;
                } on SqlException catch (e) {
                  if (e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
                      e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT ||
                      e.sqlExceptionEnum ==
                          SqlExceptionEnum.PARTITION_NOT_FOUND)
                    print(StackTrace.current);
                }
                break;
              case RemoteStatus.EXPECTED_PASSKEY:
                continue;
              default:
            }
            throw TransmitStatusException(null,
                cause: e1.cause,
                remoteStatus: e1.remoteStatus,
                sourceName: e1.sourceName);
          }
          throw TransmitStatusException(e1.transmitStatus,
              cause: e1.cause, sourceName: e1.sourceName);
        }
        remainingCount--;
        sentCount++;
      }
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND)
        print("UI $e");
    }
    if (sentItem) {
      //FoodApplication.getUiEventBus().post(new SharingFragmentOtto(SharingFragment.SharingType.UNKNOWN, false));
      transmitStatusDto = TransmitStatusDto(TransmitStatus.UPLOAD_COMPLETE,
          message: totalCount.toString() + " records sent",
          completedRecords: totalCount,
          totalRecords: totalCount,
          userInitiated: false);
      //FoodApplication.getUiEventBus().post(transmitStatusDto);
      //FoodApplication.getEventBus().post(refreshPageOttoDto);
    }
    await db.close();
  }
}
