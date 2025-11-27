class AdjustSubjectModel {
  final int id;
  final String title;
  final List<String> listMediaSrc;
  final double rootRatioValue;
  final int dividers;
  double currentRatioValue;

  AdjustSubjectModel({
    required this.id,
    required this.listMediaSrc,
    required this.title,
    required this.rootRatioValue,
    required this.dividers,
    required this.currentRatioValue,
  });

  AdjustSubjectModel copyWith({double? currentRatioValue}) {
    return AdjustSubjectModel(
        id: id,
        listMediaSrc: listMediaSrc,
        title: title,
        rootRatioValue: rootRatioValue,
        dividers: dividers,
        currentRatioValue: currentRatioValue ?? this.currentRatioValue);
  }

  bool equalTo(AdjustSubjectModel newModel) {
    return id == newModel.id &&
        title == newModel.title &&
        listMediaSrc == newModel.listMediaSrc &&
        rootRatioValue == newModel.rootRatioValue &&
        dividers == newModel.dividers &&
        currentRatioValue == newModel.currentRatioValue;
  }

  @override
  String toString() {
    return 'AdjustSubjectModel{id: $id, title: $title, listMediaSrc: $listMediaSrc, rootRatioValue: $rootRatioValue, dividers: $dividers, currentRatioValue: $currentRatioValue}';
  }
}
