import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  AdminPage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final List<Map> myProducts =
      List.generate(1000, (index) => {"id": index, "name": "Product $index"})
          .toList();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approvals'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: ListView.builder(
            itemCount: myProducts.length,
            itemBuilder: (context, position) {
              return Row(children: [
                Text(myProducts[position]['name']),
                Spacer(),
                IconButton(
                    onPressed: null,
                    icon: Icon(Icons.cancel, color: Colors.red)),
                IconButton(
                    onPressed: null,
                    icon: Icon(Icons.check_circle, color: Colors.green))
              ]);
            }),
      ),
    );
  }
}
