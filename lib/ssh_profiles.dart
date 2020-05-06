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
                    return GestureDetector(
                      onTap: () {
                        _updateLastUsed(profile: profiles[index]);
                        connect(
                          context: context,
                          hostname: profiles[index]['hostname'],
                          username: profiles[index]['username'],
                          password: profiles[index]['password'],
                          port: profiles[index]['port'],
                        );
                      },
                      onLongPress: () {
                        CustomWidgets.editDeleteDialog(
                          context: context,
                          profile: profiles[index],
                          index: index,
                          editTap: () {
                            Navigator.pop(context);
                            _update(
                              context: context,
                              id: profiles[index]['id'],
                              hostname: profiles[index]['hostname'],
                              username: profiles[index]['username'],
                              password: profiles[index]['password'],
                              port: profiles[index]['port'],
                            );
                          },
                          deleteTap: () {
                            Navigator.pop(context);
                            _deleteProfile(profiles[index]['id']);
                          },
                        );
                      },
                      child: ListTile(
                        title: Text(
                          "${profiles[index]['username']}@${profiles[index]['hostname']}:${profiles[index]['port']}",
                        ),
                        subtitle:
                            Text("Last used: ${time(profiles[index]['lastused'])}"),
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
    var result = await database.rawQuery('SELECT * FROM profiles');
    setState(() {
      profiles = result;
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
        _navigateToShell(
          context: context,
          client: client,
          title: "$username@$hostname:$port",
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

  _navigateToShell(
      {@required context, @required client, @required title}) async {
    var reply = Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => Shell(
          client,
          title,
        ),
      ),
    );
    print("Reply: $reply");
    if (reply.toString() != "anything") {
      setState(() {
        _isLoading = true;
      });
      _loadProfiles();
    }
  }

  _add(context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => AddSSH(),
      ),
    );
    print("Back from add screen");
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

  _updateLastUsed({
    @required profile,
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

    await database.rawUpdate(
        'UPDATE profiles SET hostname = ?, username = ?, password = ?, port = ?, lastused = ? WHERE id = ?',
        [
          profile['hostname'],
          profile['username'],
          profile['password'],
          profile['port'],
          DateTime.now().toString(),
          profile['id'],
        ]);
  }

  String time(text) {
    var time = DateTime.parse(text);
    String month;
    String day = time.day.toString();
    String year = time.year.toString();
    switch (time.month) {
      case 1:
        month = "January";
        break;
      case 2:
        month = "February";
        break;
      case 3:
        month = "March";
        break;
      case 4:
        month = "April";
        break;
      case 5:
        month = "May";
        break;
      case 6:
        month = "June";
        break;
      case 7:
        month = "July";
        break;
      case 8:
        month = "August";
        break;
      case 9:
        month = "September";
        break;
      case 10:
        month = "October";
        break;
      case 11:
        month = "November";
        break;
      case 12:
        month = "December";
        break;
    }
    return "$month $day, $year";
  }
}
