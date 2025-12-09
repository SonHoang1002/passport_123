package com.tapuniverse.passportphoto.exports

import android.content.Context
import android.util.Log
import com.tapuniverse.passportphoto.helper.ImageHelper
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import java.io.FileOutputStream
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext


class ExportPhoto {
    suspend fun handleGenerateSinglePhotoMediaToImage(
        context: Context,
        indexImageFormat: Int,
        imageCroppedPath: String,
        outPath: String,
        quality: Int,
        passportWidthByPixelPointLimited: Double,
        passportHeightByPixelPointLimited: Double,
    ): ArrayList<String> {
        return try {
            val inputFile = File(imageCroppedPath)
            if (!inputFile.exists()) {
                throw FileNotFoundException("Input file not found: $imageCroppedPath")
            }

            if (passportWidthByPixelPointLimited <= 0 || passportHeightByPixelPointLimited <= 0) {
                throw IllegalArgumentException("Invalid dimensions: ${passportWidthByPixelPointLimited}x$passportHeightByPixelPointLimited")
            }

            if (quality < 0 || quality > 100) {
                throw IllegalArgumentException("Quality must be between 0-100: $quality")
            }

            ImageHelper().resizeAndResoluteImage(
                context = context,
                inputPath = imageCroppedPath,
                outPath = outPath,
                format = indexImageFormat,
                width = passportWidthByPixelPointLimited.toInt(),
                height = passportHeightByPixelPointLimited.toInt(),
                scaleWidth = 1.0,
                scaleHeight = 1.0,
                quality = quality,
            )

            val outputFile = File(outPath)
            if (!outputFile.exists()) {
                throw IOException("Output file was not created: $outPath")
            }

            val fileSize = outputFile.length()
            if (fileSize <= 0) {
                throw IOException("Output file has invalid size: $fileSize bytes")
            }

            val listResult = ArrayList<String>()
            listResult.add(outPath)
            listResult.add(fileSize.toDouble().toString())
            listResult
        } catch (e: Exception) {
            Log.e("PhotoMedia", "Unexpected error", e)
            throw e
        }
    }

      suspend fun generateSingleImagePdf(
        passportWidth: Double,
        passportHeight: Double,
        listFilePath: List<String>,
        pdfOutPath: String,
    ): ArrayList<String>? {
        return try {
            withContext(Dispatchers.IO) {
                val pdfDocument = PdfDocument()
                val outputFile = File(pdfOutPath)

                val fos = FileOutputStream(outputFile)
                try {
                    for ((index, filePath) in listFilePath.withIndex()) {
                        val file = File(filePath)
                        if (!file.exists()) {
                            println("Warning: File not found: $filePath")
                            continue
                        }

                        val bitmap = BitmapFactory.decodeFile(filePath)
                        if (bitmap == null) {
                            println("Warning: Cannot decode bitmap: $filePath")
                            continue
                        }

                        try {
                            val pageInfo = PdfDocument.PageInfo.Builder(
                                passportWidth.toInt(),
                                passportHeight.toInt(),
                                index + 1
                            ).create()

                            val page = pdfDocument.startPage(pageInfo)
                            val canvas = page.canvas

                            val paint = Paint()

                            val scaleX = passportWidth / bitmap.width
                            val scaleY = passportHeight / bitmap.height
                            val scale = maxOf(scaleX, scaleY)

                            val scaledWidth = (bitmap.width * scale).toFloat()
                            val scaledHeight = (bitmap.height * scale).toFloat()

                            val left = (passportWidth - scaledWidth) / 2
                            val top = (passportHeight - scaledHeight) / 2

                            val matrix = Matrix().apply {
                                postScale(scale.toFloat(), scale.toFloat())
                                postTranslate(left.toFloat(), top.toFloat())
                            }

                            canvas.drawBitmap(bitmap, matrix, paint)

                            pdfDocument.finishPage(page)

                        } finally {
                            bitmap.recycle()
                        }
                    }

                    if (pdfDocument.pages.isEmpty()) {
                        throw IllegalStateException("No valid images to create PDF")
                    }

                    pdfDocument.writeTo(fos)
                    fos.flush()

                    println ("PDF created successfully: ${outputFile.absolutePath}")
                    println("PDF size: ${outputFile.length()} bytes, Pages: ${pdfDocument.pages.size}")

                    val listResult = ArrayList<String>()
                     listResult.add(outputFile.absolutePath)
                     listResult.add(outputFile.length().toString())
                     listResult

                } catch (e: Exception) {
                    println("Error creating PDF: ${e.message}")
                    outputFile.takeIf { it.exists() }?.delete()
                    null
                } finally {
                    try {
                        fos.close()
                    } catch (e: IOException) {
                        println("Error closing stream: ${e.message}")
                    }
                    pdfDocument.close()
                }
            }
        } catch (e: Exception) {
            println("generatePdf error: ${e.message}")
            null
        }
    }
}
