import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:checkbase/helpers/database_helper.dart';
import 'package:checkbase/model/checklist_model.dart';

class EditChecklistItemsViewModel with ChangeNotifier {
  List<ChecklistItem> _checklistItems = <ChecklistItem>[];
  
  int getChecklistItemCount() => _checklistItems.length;
  ChecklistItem getItemAt(int index) => _checklistItems[index];
  
  void addAllChecklistItems(List<ChecklistItem> items) {
    _checklistItems.clear();
    _checklistItems.addAll(items);

    notifyListeners();
  }

  Iterable<ChecklistItem> getFiltered(String filter) {
    return _checklistItems.where((item) => item.text.toLowerCase().contains(filter.toLowerCase()));
  }

  void updateChecklistItem(ChecklistItem checklistItem, String newText) {
    var item = _checklistItems.firstWhereOrNull((element) => element.id == checklistItem.id);

    if (item != null) {
      item.text = newText;
      DatabaseHelper.updateChecklistItemText(checklistItem, newText);
    }

    notifyListeners();
  }
}