package com.tapuniverse.passportphoto.exports

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import com.tapuniverse.passportphoto.compress.HeifConverter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import androidx.core.graphics.scale

class ExportPhoto {

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

                var bitmap: Bitmap = decodeBitmap(inputPath)
                Log.i(
                    "resizeAndResoluteImage",
                    "bitmap size: ${bitmap.width}, height: ${bitmap.height}"
                )
                 var bitmapScale:Bitmap;
                if(width == null || height == null  || scaleWidth ==null || scaleHeight == null){
                    bitmapScale = bitmap
                }else{
                    bitmapScale =
                        bitmap.scale((scaleWidth * width).toInt(), (scaleHeight * height).toInt())
                }



                Log.i(
                    "resizeAndResoluteImage",
                    "scale: w: ${scaleWidth} - h: ${scaleHeight}, width: ${width}, height: ${height}, quality ${quality} "
                )

                var outputStream = FileOutputStream(outPath)
                var quality = quality
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

    fun resizePhoto(
        inputPath: String,
        outPath: String,
        width: Int,
        height: Int,
        scale: Double,
    ): Boolean {
        return try {
            var bitmap: Bitmap = BitmapFactory.decodeFile(inputPath)
            var bitmapScale = Bitmap.createScaledBitmap(
                bitmap,
                (scale * width).toInt(),
                (scale * height).toInt(),
                true
            )
            var outputStream = FileOutputStream(outPath)
            bitmapScale.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            true

        } catch (e: Exception) {
            false
        }
    }

    fun getAllImageFolders(context: Context): List<List<String>> {
        val imageFolders = mutableListOf<String>()
        val imageFolderPaths = mutableListOf<String>()
        val results = mutableListOf<List<String>>();

        val projection = arrayOf(
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME
        )

        val sortOrder = "${MediaStore.Images.Media.DATE_TAKEN} DESC"
        val selection = "${MediaStore.Images.Media.MIME_TYPE} LIKE ?"
        val selectionArgs = arrayOf("image/%")

        val contentResolver: ContentResolver = context.contentResolver
        val cursor: Cursor? = contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            sortOrder
        )

        cursor?.use {
            val columnIndexFolderName =
                it.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME)
            val columnIndexData = it.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)

            while (it.moveToNext()) {
                val folderName = it.getString(columnIndexFolderName)
                val imagePath = it.getString(columnIndexData)
                Log.d("ImageFolders", "Folder: $folderName, Path: $imagePath")
                // Check if the folder is not already added
                if (!imageFolders.contains(folderName)) {
                    imageFolders.add(folderName)
                    imageFolderPaths.add(imagePath)
                }
            }
            results.add(imageFolders)
            results.add(imageFolderPaths)

        }

        cursor?.close()
        return results
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