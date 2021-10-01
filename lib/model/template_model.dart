import 'package:flutter/material.dart';

import 'package:checkbase/helpers/deleted_item.dart';
import 'package:checkbase/helpers/database_helper.dart';

class TemplateViewModel with ChangeNotifier {
  ChecklistTemplate template;
  List<TemplateItem> _items = List.empty(growable: true);
  DeletedItem<TemplateItem>? _deletedItem;

  TemplateViewModel({ required this.template });

  int get itemCount => _items.length;
  TemplateItem getItemAt(int index) => _items[index];

  Future<void> addItem(TemplateItem templateItem) async {
    await DatabaseHelper.addItemToTemplate(template, templateItem);
    _items.add(templateItem);
    notifyListeners();
  }

  void addItems(List<TemplateItem> items) {
    _items.addAll(items);
    notifyListeners();
  }
  
  Future<void> deleteItem(TemplateItem templateItem) async {
    await DatabaseHelper.deleteTemplateItem(template, templateItem);
    _items.remove(templateItem);
    _deletedItem = DeletedItem(obj: templateItem);
    notifyListeners();
  }
  
  Future<void> moveTemplateItem(TemplateItem templateItem, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    var item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    templateItem.listOrder = newIndex;
    await DatabaseHelper.updateTemplateItemOrder(template, templateItem, oldIndex);
  }

  Future<void> refreshItems() async {
    _items.clear();
    _items.addAll(await DatabaseHelper.getItemsForTemplate(template));
  }

  Future<void> restoreDeletedTemplateItem() async {
    if (_deletedItem != null) {
      var templateItem = _deletedItem!.obj;
      var originalListOrder = templateItem.listOrder;

      await addItem(templateItem);
      await moveTemplateItem(templateItem, templateItem.listOrder, originalListOrder);
    }

    notifyListeners();
  }
}

class TemplateItem {
  int templateId;
  int id;
  String text;
  int listOrder;

  TemplateItem({ this.templateId = 0, this.id = 0, required this.text, this.listOrder = 0 });

  factory TemplateItem.fromMap(Map<dynamic, dynamic> map) {
    return TemplateItem(
      id: map["id"] as int,
      text: map["text"],
      listOrder: map["list_order"] == null ? 0 : map["list_order"]
    );
  }
}

class ChecklistTemplate {
  int id;
  String name;
  int listOrder;

  ChecklistTemplate({ this.id = 0, required this.name, this.listOrder = 0 });

  factory ChecklistTemplate.fromMap(Map<dynamic, dynamic> map) {
    return ChecklistTemplate(
      id: map["id"] as int,
      name: map["name"] as String,
      listOrder: map["list_order"] as int
    );
  }
}