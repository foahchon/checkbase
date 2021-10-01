import 'package:flutter/material.dart';

class Picklist<TItem, TKey> extends StatefulWidget {
  final String title;
  final String prompt;
  final String defaultValue;
  final String okButtonText;
  final String cancelButtonText;
  final List<TItem> items;
  final String Function(TItem obj) displayStringForOption;
  final TKey Function(TItem obj) keyGetter;

  Picklist({Key? key,
    required this.title,
    required this.prompt,
    this.defaultValue = "",
    this.okButtonText = "OK",
    this.cancelButtonText = "Cancel",
    required this.items,
    required this.displayStringForOption,
    required this.keyGetter
  }) : super(key: key);

  _PicklistState<TItem, TKey> createState() => _PicklistState<TItem, TKey>();
}

class _PicklistState<TItem, TKey> extends State<Picklist<TItem, TKey>> {

  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: <Widget>[
          Text(widget.title, style: Theme.of(context).textTheme.headline6),
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                var currentItem = widget.items[index];

                return InkWell(
                  child: Container(
                    color: selectedIndex == index ? Colors.black12 : Colors.transparent,
                    child: ListTile(
                      title: Text(widget.displayStringForOption(currentItem)),
                      onTap: () {
                        setState(() {
                            selectedIndex = index;
                        });
                      }
                    )
                  )
                );
              }
            )
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(child: Text(widget.okButtonText),
                  onPressed: () {
                    Navigator.pop<TItem>(context, widget.items[selectedIndex]);
                  }
                )
              ),
              Expanded(
                child: TextButton(child: Text(widget.cancelButtonText),
                  onPressed: () {
                    Navigator.pop(context);
                  }
                )
              )
            ]
          )
        ]
      )
    );
  }
}