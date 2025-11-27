import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/models/adjust_subject_model.dart';
import 'package:passport_photo_2/providers/events/adjust_subject_event.dart';
import 'package:passport_photo_2/providers/states/adjust_subject_state.dart';

class AdjustSubjectBloc extends Bloc<AdjustSubjectEvent, AdjustSubjectState> {
  AdjustSubjectBloc() : super(InitAdjustSubjectState()) {
    on<UpdateAdjustSubjectEvent>((event, emit) {
      List<AdjustSubjectModel> list = List.from(state.listAdjustSubjectModel);
      AdjustSubjectModel newModel = event.model;
      final index = list.indexWhere((element) => element.id == newModel.id);
      AdjustSubjectModel currentAdjustSubject = list[index];
      if (currentAdjustSubject.equalTo(newModel)) {
        return;
      }
      list[index] = newModel;
      emit(UpdateAdjustSubjectState(listAdjustSubjectModel: list));
    });
    on<ResetAdjustSubjectEvent>((event, emit) {
      emit(UpdateAdjustSubjectState(
          listAdjustSubjectModel: LIST_ADJUST_SUBJECT_MODEL));
    });
  }
}
