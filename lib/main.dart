import 'package:flutter/painting.dart';
import 'package:rockvole_replicator_todo/dao/TaskHcDao.dart';
import 'package:rockvole_replicator_todo/dao/TaskMixin.dart';
import 'package:rockvole_replicator_todo/helpers/SqfliteHelper.dart';
import 'package:yaml/yaml.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:rockvole_db/rockvole_sqflite.dart';
import 'package:sqflite/sqflite.dart';
import 'dao/TaskDao.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage('Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(this.title, {Key? key}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _textEditingController = TextEditingController();
  FocusNode _focusNode = FocusNode();
  String? _autoCompleteValue;
  List<String> _taskNames = [];
  late List<TaskDto> _taskList;
  late SchemaMetaData _smd;
  late SchemaMetaData _smdSys;
  late TaskDao _taskDao;
  WardenType _localWardenType = WardenType.USER;
  WardenType _remoteWardenType = WardenType.USER;

  Future<void> getYaml() async {
    String yamlString =
        await rootBundle.loadString('ancillary/assets/todo_schema.yaml');
    YamlMap yaml = loadYaml(yamlString);
    _smd = SchemaMetaData.yaml(yaml);
    _smd = SchemaMetaDataTools.createSchemaMetaData(_smd);
    _smdSys = TransactionTools.createHcSchemaMetaData(_smd);
  }

  Future<AbstractDatabase> getConnection() async {
    var databasesPath = (await getDatabasesPath()).toString() + "/task_data.db";
    AbstractDatabase db = SqfliteDatabase.filename(databasesPath);
    await db.connect();
    return db;
  }

  Future<DbTransaction> getTransaction() async {
    DbTransaction transaction = await SqfliteHelper.getSqfliteDbTransaction(
    'task_data', (await getDatabasesPath()).toString());
    return transaction;
  }

  Future<void> setupDb() async {
    await getYaml();
    AbstractDatabase db = await getConnection();
    DbTransaction transaction = await getTransaction();

    _taskDao = TaskDao(_smd, transaction);
    await _taskDao.init(initTable: false);
    if ((await _taskDao.doesTableExist())) {
      _taskList = await _taskDao.getTaskListByName(null);
      _taskList.forEach((TaskDto taskDto) {
        _taskNames.add(taskDto.task_description!);
      });
      _taskNames.sort();
    } else {
      await _taskDao.createTable();
    }
    await db.close();
  }

  Future<void> addTask(String task_description, bool task_complete) async {
    AbstractDatabase db = await getConnection();
    DbTransaction transaction = await getTransaction();

    AbstractWarden abstractWarden =
        ClientWardenFactory.getAbstractWarden(_localWardenType, _remoteWardenType);
    await abstractWarden.init(TaskMixin.C_TABLE_ID, _smd, _smdSys, transaction);
    HcDto hcDto = HcDto.sep(null, OperationType.INSERT, 99, null, 'Insert Task',
        null, TaskMixin.C_TABLE_ID);
    TaskHcDto taskHcDto =
        TaskHcDto.sep(null, task_description, task_complete, hcDto);
    AbstractTableTransactions tableTransactions =
        TableTransactions.sep(taskHcDto, TaskMixin.C_TABLE_ID);
    await tableTransactions.init(_localWardenType, _remoteWardenType, _smd, _smdSys, transaction);
    abstractWarden.initialize(tableTransactions);
    try {
      await abstractWarden.write();
      _taskNames.add(task_description);
      _taskNames.sort();
    } on SqlException catch (e) {
      print(e);
    }
    await db.close();
  }

  @override
  void initState() {
    super.initState();
    setupDb();
  }

  void blank() {
    _textEditingController.clear();
    _autoCompleteValue = null;
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) currentFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    String _autoCompleteSelection;
    RawAutocomplete rawAutocomplete = RawAutocomplete(
        textEditingController: _textEditingController,
        focusNode: _focusNode,
        optionsBuilder: (TextEditingValue textEditingValue) {
          _autoCompleteValue = textEditingValue.text;
          return _taskNames.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (Object selection) {
          setState(() {
            _autoCompleteSelection = selection as String;
          });
        },
        fieldViewBuilder: (BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted) {
          return TextFormField(
            controller: textEditingController,
            decoration: InputDecoration(
                hintText: 'This is an RawAutocomplete 2.0',
                suffixIcon: IconButton(
                  onPressed: () => blank(),
                  icon: Icon(Icons.clear),
                )),
            focusNode: focusNode,
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
            },
            validator: (String? value) {
              if (!_taskNames.contains(value)) {
                return 'Nothing selected.';
              }
              return null;
            },
          );
        },
        optionsViewBuilder: (BuildContext context,
            AutocompleteOnSelected<Object> onSelected,
            Iterable<Object> options) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: SizedBox(
                height: 300.0,
                child: ListView(
                  children: options
                      .map((Object option) => GestureDetector(
                            onTap: () {
                              onSelected(option);
                            },
                            child: ListTile(
                              title: Card(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  option as String,
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.pink),
                                ),
                              )),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          );
        });
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(children: [
              Expanded(child: rawAutocomplete),
              Padding(
                  padding: EdgeInsets.all(10.0),
                  child: OutlinedButton(
                      onPressed: () {
                        String text = _textEditingController.text;
                        if (_autoCompleteValue != null)
                          addTask(_autoCompleteValue!, false);
                        blank();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Adding $text"),
                        ));
                      },
                      child: Text('Add')))
            ]),
          ],
        ),
      ),
    );
  }
}
