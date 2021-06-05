import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';

enum ServerStatus { ERROR, TRANSMITTING, COMPLETE, USER_STOPPED }

class Application {
  static final Application _application = Application._internal();

  factory Application() {
    return _application;
  }
  Application._internal();
  // ---------------------------------------------------------------------------
  late SchemaMetaData smd;
  late SchemaMetaData smdSys;
  ServerStatus serverStatus=ServerStatus.COMPLETE;
  RemoteStatus? remoteStatus=RemoteStatus.PROCESSED_OK;
  late UserTools userTools;
  late DataBaseAccess dbAccess;
  late ConfigurationNameDefaults defaults;
  late Bus bus;

  init() async {
    await getYaml();
    serverStatus=ServerStatus.COMPLETE;
    userTools = UserTools();
    dbAccess =
        DataBaseAccess(_application.smd, _application.smdSys, userTools);
    defaults = ConfigurationNameDefaults();
    bus = Bus(_application);
  }

  Future<void> getYaml() async {
    String yamlString =
    await rootBundle.loadString('ancillary/assets/todo_schema.yaml');
    YamlMap yaml = loadYaml(yamlString);
    smd = SchemaMetaData.yaml(yaml);
    smd = SchemaMetaDataTools.createSchemaMetaData(smd);
    smdSys = TransactionTools.createHcSchemaMetaData(smd);
  }
}
