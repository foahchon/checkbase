import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:checkbase/helpers/deleted_list.dart';
import 'package:checkbase/model/checklist_model.dart';
import 'package:checkbase/helpers/database_helper.dart';

class AllChecklistsViewModel with ChangeNotifier {
  DeletedList<Checklist, ChecklistItem>? undoItem;
  List<Checklist> _items = List<Checklist>.empty(growable: true);

  Checklist getChecklistAt(int index) => _items[index];
  int getChecklistCount() => _items.length;

  Future<void> addChecklist(Checklist checklist) async {
    _items.add(checklist);
    await DatabaseHelper.addChecklist(checklist);

    notifyListeners();
  }

  void addAllChecklists(List<Checklist> items) {
    _items.addAll(items);
    notifyListeners();
  }

  Future<void> deleteChecklist(Checklist checklist) async {
    var checklistItems = await DatabaseHelper.getItemsForChecklist(checklist);
    undoItem = DeletedList<Checklist, ChecklistItem>(obj: checklist, objItems: checklistItems);

    await DatabaseHelper.deleteChecklist(checklist);
    _items.remove(checklist);

    notifyListeners();
  }
  
  Future<void> restoreDeletedChecklist() async {
    if (undoItem != null) {
      var checklist = undoItem!.obj;
      var originalListOrder = checklist.listOrder;
      await addChecklist(checklist);
      await moveChecklist(checklist, checklist.listOrder, originalListOrder);

      undoItem!.objItems.forEach((checklistItem) async {
        await DatabaseHelper.addItemToChecklist(checklist, checklistItem);
        await DatabaseHelper.updateChecklistItemOrder(checklist, checklistItem, checklistItem.listOrder);
       });

      notifyListeners();
    }
  }

  Future<void> moveChecklist(Checklist checklist, int oldIndex, int newIndex) async {
      if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    var item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    checklist.listOrder = newIndex;
    DatabaseHelper.updateChecklistOrder(checklist, oldIndex);
  }

  Future<void> refreshItems() async {
    _items.clear();
    _items.addAll(await DatabaseHelper.getAllChecklists());

    notifyListeners();
  }

  Future<void> updateItem(Checklist checklist) async {
    var itemToUpdate = _items.firstWhereOrNull((element) => element.id == checklist.id);
    await DatabaseHelper.refreshChecklist(itemToUpdate);
    
    notifyListeners();
  }
}