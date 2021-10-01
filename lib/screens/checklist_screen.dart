import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import 'package:checkbase/helpers/database_helper.dart';
import 'package:checkbase/model/template_model.dart';
import 'package:checkbase/widgets/autocomplete_input_box.dart';
import 'package:checkbase/widgets/input_box.dart';
import '../model/checklist_model.dart';

class ChecklistScreen extends StatefulWidget {

  final Checklist checklist;
  final List<ChecklistItem> items;

  const ChecklistScreen({ Key? key, required this.checklist, required this.items }) : super(key: key);

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> with RouteAware {

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider<ChecklistViewModel>(
      create: (context) {
        var viewModel = ChecklistViewModel(checklist: widget.checklist);
        viewModel.addItems(widget.items);

        return viewModel;
      },
      child: Consumer<ChecklistViewModel>(
        builder: (context, viewModel, child) => Scaffold(
          appBar: AppBar(
            title: Text(viewModel.checklist.title + (viewModel.completed ? " (completed)" : "")),
          ),
          body: ReorderableListView.builder(
            itemCount: viewModel.itemCount,
            itemBuilder: (context, index) {
              var currentItem = viewModel.getItemAt(index);

              return Dismissible(
                key: ValueKey<int>(currentItem.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: const Color.fromRGBO(255, 0, 0, 0.5),
                  child: const Icon(Icons.delete, color: Colors.white),
                  alignment: AlignmentDirectional.centerEnd
                ),
                child: CheckboxListTile(
                  key: ValueKey<int>(currentItem.id),
                  title: Text(currentItem.text),
                  value: currentItem.complete,
                  onChanged: (newValue) async {
                    await viewModel.updateItemStatus(currentItem, newValue!);
                  }
                ),
                onDismissed: (direction) {
                  viewModel.deleteItem(currentItem);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Deleted '${currentItem.text}' from checklist."),
                      action: SnackBarAction(
                        label: "Undo",
                        onPressed: () async {
                          await viewModel.restoreDeletedChecklistItem();
                        },
                      ),
                    )
                  );
                },
              );
            },
            onReorder: (oldIndex, newIndex) async {
              var item = viewModel.getItemAt(oldIndex);
              await viewModel.moveChecklistItem(item, oldIndex, newIndex);
            }
          ),
          floatingActionButton: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            animatedIconTheme: IconThemeData(size: 28.0),
            backgroundColor: Colors.blue,
            visible: true,
            curve: Curves.bounceInOut,
            children: [
              SpeedDialChild(
                child: Icon(Icons.chrome_reader_mode, color: Colors.white),
                backgroundColor: Colors.blue,
                onTap: () async {
                  var checklistItems = await DatabaseHelper.getAllChecklistItems();

                  var result = await showDialog<ChecklistItem>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AutocompleteInputBox<ChecklistItem, int>(
                        title: "Enter new list item",
                        prompt: "Enter your new item! :D",
                        items: checklistItems,
                        displayStringForOption: (item) => item.text,
                        suggestionFilter: (item, input) => item.text.toLowerCase().contains(input.toLowerCase()),
                        keyGetter: (item) => item.id,
                        buildDefault: (text) => ChecklistItem(id: 0, text: text)
                      );
                    }
                  );

                  if (result != null) {
                    await viewModel.addItem(result);
                  }

                  await viewModel.refreshItems();
                },
                label: "Add New Item",
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue
                ),
                labelBackgroundColor: Colors.white,
              ),

              SpeedDialChild(
                child: Icon(Icons.chrome_reader_mode, color: Colors.white),
                label: "Create Template From List",
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue
                ),
                labelBackgroundColor: Colors.white,
                backgroundColor: Colors.blue,
                onTap: () async {
                  var templateName = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return InputBox(
                        title: "New Template from Checklist",
                        prompt: "Enter name for your new template:",
                      );
                    }
                  );

                  if (templateName != null && templateName != "") {
                    DatabaseHelper.createTemplateFromChecklist(new ChecklistTemplate(name: templateName), viewModel.checklist);
                  }

                  await viewModel.refreshItems();
                },
              )
            ],
          )
        )
      )
    );
  }
}