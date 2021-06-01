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
  SchemaMetaData _smd;
  SchemaMetaData _smdSys;
  late List<TaskDto> _taskList;
  late TaskDao _taskDao;
  late UserTools _userTools;
  WardenType _localWardenType = WardenType.USER;
  WardenType _remoteWardenType = WardenType.USER;

  DataBaseAccess(this._smd, this._smdSys, this._userTools);

  Future<List<String>> setupDb(ConfigurationNameDefaults defaults) async {
    List<String> taskNames = [];
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    // Initialise Configuration table
    ConfigurationDto configurationDto;
    ConfigurationDao configurationDao =
        ConfigurationDao(_smd, transaction, defaults);
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
    // Get list of tasks
    _taskDao = TaskDao(_smd, transaction);
    await _taskDao.init(initTable: false);
    if ((await _taskDao.doesTableExist())) {
      try {
        _taskList = await _taskDao.getTaskListByName(null);
        _taskList.forEach((TaskDto taskDto) {
          taskNames.add(taskDto.task_description!);
        });
        taskNames.sort();
      } on SqlException {}
    } else {
      await _taskDao.createTable();
    }
    await db.close();
    return taskNames;
  }

  Future<void> storeUser(String email) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    // Put default values in User table
    UserDao userDao = UserDao(_smd, transaction);
    await userDao.init();

    UserDto userDto = UserDto.sep(null, null, 0, WardenType.USER, 0, 0);
    int? cuId = await userDao.addDto(userDto, _localWardenType);

    // Put default values in User Store table
    UserStoreDao userStoreDao = UserStoreDao(_smd, transaction);
    await userStoreDao.init();

    UserStoreDto userStoreDto =
        UserStoreDto.sep(cuId, email, 0, 'User', 'User', 0, 0, 0);
    await userStoreDao.insertDto(userStoreDto);

    await _userTools.setCurrentUserId(_smd, transaction, cuId!);

    await db.close();
  }

  Future<List<String>> addTask(String task_description, bool task_complete,
      List<String> taskNames) async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();

    AbstractWarden abstractWarden = ClientWardenFactory.getAbstractWarden(
        _localWardenType, _remoteWardenType);
    await abstractWarden.init(TaskMixin.C_TABLE_ID, _smd, _smdSys, transaction);
    HcDto hcDto = HcDto.sep(null, OperationType.INSERT, 99, null, 'Insert Task',
        null, TaskMixin.C_TABLE_ID);
    TaskHcDto taskHcDto =
        TaskHcDto.sep(null, task_description, task_complete, hcDto);
    AbstractTableTransactions tableTransactions =
        TableTransactions.sep(taskHcDto, TaskMixin.C_TABLE_ID);
    await tableTransactions.init(
        _localWardenType, _remoteWardenType, _smd, _smdSys, transaction);
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

  Future<UserDto> getCurrentUserDto() async {
    UserDto? currentUserDto = UserDto.sep(null, null, null, null, null, null);
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    try {
      currentUserDto = await _userTools.getCurrentUserDto(_smd, transaction);
    } catch (e) {}
    await db.close();
    return currentUserDto!;
  }

  Future<UserStoreDto> getCurrentUserStoreDto() async {
    UserStoreDto? currentUserStoreDto =
        UserStoreDto.sep(null, null, null, null, null, null, null, null);
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    try {
      currentUserStoreDto =
          await _userTools.getCurrentUserStoreDto(_smd, transaction);
    } catch (e) {}
    await db.close();
    return currentUserStoreDto!;
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
    bool isAdmin = await _userTools.isAdmin(_smd, transaction);
    await db.close();
    return isAdmin;
  }
}
