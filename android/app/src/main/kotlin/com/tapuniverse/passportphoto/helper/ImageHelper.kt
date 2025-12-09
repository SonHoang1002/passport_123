package com.tapuniverse.passportphoto.helper

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.os.Build
import android.util.Log
import androidx.core.graphics.scale
import androidx.exifinterface.media.ExifInterface
import com.tapuniverse.passportphoto.compress.HeifConverter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException

class ImageHelper {

    suspend fun resizeAndResoluteImage(
        context: Context,
        inputPath: String,
        outPath: String,
        format: Int,
        width: Int?,
        height: Int?,
        scaleWidth: Double?,
        scaleHeight: Double?,
        quality: Int
    ): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val bitmap: Bitmap = decodeBitmap(inputPath)
                Log.i(
                    "resizeAndResoluteImage",
                    "bitmap size: ${bitmap.width}, height: ${bitmap.height}"
                )
                var bitmapScale:Bitmap
                if(width == null || height == null  || scaleWidth == null || scaleHeight == null){
                    bitmapScale = bitmap
                }else{
                    bitmapScale =
                        bitmap.scale((scaleWidth * width).toInt(), (scaleHeight * height).toInt())
                }
                Log.i(
                    "resizeAndResoluteImage",
                    "scale: w: ${scaleWidth} - h: ${scaleHeight}, width: ${width}, height: ${height}, quality ${quality} "
                )

                val outputStream = FileOutputStream(outPath)
                val quality = quality
                Log.i("format", format.toString());
                when (format) {
                    0 -> {
                        bitmapScale.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                    }

                    1 -> {
                        bitmapScale.compress(Bitmap.CompressFormat.PNG, quality, outputStream)
                    }

                    2 -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            bitmapScale.compress(
                                Bitmap.CompressFormat.WEBP_LOSSY,
                                quality,
                                outputStream
                            )
                        } else {
                            bitmapScale.compress(Bitmap.CompressFormat.WEBP, quality, outputStream)
                        }
                    }

                    3 -> {
                        HeifConverter().compressHeifFile(
                            context = context,
                            bitmap = bitmapScale,
                            outputStream = outputStream,
                            quality = quality,
                        )
                    }
                }
                outputStream.close()
                return@withContext true;
            } catch (e: Exception) {
                Log.e("changeImageFormat error", e.toString())
                return@withContext false
            }
        }
    }

}

fun rotateBitmap(source: Bitmap, angle: Float): Bitmap {
    val matrix = Matrix()
    matrix.postRotate(angle)
    return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
}

fun flipBitmap(source: Bitmap, angle: Float): Bitmap {
    val matrix = Matrix()
    matrix.postRotate(angle)
    matrix.postScale(-1f, 1f)
    return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
}

@Throws(FileNotFoundException::class, IOException::class, OutOfMemoryError::class)
fun decodeBitmap(file: String?): Bitmap {
    val exif = ExifInterface(file!!)
    val orientation: Int =
        exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED)
    var mOptions = BitmapFactory.Options()
    mOptions.inJustDecodeBounds = false
    val bitmap = BitmapFactory.decodeFile(file, mOptions)
    // 180 , check exif inteface 2,4,5,7
    when (orientation) {
        ExifInterface.ORIENTATION_ROTATE_90 -> {
            return rotateBitmap(bitmap, 90f)
        }

        ExifInterface.ORIENTATION_ROTATE_270 -> {
            return rotateBitmap(bitmap, -90f)
        }

        ExifInterface.ORIENTATION_ROTATE_180 -> {
            return rotateBitmap(bitmap, 180f)
        }

        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> {
            return flipBitmap(bitmap, 0f)
        }

        ExifInterface.ORIENTATION_FLIP_VERTICAL -> {
            return flipBitmap(bitmap, 180f)
        }

        ExifInterface.ORIENTATION_TRANSPOSE -> {
            return flipBitmap(bitmap, 90f)
        }

        ExifInterface.ORIENTATION_TRANSVERSE -> {
            return flipBitmap(bitmap, 270f)
        }

        else -> return bitmap
    }
}