import 'package:pass1_/helpers/firebase_helpers.dart';

Future<String> handleRatingApp() async {
  try {
    bool isRating = await FirebaseHelpers().checkRating();
    if (isRating) return "Rated";
    await FirebaseHelpers().updateRating();
    return "Updated";
  } catch (e) {
    String message = "handleRatingApp error: $e";
    return message;
  }
}
