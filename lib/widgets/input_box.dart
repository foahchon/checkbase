import 'package:flutter/material.dart';

class InputBox extends StatefulWidget {

  final String title;
  final String prompt;
  final String defaultValue;
  final String okButtonText;
  final String cancelButtonText;

  InputBox({Key? key,
                  this.title = "",
                  this.prompt = "",
                  this.defaultValue = "",
                  this.okButtonText = "OK",
                  this.cancelButtonText = "Cancel"
                }) : super(key: key);

  _InputBoxState createState() => _InputBoxState();
}

class _InputBoxState extends State<InputBox> {
  final TextEditingController _editingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _editingController.text = widget.defaultValue;

    return AlertDialog(
      title: Text(widget.title),
      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.prompt),
            TextField(controller: _editingController),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(widget.okButtonText),
          onPressed: () {
            Navigator.pop(context, _editingController.text);
          },
        ),
        TextButton(
          child: Text(widget.cancelButtonText),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ],
    );
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }
}