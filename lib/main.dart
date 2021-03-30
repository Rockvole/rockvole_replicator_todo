import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';

import 'database_access.dart';
import 'refresh_service.dart';

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

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  TextEditingController _textEditingController = TextEditingController();
  late AnimationController controller;
  late Animation colorAnimation;
  late Animation rotateAnimation;
  FocusNode _focusNode = FocusNode();
  late DataBaseAccess _dbAccess;
  String? _autoCompleteValue;
  List<String> _taskNames = [];

  Future<void> initDb() async {
    _dbAccess = DataBaseAccess();
    _taskNames = await _dbAccess.setupDb();
  }

  Future<bool> syncDatabaseFull() async {
    await Future.delayed(Duration(seconds: 5), () {});
    return Future.value(true);
  }

  @override
  void initState() {
    super.initState();
    initDb();

    controller =
        AnimationController(vsync: this, duration: Duration(seconds: 200));
    rotateAnimation = Tween<double>(begin: 0.0, end: 360.0).animate(controller);
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
              await controller.forward();
              await syncDatabaseFull();
              controller.stop();
              controller.reset();
            },
          ),
        ],
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
