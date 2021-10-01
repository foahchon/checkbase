import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:checkbase/model/checklist_model.dart';
import 'package:checkbase/widgets/input_box.dart';
import 'package:checkbase/helpers/database_helper.dart';
import 'package:checkbase/model/edit_checklist_items_model.dart';

class EditChecklistItemsScreen extends StatefulWidget {
  const EditChecklistItemsScreen({Key? key }) : super(key: key);

  @override
  _EditChecklistItemsScreen createState() => _EditChecklistItemsScreen();
}

class _EditChecklistItemsScreen extends State<EditChecklistItemsScreen> {
  final _textEditingController = TextEditingController();
  List<ChecklistItem> _searchResults = List.empty(growable: true);
  late final EditChecklistItemsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditChecklistItemsViewModel>(
      create: (context) {
        viewModel = EditChecklistItemsViewModel();
        
        DatabaseHelper.getAllChecklistItems().then((items) {
          viewModel.addAllChecklistItems(items);
        });
        
        return viewModel;
      },
      child: Consumer<EditChecklistItemsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Edit Checklist Items"),
            ),
            body: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    hintText: "Enter a search term"
                  ),
                  controller: _textEditingController,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length != 0 ? _searchResults.length : viewModel.getChecklistItemCount(),
                    itemBuilder: (context, index) {
                      var currentChecklistItem = _searchResults.length != 0 ? _searchResults[index] : viewModel.getItemAt(index);

                      return ListTile(
                        key: ValueKey<int>(currentChecklistItem.id),
                        title: Text(currentChecklistItem.text),
                        onLongPress: () async {
                          var newText = await showDialog<String>(
                            context: context,
                            barrierDismissible: false,
                            builder: (buildContext) {
                              return InputBox(
                                title: "Edit List Item",
                                prompt: "Enter new description:",
                                defaultValue: currentChecklistItem.text,
                              );
                            }
                          );

                          if (newText != null) {
                            viewModel.updateChecklistItem(currentChecklistItem, newText);
                          }
                        },
                      );
                    },
                  ),
                )
              ],
            )
          );
        }
      )
    );
  }

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      setState(() {
        if (_textEditingController.text.isNotEmpty) {
          _searchResults = viewModel.getFiltered(_textEditingController.text).toList();
        }
        else {
          _searchResults = [];
        }
      });
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}