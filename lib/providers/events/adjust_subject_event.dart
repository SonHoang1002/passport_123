import 'package:passport_photo_2/models/adjust_subject_model.dart';

abstract class AdjustSubjectEvent {}

class UpdateAdjustSubjectEvent extends AdjustSubjectEvent {
  final AdjustSubjectModel model;
  UpdateAdjustSubjectEvent({required this.model});
}

class ResetAdjustSubjectEvent extends AdjustSubjectEvent {
  ResetAdjustSubjectEvent();
}

// class UpdateAdjustSubjectEvent extends AdjustSubjectEvent {
//   final List<AdjustSubjectModel> listAdjustSubjectModel;

//   UpdateAdjustSubjectEvent({required this.listAdjustSubjectModel});
// }