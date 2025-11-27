class StepModel {
  // 0 -> light, 1 -> dark, 2 -> selected 
  final int id;
  final List<String> listMediaSrc; 
  final String title;

  StepModel({
    required this.id,
    required this.listMediaSrc,
    required this.title,
  });
}
