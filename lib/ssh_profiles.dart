import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ssh/ssh.dart';
import 'add_ssh.dart';
import 'shell.dart';
import 'widgets.dart';

class SshProfiles extends StatefulWidget {
  @override
  _SshProfilesState createState() => _SshProfilesState();
}

class _SshProfilesState extends State<SshProfiles> {
  var width;
  var height;
  var profiles;
  bool _isLoading = true;
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      _loadProfiles();
    }
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "SSH Profiles",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _isLoading
          ? Container(
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CustomWidgets.circularProgress(),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () {
                setState(() {
                  _isLoading = true;
                });
                _loadProfiles();
                return null;
              },
              child: Container(
                child: ListView.separated(
                  separatorBuilder: (BuildContext context, index) {
                    return Divider(
                      height: 0,
                      color: Colors.black,
                    );
                  },
                  itemCount: profiles.length,
                  itemBuilder: (BuildContext context, index) {
                    var key = Key(index.toString());
                    return GestureDetector(
                      onTap: () {
                        connect(
                          context: context,
                          hostname: profiles[index]['hostname'],
                          username: profiles[index]['username'],
                          password: profiles[index]['password'],
                          port: profiles[index]['port'],
                        );
                      },
                      child: Dismissible(
                        key: key,
                        background: Container(
                          alignment: AlignmentDirectional.centerStart,
                          color: Colors.blue,
                          child: Padding(
                            padding: EdgeInsets.only(left: width * 0.04),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        secondaryBackground: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          color: Colors.redAccent,
                          child: Padding(
                            padding: EdgeInsets.only(right: width * 0.04),
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        onDismissed: (v) {
                          if (v.toString() == "DismissDirection.endToStart") {
                            _deleteProfile(profiles[index]['id']);
                          } else {
                            _update(
                              context: context,
                              id: profiles[index]['id'],
                              hostname: profiles[index]['hostname'],
                              username: profiles[index]['username'],
                              password: profiles[index]['password'],
                              port: profiles[index]['port'],
                            );
                          }
                        },
                        child: ListTile(
                          title: Text(
                            "${profiles[index]['username']}@${profiles[index]['hostname']}:${profiles[index]['port']}",
                          ),
                          subtitle:
                              Text("Last used: ${profiles[index]['lastused']}"),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _add(context);
        },
        child: Icon(
          Icons.add,
        ),
      ),
    );
  }

  _loadProfiles() async {
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

    profiles = await database.rawQuery('SELECT * FROM profiles');
    print(profiles);
    setState(() {
      _isLoading = false;
    });
  }

  _deleteProfile(id) async {
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
    database.transaction((txn) {
      txn.execute("delete from profiles where id = $id");
      _loadProfiles();
      return;
    });
  }

  Future connect({
    @required context,
    @required hostname,
    @required username,
    @required password,
    @required port,
  }) async {
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
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => Shell(
              client,
              "$username@$hostname:$port",
            ),
          ),
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

  _add(context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => AddSSH(),
      ),
    );
    setState(() {
      _isLoading = true;
    });
    _loadProfiles();
  }

  _update({context, id, hostname, username, password, port}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => AddSSH(
          id: id,
          update: true,
          hostname: hostname,
          username: username,
          password: password,
          port: port,
        ),
      ),
    );
    setState(() {
      _isLoading = true;
    });
    _loadProfiles();
  }
}
