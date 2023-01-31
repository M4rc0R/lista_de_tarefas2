import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(
    MaterialApp(
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todocontroller = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic>? lastRemoved;

  int? lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = jsonDecode(data);
      });
    });
  }

  void _addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _todocontroller.text;
      _todocontroller.text = "";
      newTodo["ok"] = false;
      _toDoList.add(newTodo);

      saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(
      Duration(seconds: 2),
    );

    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.greenAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _todocontroller,
                    decoration: InputDecoration(
                      labelText: 'Nova Tareda',
                      labelStyle: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addTodo,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  child: Text("ADD"),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete_forever,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
          title: Text(_toDoList[index]["title"]),
          value: _toDoList[index]["ok"],
          secondary: CircleAvatar(
            child: _toDoList[index]["ok"]
                ? Icon(
                    Icons.check,
                    color: Colors.green,
                  )
                : Icon(Icons.error, color: Colors.red),
          ),
          onChanged: (c) {
            setState(() {
              _toDoList[index]["ok"] = c;
              saveData();
            });
          }),
      onDismissed: (direction) {
        setState(() {
          lastRemoved = Map.from(_toDoList[index]);
          lastRemovedPos = index;
          _toDoList.removeAt(index);

          saveData();

          final snack = SnackBar(
            content: Text("Tarefa removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(lastRemovedPos!, lastRemovedPos);
                    saveData();
                  });
                }),
            duration: Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  /**/

  Future<File> getfile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> saveData() async {
    String data = jsonEncode(_toDoList);
    final file = await getfile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await getfile();
      return file.readAsString();
    } catch (e) {
      return null!;
    }
  }
}
