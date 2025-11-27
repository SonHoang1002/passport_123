package com.tapuniverse.passportphoto.canvas

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.os.Build
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.FileOutputStream
import java.lang.Double.max


class GenerateImageWithCanvas {

    fun transferBitmapPassport(
        passportPath: String, // png image
        quality: Int,
    ): Bitmap {

        val bitmapPassport = BitmapFactory.decodeFile(passportPath)

        val outputStream = ByteArrayOutputStream()

        bitmapPassport.compress(Bitmap.CompressFormat.PNG, quality, outputStream)

        val byteArray = outputStream.toByteArray()

        val compressedBitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)

        outputStream.close()

        return compressedBitmap

    }

    fun generateSinglePage(
        passportPath: String,
        outputPath: String,
        paperWidth: Double,
        paperHeight: Double,
        passportWidth: Double,
        passportHeight: Double,
        countImageOn1Row: Int,
        countRow: Int,
        countImageNeedDraw: Int,
        spacingHorizontal: List<Double>,
        spacingVertical: List<Double>,
        margin: Margin,
        qualityPassport: Int,
        outputFormat: Int, // 0: JPG, 1: PNG, 3: JPG -
        bitmapConfigIndex: Int,
    ): String {

        Log.i(
            "generateSinglePage",
            "passportPath: $passportPath \n outputPath: $outputPath \n paperWidth: $paperWidth \n paperHeight: $paperHeight \n passportWidth: $passportWidth \n passportHeight: $passportHeight \n countImageOn1Row: $countImageOn1Row \n countRow: $countRow \n countImageNeedDraw: $countImageNeedDraw \n spacingHorizontal: $spacingHorizontal \n spacingVertical: $spacingVertical \n margin: top: ${margin.top} \n bottom: ${margin.bottom} \n left: ${margin.left} \n right: ${margin.right} \n qualityPassport: $qualityPassport \n outputFormat: $outputFormat \n bitmapConfigIndex: $bitmapConfigIndex"
        )
        var quality = 90
        var bitmapPassport: Bitmap = transferBitmapPassport(passportPath, qualityPassport)

        var bitmapConfig = Bitmap.Config.ARGB_8888

        when (bitmapConfigIndex) {
            0 -> {
                bitmapConfig = Bitmap.Config.ARGB_8888
            }

            1 -> {
                bitmapConfig = Bitmap.Config.RGB_565
            }

            2 -> {
                bitmapConfig = Bitmap.Config.ALPHA_8
            }

            3 -> {
                bitmapConfig = Bitmap.Config.RGBA_F16
            }

            4 -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    bitmapConfig = Bitmap.Config.RGBA_1010102
                }
            }
        }
        Log.i("generateSinglePage", "bitmapConfig: $bitmapConfig")
        val bitmapPaper = Bitmap.createBitmap(paperWidth.toInt(), paperHeight.toInt(), bitmapConfig)
        val canvas = Canvas(bitmapPaper)

        val rectPaper = Rect(0, 0, paperWidth.toInt(), paperHeight.toInt())

        // draw paper
        val paintPaper = Paint()
        paintPaper.setColor(Color.WHITE)
        canvas.drawRect(
            rectPaper, paintPaper
        )

        // draw paper
        val column = countImageOn1Row
        val row = countRow

        val tong_do_dai_can_ve: Double =
            column * (spacingHorizontal[0] + passportWidth)

        val deltaWidthToAlignCenter: Double =
            max(0.0, ((paperWidth - margin.left * 2 - tong_do_dai_can_ve) / 2))


        Log.i(
            "srcRect",
            "marginLeft: ${passportWidth.toInt()} ${passportHeight.toInt()}"
        )




        for (y in 0 until row) {
            for (i in 0 until column) {
                val marginLeft: Double =
                    margin.left + passportWidth * i + spacingHorizontal[0] * (i + 1) +
                            deltaWidthToAlignCenter
                val marginTop: Double =
                    margin.top + passportHeight * y + spacingVertical[0] * (y + 1)

                val dstRect = Rect(
                    marginLeft.toInt(),
                    marginTop.toInt(),
                    passportWidth.toInt(),
                    passportHeight.toInt(),
                )
                val thu_tu_cua_anh = y * column + (i + 1)
                if (thu_tu_cua_anh > countImageNeedDraw) {
                    val paint = Paint()
                    paint.setColor(Color.RED)
                    canvas.drawRect(
                        dstRect,
                        paint,
                    )
                } else {
                    val srcRect = Rect(
                        0,
                        0,
                        bitmapPassport.width,
                        bitmapPassport.height,
                    )


                    canvas.drawBitmap(
                        bitmapPassport, srcRect, dstRect, Paint()
                    )
                }
            }
        }

        val outputFileStream = FileOutputStream(outputPath)

        when (outputFormat) {
            0 -> {
                bitmapPaper.compress(Bitmap.CompressFormat.JPEG, quality, outputFileStream)
            }

            1 -> {
                bitmapPaper.compress(Bitmap.CompressFormat.PNG, quality, outputFileStream)
            }

            2 -> {
                bitmapPaper.compress(Bitmap.CompressFormat.JPEG, quality, outputFileStream)
            }
        }


        outputFileStream.close()

        return outputPath
    }
}

data class Margin(
    val left: Double,
    val top: Double,
    val right: Double,
    val bottom: Double,
)
