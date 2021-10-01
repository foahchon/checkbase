class DeletedList<TList, TItem> {
  late TList obj;
  List<TItem> objItems = List.empty(growable: true);

  DeletedList({ required this.obj, required this.objItems });
}