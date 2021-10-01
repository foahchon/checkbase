import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import 'package:checkbase/model/all_checklists_model.dart';
import 'package:checkbase/model/template_model.dart';
import 'package:checkbase/screens/all_templates_screen.dart';
import 'package:checkbase/widgets/picklist.dart';
import 'package:checkbase/model/checklist_model.dart';
import 'package:checkbase/screens/checklist_screen.dart';
import 'package:checkbase/widgets/input_box.dart';
import 'package:checkbase/helpers/database_helper.dart';
import 'edit_checklist_items_screen.dart';

class AllChecklistsScreen extends StatefulWidget {
  const AllChecklistsScreen({Key? key }) : super(key: key);

  @override
  _AllChecklistsScreenState createState() => _AllChecklistsScreenState();

}

class _AllChecklistsScreenState extends State<AllChecklistsScreen> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AllChecklistsViewModel>(
      create: (context) {
        var viewModel = AllChecklistsViewModel();
        
        DatabaseHelper.getAllChecklists().then((lists) {
          viewModel.addAllChecklists(lists);
        });
        
        return viewModel;
      },
      child: Consumer<AllChecklistsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: 88,
                    child: const DrawerHeader(
                      decoration: BoxDecoration(color: Colors.blue),
                      child: Text("Navgation Menu", style: TextStyle(color: Colors.white, fontSize: 20)),
                      padding: EdgeInsets.only(top: 15, left: 10)
                    )
                  ),

                  ListTile(
                    title: const Text("Checklists"),
                    onTap: () async {
                      Navigator.pop(context);

                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllChecklistsScreen())
                      );
                    }
                  ),
                  ListTile(
                    title: const Text("Templates"),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllTemplatesScreen())
                      );
                    }
                  ),
                  ListTile(
                    title: const Text("Edit Checklist Items"),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditChecklistItemsScreen())
                      );
                    },
                  )
                ]
              )
            ),
            appBar: AppBar(
              title: Text("All Checklists"),
            ),
            body: RefreshIndicator(
              child: ReorderableListView.builder(
                itemCount: viewModel.getChecklistCount(),
                itemBuilder: (context, index) {
                  var currentChecklist = viewModel.getChecklistAt(index);

                  return Dismissible(
                    key: ValueKey<int>(currentChecklist.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: const Color.fromRGBO(255, 0, 0, 0.5),
                      child: const Icon(Icons.delete, color: Colors.white),
                      alignment: AlignmentDirectional.centerEnd
                    ),
                    child: ListTile(
                      title: Text(currentChecklist.title),
                      subtitle: Text("${currentChecklist.numComplete} out of ${currentChecklist.numItems} items complete"),
                      leading: currentChecklist.numComplete == currentChecklist.numItems ? Icon(Icons.check, color: Colors.green) : Icon(null),
                      onTap: () async {
                        var items = await DatabaseHelper.getItemsForChecklist(currentChecklist);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChecklistScreen(checklist: currentChecklist, items: items))
                        );
                        await viewModel.updateItem(currentChecklist);
                      }
                    ),
                    onDismissed: (direction) {
                      viewModel.deleteChecklist(currentChecklist);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Deleted checklist '${currentChecklist.title}.'"),
                          action: SnackBarAction(label: "Undo", onPressed: () async => await viewModel.restoreDeletedChecklist()),
                        )
                      );
                    },
                  );
                },

                onReorder: (oldIndex, newIndex) async {
                  var checklist = viewModel.getChecklistAt(oldIndex);
                  await viewModel.moveChecklist(checklist, oldIndex, newIndex);
                },
              ),
              onRefresh: () async {
                await viewModel.refreshItems();
              },
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
                    var newListTitle = await showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return InputBox(
                          title: "Enter title of new list",
                          prompt: "Enter a new title for your new list:",
                        );
                      }
                    );
                    if (newListTitle != null) {
                      viewModel.addChecklist(Checklist(title: newListTitle));
                    }
                  },
                  label: "Create",
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue
                  ),
                  labelBackgroundColor: Colors.white,
                ),

                SpeedDialChild(
                  child: Icon(Icons.chrome_reader_mode, color: Colors.white),
                  backgroundColor: Colors.blue,
                  label: "View Templates",
                  onTap: () async {
                    await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => AllTemplatesScreen())
                    );
                    viewModel.refreshItems();
                  }
                ),

                SpeedDialChild(
                  child: Icon(Icons.chrome_reader_mode, color: Colors.white),
                  backgroundColor: Colors.blue,
                  label: "Create from Template...",
                  onTap: () async {
                    var templates = await DatabaseHelper.getAllTemplates();

                    var template = await showDialog<ChecklistTemplate>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Picklist<ChecklistTemplate, int>(
                          title: "Create List from Template",
                          prompt: "Choose a template to create your list from:",
                          items: templates,
                          displayStringForOption: (item) => item.name,
                          keyGetter: (item) => item.id
                        );
                      }
                    );
                    if (template != null) {
                      var newListTitle = await showDialog<String>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return InputBox(
                            title: "Create List from Template",
                            prompt: "Enter name for new list:",
                          );
                        }
                      );

                      if (newListTitle != null && newListTitle.isNotEmpty) {
                        await DatabaseHelper.createChecklistFromTemplate(new Checklist(title: newListTitle), template);
                        await viewModel.refreshItems();
                      }
                    }
                  }
                )
              ],
            )
          );
        }
      )
    );
  }
}