import 'package:rockvole_replicator_todo/helpers/SqfliteHelper.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:rockvole_db/rockvole_sqflite.dart';
import 'package:sqflite/sqflite.dart';

import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';

class DataBaseAccess {
  Application _application;
  WardenType _localWardenType = WardenType.USER;
  WardenType _remoteWardenType = WardenType.USER;

  DataBaseAccess(this._application);

  Future<List<String>> fetchTaskList(DbTransaction transaction) async {
    List<String> taskNames = [];
    TaskDao taskDao;
    // Get list of tasks
    taskDao = TaskDao(_application.smd, transaction);
    await taskDao.init(initTable: false);
    if ((await taskDao.doesTableExist())) {
      try {
        List<TaskDto> taskList = await taskDao.getTaskListByName(null);
        taskList.forEach((TaskDto taskDto) {
          taskNames.add(taskDto.task_description!);
        });
        taskNames.sort();
      } on SqlException {}
    } else {
      await taskDao.createTable();
    }
    return taskNames;
  }

  Future<List<TaskHcDto>> fetchTaskHcList(DbTransaction transaction) async {
    List<TaskHcDto> taskHcDtoList = [];
    TaskHcDao taskHcDao;
    TaskHcDto taskHcDto;
    taskHcDao = TaskHcDao(_application.smdSys, transaction);
    await taskHcDao.init(initTable: false);

    WaterLineDao waterLineDao =
        WaterLineDao.sep(_application.smdSys, transaction);
    await waterLineDao.init();
    List<WaterLineDto> waterLineDtoList = [];
    try {
      waterLineDtoList = await waterLineDao.getWaterLineByTableType(
          TaskMixin.C_TABLE_ID, WaterState.SERVER_PENDING, null);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum != SqlExceptionEnum.ENTRY_NOT_FOUND) rethrow;
    }
    Iterator<WaterLineDto> iter = waterLineDtoList.iterator;
    while (iter.moveNext()) {
      WaterLineDto waterLineDto = iter.current;
      taskHcDto = await taskHcDao.getTaskHcDtoByTs(waterLineDto.water_ts!);
      taskHcDtoList.add(taskHcDto);
    }
    return taskHcDtoList;
  }

  Future<WaterLineDto?> setWaterLineState(
      int ts, WaterState localStateType) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    WaterLineDao waterLineDao =
        WaterLineDao.sep(_application.smdSys, transaction);
    WaterLineDto? waterLineDto;
    WaterLine waterLine =
        WaterLine(waterLineDao, _application.smdSys, transaction);
    try {
      waterLineDto = await waterLine.retrieveByTs(ts);
      waterLine.setWaterState(localStateType);
      await waterLine.updateRow();
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_UPDATE ||
          e.sqlExceptionEnum == SqlExceptionEnum.FAILED_SELECT)
        print("UI $e");
      else
        rethrow;
    } finally {
      await db.close();
    }
    return waterLineDto;
  }

  Future<void> cleanRows(WaterLineDto? waterLineDto) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    try {
      CleanTables cleanTables =
          CleanTables(_application.smd, _application.smdSys, transaction);
      await cleanTables.deleteRow(waterLineDto!, true, false, false);
    } finally {
      await db.close();
    }
  }

  Future<List<String>> setupDb(ConfigurationNameDefaults defaults) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    // Initialise Configuration table
    ConfigurationDto configurationDto;
    ConfigurationDao configurationDao =
        ConfigurationDao(_application.smd, transaction, defaults);
    await configurationDao.init(initTable: false);
    await configurationDao.insertDefaultValues();
    try {
      configurationDto = await configurationDao.getConfigurationDtoByUnique(
          0, WardenType.USER, ConfigurationNameEnum.WEB_URL, 0);
    } on SqlException catch (e) {
      if (e.sqlExceptionEnum == SqlExceptionEnum.ENTRY_NOT_FOUND) {
        configurationDto = ConfigurationDto.sep(null, 0, WardenType.USER,
            ConfigurationNameEnum.WEB_URL, 0, null, '10.0.2.2', defaults);
        await configurationDao.insertDto(configurationDto);
      }
    }
    List<String> taskNames = await fetchTaskList(transaction);
    await db.close();
    return taskNames;
  }

  Future<void> storeUser(String email) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    // Put default values in User table
    UserDao userDao = UserDao(_application.smd, transaction);
    await userDao.init();

    UserDto userDto = UserDto.sep(null, null, 0, WardenType.USER, 0, 0);
    int? cuId = await userDao.addDto(userDto, _localWardenType);

    // Put default values in User Store table
    UserStoreDao userStoreDao = UserStoreDao(_application.smd, transaction);
    await userStoreDao.init();

    UserStoreDto userStoreDto =
        UserStoreDto.sep(cuId, email, 0, 'User', 'User', 0, 0, 0);
    await userStoreDao.insertDto(userStoreDto);

    await _application.userTools
        .setCurrentUserId(_application.smd, transaction, cuId!);

    await db.close();
  }

  Future<List<String>> addTask(String task_description, bool task_complete,
      List<String> taskNames) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    AbstractWarden abstractWarden =
        WardenFactory.getAbstractWarden(_localWardenType, _remoteWardenType);
    await abstractWarden.init(TaskMixin.C_TABLE_ID, _application.smd,
        _application.smdSys, transaction);
    HcDto hcDto = HcDto.sep(null, OperationType.INSERT, 99, null, 'Insert Task',
        null, TaskMixin.C_TABLE_ID);
    TaskHcDto taskHcDto =
        TaskHcDto.sep(null, task_description, task_complete, hcDto);
    AbstractTableTransactions tableTransactions =
        TableTransactions.sep(taskHcDto, TaskMixin.C_TABLE_ID);
    await tableTransactions.init(_localWardenType, _remoteWardenType,
        _application.smd, _application.smdSys, transaction);
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

  Future<UserDto?> getCurrentUserDto() async {
    UserDto? currentUserDto = UserDto.sep(null, null, null, null, null, null);
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    try {
      currentUserDto = await _application.userTools
          .getCurrentUserDto(_application.smd, transaction);
    } catch (e) {}
    await db.close();
    return currentUserDto;
  }

  Future<UserStoreDto?> getCurrentUserStoreDto() async {
    UserStoreDto? currentUserStoreDto =
        UserStoreDto.sep(null, null, null, null, null, null, null, null);
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    try {
      currentUserStoreDto = await _application.userTools
          .getCurrentUserStoreDto(_application.smd, transaction);
    } catch (e) {}
    await db.close();
    return currentUserStoreDto;
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

  Future<bool> isAdmin() async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    bool isAdmin =
        await _application.userTools.isAdmin(_application.smd, transaction);
    await db.close();
    return isAdmin;
  }
}
