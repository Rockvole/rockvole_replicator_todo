import 'package:flutter/material.dart';
import 'package:rockvole_db_replicator/rockvole_db.dart';
import 'package:rockvole_db_replicator/rockvole_transactions.dart';
import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';

class AdminPage extends StatefulWidget {
  AdminPage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Application _application;

  Future<List<TaskTrDto>?> fetchTasks() async {
    AbstractDatabase db = await DataBaseAccess.getConnection();
    DbTransaction transaction = await DataBaseAccess.getTransaction();
    List<TaskTrDto>? taskTrDtoList =
        await _application.dbAccess.fetchTaskTrList(transaction);
    if (taskTrDtoList.length == 0) taskTrDtoList = null;
    await db.close();
    return taskTrDtoList;
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
        body: Column(children: [
          Padding(
              padding: EdgeInsets.all(10.0),
              child: FutureBuilder<List<TaskTrDto>?>(
                  future: fetchTasks(),
                  initialData: [],
                  builder: (BuildContext context,
                      AsyncSnapshot<List<TaskTrDto>?> snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, position) {
                            return Row(children: [
                              Text(snapshot.data![position].task_description!),
                              Spacer(),
                              IconButton(
                                  onPressed: () async {
                                    WaterLineDto? waterLineDto =
                                        await _application.dbAccess
                                            .setWaterLineState(
                                                snapshot.data![position].ts!,
                                                WaterState.CLIENT_REJECTED);
                                    await _application.dbAccess
                                        .cleanRows(waterLineDto);
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.cancel, color: Colors.red)),
                              IconButton(
                                  onPressed: () async {
                                    await _application.dbAccess
                                        .setWaterLineState(
                                            snapshot.data![position].ts!,
                                            WaterState.CLIENT_APPROVED);
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.check_circle,
                                      color: Colors.green))
                            ]);
                          });
                    } else {
                      return Text("No items for Approval / Rejection found",
                          style: TextStyle(fontSize: 18));
                    }
                  })),
          Spacer(),
          Row(children: [
            Expanded(
              child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: OutlinedButton(
                      onPressed: () async {
                        await _application.dbAccess.dropWaterLine();
                      },
                      child: Text("Clear Water Line"))),
            )
          ])
        ]));
  }
}
