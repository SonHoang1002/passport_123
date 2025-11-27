package com.tapuniverse.passportphoto.detect_object

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.FileOutputStream

class RemoveBackground(context: Context) {
    var localBitmapSegmenter = LocalBitmapSegmenter(context)

      fun detectObjectAndRemoveBackground(
        context: Context,
        inputPath: String,
        outputPath: String,
        format: Int,
        result: MethodChannel.Result
    ): Boolean {
        val quality = 100
        var bitmap: Bitmap = BitmapFactory.decodeFile(inputPath)
        Log.i("bitmap", bitmap.toString())
        try {
            CoroutineScope(Dispatchers.IO).launch {
                    localBitmapSegmenter.segmentPathBitmap(
                        bitmap
                    ).collectLatest {
                        var outputStream = FileOutputStream(outputPath)
                        when (it.resultCodeResultCode) {
                            ResultCode.SUCCESS -> {
                                val newBitmap: Bitmap = it.bitmap!!
                                newBitmap.compress(Bitmap.CompressFormat.PNG, quality, outputStream)
                                outputStream.close()
                                withContext(Dispatchers.Main){
                                    result.success(true)
                                }
                            }

                            ResultCode.FAIL -> {
                                withContext(Dispatchers.Main) {
                                    result.success(false)
                                }
                                Log.e("detectObjectAndRemoveBackground error", "ResultCode.FAIL")
                            }
                            else -> {
                                withContext(Dispatchers.Main) {
                                    result.success(null)
                                }
                                Log.e(
                                    "detectObjectAndRemoveBackground error",
                                    "ResultCode.TF_LITE_NOT_INITIALIZED"
                                )
                            }
                        }
                    }
            }
            return true
        } catch (e: Exception) {
            Log.e("detectObjectAndRemoveBackground error", e.toString())
            return false
        }
    }
}


//                            when (format) {
//                                0 -> {
//                                    newBitmap.compress(
//                                        Bitmap.CompressFormat.PNG,
//                                        quality,
//                                        outputStream
//                                    )
//                                }
//
//                                1 -> {
//                                    newBitmap.compress(Bitmap.CompressFormat.PNG, quality, outputStream)
//                                }
//
//                                2 -> {
//                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
//                                        newBitmap.compress(
//                                            Bitmap.CompressFormat.WEBP_LOSSY,
//                                            quality,
//                                            outputStream
//                                        )
//                                    } else {
//                                        newBitmap.compress(
//                                            Bitmap.CompressFormat.WEBP,
//                                            quality,
//                                            outputStream
//                                        )
//                                    }
//                                }
//
//                                3 -> {
//                                    HeifConverter().compressHeifFile(
//                                        context = context,
//                                        bitmap = newBitmap,
//                                        outputStream = outputStream,
//                                        quality = quality,
//                                    )
//                                }
//                            }