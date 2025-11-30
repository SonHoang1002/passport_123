import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/models/adjust_subject_model.dart';

abstract class AdjustSubjectState {
  final List<AdjustSubjectModel> listAdjustSubjectModel;

  AdjustSubjectState({required this.listAdjustSubjectModel});
}

class InitAdjustSubjectState extends AdjustSubjectState {
  InitAdjustSubjectState()
    : super(listAdjustSubjectModel: LIST_ADJUST_SUBJECT_MODEL);
}

class UpdateAdjustSubjectState extends AdjustSubjectState {
  final List<AdjustSubjectModel> listAdjustSubjectModel;

  UpdateAdjustSubjectState({required this.listAdjustSubjectModel})
    : super(listAdjustSubjectModel: listAdjustSubjectModel);
}
