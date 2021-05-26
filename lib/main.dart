import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';
import 'refresh_service.dart';
import 'web_service.dart';

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
  late ConfigurationNameDefaults _defaults;
  late UserTools _userTools;
  late DataBaseAccess _dbAccess;
  late WebService _webService;
  UserDto? _currentUserDto;
  UserStoreDto? _currentUserStoreDto;
  String? _autoCompleteValue;
  List<String> _taskNames = [];
  late Bus _bus;
  late Application _application;
  bool saveEnabled = true;
  bool _isAdmin = false;

  Future<void> initDb() async {
    _application = Application();
    await _application.getYaml();
    _userTools = UserTools();
    _dbAccess =
        DataBaseAccess(_application.smd, _application.smdSys, _userTools);
    _defaults = ConfigurationNameDefaults();
    _taskNames = await _dbAccess.setupDb(_defaults);
    await fetchUserData(true);
  }

  Future<void> fetchUserData(bool updateEmail) async {
    _currentUserDto = await _dbAccess.getCurrentUserDto();
    _currentUserStoreDto = await _dbAccess.getCurrentUserStoreDto();
    if (updateEmail) {
      String email = _currentUserStoreDto!.email.toString();
      setState(() {
        saveEnabled = email.isEmpty;
      });
      _emailTextController.text = email;
    }
    _isAdmin = await _dbAccess.isAdmin();
  }

  Future<bool> syncDatabaseFull() async {
    print('start long op');
    _webService = WebService(_application.smd, _application.smdSys, _userTools,
        _defaults, _bus.eventBus);
    await _webService.init();
    unawaited(_controller.forward());
    await fetchUserData(false);
    String? passKey = _currentUserDto!.pass_key;
    //await Future.delayed(Duration(seconds: 10), () {});
    bool isNewUser = (_currentUserDto!.id == 1);
    try {
      if (!isNewUser && _currentUserDto!.pass_key != null) {
        await _webService.sendChanges(null, true);
      }
      AuthenticationDto? authenticationDto =
          await _webService.authenticateUser(WaterState.SERVER_APPROVED, true);
      if (authenticationDto != null) {
        TransmitStatus? transmitStatus = await _webService.downloadRows(
            WaterState.SERVER_APPROVED, authenticationDto.newRecords);
      }
      if (_currentUserDto!.warden == WardenType.ADMIN) {
        authenticationDto =
            await _webService.authenticateUser(WaterState.SERVER_PENDING, true);
        if (authenticationDto != null)
          await _webService.downloadRows(
              WaterState.SERVER_APPROVED, authenticationDto.newRecords);
      }
      if (_webService.taskTableReceived) {
        _taskNames = await _dbAccess.setupDb(_defaults);
        setState(() {}); // Refresh screen
        blank();
      }
    } on TransmitStatusException catch (e) {
      print(e.cause);
      String? message;
      switch (e.transmitStatus) {
        case TransmitStatus.REMOTE_STATE_ERROR:
          message = e.cause;
          break;
        case TransmitStatus.SOCKET_TIMEOUT:
          message = e.sourceName;
          break;
        case TransmitStatus.USER_UPDATED:
          //AlarmReceiver.correctAlarmRange(this, false, application);
          break;
        default:
      }
      TransmitStatusDto transmitStatusDto = TransmitStatusDto(e.transmitStatus,
          message: message, userInitiated: true);
      if (e.remoteStatus != null) {
        transmitStatusDto.remoteStatus = e.remoteStatus;
        if (e.remoteStatus == RemoteStatus.CUSTOM_ERROR) {
          transmitStatusDto.message = message;
        }
      }
      _bus.eventBus.fire(transmitStatusDto);
    } on SocketException catch (e) {
      print("$e");
    }
    print('stop long op');
    _controller.stop();
    _controller.reset();
    return Future.value(true);
  }

  @override
  void initState() {
    super.initState();
    initDb();
    _bus = Bus(_application);
    _bus.displayServerStatus(context);

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
              await syncDatabaseFull();
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
                                  await _dbAccess.storeUser(email);
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
                          _taskNames = await _dbAccess.addTask(
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
