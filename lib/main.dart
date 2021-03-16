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
  List<String> _kOptions = [];
  late List<TaskDto> _taskList;
  int? _chosenValue = 2;
  Map<int, String> _nameMap = {
    1: 'Android',
    2: 'IOS',
    3: 'Flutter',
    4: 'Node',
    5: 'Java',
    6: 'Python',
    7: 'PHP'
  };
  late SchemaMetaData smd;
  late SchemaMetaData smdSys;
  late TaskDao _taskDao;

  Future<void> getYaml() async {
    String yamlString =
        await rootBundle.loadString('ancillary/assets/todo_schema.yaml');
    YamlMap yaml = loadYaml(yamlString);
    smd = SchemaMetaData.yaml(yaml);
    smd = SchemaMetaDataTools.createSchemaMetaData(smd);
    SchemaMetaData smdSys = TransactionTools.createHcSchemaMetaData(smd);
  }

  Future<void> setupDb() async {
    await getYaml();
    ConfigurationNameDefaults defaults = ConfigurationNameDefaults();

    var databasesPath = (await getDatabasesPath()).toString() + "/task_data.db";
    AbstractDatabase db = SqfliteDatabase.filename(databasesPath);
    await db.connect();
    DbTransaction transaction = await SqfliteHelper.getSqfliteDbTransaction(
        'task_data', (await getDatabasesPath()).toString());

    _taskDao = TaskDao(smd, transaction);
    await _taskDao.init(initTable: false);
    if ((await _taskDao.doesTableExist())) {
      _taskList = await _taskDao.getTaskListByName(null);
      _taskList.forEach((TaskDto taskDto) {
        _kOptions.add(taskDto.task_description!);
      });
    } else {
      await _taskDao.createTable();
    }
    //await db.close();
  }

  Future<void> addTask(
      int id, String task_description, bool task_complete) async {
    TaskDto taskDto = TaskDto.wee(id, task_description, task_complete);
    await _taskDao.insertDto(taskDto);
  }

  @override
  void initState() {
    super.initState();
    setupDb();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    print("chosen=" + _nameMap[_chosenValue].toString());
    addTask(_chosenValue!, _nameMap[_chosenValue]!, false);
  }

  @override
  Widget build(BuildContext context) {

    String _autocompleteSelection;
    List<Widget> nameList = [];
    List<DropdownMenuItem<int>> menuItemList = [];
    _nameMap.forEach((key, value) {
      nameList.add(Text(value, style: TextStyle(color: Colors.black)));
      menuItemList.add(DropdownMenuItem<int>(
        value: key,
        child: Text(
          value,
          style: TextStyle(color: Colors.black),
        ),
      ));
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            DropdownButton<int>(
              //focusColor: Colors.white,
              value: _chosenValue,
              //elevation: 5,
              style: TextStyle(color: Colors.blue, fontSize: 18),
              iconEnabledColor: Colors.black,
              items: menuItemList,
              //selectedItemBuilder: (BuildContext context) {
              //  return nameList;
              //},
              hint: Text(
                "Please choose a language",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              onChanged: (int? value) {
                setState(() {
                  _chosenValue = value;
                });
              },
            ),
            RawAutocomplete(
                optionsBuilder: (TextEditingValue textEditingValue) {
              return _kOptions.where((String option) {
                return option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            }, onSelected: (String selection) {
              setState(() {
                _autocompleteSelection = selection;
              });
            }, fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                decoration: InputDecoration(
                  hintText: 'This is an RawAutocomplete 2.0',
                ),
                focusNode: focusNode,
                onFieldSubmitted: (String value) {
                  onFieldSubmitted();
                },
                validator: (String? value) {
                  if (!_kOptions.contains(value)) {
                    return 'Nothing selected.';
                  }
                  return null;
                },
              );
            }, optionsViewBuilder: (BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: SizedBox(
                    height: 300.0,
                    child: ListView(
                      children: options
                          .map((String option) => GestureDetector(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: ListTile(
                                  title: Card(
                                      child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      option,
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
            })
          ],
        ),
      ),
    );
  }
}
