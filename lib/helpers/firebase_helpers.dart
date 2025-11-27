import 'package:android_id/android_id.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';

class FirebaseHelpers {
  Future<DocumentReference<Map<String, dynamic>>> _getAndroidDocument(
      String? androidId) async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference<Map<String, dynamic>> docRef =
          db.collection("users").doc(androidId);
      return docRef;
    } catch (e) {
      consolelog("_getAndroidDocument error: ${e.toString()}");
      debugPrint("_getAndroidDocument error: ${e.toString()}");
      rethrow;
    }
  }

  Future<void> sendFirebaseAndroidId() async {
    try {
      String? androidId = await _getAndroidId();
      var docRef = await _getAndroidDocument(androidId);
      var doc = await docRef.get();
      if (doc.data() == null || !doc.exists) {
        docRef
            .set({"id": androidId, "isRating": false})
            .then((void x) => debugPrint("Add id success"))
            .onError((Object? error, StackTrace stackTrace) =>
                debugPrint("Add id error: $error"));
      }
    } catch (e) {
      consolelog("sendFirebaseAndroidId error: ${e.toString()}");
      debugPrint("sendFirebaseAndroidId error: ${e.toString()}");
      rethrow;
    }
  }

  Future<String?> _getAndroidId() async {
    String? androidId = await const AndroidId().getId();
    debugPrint("androidId: ${androidId!}");
    return androidId;
  }

  Future<bool> checkRating() async {
    try {
      String? androidId = await _getAndroidId();
      var docRef = await _getAndroidDocument(androidId);
      var doc = await docRef.get();
      if (doc.exists && doc.data()?["isRating"] == true) {
        debugPrint("CheckRating log: User existed or rated!!");
        return true;
      } else {
        debugPrint("CheckRating log: User doesn't existed or rated!!");
        return false;
      }
    } catch (e) {
      debugPrint("CheckRating error: $e ");
      return true;
    }
  }

  Future<bool> updateRating() async {
    try {
      String? androidId = await _getAndroidId();
      var docRef = await _getAndroidDocument(androidId);
      var doc = await docRef.get();
      if (doc.data() != null && doc.exists) {
        docRef
            .update({"isRating": true, "id": androidId})
            .then((void x) => debugPrint(
                " ------------------------- Update rating status to true ------------------------- "))
            .onError((Object? error, StackTrace stackTrace) => debugPrint(
                " ------------------------- Update rating error: $error  ------------------------- "));
      } else {
        docRef
            .set({"isRating": true, "id": androidId})
            .then((void x) => debugPrint(
                " ------------------------- Update (with create when doc is null) rating status to true ------------------------- "))
            .onError((Object? error, StackTrace stackTrace) => debugPrint(
                " ------------------------- Update (with create when doc is null) rating error: $error  ------------------------- "));
      }
      return true;
    } catch (e) {
      debugPrint("updateRating error: $e");
      rethrow;
    }
  }

  Future testDeleteRating() async {
    try {
      String? androidId = await _getAndroidId();
      var docRef = await _getAndroidDocument(androidId);
      var doc = await docRef.get();
      if (doc.data() != null && doc.exists) {
        docRef
            .delete()
            .then((void x) => debugPrint(
                " ------------------------- Delete succesfully ------------------------- "))
            .onError((Object? error, StackTrace stackTrace) => debugPrint(
                " ------------------------- Delete error: $error  ------------------------- "));
      }
    } catch (e) {
      debugPrint("testDeleteRating error: $e");
      rethrow;
    }
  }
}
