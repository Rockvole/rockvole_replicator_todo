import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

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
  initialize() {
    serverStatus=ServerStatus.COMPLETE;
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
