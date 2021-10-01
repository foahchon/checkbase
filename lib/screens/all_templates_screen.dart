import 'package:checkbase/model/template_model.dart';
import 'package:checkbase/widgets/input_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import 'package:checkbase/helpers/database_helper.dart';
import 'package:checkbase/screens/template_screen.dart';
import '../model/all_templates_model.dart';


class AllTemplatesScreen extends StatefulWidget {
  const AllTemplatesScreen({Key? key }) : super(key: key);

  @override
  _AllTemplatesScreen createState() => _AllTemplatesScreen();
}

class _AllTemplatesScreen extends State<AllTemplatesScreen>
{
  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider<TemplatesViewModel>(
      create: (context) {
        var viewModel = TemplatesViewModel();
        viewModel.refreshItems();

        return viewModel;
      },
      child: Consumer<TemplatesViewModel>(
        builder: (context, viewModel, child) => Scaffold(
          appBar: AppBar(
            title: const Text("All Templates"),
          ),
          body: ReorderableListView.builder(
            itemCount: viewModel.getTemplateCount(),
            itemBuilder: (context, index) {
              var currentTemplate = viewModel.getTemplateAt(index);

              return Dismissible(
                key: ValueKey<int>(currentTemplate.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: const Color.fromRGBO(255, 0, 0, 0.5),
                  child: const Icon(Icons.delete, color: Colors.white),
                  alignment: AlignmentDirectional.centerEnd
                ),
                child: ListTile(
                  key: ValueKey<int>(currentTemplate.id),
                  title: Text(currentTemplate.name),
                  onTap: () async {
                    var templateItems = await DatabaseHelper.getItemsForTemplate(currentTemplate);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TemplateScreen(template: currentTemplate, items: templateItems))
                    );
                  }
                ),
                onDismissed: (direction) async {
                  await viewModel.deleteTemplate(currentTemplate);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Deleted template '${currentTemplate.name}'."),
                      action: SnackBarAction(
                        label: "Undo",
                        onPressed: () {
                          viewModel.restoreDeletedTemplate();
                        },
                      ),
                    )
                  );
                },
              );
            },
            onReorder: (oldIndex, newIndex) async {
              var item = viewModel.getTemplateAt(oldIndex);
              await viewModel.moveTemplate(item, oldIndex, newIndex);
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
                    var newTemplateName = await showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return InputBox(
                          title: "Enter title of new template",
                          prompt: "Enter a new title for your new template:",
                        );
                      }
                    );
                    if (newTemplateName != null && newTemplateName.isNotEmpty) {
                      viewModel.addTemplate(ChecklistTemplate(name: newTemplateName));
                    }
                  },
                  label: "Create New Template",
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
                )
              ],
            )
        )
      )
    );
  }
}