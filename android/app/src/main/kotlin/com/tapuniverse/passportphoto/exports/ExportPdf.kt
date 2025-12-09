package com.tapuniverse.passportphoto.exports

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.tapuniverse.passportphoto.helper.ImageHelper
import java.io.File
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.pdf.PdfDocument
import android.util.Size
import java.io.FileOutputStream
import androidx.core.graphics.createBitmap
import kotlin.math.max


class ExportPdf {
    suspend fun handleGenerateMultiplePaperMediaToImage(
        context: Context,
        imageCroppedPath: String,
        indexImageFormat: Int,
        extension: String,
        quality: Int,
        copyNumber: Int,
        countPage: Int,
        paperSizeByPixelPointLimited: Size,
        passportSizeByPixelLimited: Size,
        countColumnIn1Page: Int,
        countRowIn1Page: Int,
        spacingHorizontalByPixelPoint: Double,
        spacingVerticalByPixelPoint: Double,
        marginByPixelPoint: RectF,
    ): ArrayList<String> {
        /// Kiểm tra extension cuối cùng sẽ tạo ra và ghi vào

        /// Kiểm tra có cần thay đổi quality hay không
        /// Nếu indexImageFormat = 0 ( jpg ) -> thay đổi quality
        /// Nếu indexImageFormat = 1 ( png ) -> lấy crop file để xử lý luôn

        /// Lấy canvas có kích thước của paper size
        /// kết hợp với kích thước của passport để quyết định vẽ như thế nào
        /// Vẽ tất cả những item page

        /// Generate ra những ảnh đã vẻ bên trên
        /// Để tối ưu, chỉ lấy hai ảnh cuối cùng
        /// ( nếu có từ 2 ảnh trở lên )

        /// Trả ra danh sách path ( max chỉ có hai ảnh, 1 double là tổng kích thước của những ảnh )

        try {
            val resizeBitmap: Bitmap

            if (indexImageFormat == 0) { // jpg
                val externalDir = context.getExternalFilesDir(null)
                val cacheOutPath = File(externalDir, "finished_image.${extension}").path
                val croppedBitmap = BitmapFactory.decodeFile(imageCroppedPath)
                ImageHelper().resizeAndResoluteImage(
                    context = context,
                    inputPath = imageCroppedPath,
                    outPath = cacheOutPath,
                    format = 0,
                    width = croppedBitmap.width,
                    height = croppedBitmap.height,
                    scaleWidth = 1.0,
                    scaleHeight = 1.0,
                    quality = quality,
                )
                resizeBitmap = BitmapFactory.decodeFile(cacheOutPath)
            } else {
                resizeBitmap = BitmapFactory.decodeFile(imageCroppedPath)
            }

            val listBitmap: ArrayList<Bitmap> = drawPdfImage(
                resizeBitmap = resizeBitmap,
                copyNumber = copyNumber,
                countPage = countPage,
                paperSizeByPixelPointLimited = paperSizeByPixelPointLimited,
                passportSizeByPixelLimited = passportSizeByPixelLimited,
                countColumnIn1Page = countColumnIn1Page,
                countRowIn1Page = countRowIn1Page,
                spacingHorizontalByPixelPoint = spacingHorizontalByPixelPoint,
                spacingVerticalByPixelPoint = spacingVerticalByPixelPoint,
                marginByPixelPoint = marginByPixelPoint,
            )
            context.getExternalFilesDir(null)
            val lengthBitmap = listBitmap.size

            val listMainFile = ArrayList<File>()

            if (lengthBitmap > 2) {
                val listTempFile = ArrayList<File>()

                val listCollapseBitmap =
                    listOf(
                        listBitmap[0], listBitmap[lengthBitmap - 1]
                    )
                for (bitmap in listCollapseBitmap.withIndex()) {
                    val externalDir = context.getExternalFilesDir(null)
                    val path: String =
                        File(externalDir, "generated_pdf_image_${bitmap.index}.$extension").path

                    val fos = FileOutputStream(path)
                    bitmap.value.compress(Bitmap.CompressFormat.JPEG, 100, fos)
                    listTempFile.add(File(path))
                    fos.close()
                }
                for (indexPage in 1..countPage) {
                    if (indexPage < countPage - 1) {
                        listMainFile.add(listTempFile[0]);
                    } else {
                        listMainFile.add(listTempFile[1]);
                    }
                }
            } else {
                for (bitmap in listBitmap.withIndex()) {
                    val externalDir = context.getExternalFilesDir(null)
                    val path: String =
                        File(externalDir, "generated_pdf_image_${bitmap.index}.${extension}").path
                    val fos = FileOutputStream(path)
                    bitmap.value.compress(Bitmap.CompressFormat.JPEG, 100, fos)
                    listMainFile.add(File(path))
                    fos.close()
                }
            }
            var sum = 0.0
            for (file in listMainFile) {
                sum += file.length()
            }

            val listResult: ArrayList<String> = ArrayList()
            listResult.addAll(listMainFile.map { it -> it.path })
            listResult.add(sum.toString())
            return listResult
        } catch (e: Exception) {
            Log.e("ExportPdf error", e.toString())
            throw e
        }

    }

    private fun drawPdfImage(
        resizeBitmap: Bitmap,
        copyNumber: Int,
        countPage: Int,
        paperSizeByPixelPointLimited: Size,
        passportSizeByPixelLimited: Size,
        countColumnIn1Page: Int,
        countRowIn1Page: Int,
        spacingHorizontalByPixelPoint: Double,
        spacingVerticalByPixelPoint: Double,
        marginByPixelPoint: RectF,
    ): ArrayList<Bitmap> {

        val listResultBitmap: ArrayList<Bitmap> = ArrayList()
        for (indexPage in 0 until countPage) {
            val result = generateSinglePdfImage(
                imageData = resizeBitmap,
                paperSizeByPixel = paperSizeByPixelPointLimited,
                passportSizeByPixel = passportSizeByPixelLimited,
                countImageNeedDraw = copyNumber,
                indexPage = indexPage,
                countColumnIn1Page = countColumnIn1Page,
                countRowIn1Page = countRowIn1Page,
                spacingHorizontalByPixel = spacingHorizontalByPixelPoint,
                spacingVerticalByPixel = spacingVerticalByPixelPoint,
                margin = marginByPixelPoint
            )
            listResultBitmap.add(result)
        }
        return listResultBitmap
    }

    private fun generateSinglePdfImage(
        imageData: Bitmap,
        paperSizeByPixel: Size,
        passportSizeByPixel: Size,
        indexPage: Int,
        countImageNeedDraw: Int,
        countRowIn1Page: Int,
        countColumnIn1Page: Int,
        spacingHorizontalByPixel: Double,
        spacingVerticalByPixel: Double,
        margin: RectF
    ): Bitmap {
        println(
            "_generateSinglePdfImage param: " +
                    "paperSizeByPixel = $paperSizeByPixel, " +
                    "passportSizeByPixel = $passportSizeByPixel, " +
                    "countRowIn1Page = $countRowIn1Page, " +
                    "countColumnIn1Page = $countColumnIn1Page, " +
                    "indexPage = $indexPage, " +
                    "spacingHorizontalByPixel = $spacingHorizontalByPixel, " +
                    "spacingVerticalByPixel = $spacingVerticalByPixel, " +
                    "margin: $margin"
        )

        // Tạo bitmap với kích thước paper
        val resultBitmap =
            createBitmap(paperSizeByPixel.width.toInt(), paperSizeByPixel.height.toInt())

        val canvas = Canvas(resultBitmap)

        // Vẽ nền trắng
        canvas.drawRect(
            0f, 0f, paperSizeByPixel.width.toFloat(), paperSizeByPixel.height.toFloat(),
            Paint().apply { color = Color.WHITE }
        )

        // Tính phần thừa để căn giữa các passport
        val totalDrawingWidth = countColumnIn1Page *
                (spacingHorizontalByPixel + passportSizeByPixel.width)
        val deltaWidthToAlignCenter = max(
            0.0,
            (paperSizeByPixel.width - margin.left * 2 - totalDrawingWidth) / 2
        )

        val aspectRatio = passportSizeByPixel.width / passportSizeByPixel.height
        val imageAspectRatio = imageData.width.toFloat() / imageData.height.toFloat()
        println("passportSizeByPixel aspect ratio = $aspectRatio, imageData = $imageAspectRatio")

        for (indexRow in 0 until countRowIn1Page) {
            for (indexColumn in 0 until countColumnIn1Page) {
                val marginLeft = margin.left +
                        passportSizeByPixel.width * indexColumn +
                        spacingHorizontalByPixel * (indexColumn + 1) +
                        deltaWidthToAlignCenter

                val marginTop = margin.top +
                        passportSizeByPixel.height * indexRow +
                        spacingVerticalByPixel * (indexRow + 1)

                // Tính chỉ số ảnh hiện tại
                val currentImageIndex = indexPage * countRowIn1Page * countColumnIn1Page +
                        indexRow * countColumnIn1Page +
                        indexColumn + 1

                val isOverCountImageNeedDraw = currentImageIndex > countImageNeedDraw

                val destRect = RectF(
                    marginLeft.toFloat(),
                    marginTop.toFloat(),
                    (marginLeft + passportSizeByPixel.width).toFloat(),
                    (marginTop + passportSizeByPixel.height).toFloat()
                )

                if (isOverCountImageNeedDraw) {
                    // Vẽ hình chữ nhật trong suốt
                    canvas.drawRect(
                        destRect,
                        Paint().apply { color = Color.TRANSPARENT }
                    )
                } else {
                    // Vẽ ảnh vào vị trí
                    val srcRect = Rect(0, 0, imageData.width, imageData.height)
                    canvas.drawBitmap(
                        imageData,
                        srcRect,
                        destRect,
                        Paint().apply {
                            isFilterBitmap = true
                            isAntiAlias = true
                        }
                    )
                }
            }
        }

        return resultBitmap
    }

    suspend fun handleGenerateMultiplePaperMediaToPdf(
        context: Context,
        imageCroppedPath: String,
        pdfOutPath: String,
        quality: Int,
        copyNumber: Int,
        countPage: Int,
        countColumnIn1Page: Int,
        countRowIn1Page: Int,
        paperSizeByPoint: Size,
        passportSizeByPoint: Size,
        spacingHorizontalByPoint: Double,
        spacingVerticalByPoint: Double,
        marginByPoint: RectF,
    ): ArrayList<String> {
        try {
            val externalDir = context.getExternalFilesDir(null)
            val cacheOutPath = File(externalDir, "finished_image.jpg").path
            val croppedBitmap = BitmapFactory.decodeFile(imageCroppedPath)
            ImageHelper().resizeAndResoluteImage(
                context = context,
                inputPath = imageCroppedPath,
                outPath = cacheOutPath,
                format = 0,
                width = croppedBitmap.width,
                height = croppedBitmap.height,
                scaleWidth = 1.0,
                scaleHeight = 1.0,
                quality = quality,
            )
            val resizeBitmap = BitmapFactory.decodeFile(cacheOutPath)

            generatePaperPdf(
                paperSizeByPoint = paperSizeByPoint,
                passportSizeByPoint = passportSizeByPoint,
                copyNumber = copyNumber,
                countColumnIn1Page = countColumnIn1Page,
                countRowIn1Page = countRowIn1Page,
                marginByPoint = marginByPoint,
                spacingHorizontalByPoint = spacingHorizontalByPoint,
                spacingVerticalByPoint = spacingVerticalByPoint,
                countPage = countPage,
                resizeBitmap = resizeBitmap,
                pdfOutPath = pdfOutPath
            )

            val listResult = ArrayList<String>()

            listResult.add(pdfOutPath)
            listResult.add(File(pdfOutPath).length().toString())
            return listResult

        } catch (e: Exception) {
            Log.e("ExportPdf error", e.toString())
            throw e
        }

    }

    fun generatePaperPdf(
        paperSizeByPoint: Size,
        passportSizeByPoint: Size,
        copyNumber: Int,
        countColumnIn1Page: Int,
        countRowIn1Page: Int,
        marginByPoint: RectF,
        spacingHorizontalByPoint: Double,
        spacingVerticalByPoint: Double,
        countPage: Int,
        resizeBitmap: Bitmap,
        pdfOutPath: String
    ) {
        val pdfDocument = PdfDocument()
        val outputFile = File(pdfOutPath)

        val fos = FileOutputStream(outputFile)
        x
    }

}
