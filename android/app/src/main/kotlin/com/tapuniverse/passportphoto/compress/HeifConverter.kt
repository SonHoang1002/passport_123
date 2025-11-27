package com.tapuniverse.passportphoto.compress

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import androidx.heifwriter.HeifWriter
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

object TmpFileUtil {
    fun createTmpFile(context: Context): File {
        val string = UUID.randomUUID().toString()
        return  File(context.cacheDir,  string)
    }
}

class HeifConverter : FormatHandler {
    override val type: Int
        get() = 2
    override val typeName: String
        get() = "heif"

    fun compressHeifFile(
        context:  Context,
        bitmap: Bitmap,
        outputStream: FileOutputStream,
        quality: Int,

    ): Boolean {
        val tmpFile = TmpFileUtil.createTmpFile(context)
        val options = makeOption(1)
        try {
            val heifWriter = HeifWriter.Builder(
                tmpFile.absolutePath,
                bitmap.width,
                bitmap.height,
                HeifWriter.INPUT_MODE_BITMAP
            ).setQuality(quality).setMaxImages(1).build()
            heifWriter.start()
            heifWriter.addBitmap(bitmap)
            heifWriter.stop(5000)
            heifWriter.close()
            outputStream.write(tmpFile.readBytes())
            return true
        } catch (e: Exception) {
            Log.e("ERROR compressHeifFile", e.toString())
            return false
        }

    }


    private fun compress(
        inputPath: String,
        minWidth: Int,
        minHeight: Int,
        quality: Int,
        targetPath: String
    ) {
        val options = makeOption(1)
        val bitmap = BitmapFactory.decodeFile(inputPath, options)
        convertToHeif(inputPath, bitmap, minWidth, minHeight, targetPath, quality)
    }

    private fun makeOption(inSampleSize: Int): BitmapFactory.Options {
        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = false
        options.inPreferredConfig = Bitmap.Config.ARGB_8888
        options.inSampleSize = inSampleSize
//        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
//            @Suppress("DEPRECATION")
//            options.inDither = true
//        }
        return options
    }

    private fun convertToHeif(
        inputPath: String,
        bitmap: Bitmap,
        minWidth: Int,
        minHeight: Int,
        targetPath: String,
        quality: Int
    ) {

        try {
            val heifWriter = HeifWriter.Builder(
                targetPath,
                bitmap.width,
                bitmap.height,
                HeifWriter.INPUT_MODE_BITMAP
            ).setQuality(quality).setMaxImages(1).build()
            heifWriter.start()
            heifWriter.addBitmap(bitmap)
            heifWriter.stop(5000)
            heifWriter.close()
        } catch (e: Exception) {
            Log.i("convertToHeif error", e.toString())
        }
    }

    override fun handleFile(
        context:  Context,
        inputPath: String,
        outputStream: FileOutputStream,
        minWidth: Int,
        minHeight: Int,
        quality: Int,
        keepExif: Boolean,
    ) {
        val tmpFile = TmpFileUtil.createTmpFile(context)
        compress(inputPath, minWidth, minHeight, quality, tmpFile.absolutePath)
        outputStream.write(tmpFile.readBytes())
    }
}

interface FormatHandler {
    val type: Int
    val typeName: String
    fun handleFile(
        context: Context,
        path: String,
        outputStream: FileOutputStream,
        minWidth: Int,
        minHeight: Int,
        quality: Int,
        keepExif: Boolean,
    )
}