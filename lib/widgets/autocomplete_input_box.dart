import 'package:flutter/material.dart';

class AutocompleteInputBox<TItem extends Object, TKey> extends StatefulWidget {

  final String title;
  final String prompt;
  final String defaultValue;
  final String okButtonText;
  final String cancelButtonText;
  final List<TItem> items;
  final String Function(TItem obj) displayStringForOption;
  final bool Function(TItem obj, String str) suggestionFilter;
  final TKey Function(TItem obj) keyGetter;
  final TItem Function(String text) buildDefault;

  AutocompleteInputBox({Key? key,
                  required this.title,
                  required this.prompt,
                  this.defaultValue = "",
                  this.okButtonText = "OK",
                  this.cancelButtonText = "Cancel",
                  required this.items,
                  required this.displayStringForOption,
                  required this.suggestionFilter,
                  required this.keyGetter,
                  required this.buildDefault
                }) : super(key: key);

  @override
  State<AutocompleteInputBox<TItem, TKey>> createState() => _AutocompleteInputBoxState<TItem, TKey>();
}

class _AutocompleteInputBoxState<TItem extends Object, TKey> extends State<AutocompleteInputBox<TItem, TKey>> {

  TItem? _selection;

  @override
  Widget build(BuildContext context) {
    TextEditingValue textEdit = TextEditingValue();
    
    return AlertDialog(
      title: Text(widget.title),
      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.prompt),
            Autocomplete<TItem>(
              optionsBuilder: (textEditingValue) {
                textEdit = textEditingValue;
                if (textEditingValue.text == "") {
                  return Iterable<TItem>.empty();
                }
                return widget.items.where((item) => widget.suggestionFilter(item, textEdit.text));
              },

              displayStringForOption: widget.displayStringForOption,

              onSelected: (selection) {
                _selection = selection;
              },
            )
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(widget.okButtonText),
          onPressed: () {
            var result = _selection ?? widget.buildDefault(textEdit.text);
            Navigator.pop<TItem>(context, result);
          }
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
}