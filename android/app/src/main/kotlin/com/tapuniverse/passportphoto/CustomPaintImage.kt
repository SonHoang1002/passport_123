package com.tapuniverse.passportphoto

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.util.Log
import com.tapuniverse.passportphoto.exports.decodeBitmap
import java.io.FileOutputStream

class PassportCanvas {
    fun maskTwoImage(originalFilePath: String, transparentFilePath: String, outputPath: String) {


//        val bitmapOriginal: Bitmap = BitmapFactory.decodeFile(originalFilePath)
//        val bitmapTransparent: Bitmap = BitmapFactory.decodeFile(transparentFilePath)

        val bitmapOriginal: Bitmap = decodeBitmap(originalFilePath)
        var bitmapTransparent: Bitmap = decodeBitmap(transparentFilePath)
        val bitmapResult: Bitmap = Bitmap.createBitmap(
            bitmapOriginal.width,
            bitmapOriginal.height,
            Bitmap.Config.ARGB_8888
        )


        var canvas = Canvas(bitmapResult)

        val paintOriginal = Paint()
        paintOriginal.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC)

        val paintTransparent = Paint()
        paintTransparent.xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)

        Log.i(
            "maskTwoImage",
            "originalFilePath: ${originalFilePath}: ${bitmapOriginal.width}-${bitmapOriginal.height}"
        )
        Log.i(
            "maskTwoImage",
            "transparentFilePath: ${transparentFilePath}: ${bitmapTransparent.width}-${bitmapTransparent.height}"
        )

        canvas
            .drawBitmap(bitmapOriginal, 0.0f, 0.0f, paintOriginal)
        canvas.save()
        canvas.scale(
            bitmapOriginal.width * 1f / bitmapTransparent.width,
            bitmapOriginal.height * 1f / bitmapTransparent.height
        )
        canvas
            .drawBitmap(bitmapTransparent, 0.0f, 0.0f, paintTransparent)
        canvas.restore()

        val fileOutputStream = FileOutputStream(outputPath)


        bitmapResult.compress(Bitmap.CompressFormat.PNG, 100, fileOutputStream)
        fileOutputStream.close()
    }




//    fun adjustImages(
//        backgroundFilePath: String,
//        objectFilePath: String,
//        listOffsetObject: List<Double>,
//        listPreviewFrame: List<Double>,
//        outputPath: String,
//        needBlurAndShadow: Boolean? = false,
//
//        ) {
//        var bitmapBackground: Bitmap = BitmapFactory.decodeFile(backgroundFilePath)
//        var bitmapObject: Bitmap = BitmapFactory.decodeFile(objectFilePath)
//        var bitmapResult: Bitmap = Bitmap.createBitmap(
//            bitmapBackground.width,
//            bitmapBackground.height,
//            Bitmap.Config.ARGB_8888
//        )
//        var canvas = Canvas(bitmapResult)
//
//        val leftObject: Float =
//            ((listOffsetObject[0] / listPreviewFrame[0]) * bitmapBackground.width).toFloat()
//        val topObject: Float =
//            ((listOffsetObject[1] / listPreviewFrame[1]) * bitmapBackground.height).toFloat()
//
//        var paintBackground = Paint()
//        paintBackground.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC)
//
//        var paintObject = Paint()
//        paintObject.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_OVER)
//
//        canvas.drawBitmap(bitmapBackground, 0.0f, 0.0f, paintBackground)
//        // draw blur, shadows
//        if (needBlurAndShadow == true) {
//            var paintBlurShadow = Paint()
//            paintBackground. = ui.ImageFilter.blur(
//                sigmaX: 6.0, sigmaY: 6.0, tileMode: TileMode.decal)
//            paintBlurShadow.colorFilter = ColorFilter()
//        }
//
//        canvas.save();
//        canvas.scale(
//            bitmapBackground.width * 1f / bitmapBackground.width,
//            bitmapBackground.height * 1f / bitmapBackground.height,
//        );
//        canvas.drawBitmap(bitmapObject, leftObject, topObject, paintObject)
//        canvas.restore();
//
//        var fileOutputStream = FileOutputStream(outputPath)
//        bitmapResult.compress(Bitmap.CompressFormat.PNG, 100, fileOutputStream)
//        fileOutputStream.close()
//    }
}