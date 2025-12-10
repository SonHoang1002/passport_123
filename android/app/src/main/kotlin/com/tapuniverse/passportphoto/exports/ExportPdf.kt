package com.tapuniverse.passportphoto.exports

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.tapuniverse.passportphoto.helper.ImageHelper
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.pdf.PdfDocument
import android.util.Size
import androidx.core.graphics.createBitmap
import kotlin.math.ceil
import kotlin.math.max
import java.io.File
import java.io.FileOutputStream
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.min


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
        spacingHorizontalByPixel: Double,  // spacing GIỮA các ảnh
        spacingVerticalByPixel: Double,    // spacing GIỮA các hàng
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

        // Tính toán căn giữa theo chiều ngang
        // Tổng chiều rộng cần vẽ = n * imageWidth + (n-1) * spacing
        val totalWidthNeeded = countColumnIn1Page * passportSizeByPixel.width +
                (countColumnIn1Page - 1) * spacingHorizontalByPixel

        // Khoảng cách cần thêm vào 2 bên để căn giữa chiều ngang
        val deltaWidthToAlignCenter = max(
            0.0,
            (paperSizeByPixel.width - margin.left - margin.right - totalWidthNeeded) / 2
        )

        println("Total width needed: $totalWidthNeeded, Delta width: $deltaWidthToAlignCenter")

        val aspectRatio = passportSizeByPixel.width / passportSizeByPixel.height
        val imageAspectRatio = imageData.width.toFloat() / imageData.height.toFloat()
        println("passportSizeByPixel aspect ratio = $aspectRatio, imageData = $imageAspectRatio")

        for (indexRow in 0 until countRowIn1Page) {
            for (indexColumn in 0 until countColumnIn1Page) {
                // Tính toán vị trí
                // Chiều ngang: margin + căn_giữa + column * (imageWidth + spacing)
                val left = margin.left +
                        deltaWidthToAlignCenter +
                        indexColumn * (passportSizeByPixel.width + spacingHorizontalByPixel*2)

                // Chiều dọc: margin + row * (imageHeight + spacing) - KHÔNG căn giữa
                val top = margin.top +
                        indexRow * (passportSizeByPixel.height + spacingVerticalByPixel*2)

                // Tính chỉ số ảnh hiện tại (bắt đầu từ 0)
                val currentImageIndex = indexPage * countRowIn1Page * countColumnIn1Page +
                        indexRow * countColumnIn1Page +
                        indexColumn

                val isOverCountImageNeedDraw = currentImageIndex >= countImageNeedDraw

                val destRect = RectF(
                    left.toFloat(),
                    top.toFloat(),
                    (left + passportSizeByPixel.width).toFloat(),
                    (top + passportSizeByPixel.height).toFloat()
                )

                if (isOverCountImageNeedDraw) {
                    // Vẽ hình chữ nhật trong suốt
                    canvas.drawRect(
                        destRect,
                        Paint().apply {
                            color = Color.TRANSPARENT
                            style = Paint.Style.FILL
                        }
                    )

                    // Vẽ border cho container trống (tùy chọn, để debug)
                    canvas.drawRect(
                        destRect,
                        Paint().apply {
                            color = Color.LTGRAY
                            style = Paint.Style.STROKE
                            strokeWidth = 0.5f
                        }
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

                    // Vẽ border xung quanh ảnh (tùy chọn, để debug)
                    canvas.drawRect(
                        destRect,
                        Paint().apply {
                            color = Color.argb(50, 128, 128, 128) // Màu xám trong suốt
                            style = Paint.Style.STROKE
                            strokeWidth = 0.5f
                        }
                    )
                }

                // Debug: in ra vị trí của ảnh đầu tiên mỗi hàng
                if (indexColumn == 0) {
                    println("Row $indexRow: top = $top, destRect = $destRect")
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
                marginByPoint = marginByPoint,
                spacingHorizontalByPoint = spacingHorizontalByPoint,
                spacingVerticalByPoint = spacingVerticalByPoint,
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
        marginByPoint: RectF,
        spacingHorizontalByPoint: Double,  // spacing GIỮA các ảnh (dùng cho margin)
        spacingVerticalByPoint: Double,    // spacing GIỮA các hàng (dùng cho margin)
        resizeBitmap: Bitmap,
        pdfOutPath: String
    ) {
        try {
            val pdfDocument = PdfDocument()
            val outputFile = File(pdfOutPath)

            // Tạo thư mục nếu chưa tồn tại
            outputFile.parentFile?.mkdirs()

            val fos = FileOutputStream(outputFile)

            // Tính toán tương tự Dart code
            // imageSize = passportSize + spacing * 2 (vì spacing ở cả 2 bên)
            val imageSizeWithSpacing = Size(
                (passportSizeByPoint.width + spacingHorizontalByPoint * 2).toInt(),
                (passportSizeByPoint.height + spacingVerticalByPoint * 2).toInt()
            )

            // Tính toán số ảnh trong 1 hàng
            // availableWidth = paperSize - marginLeft - marginRight
            val availableWidth = paperSizeByPoint.width - marginByPoint.left - marginByPoint.right

            // Tính số ảnh trong 1 hàng: availableWidth / imageSizeWithSpacing.width
            val countImageIn1Row = if (availableWidth > 0 && imageSizeWithSpacing.width > 0) {
                floor(availableWidth / imageSizeWithSpacing.width).toInt()
            } else {
                0
            }

            // Tính toán tương tự cho số hàng
            // availableHeight = paperSize - marginTop - marginBottom
            val availableHeight = paperSizeByPoint.height - marginByPoint.top - marginByPoint.bottom

            val countImageIn1Column = if (availableHeight > 0 && imageSizeWithSpacing.height > 0) {
                floor(availableHeight / imageSizeWithSpacing.height).toInt()
            } else {
                0
            }

            // Đảm bảo không nhỏ hơn 1
            val countImageIn1Page = max(1, countImageIn1Row) * max(1, countImageIn1Column)
            val countPage = ceil(copyNumber.toDouble() / countImageIn1Page).toInt()

            // Kiểm tra nếu không đủ chỗ cho ít nhất 1 ảnh
            if (countImageIn1Row < 1 || countImageIn1Column < 1) {
                throw IllegalArgumentException("Kích thước ảnh quá lớn so với trang giấy")
            }

            // Tính toán tổng chiều rộng cần vẽ để căn giữa chiều ngang
            // Tổng chiều rộng = n * imageSizeWithSpacing.width
            val totalWidthNeeded = countImageIn1Row * imageSizeWithSpacing.width

            // Khoảng cách cần thêm vào 2 bên để căn giữa chiều ngang
            val deltaWidthToAlignCenter = max(
                0.0,
                ((availableWidth - totalWidthNeeded) / 2).toDouble()
            )

            println("Total width needed: $totalWidthNeeded, Delta width: $deltaWidthToAlignCenter")
            println("Count per page: $countImageIn1Page, Total pages: $countPage")

            // Tạo ma trận cho bitmap để fit cover (tương tự pw.BoxFit.cover)
            val bitmapMatrix = Matrix()
            val scaleX = passportSizeByPoint.width / resizeBitmap.width.toFloat()
            val scaleY = passportSizeByPoint.height / resizeBitmap.height.toFloat()
            val scale = maxOf(scaleX, scaleY) // BoxFit.cover lấy scale lớn hơn

            bitmapMatrix.setScale(scale, scale)

            // Tính toán offset để căn giữa sau khi scale
            val scaledWidth = resizeBitmap.width * scale
            val scaledHeight = resizeBitmap.height * scale
            val offsetX = (passportSizeByPoint.width - scaledWidth) / 2
            val offsetY = (passportSizeByPoint.height - scaledHeight) / 2
            bitmapMatrix.postTranslate(offsetX, offsetY)

            for (pageIndex in 0 until countPage) {
                val pageInfo = PdfDocument.PageInfo.Builder(
                    paperSizeByPoint.width.toInt(),
                    paperSizeByPoint.height.toInt(),
                    pageIndex + 1
                ).create()

                val page = pdfDocument.startPage(pageInfo)
                val canvas = page.canvas
                val paint = Paint()

                // Vẽ nền trắng cho trang
                paint.color = Color.WHITE
                paint.style = Paint.Style.FILL
                canvas.drawRect(
                    0f,
                    0f,
                    paperSizeByPoint.width.toFloat(),
                    paperSizeByPoint.height.toFloat(),
                    paint
                )

                // Số ảnh cần vẽ trên trang hiện tại
                val soAnh = if (pageIndex == countPage - 1) {
                    // Trang cuối: số ảnh còn lại
                    copyNumber - countImageIn1Page * (countPage - 1)
                } else {
                    countImageIn1Page
                }

                // Vẽ tất cả các vị trí (cả ảnh thật và container trống)
                for (indexInPage in 0 until countImageIn1Page) {
                    // Tính toán vị trí hàng và cột
                    val row = indexInPage / countImageIn1Row
                    val col = indexInPage % countImageIn1Row

                    // Tính toán tọa độ với căn giữa chiều ngang
                    // Chiều ngang: margin + căn_giữa + column * imageSizeWithSpacing.width
                    val left = marginByPoint.left +
                            deltaWidthToAlignCenter +
                            col * imageSizeWithSpacing.width

                    // Chiều dọc: margin + row * imageSizeWithSpacing.height - KHÔNG căn giữa
                    val top = marginByPoint.top +
                            row * imageSizeWithSpacing.height

                    // Kiểm tra nếu vượt quá số ảnh cần vẽ -> vẽ container trống
                    if (indexInPage >= soAnh) {
                        // Vẽ container trống trong suốt
                        continue
                    }

                    // Tính toán vị trí thực tế để vẽ ảnh (có tính spacing)
                    val imageLeft = left + spacingHorizontalByPoint
                    val imageTop = top + spacingVerticalByPoint

                    // Vẽ background xám cho container ảnh (tương tự PdfColors.grey500)
                    paint.color = Color.rgb(158, 158, 158) // Màu grey500
                    paint.style = Paint.Style.FILL
                    canvas.drawRect(
                        RectF(
                            imageLeft.toFloat(),
                            imageTop.toFloat(),
                            (imageLeft + passportSizeByPoint.width).toFloat(),
                            (imageTop + passportSizeByPoint.height).toFloat()
                        ),
                        paint
                    )

                    // Vẽ bitmap với BoxFit.cover
                    canvas.save()
                    canvas.translate(imageLeft.toFloat(), imageTop.toFloat())
                    canvas.drawBitmap(resizeBitmap, bitmapMatrix, paint)
                    canvas.restore()

                    // Vẽ border xung quanh ảnh (tùy chọn)
                    paint.color = Color.LTGRAY
                    paint.style = Paint.Style.STROKE
                    paint.strokeWidth = 0.5f
                    canvas.drawRect(
                        RectF(
                            imageLeft.toFloat(),
                            imageTop.toFloat(),
                            (imageLeft + passportSizeByPoint.width).toFloat(),
                            (imageTop + passportSizeByPoint.height).toFloat()
                        ),
                        paint
                    )
                }

                pdfDocument.finishPage(page)
            }

            // Ghi PDF ra file
            pdfDocument.writeTo(fos)
            pdfDocument.close()
            fos.close()

            println("PDF created successfully at: $pdfOutPath")

        } catch (e: Exception) {
            e.printStackTrace()
            throw e
        }
    }


}
