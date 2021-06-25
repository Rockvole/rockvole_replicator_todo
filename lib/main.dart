import 'package:pedantic/pedantic.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';
import 'package:rockvole_replicator_todo/dao/TaskMixin.dart';

import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';
import 'refresh_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rockvole Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage('Rockvole Replicator Demo'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(this.title, {Key? key}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  TextEditingController _textEditingController = TextEditingController();
  late TextEditingController _emailTextController = TextEditingController();
  late AnimationController _controller;
  late Animation colorAnimation;
  late Animation rotateAnimation;
  FocusNode _focusNode = FocusNode();
  UserDto? _currentUserDto;
  UserStoreDto? _currentUserStoreDto;
  String? _autoCompleteValue;
  List<String> _taskNames = [];
  late Application _application;
  bool saveEnabled = true;
  bool _isAdmin = false;

  Future<void> initDb() async {
    _application = Application();
    await _application.init();
    _taskNames = await _application.dbAccess.setupDb(_application.defaults);
    await fetchUserData(true);
    _application.bus.displayServerStatus(context);
  }

  Future<void> fetchUserData(bool updateEmail) async {
    _currentUserDto = await _application.dbAccess.getCurrentUserDto();
    _currentUserStoreDto = await _application.dbAccess.getCurrentUserStoreDto();
    if (updateEmail && _currentUserStoreDto!=null) {
      String email = _currentUserStoreDto!.email.toString();
      setState(() {
        saveEnabled = email.isEmpty;
      });
      _emailTextController.text = email;
    }
    bool ia = await _application.dbAccess.isAdmin();
    setState(() {
      _isAdmin=ia;
    });
  }

  @override
  void initState() {
    super.initState();
    initDb();

    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 200));
    rotateAnimation =
        Tween<double>(begin: 0.0, end: 360.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void blank() {
    _textEditingController.clear();
    _autoCompleteValue = null;
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) currentFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    RestIntentService intent = RestIntentService(_application);
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
            TextEditingController taskTextController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted) {
          return TextFormField(
            controller: taskTextController,
            decoration: InputDecoration(
                hintText: 'Enter Task Name',
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
        actions: <Widget>[
          Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.all(10),
              color: Colors.orangeAccent,
              alignment: Alignment.center,
              child: Text(
                _isAdmin ? 'Admin' : 'User',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )),
          AnimatedSync(
            animation: rotateAnimation as Animation<double>,
            callback: () async {
              unawaited(_controller.forward());
              await fetchUserData(false);
              Set tableTypeSet = await intent.syncDatabaseFull(_currentUserDto!, _currentUserStoreDto!);
              if(tableTypeSet.contains(TaskMixin.C_TABLE_ID)) {
                _taskNames = await _application.dbAccess.setupDb(_application.defaults);
                setState(() {}); // Refresh screen
                blank();
              }
              if(tableTypeSet.contains(UserMixin.C_TABLE_ID)) {
                setState(() {}); // Refresh screen
                blank();
              }
              _controller.stop();
              _controller.reset();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _emailTextController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter Your E-Mail address',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          saveEnabled = true;
                        });
                        _emailTextController.clear();
                      },
                      icon: Icon(Icons.clear),
                    ),
                  ),
                )),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: OutlinedButton(
                        onPressed: saveEnabled
                            ? () async {
                                String email = _emailTextController.text;
                                if (!email.contains("@")) {
                                  await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                            title: Text('Invalid E-Mail'),
                                            content: Text(
                                                'E-Mail address must contain @'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('OK'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          ));
                                } else {
                                  await _application.dbAccess.storeUser(email);
                                  setState(() {
                                    saveEnabled = email.isEmpty;
                                  });
                                }
                              }
                            : null,
                        child: Text('Save')))
              ],
            ),
            Row(children: [
              Expanded(child: rawAutocomplete),
              Padding(
                  padding: EdgeInsets.all(10.0),
                  child: OutlinedButton(
                      onPressed: () async {
                        String text = _textEditingController.text;
                        if (_autoCompleteValue != null)
                          _taskNames = await _application.dbAccess.addTask(
                              _autoCompleteValue!, false, _taskNames);
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
