class ItemImage {
  final String id;
  final String path;
  final double? valueSize;
  ItemImage({
    required this.id,
    required this.path,
    this.valueSize = 0,
  });
  void toInfor() {
    print("id:${id}, path: ${path}, valueSize: ${valueSize}");
  }
}
