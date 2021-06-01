import 'dart:io';

import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';
import 'web_service.dart';

class RestIntentService {
  late WebService _webService;
  Application _application;
  UserTools _userTools;
  ConfigurationNameDefaults _defaults;
  Bus _bus;

  //UserDto? _currentUserDto;
  //UserStoreDto? _currentUserStoreDto;

  RestIntentService(this._application, this._userTools, this._defaults, this._bus);

  Future<bool> syncDatabaseFull(UserDto _currentUserDto, UserStoreDto _currentUserStoreDto) async {
    print('start long op');
    _webService = WebService(_application.smd, _application.smdSys, _userTools,
        _defaults, _bus.eventBus);
    await _webService.init();
    //unawaited(_controller.forward());
    //await fetchUserData(false);
    String? passKey = _currentUserDto.pass_key;
    bool isNewUser = (_currentUserDto.id == 1);
    try {
      if (!isNewUser && _currentUserDto.pass_key != null) {
        await _webService.sendChanges(null, true);
      }
      AuthenticationDto? authenticationDto =
      await _webService.authenticateUser(WaterState.SERVER_APPROVED, true);
      if (authenticationDto != null) {
        TransmitStatus? transmitStatus = await _webService.downloadRows(
            WaterState.SERVER_APPROVED, authenticationDto.newRecords);
      }
      if (_currentUserDto.warden == WardenType.ADMIN) {
        authenticationDto =
        await _webService.authenticateUser(WaterState.SERVER_PENDING, true);
        if (authenticationDto != null)
          await _webService.downloadRows(
              WaterState.SERVER_APPROVED, authenticationDto.newRecords);
      }
      //if (_webService.taskTableReceived) {
      //  _taskNames = await _dbAccess.setupDb(_defaults);
      //  setState(() {}); // Refresh screen
      //  blank();
      //}
    } on TransmitStatusException catch (e) {
      print(e.cause);
      String? message;
      switch (e.transmitStatus) {
        case TransmitStatus.REMOTE_STATE_ERROR:
          message = e.cause;
          break;
        case TransmitStatus.SOCKET_TIMEOUT:
          message = e.sourceName;
          break;
        case TransmitStatus.USER_UPDATED:
        //AlarmReceiver.correctAlarmRange(this, false, application);
          break;
        default:
      }
      TransmitStatusDto transmitStatusDto = TransmitStatusDto(e.transmitStatus,
          message: message, userInitiated: true);
      if (e.remoteStatus != null) {
        transmitStatusDto.remoteStatus = e.remoteStatus;
        if (e.remoteStatus == RemoteStatus.CUSTOM_ERROR) {
          transmitStatusDto.message = message;
        }
      }
      _bus.eventBus.fire(transmitStatusDto);
    } on SocketException catch (e) {
      print("$e");
    }
    print('stop long op');
    //_controller.stop();
    //_controller.reset();
    return Future.value(_webService.taskTableReceived);
  }

}