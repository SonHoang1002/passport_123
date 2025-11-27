package com.tapuniverse.passportphoto.detect_object

import android.graphics.Bitmap

data class SegmentResult(val bitmap: Bitmap?, val resultCodeResultCode: ResultCode)


enum class ResultCode { SUCCESS, FAIL, TF_LITE_NOT_INITIALIZED }