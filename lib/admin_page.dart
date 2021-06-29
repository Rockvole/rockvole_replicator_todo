import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  AdminPage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _AdminPageState createState() => _AdminPageState();
}

class TaskStruct {
  int id;
  String taskName;
  TaskStruct(this.id, this.taskName);
}

class _AdminPageState extends State<AdminPage> {

  Future<List<TaskStruct>> fetchTasks() async {
    final List<TaskStruct> tasks =
        List.generate(1000, (index) => TaskStruct(index, "Product $index"));
    return tasks;
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
            child: FutureBuilder<List<TaskStruct>>(
                future: fetchTasks(),
                initialData: [],
                builder: (BuildContext context,
                    AsyncSnapshot<List<TaskStruct>> snapshot) {
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, position) {
                        return Row(children: [
                          Text(snapshot.data![position].taskName),
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
