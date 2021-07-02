import 'package:flutter/material.dart';
import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';

class AdminPage extends StatefulWidget {
  AdminPage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Application _application;

  Future<List<TaskHcDto>> fetchTasks() async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    List<TaskHcDto> taskHcDtoList = await _application.dbAccess.fetchTaskHcList(transaction);
    await db.close();
    return taskHcDtoList;
  }

  @override
  void initState() {
    super.initState();
    _application = Application();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Approvals'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
            padding: EdgeInsets.all(8),
            child: FutureBuilder<List<TaskHcDto>>(
                future: fetchTasks(),
                initialData: [],
                builder: (BuildContext context,
                    AsyncSnapshot<List<TaskHcDto>> snapshot) {
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, position) {
                        return Row(children: [
                          Text(snapshot.data![position].task_description!),
                          Spacer(),
                          IconButton(
                              onPressed: null,
                              icon: Icon(Icons.cancel, color: Colors.red)),
                          IconButton(
                              onPressed: null,
                              icon:
                                  Icon(Icons.check_circle, color: Colors.green))
                        ]);
                      });
                })));
  }
}
