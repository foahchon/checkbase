import 'package:flutter/material.dart';

import 'package:checkbase/model/template_model.dart';
import 'package:checkbase/helpers/database_helper.dart';
import 'package:checkbase/helpers/deleted_item.dart';

class ChecklistViewModel with ChangeNotifier {

  Checklist checklist;
  List<ChecklistItem> _items = <ChecklistItem>[];
  DeletedItem<ChecklistItem>? _deletedItem;

  ChecklistViewModel({ required this.checklist });

  bool get completed => _items.every((item) => item.complete);
  int get itemCount => _items.length;

  Future<void> addItem(ChecklistItem checklistItem) async {
    await DatabaseHelper.addItemToChecklist(checklist, checklistItem);
    _items.add(checklistItem);
    notifyListeners();
  }

  ChecklistItem getItemAt(int index) => _items[index];

  Future<void> updateItemStatus(ChecklistItem item, bool isComplete) async {
    await DatabaseHelper.updateChecklistItemStatus(checklist, item, isComplete);
    notifyListeners();
  }

  void addItems(List<ChecklistItem> items) {
    _items.addAll(items);
  }

  Future<void> refreshItems() async {
    _items.clear();
    _items.addAll(await DatabaseHelper.getItemsForChecklist(checklist));
    notifyListeners();
  }

  Future<void> moveChecklistItem(ChecklistItem checklistItem, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    var item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    checklistItem.listOrder = newIndex;
    await DatabaseHelper.updateChecklistItemOrder(checklist, checklistItem, oldIndex);
  }

  Future<void> deleteItem(ChecklistItem checklistItem) async {
    await DatabaseHelper.deleteChecklistItem(checklist, checklistItem);
    _items.remove(checklistItem);
    _deletedItem = DeletedItem(obj: checklistItem);
    notifyListeners();
  }

  Future<void> deleteItemAt(int index) async {
    await deleteItem(_items[index]);
  }

  Future<void> restoreDeletedChecklistItem() async {
    if (_deletedItem != null) {
      var checklistItem = _deletedItem!.obj;
      var originalListOrder = checklistItem.listOrder;

      await addItem(checklistItem);
      await moveChecklistItem(checklistItem, checklistItem.listOrder, originalListOrder);
    }

    notifyListeners();
  }
}

class ChecklistItem {
  int id;
  String text;
  bool complete = false;
  int listOrder;

  ChecklistItem({ this.id = 0, required this.text, this.complete = false, this.listOrder = 0 });

  factory ChecklistItem.fromMap(Map<dynamic, dynamic> map) {
    return ChecklistItem(
      text: map["text"] as String,
      complete: map["complete"] == null ? false : map["complete"] as int == 1,
      id: map["id"] as int,
      listOrder: map["list_order"] == null ? 0 : map["list_order"] as int
    );
  }

  factory ChecklistItem.fromTemplateItem(TemplateItem templateItem) {
    return ChecklistItem(
      id: templateItem.id,
      text: templateItem.text,
      complete: false,
      listOrder: templateItem.listOrder
    );
  }
}

class Checklist {
  String title;
  int id;
  int listOrder;
  int numItems;
  int numComplete;

  Checklist({ this.id = 0, required this.title, this.listOrder = 0, this.numItems = 0, this.numComplete = 0 });

  factory Checklist.fromMap(Map<dynamic, dynamic> map) {
    return Checklist(
      id: map["id"] as int,
      title: map["title"] as String,
      listOrder: map["list_order"] == null ? 0 : map["list_order"] as int,
      numItems: map["num_items"] == null ? 0 : map["num_items"] as int,
      numComplete: map["num_complete"] == null ? 0 : map["num_complete"] as int
    );
  }
}