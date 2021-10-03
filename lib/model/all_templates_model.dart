import 'package:flutter/material.dart';

import 'package:checkbase/helpers/database_helper.dart';
import 'package:checkbase/helpers/deleted_list.dart';
import 'package:checkbase/model/template_model.dart';

class TemplatesViewModel with ChangeNotifier {
  List<ChecklistTemplate> _templates = <ChecklistTemplate>[];
  DeletedList<ChecklistTemplate, TemplateItem>? undoItem;
  
  int getTemplateCount() => _templates.length;

  Future<void> addTemplate(ChecklistTemplate template) async {
    await DatabaseHelper.addTemplate(template);
    _templates.add(template);
    notifyListeners();
  }
  
  Future<void> addTemplates(List<ChecklistTemplate> items) async {
    _templates.addAll(items);
    notifyListeners();
  }
  
  Future<void> refreshItems() async {
    _templates.clear();
    _templates.addAll(await DatabaseHelper.getAllTemplates());
    notifyListeners();
  }
  
  ChecklistTemplate getTemplateAt(int index) {
    return _templates[index];
  }
  
  Future<void> deleteTemplate(ChecklistTemplate template) async {
    var templateItems = await DatabaseHelper.getItemsForTemplate(template);
    await DatabaseHelper.deleteTemplate(template);
    undoItem = DeletedList<ChecklistTemplate, TemplateItem>(obj: template, objItems: templateItems);
    
    _templates.remove(template);
    notifyListeners();
  }
  
  Future<void> restoreDeletedTemplate() async {
    if (undoItem != null) {
      var template = undoItem!.obj;
      var originalListOrder = template.listOrder;

      await addTemplate(template);
      await moveTemplate(template, template.listOrder, originalListOrder);

      undoItem!.objItems.forEach((templateItem) async {
        await DatabaseHelper.addItemToTemplate(template, templateItem);
        await DatabaseHelper.updateTemplateItemOrder(template, templateItem, templateItem.listOrder);
      });

      notifyListeners();
    }
  }
  
  Future<void> moveTemplate(ChecklistTemplate template, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    var item = _templates.removeAt(oldIndex);
    _templates.insert(newIndex, item);

    item.listOrder = newIndex;
    await DatabaseHelper.updateTemplateOrder(template, oldIndex, newIndex);
  }




}