import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:rockvole_replicator_todo/helpers/SqfliteHelper.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:rockvole_db/rockvole_sqflite.dart';
import 'package:sqflite/sqflite.dart';

import 'dao/TaskDao.dart';
import 'dao/TaskHcDao.dart';
import 'dao/TaskMixin.dart';

class DataBaseAccess {
  late SchemaMetaData smd;
  late SchemaMetaData smdSys;
  late List<TaskDto> _taskList;
  late TaskDao _taskDao;
  WardenType _localWardenType = WardenType.USER;
  WardenType _remoteWardenType = WardenType.USER;

  Future<void> getYaml() async {
    String yamlString =
    await rootBundle.loadString('ancillary/assets/todo_schema.yaml');
    YamlMap yaml = loadYaml(yamlString);
    smd = SchemaMetaData.yaml(yaml);
    smd = SchemaMetaDataTools.createSchemaMetaData(smd);
    smdSys = TransactionTools.createHcSchemaMetaData(smd);
  }

  Future<List<String>> setupDb(ConfigurationNameDefaults defaults) async {
    List<String> taskNames = [];
    await getYaml();
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    // Initialise Configuration table
    ConfigurationDao configurationDao=ConfigurationDao(smd, transaction, defaults);
    await configurationDao.init(initTable: false);
    await configurationDao.insertDefaultValues();

    UserDao userDao = UserDao(smd, transaction);
    await userDao.init();
    int rowCount = await userDao.getRowCount();
    if(rowCount==0) {
      UserDto userDto = UserDto.sep(1,null,0,WardenType.USER,0,0);
      await userDao.insertDto(userDto);
    }
    // Get list of tasks
    _taskDao = TaskDao(smd, transaction);
    await _taskDao.init(initTable: false);
    if ((await _taskDao.doesTableExist())) {
      try {
        _taskList = await _taskDao.getTaskListByName(null);
        _taskList.forEach((TaskDto taskDto) {
          taskNames.add(taskDto.task_description!);
        });
        taskNames.sort();
      } on SqlException {
      }
    } else {
      await _taskDao.createTable();
    }
    await db.close();
    return taskNames;
  }

  Future<List<String>> addTask(String task_description, bool task_complete, List<String> taskNames) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    AbstractWarden abstractWarden =
    ClientWardenFactory.getAbstractWarden(_localWardenType, _remoteWardenType);
    await abstractWarden.init(TaskMixin.C_TABLE_ID, smd, smdSys, transaction);
    HcDto hcDto = HcDto.sep(null, OperationType.INSERT, 99, null, 'Insert Task',
        null, TaskMixin.C_TABLE_ID);
    TaskHcDto taskHcDto =
    TaskHcDto.sep(null, task_description, task_complete, hcDto);
    AbstractTableTransactions tableTransactions =
    TableTransactions.sep(taskHcDto, TaskMixin.C_TABLE_ID);
    await tableTransactions.init(_localWardenType, _remoteWardenType, smd, smdSys, transaction);
    abstractWarden.initialize(tableTransactions);
    try {
      await abstractWarden.write();
      taskNames.add(task_description);
      taskNames.sort();
    } on SqlException catch (e) {
      print(e);
    }
    await db.close();
    return taskNames;
  }

  static Future<AbstractDatabase> getConnection() async {
    var databasesPath = (await getDatabasesPath()).toString() + "/task_data.db";
    AbstractDatabase db = SqfliteDatabase.filename(databasesPath);
    await db.connect();
    return db;
  }

  static Future<DbTransaction> getTransaction() async {
    DbTransaction transaction = await SqfliteHelper.getSqfliteDbTransaction(
        'task_data', (await getDatabasesPath()).toString());
    return transaction;
  }

}