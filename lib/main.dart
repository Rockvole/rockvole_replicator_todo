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
  late AnimationController _controller;
  late Animation colorAnimation;
  late Animation rotateAnimation;
  FocusNode _focusNode = FocusNode();
  late ConfigurationNameDefaults _defaults;
  late UserTools _userTools;
  late DataBaseAccess _dbAccess;
  late WebService _webService;
  UserDto? _currentUserDto;
  String? _autoCompleteValue;
  List<String> _taskNames = [];
  late Bus bus;
  late Application _application;

  Future<void> initDb() async {
    _application = Application();
    _dbAccess = DataBaseAccess();
    _defaults = ConfigurationNameDefaults();
    _taskNames = await _dbAccess.setupDb(_defaults);
    _userTools = UserTools();
    _currentUserDto =
        await _dbAccess.getCurrentUserDto(_dbAccess.smd, _userTools);
    _webService = WebService(
        _dbAccess.smd, _dbAccess.smdSys, _userTools, _defaults, bus.eventBus);
    await _webService.init();
  }

  Future<bool> syncDatabaseFull() async {
    print('start long op');
    unawaited(_controller.forward());
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
      bus.eventBus.fire(transmitStatusDto);
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
    bus = Bus(_application);
    bus.displayServerStatus(context);

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
        actions: <Widget>[
          AnimatedSync(
            animation: rotateAnimation as Animation<double>,
            callback: () async {
              await syncDatabaseFull();
            },
          ),
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
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: 'E-Mail',
                      hintText: 'Enter Your E-Mail address'),
                )),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: OutlinedButton(
                        onPressed: () {
                          print('hi');
                        },
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
