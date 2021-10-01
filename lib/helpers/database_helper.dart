import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:checkbase/model/template_model.dart';
import 'package:checkbase/model/checklist_model.dart';

class DatabaseHelper {

  static Database? _db;
  static bool _dbIsOpen = false;

  static Future<void> _ensureDbIsOpen() async {

    if (!_dbIsOpen) {
      var dbPath = join(await getDatabasesPath(), "lists.db");
    
      _db = await openDatabase(dbPath,
        onOpen: (db) {
          db.execute("PRAGMA foreign_keys = ON");
          // print("Opening dbPath: $dbPath");
        },

        onCreate: (db, version) async {
          await db.execute("""CREATE TABLE IF NOT EXISTS checklists(
                              id INTEGER PRIMARY KEY,
                              title TEXT,
                              list_order INTEGER
                          )""");

          await db.execute("""CREATE TABLE IF NOT EXISTS checklist_items(
                              id INTEGER PRIMARY KEY, text TEXT
                          )""");

          await db.execute("""CREATE TABLE IF NOT EXISTS checklists_checklist_items(
                              checklist_id INTEGER,
                              checklist_items_id INTEGER,
                              complete BOOL,
                              list_order INTEGER,
                              FOREIGN KEY (checklist_id) REFERENCES checklists(id)
                              ON DELETE CASCADE,
                              FOREIGN KEY (checklist_items_id) REFERENCES checklist_items(id),
                              PRIMARY KEY(checklist_id, checklist_items_id)
                              )""");

          await db.execute("""CREATE TABLE IF NOT EXISTS templates(
                               id INTEGER PRIMARY KEY,
                               name TEXT,
                               list_order INTEGER
                              )""");

          await db.execute("""CREATE TABLE templates_checklist_items(
                            templates_id INTEGER,
                            checklist_items_id INTEGER,
                            list_order INTEGER,
                            FOREIGN KEY (templates_id) REFERENCES templates(id)
                            ON DELETE CASCADE,
                            FOREIGN KEY (checklist_items_id) REFERENCES checklist_items(id),
                            PRIMARY KEY (templates_id, checklist_items_id)
                            )""");

        },
        version: 1
      );

      _dbIsOpen = true;
    }
  }

  static Future<void> closeDb() async {
    await _db!.close();
    _dbIsOpen = false;
  }

  static Future<List<Checklist>> getAllChecklists() async {
    await _ensureDbIsOpen();
    List<Map<dynamic, dynamic>> checklists = await _db!.rawQuery("""SELECT cl.id, cl.title, cl.list_order, COUNT(*) AS num_items, SUM(cci.complete) AS num_complete
                                                                   FROM checklists_checklist_items cci
                                                                   JOIN checklists cl ON cl.id = cci.checklist_id
                                                                   GROUP BY checklist_id
                                                                   ORDER BY cl.list_order""");

    return List<Checklist>.from(checklists.map<Checklist>((c) => Checklist.fromMap(c)));
  }

  static Future<int> addChecklist(Checklist checklist) async {
    await _ensureDbIsOpen();
    
    var itemCount = (await getAllChecklists()).length;
    var id = await _db!.rawInsert("INSERT INTO checklists(title, list_order) VALUES (?, ?)", [checklist.title, itemCount]);
    
    checklist.listOrder = itemCount;
    checklist.id = id;
    return id;
  }

  static Future<void> deleteChecklist(Checklist checklist) async {
    await _ensureDbIsOpen();
    
    await _db!.rawQuery("DELETE FROM checklists WHERE ID = ?", [checklist.id]);

    await _db!.rawUpdate("""UPDATE checklists
                           SET list_order = list_order - 1
                           WHERE list_order > ?""", [checklist.listOrder]);
  }

  static Future<List<ChecklistItem>> getItemsForChecklist(Checklist checklist) async {
    List<Map<dynamic, dynamic>> checklistItems = await _db!.rawQuery("""SELECT ci.id, ci.text, cci.complete, cci.list_order FROM checklists_checklist_items cci
                                                                       JOIN checklist_items ci ON cci.checklist_items_id = ci.id
                                                                       WHERE cci.checklist_id = ?
                                                                       ORDER BY cci.list_order""", [checklist.id]);
    
    return List<ChecklistItem>.from(checklistItems.map<ChecklistItem>((i) => ChecklistItem.fromMap(i)));
  }

  static Future<void> updateChecklistItemStatus(Checklist checklist, ChecklistItem item, bool isComplete) async {
    await _ensureDbIsOpen();

    await _db!.rawQuery("""UPDATE checklists_checklist_items
                          SET complete = ${isComplete ? 1 : 0}
                          WHERE checklist_id = ? AND checklist_items_id = ?""", [checklist.id, item.id]);

    item.complete = isComplete;
  }

  static Future<List<ChecklistItem>> getAllChecklistItems() async {
    await _ensureDbIsOpen();

    List<Map<dynamic, dynamic>> checklistItems = await _db!.rawQuery("SELECT * FROM checklist_items");
    
    return List<ChecklistItem>.from(checklistItems.map<ChecklistItem>((i) => ChecklistItem.fromMap(i)));
  }

  static Future<int> addItemToChecklist(Checklist checklist, ChecklistItem checklistItem) async {
    await _ensureDbIsOpen();

    var id = checklistItem.id;
    var itemCount = (await getItemsForChecklist(checklist)).length;

    if (id == 0) {
      id = await _db!.rawInsert("""INSERT OR IGNORE INTO checklist_items(text)
                                  VALUES (?)""", [checklistItem.text]);
    }

    await _db!.rawInsert("""INSERT OR IGNORE INTO checklists_checklist_items(checklist_id, checklist_items_id, complete, list_order)
                           VALUES (?, ?, ?, ?)""", [checklist.id, id, 0, itemCount]);

    checklistItem.listOrder = itemCount;
    checklistItem.id = id;

    return id;
  }
  
  static Future<void> updateChecklistItemOrder(Checklist checklist, ChecklistItem checklistItem, int oldIndex) async {
    await _ensureDbIsOpen();
    
    var newIndex = checklistItem.listOrder;

    if (newIndex < oldIndex) { // item moving up
      await _db!.rawUpdate("""UPDATE checklists_checklist_items
                            SET list_order = list_order + 1
                            WHERE checklist_id = ? AND list_order >= ? AND list_order <= ?""", [checklist.id, newIndex, oldIndex]);
    }

    else if (newIndex > oldIndex) { // item moving down
      await _db!.rawUpdate("""UPDATE checklists_checklist_items
                              SET list_order = list_order - 1
                              WHERE checklist_id = ? AND list_order >= ? AND list_order <= ?""", [checklist.id, oldIndex, newIndex]);
    }
    
    await _db!.rawUpdate("""UPDATE checklists_checklist_items
                           SET list_order = ?
                           WHERE checklist_id = ? AND checklist_items_id = ?""", [newIndex, checklist.id, checklistItem.id]);
  }

  static Future<void> deleteChecklistItem(Checklist checklist, ChecklistItem checklistItem) async {
    await _ensureDbIsOpen();

    await _db!.rawDelete("""DELETE FROM checklists_checklist_items
                           WHERE checklist_id = ? AND checklist_items_id = ?""", [checklist.id, checklistItem.id]);

    await _db!.rawUpdate("""UPDATE checklists_checklist_items
                           SET list_order = list_order - 1
                           WHERE list_order > ?""", [checklistItem.listOrder]);
  }

  static Future<void> updateChecklistOrder(Checklist checklist, int oldIndex) async {
    await _ensureDbIsOpen();

    var newIndex = checklist.listOrder;

    if (newIndex < oldIndex) { // item moving up
      await _db!.rawUpdate("""UPDATE checklists
                             SET list_order = list_order + 1
                             WHERE list_order >= ? AND list_order <= ?""", [newIndex, oldIndex]);
    }

    else if (newIndex > oldIndex) { // item moving down
      await _db!.rawUpdate("""UPDATE checklists
                             SET list_order = list_order - 1
                             WHERE list_order >= ? AND list_order <= ?""", [oldIndex, newIndex]);
    }

    await _db!.rawUpdate("""UPDATE checklists
                           SET list_order = ?
                           WHERE id = ?""", [newIndex, checklist.id]);
  }

  static Future<void> createTemplateFromChecklist(ChecklistTemplate template, Checklist checklist) async {
    await _ensureDbIsOpen();

    var templateOrder = (await getAllTemplates()).length;
    var templateId = await _db!.rawInsert("""INSERT INTO templates(name, list_order) VALUES (?, ?)""", [template.name, templateOrder]);

    await _db!.rawInsert("""INSERT INTO templates_checklist_items(templates_id, checklist_items_id, list_order)
                           SELECT ? as templates_id, cci.checklist_items_id, cci.list_order
                           FROM checklists_checklist_items cci
                           WHERE cci.checklist_id = ?""", [templateId, checklist.id]);
  }

  static Future<void> deleteTemplate(ChecklistTemplate template) async {
    await _ensureDbIsOpen();
    
    await _db!.rawDelete("DELETE FROM templates WHERE id = ?", [template.id]);

    await _db!.rawUpdate("""UPDATE templates
                           SET list_order = list_order - 1
                           WHERE list_order > ?""", [template.listOrder]);
  }

  static Future<List<ChecklistTemplate>> getAllTemplates() async {
    await _ensureDbIsOpen();
    
    var checklistTemplates = await _db!.rawQuery("""SELECT * from templates
                                                   ORDER BY list_order""");

    return List<ChecklistTemplate>.from(checklistTemplates.map<ChecklistTemplate>((i) => ChecklistTemplate.fromMap(i)));
  }

  static Future<int> addTemplate(ChecklistTemplate template) async {
    await _ensureDbIsOpen();

    var itemCount = (await getAllTemplates()).length;
    var id = await _db!.rawInsert("""INSERT INTO templates(name, list_order)
                                    VALUES (?, ?)""", [template.name, itemCount]);

    template.listOrder = itemCount;
    template.id = id;

    return id;
  }

  static Future<void> addItemToTemplate(ChecklistTemplate template, TemplateItem templateItem) async {
    await _ensureDbIsOpen();

    var checklistItem = ChecklistItem.fromTemplateItem(templateItem);
    var id = checklistItem.id;
    var itemCount = (await getItemsForTemplate(template)).length;

    if (id == 0) {
      id = await _db!.rawInsert("""INSERT OR IGNORE INTO checklist_items(text)
                                  VALUES (?)""", [checklistItem.text]);
    }

    await _db!.rawInsert("""INSERT OR IGNORE INTO templates_checklist_items(templates_id, checklist_items_id, list_order)
                           VALUES (?, ?, ?)""", [template.id, id, itemCount]);

    templateItem.listOrder = itemCount;
    templateItem.templateId = template.id;
    templateItem.id = checklistItem.id;
  }

  static Future<void> deleteTemplateItem(ChecklistTemplate template, TemplateItem templateItem) async {
    await _ensureDbIsOpen();

    await _db!.rawDelete("""DELETE FROM templates_checklist_items
                           WHERE templates_id = ? AND checklist_items_id = ?""", [template.id, templateItem.id]);

    await _db!.rawUpdate("""UPDATE templates_checklist_items
                           SET list_order = list_order - 1
                           WHERE list_order > ? AND templates_id = ?""", [templateItem.listOrder, template.id]);
  }

  static Future<void> updateTemplateItemOrder(ChecklistTemplate template, TemplateItem templateItem, int oldIndex) async {
    await _ensureDbIsOpen();
    
    var newIndex = templateItem.listOrder;

    if (newIndex < oldIndex) { // item moving up
      await _db!.rawUpdate("""UPDATE templates_checklist_items
                            SET list_order = list_order + 1
                            WHERE templates_id = ? AND list_order >= ? AND list_order <= ?""", [template.id, newIndex, oldIndex]);
    }

    else if (newIndex > oldIndex) { // item moving down
      await _db!.rawUpdate("""UPDATE templates_checklist_items
                             SET list_order = list_order - 1
                             WHERE templates_id = ? AND list_order >= ? AND list_order <= ?""", [template.id, oldIndex, newIndex]);
    }
    
    await _db!.rawUpdate("""UPDATE templates_checklist_items
                           SET list_order = ?
                           WHERE templates_id = ? AND checklist_items_id = ?""", [newIndex, template.id, templateItem.id]);
  }

  static Future<List<TemplateItem>> getItemsForTemplate(ChecklistTemplate template) async {
    await _ensureDbIsOpen();

    var templateItems = await _db!.rawQuery("""SELECT tci.checklist_items_id as id, ci.text, tci.list_order
                                              FROM templates_checklist_items tci
                                              JOIN checklist_items ci ON tci.checklist_items_id = ci.id
                                              WHERE tci.templates_id = ?
                                              ORDER BY tci.list_order""", [template.id]);

    return List<TemplateItem>.from(templateItems.map<TemplateItem>((i) => TemplateItem.fromMap(i)));
  }

  static Future<void> createChecklistFromTemplate(Checklist checklist, ChecklistTemplate template) async {
    await _ensureDbIsOpen();

    var checklistOrder = (await getAllChecklists()).length;
    var checklistId = await _db!.rawInsert("INSERT INTO checklists(title, list_order) VALUES (?, ?)", [checklist.title, checklistOrder]);

    await _db!.rawInsert("""INSERT INTO checklists_checklist_items(checklist_id, checklist_items_id, complete, list_order)
                            SELECT ? AS checklist_id, tci.checklist_items_id, 0 AS complete, tci.list_order
                            FROM templates_checklist_items tci
                            WHERE tci.templates_id = ?""", [checklistId, template.id]);

    checklist.id = checklistId;
  }

  static Future<void> updateTemplateOrder(ChecklistTemplate template, int oldIndex, int newIndex) async {
    await _ensureDbIsOpen();

    var newIndex = template.listOrder;

    if (newIndex < oldIndex) { // item moving up
      await _db!.rawUpdate("""UPDATE templates
                             SET list_order = list_order + 1
                             WHERE list_order >= ? AND list_order <= ?""", [newIndex, oldIndex]);
    }

    else if (newIndex > oldIndex) { // item moving down
      await _db!.rawUpdate("""UPDATE templates
                             SET list_order = list_order - 1
                             WHERE list_order >= ? AND list_order <= ?""", [oldIndex, newIndex]);
    }
    
    await _db!.rawUpdate("""UPDATE templates
                           SET list_order = ?
                           WHERE id = ?""", [newIndex, template.id]);
  }

  static Future<void> updateChecklistItemText(ChecklistItem checklistItem, String newText) async {
    await _ensureDbIsOpen();

    await _db!.rawUpdate("""UPDATE checklist_items
                           SET text = ?
                           WHERE id = ?""", [newText, checklistItem.id]);
  }

  static Future<void> refreshChecklist(Checklist? checklist) async {
    await _ensureDbIsOpen();

    var dbChecklist = (await _db!.rawQuery("""SELECT cl.id, cl.title, cl.list_order, COUNT(*) AS num_items, SUM(cci.complete) AS num_complete
                                              FROM checklists_checklist_items cci
                                              JOIN checklists cl ON cl.id = cci.checklist_id
                                              WHERE cl.id = ?
                                              GROUP BY checklist_id
                                              ORDER BY cl.list_order""", [checklist?.id]))[0];

    checklist?.numComplete = dbChecklist["num_complete"] as int;
    checklist?.numItems = dbChecklist["num_items"] as int;
    checklist?.title = dbChecklist["title"] as String;
  }
}