import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import 'package:checkbase/model/checklist_model.dart';
import 'package:checkbase/screens/checklist_screen.dart';
import 'package:checkbase/widgets/autocomplete_input_box.dart';
import 'package:checkbase/helpers/database_helper.dart';
import 'package:checkbase/model/template_model.dart';
import 'package:checkbase/widgets/input_box.dart';

class TemplateScreen extends StatefulWidget {
  
  final ChecklistTemplate template;
  final List<TemplateItem> items;

  const TemplateScreen({Key? key, required this.template, required this.items }) : super(key: key);

  @override
  _TemplateScreenState createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider<TemplateViewModel>(
      create: (context) {
        var viewModel = TemplateViewModel(template: widget.template);
        viewModel.addItems(widget.items);

        return viewModel;
      },
      child: Consumer<TemplateViewModel>(
        builder: (context, viewModel, child) => Scaffold(
          appBar: AppBar(
            title: Text(viewModel.template.name),
          ),
          body: ReorderableListView.builder(
            itemCount: viewModel.itemCount,
            itemBuilder: (context, index) {
              var currentTemplateItem = viewModel.getItemAt(index);

              return Dismissible(
                key: ValueKey<int>(currentTemplateItem.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: const Color.fromRGBO(255, 0, 0, 0.5),
                  child: const Icon(Icons.delete, color: Colors.white),
                  alignment: AlignmentDirectional.centerEnd
                ),
                child: ListTile(
                  key: ValueKey<int>(currentTemplateItem.id),
                  title: Text(currentTemplateItem.text),
                ),
                onDismissed: (direction) {
                  viewModel.deleteItem(currentTemplateItem);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Deleted '${currentTemplateItem.text}' from template."),
                      action: SnackBarAction(
                        label: "Undo",
                        onPressed: () async {
                          await viewModel.restoreDeletedTemplateItem();
                        },
                      ),
                    )
                  );
                },
              );
            },
            onReorder: (oldIndex, newIndex) async {
              var item = viewModel.getItemAt(oldIndex);
              await viewModel.moveTemplateItem(item, oldIndex, newIndex);
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
                label: "Create List From Template",
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue
                ),
                labelBackgroundColor: Colors.white,
                backgroundColor: Colors.blue,
                onTap: () async {
                  var listTitle = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return InputBox(
                        title: "New List From Template",
                        prompt: "Enter name for your new list:",
                      );
                    }
                  );

                  if (listTitle != null && listTitle.isNotEmpty) {
                    var newChecklist = Checklist(title: listTitle);
                    await DatabaseHelper.createChecklistFromTemplate(newChecklist, viewModel.template);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Created list '$listTitle.'"),
                        action: SnackBarAction(
                          label: "View",
                          onPressed: () async {
                            var items = await DatabaseHelper.getItemsForChecklist(newChecklist);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChecklistScreen(checklist: newChecklist, items: items))
                            );
                          },
                        )
                      )
                    );
                  }
                  await viewModel.refreshItems();
                },
              ),
              SpeedDialChild(
                child: Icon(Icons.chrome_reader_mode, color: Colors.white),
                label: "Add Item to Template",
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue
                ),
                labelBackgroundColor: Colors.white,
                backgroundColor: Colors.blue,
                onTap: () async {
                  var checklistItems = await DatabaseHelper.getAllChecklistItems();

                  var result = await showDialog<ChecklistItem>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AutocompleteInputBox<ChecklistItem, int>(
                        title: "New Template Item",
                        prompt: "Enter new template list item:",
                        items: checklistItems,
                        displayStringForOption: (item) => item.text,
                        suggestionFilter: (item, input ) => item.text.toLowerCase().contains(input.toLowerCase()),
                        keyGetter: (item) => item.id,
                        buildDefault: (text) => ChecklistItem(id: 0, text: text)
                      );
                    }
                  );

                  if (result != null) {
                    await viewModel.addItem(TemplateItem(id: result.id, text: result.text));
                  }
                }
              )
            ],
          )
        )
      )
    );
  }
}