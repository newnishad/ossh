import 'package:flutter/material.dart';
import 'package:ssh/ssh.dart';
import 'package:sqflite/sqflite.dart';
import 'widgets.dart';

class AddSSH extends StatefulWidget {
  final update;
  final id;
  final hostname;
  final username;
  final password;
  final port;
  AddSSH(
      {this.id,
      this.update = false,
      this.hostname = "",
      this.username = "",
      this.password = "",
      this.port = 22});
  @override
  _AddSSHState createState() => _AddSSHState();
}

class _AddSSHState extends State<AddSSH> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String hostname;
  String username;
  String password;
  int port;
  var width;
  var height;

  @override
  void initState() {
    hostname = widget.hostname;
    username = widget.username;
    password = widget.password;
    port = widget.port;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.update ? "Update" : "Add",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Container(
        height: height - MediaQuery.of(context).padding.top,
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  initialValue: hostname,
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Can't be empty";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    hostname = value;
                  },
                  decoration: InputDecoration(
                    labelText: "Hostname",
                  ),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                TextFormField(
                  initialValue: username,
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Can't be empty";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    username = value;
                  },
                  decoration: InputDecoration(
                    labelText: "Username",
                  ),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                TextFormField(
                  initialValue: password,
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Can't be empty";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    password = value;
                  },
                  decoration: InputDecoration(
                    labelText: "Password",
                  ),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: port.toString(),
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Can't be empty";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    port = int.parse(value);
                  },
                  decoration: InputDecoration(
                    labelText: "Port",
                  ),
                ),
                SizedBox(
                  height: height * 0.04,
                ),
                RaisedButton(
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    _formKey.currentState.save();
                    if (!_formKey.currentState.validate()) {
                      return;
                    }
                    connect(context);
                  },
                  child: Text(
                    widget.update ? "Update Profile" : "Add Profile",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  height: height * 0.04,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future connect(context) async {
    CustomWidgets.loadingDialog(context);
    var client = new SSHClient(
      host: hostname,
      port: port,
      username: username,
      passwordOrKey: password,
    );
    client.connect().then((response) {
      if (response.toString() == "session_connected") {
        print("Connected Successfully");
        _insertProfile(
          context: context,
          hostname: hostname,
          username: username,
          password: password,
          port: port,
        );
      } else {
        print("Connection Failed");
        Navigator.pop(context);
      }
    }).catchError((e) {
      print("Exception: Connection Failed!");
      Navigator.pop(context);
    });
  }

  _insertProfile({
    @required context,
    @required hostname,
    @required username,
    @required password,
    @required port,
  }) async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + 'ssh.db';

    Database database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE profiles (id INTEGER PRIMARY KEY, hostname TEXT, username TEXT, password TEXT, port INTEGER, lastused TEXT)',
        );
      },
    );

    if (widget.update) {
      await database.rawUpdate(
          'UPDATE profiles SET hostname = ?, username = ?, password = ?, port = ? WHERE id = ?',
          [
            hostname,
            username,
            password,
            port,
            widget.id,
          ]);
    } else {
      await database.transaction((txn) async {
        int id = await txn.rawInsert(
          'INSERT INTO profiles(hostname, username, password, port, lastused) VALUES("$hostname", "$username", "$password",$port, "${DateTime.now()}")',
        );
        print(id);
      });
    }

    Navigator.pop(context);
    Navigator.pop(context);
  }
}
