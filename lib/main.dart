import 'dart:io';
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
  late SchemaMetaData smd;
  late SchemaMetaData smdSys;

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

    TaskDao taskDao = TaskDao(smd, transaction);
    await taskDao.init();
    await taskDao.createTable();
    await db.close();
  }

  @override
  void initState() {
    super.initState();
    setupDb();
  }

  @override
  Widget build(BuildContext context) {
    int? _chosenValue = 2;
    Map<int, String> nameMap = {
      1: 'Android',
      2: 'IOS',
      3: 'Flutter',
      4: 'Node',
      5: 'Java',
      6: 'Python',
      7: 'PHP'
    };
    List<DropdownMenuItem<int>> menuItemList = [];
    nameMap.forEach((key, value) {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton<int>(
              focusColor: Colors.white,
              value: _chosenValue,
              //elevation: 5,
              style: TextStyle(color: Colors.white),
              iconEnabledColor: Colors.black,
              items: menuItemList,
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
            Text(
              'Hello',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
    );
  }
}
