import 'package:flutter/material.dart';
import 'package:ssh/ssh.dart';

class Shell extends StatefulWidget {
  final SSHClient client;
  final title;
  Shell(this.client, this.title);
  @override
  _ShellState createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final TextEditingController _controller = new TextEditingController();
  String result = "";
  bool _refreshShell = true;
  FocusNode commandFocusNode;
  var width;
  var height;
  String cmd = "";

  @override
  void initState() {
    commandFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    widget.client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    if (_refreshShell) {
      _readShell();
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.02,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                _refreshShell ? Text("Loading") : SelectableText(result),
                TextFormField(
                  controller: _controller,
                  onChanged: (value) {
                    cmd = value;
                  },
                  focusNode: commandFocusNode,
                  onEditingComplete: () {
                    commandFocusNode.unfocus();
                    _writeToShell(cmd);
                    _controller.clear();
                  },
                  decoration: InputDecoration(labelText: "Command"),
                ),
              ],
            )),
      ),
    );
  }

  _readShell() async {
    await widget.client.startShell(
      ptyType: "xterm", // defaults to vanilla
      callback: (dynamic res) {
        print(res); // read from shell
        setState(
          () {
            this.result = this.result + res.toString();
            _refreshShell = false;
          },
        );
      },
    );
  }

  _writeToShell(String cmd) async {
    await widget.client.writeToShell("$cmd\n");
  }
}
