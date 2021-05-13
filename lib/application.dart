import 'package:rockvole_db/rockvole_web_services.dart';

enum ServerStatus { ERROR, TRANSMITTING, COMPLETE, USER_STOPPED }

class Application {
  static final Application _application = Application._internal();

  factory Application() {
    return _application;
  }
  Application._internal();
  // -------------------------------------------------------
  ServerStatus serverStatus=ServerStatus.COMPLETE;
  RemoteStatus? remoteStatus=RemoteStatus.PROCESSED_OK;
  initialize() {
    serverStatus=ServerStatus.COMPLETE;
  }

}
