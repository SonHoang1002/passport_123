package com.tapuniverse.passportphoto

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import com.tapuniverse.passportphoto.canvas.GenerateImageWithCanvas
import com.tapuniverse.passportphoto.canvas.Margin
import com.tapuniverse.feedbackpopup.showPopupFeedback
import com.tapuniverse.passportphoto.exports.ExportPhoto
import com.tapuniverse.passportphoto.helper.DocumentFileSaver
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import android.content.Context
import android.graphics.RectF
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.util.Size
import com.tapuniverse.passportphoto.exports.ExportPdf
import com.tapuniverse.passportphoto.helper.ImageHelper
import kotlinx.coroutines.Job

private const val TAG = "MainActivity"

class MainActivity : FlutterFragmentActivity() {
//    var removeBg: RemoveBackground? = null
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        removeBg = RemoveBackground(this.applicationContext)
//    }

    companion object {
        const val CHANNEL = "com.tapuniverse.passportphoto"
        const val REQ_CODE_DOCUMENT_SAVER = 39285
    };

    private val REQUEST_CODE_CREATE_DOCUMENT = 1

    var listFilePathForSaveActionDocument: List<String>? = null
    var methodResult: MethodChannel.Result? = null

    var job: Job? = null;
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "configureFlutterEngine: ")
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            methodResult = result
            when (call.method) {
                "resizeAndResoluteImage" -> {
                    try {
//                    var args = call.arguments as List<Any>
//                    val inputPath = args[0] as String
//                    val outputPath = args[1] as String
//                    val format = args[2] as Int
//                    val width = args[3] as Int
//                    val height = args[4] as Int
//                    val scaleWidth = args[5] as Double
//                    val scaleHeight = args[6] as Double
                        val args = call.arguments as Map<*, *>
                        val inputPath = args["inputPath"] as String
                        val outputPath = args["outputPath"] as String
                        val format = args["indexFormat"] as Int
                        val width = args["width"] as Int?
                        val height = args["height"] as Int?
                        val scale = args["scale"] as List<Double?>?
                        val quality = args["quality"] as Int
                        val context = this
                        job?.cancel()
                        job = null
                        job = CoroutineScope(Dispatchers.IO).launch {
                            val resultExport =
                                ImageHelper().resizeAndResoluteImage(
                                    context,
                                    inputPath,
                                    outputPath,
                                    format,
                                    width,
                                    height,
                                    scaleWidth = scale?.get(0),
                                    scaleHeight = scale?.get(1),
                                    quality = quality
                                )
                            withContext(Dispatchers.Main) {
                                result.success(resultExport)
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("Method Channel Error", "ResizeAndResoluteImage: $e")
                    }
                }

                "showPopupFeedback" -> {
                    try {
                        val activity: MainActivity = this
                        showPopupFeedback(
                            activity.supportFragmentManager,
                            "tapuniverse@gmail.com",
                            activity,
                            null
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("Method Channel Error", "ResizeImage: $e")
                    }
                }

                "maskTwoImage" -> {
                    try {
                        val listData = call.arguments as List<*>
                        val originFilePath = listData[0] as String
                        val transparentFilePath = listData[1] as String
                        val outputPath = listData[2] as String
                        PassportCanvas().maskTwoImage(
                            originFilePath,
                            transparentFilePath,
                            outputPath
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("Method Channel Error", "MaskTwoImage: $e")
                    }
                }

                "detectAndSeperateObject" -> {

                }

                "generateSinglePage" -> {
                    val args = call.arguments as Map<*, *>

                    val passportPath = args["passportPath"] as String

                    val outputPath = args["outputPath"] as String

                    val paperSize = args["paperSize"] as List<Double>
                    val paperWidth = paperSize[0]
                    val paperHeight = paperSize[1]

                    val passportSize = args["passportSize"] as List<Double>
                    val passportWidth = passportSize[0]
                    val passportHeight = passportSize[1]

                    val countImageOn1Row = args["countImageOn1Row"] as Int

                    val countRow = args["countRow"] as Int

                    val countImageNeedDraw = args["countImageNeedDraw"] as Int

                    val spacingHorizontal = args["spacingHorizontal"] as List<Double>

                    val spacingVertical = args["spacingVertical"] as List<Double>

                    val margins = args["margins"] as List<Double>

                    val margin = Margin(margins[0], margins[1], margins[2], margins[3])

                    val qualityPassport = args["qualityPassport"] as Int

                    val outputFormat = args["outputFormat"] as Int

                    val bitmapConfigIndex = args["bitmapConfigIndex"] as Int

                    try {
                        job?.cancel()
                        job = null
                        job = CoroutineScope(Dispatchers.IO).launch {
                            val resultExport = GenerateImageWithCanvas().generateSinglePage(
                                passportPath, outputPath,
                                paperWidth, paperHeight,
                                passportWidth, passportHeight,
                                countImageOn1Row,
                                countRow,
                                countImageNeedDraw,
                                spacingHorizontal,
                                spacingVertical,
                                margin,
                                qualityPassport,
                                outputFormat,
                                bitmapConfigIndex
                            )
                            result.success(resultExport)
                        }
                    } catch (e: Exception) {
                        result.error("generateSinglePage error", e.message, null)
                    }
                }

                "action_create_document" -> {
                    val args = call.arguments as Map<String, Any>
                    val listPath = args["listPath"] as List<String>
                    val mimeType = args["mimeType"] as String

                    listFilePathForSaveActionDocument = listPath
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        setTypeAndNormalize(mimeType)
                        type = mimeType
                        putExtra(Intent.EXTRA_TITLE, "Passport")
                    }
                    Log.d(
                        "action_create_document",
                        "onActivityResult: listPath: ${listPath[0]} -  ${listPath.size}, mimeType: $mimeType"
                    )
                    startActivityForResult(intent, REQUEST_CODE_CREATE_DOCUMENT)
                }

                "getPlatformVersion" -> {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                }

                "getBatteryPercentage" -> {
                    val batteryManager =
                        this.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                    val value =
                        batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                    result.success(value)
                }

                "saveMultipleFiles" -> {
                    var permissionGranted = true

                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q && ActivityCompat.checkSelfPermission(
                            this,
                            Manifest.permission.WRITE_EXTERNAL_STORAGE
                        ) != PackageManager.PERMISSION_GRANTED
                    )
                        permissionGranted = false

                    if (permissionGranted) {
                        val dataList: List<ByteArray> = call.argument("dataList")!!
                        val fileNameList: List<String> = call.argument("fileNameList")!!
                        val mimeTypeList: List<String> = call.argument("mimeTypeList")!!
                        DocumentFileSaver().saveMultipleFiles(
                            this,
                            dataList,
                            fileNameList,
                            mimeTypeList
                        )
                        result.success(null)
                    } else {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                            REQ_CODE_DOCUMENT_SAVER
                        )
                    }
                }

                "showToast" -> {
                    val context = this
                    val data = call.arguments as Map<*, *>
                    val message = data["message"] as String
                    showToast(context, message)
                }

                "checkNetworkConnection" -> {
                    result.success(hasNetworkConnection())

                }

                "handleGenerateSinglePhotoMediaToImage" -> {
                    try {
                        val args = call.arguments as Map<*, *>
                        val indexImageFormat = args["indexImageFormat"] as Int
                        val imageCroppedPath = args["imageCroppedPath"] as String
                        val outPath = args["outPath"] as String
                        val quality = args["quality"] as Int
                        val passportWidthByPixelPointLimited =
                            args["passportWidthByPixelPointLimited"] as Double
                        val passportHeightByPixelPointLimited =
                            args["passportHeightByPixelPointLimited"] as Double
                        val context = this
                        job?.cancel()
                        job = null;
                        job = CoroutineScope(Dispatchers.IO).launch {
                            val result1 = ExportPhoto().handleGenerateSinglePhotoMediaToImage(
                                context = context,
                                indexImageFormat = indexImageFormat,
                                imageCroppedPath = imageCroppedPath,
                                outPath = outPath,
                                quality = quality,
                                passportWidthByPixelPointLimited = passportWidthByPixelPointLimited,
                                passportHeightByPixelPointLimited = passportHeightByPixelPointLimited,
                            )
                            withContext(Dispatchers.Main) {
                                result.success(result1)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("handleGenerateSinglePhotoMedia error", e.message, null)
                    }
                }

                "generateSingleImagePdf" -> {
                    try {
                        val args = call.arguments as Map<*, *>
                        val pdfOutPath = args["pdfOutPath"] as String
                        val passportWidth =
                            args["passportWidth"] as Double
                        val passportHeight =
                            args["passportHeight"] as Double
                        val listFilePath = args["listFilePath"] as List<String>
                        job?.cancel()
                        job = null
                        job = CoroutineScope(Dispatchers.IO).launch {
                            val result1 = ExportPhoto().generateSingleImagePdf(
                                passportWidth = passportWidth,
                                passportHeight = passportHeight,
                                pdfOutPath = pdfOutPath,
                                listFilePath = listFilePath,
                            )
                            withContext(Dispatchers.Main) {
                                result.success(result1)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("handleGenerateSinglePhotoMedia error", e.message, null)
                    }
                }

                "handleGenerateMultiplePaperMediaToImage" -> {
                    try {
                        val args = call.arguments as Map<*, *>
                        val imageCroppedPath = args["imageCroppedPath"] as String
                        val indexImageFormat = args["indexImageFormat"] as Int
                        val extension = args["extension"] as String
                        val quality = args["quality"] as Int
                        val copyNumber = args["copyNumber"] as Int
                        val countPage = args["countPage"] as Int
                        val paperWidthByPixelPointLimited =
                            args["paperWidthByPixelPointLimited"] as Double
                        val paperHeightByPixelPointLimited =
                            args["paperHeightByPixelPointLimited"] as Double

                        val paperSizeByPixelPointLimited = Size(
                            paperWidthByPixelPointLimited.toInt(),
                            paperHeightByPixelPointLimited.toInt()
                        )

                        val passportWidthByPixelLimited =
                            args["passportWidthByPixelLimited"] as Double
                        val passportHeightByPixelLimited =
                            args["passportHeightByPixelLimited"] as Double

                        val passportSizeByPixelLimited = Size(
                            passportWidthByPixelLimited.toInt(),
                            passportHeightByPixelLimited.toInt()
                        )

                        val countColumnIn1Page = args["countColumnIn1Page"] as Int
                        val countRowIn1Page = args["countRowIn1Page"] as Int
                        val spacingHorizontalByPixelPoint =
                            args["spacingHorizontalByPixelPoint"] as Double
                        val spacingVerticalByPixelPoint =
                            args["spacingVerticalByPixelPoint"] as Double
                        val marginByPixelPointLeft = args["marginByPixelPointLeft"] as Double
                        val marginByPixelPointTop = args["marginByPixelPointTop"] as Double
                        val marginByPixelPointRight = args["marginByPixelPointRight"] as Double
                        val marginByPixelPointBottom = args["marginByPixelPointBottom"] as Double

                        val marginByPixelPoint = RectF(
                            marginByPixelPointLeft.toFloat(),
                            marginByPixelPointTop.toFloat(),
                            marginByPixelPointRight.toFloat(),
                            marginByPixelPointBottom.toFloat()
                        )
                        val context = this
                        job?.cancel()
                        job = null
                        job = CoroutineScope(Dispatchers.IO).launch {
                          val result1 =  ExportPdf().handleGenerateMultiplePaperMediaToImage(
                                context = context,
                                imageCroppedPath = imageCroppedPath,
                                indexImageFormat = indexImageFormat,
                                extension = extension,
                                quality = quality,
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
                            withContext(Dispatchers.Main){
                                result.success(result1)
                            }
                        }

                    } catch (e: Exception) {
                        result.error(
                            "handleGenerateMultiplePaperMediaToImage error",
                            e.message,
                            null
                        )
                        Log.e("handleGenerateMultiplePaperMediaToImage", e.toString())
                    }
                }

                "handleGenerateMultiplePaperMediaToPdf" -> {
                    try {
                        val args = call.arguments as Map<*, *>
                        val imageCroppedPath = args["imageCroppedPath"] as String
                        val pdfOutPath = args["pdfOutPath"] as String
                        val quality = args["quality"] as Int
                        val copyNumber = args["copyNumber"] as Int
                        val paperWidthByPoint =
                            args["paperWidthByPoint"] as Double
                        val paperHeightByPoint =
                            args["paperHeightByPoint"] as Double

                        val paperSizeByPoint = Size(
                            paperWidthByPoint.toInt(),
                            paperHeightByPoint.toInt()
                        )

                        val passportWidthByPoint =
                            args["passportWidthByPoint"] as Double
                        val passportHeightByPoint =
                            args["passportHeightByPoint"] as Double

                        val passportSizeByPoint = Size(
                            passportWidthByPoint.toInt(),
                            passportHeightByPoint.toInt()
                        )

                        val spacingHorizontalByPoint =
                            args["spacingHorizontalByPoint"] as Double
                        val spacingVerticalByPoint =
                            args["spacingVerticalByPoint"] as Double
                        val marginByPointLeft = args["marginByPointLeft"] as Double
                        val marginByPointTop = args["marginByPointTop"] as Double
                        val marginByPointRight = args["marginByPointRight"] as Double
                        val marginByPointBottom = args["marginByPointBottom"] as Double

                        val marginByPoint = RectF(
                            marginByPointLeft.toFloat(),
                            marginByPointTop.toFloat(),
                            marginByPointRight.toFloat(),
                            marginByPointBottom.toFloat()
                        )
                        val context = this
                        job?.cancel()
                        job = null
                        job = CoroutineScope(Dispatchers.IO).launch {
                            val result1 =  ExportPdf().handleGenerateMultiplePaperMediaToPdf(
                                context = context,
                                imageCroppedPath = imageCroppedPath,
                                pdfOutPath = pdfOutPath,
                                quality = quality,
                                copyNumber = copyNumber,
                                paperSizeByPoint = paperSizeByPoint,
                                passportSizeByPoint = passportSizeByPoint,
                                spacingHorizontalByPoint = spacingHorizontalByPoint,
                                spacingVerticalByPoint = spacingVerticalByPoint,
                                marginByPoint = marginByPoint,
                            )
                            withContext(Dispatchers.Main){
                                result.success(result1)
                            }
                        }

                    } catch (e: Exception) {
                        result.error(
                            "handleGenerateMultiplePaperMediaToImage error",
                            e.message,
                            null
                        )
                        Log.e("handleGenerateMultiplePaperMediaToImage", e.toString())
                    }
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_CREATE_DOCUMENT && resultCode == Activity.RESULT_OK) {
            data?.data?.let { uri ->
                CoroutineScope(Dispatchers.IO).launch {
                    for (index in 0 until listFilePathForSaveActionDocument!!.size) {
                        val file = File(listFilePathForSaveActionDocument!![index])
                        saveFileToUri(file, uri)
                    }
                    Log.d(
                        "REQUEST_CODE_CREATE_DOCUMENT",
                        "onActivityResult: uri: ${uri}"
                    )
                    withContext(Dispatchers.Main) {
                        methodResult?.success(true)
                    }
                }
            }

        }
    }

    private suspend fun saveFileToUri(file: File, uri: Uri) {
        Log.d(
            "REQUEST_CODE_CREATE_DOCUMENT",
            "saveFileToUri: uri: ${uri}"
        )
        withContext(Dispatchers.IO) {
            try {
                contentResolver.openOutputStream(uri)?.use { outputStream ->
                    file.inputStream().use { inputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }


}

fun Context.hasNetworkConnection(): Boolean {
    val connectivityManager =
        getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    val network = connectivityManager.activeNetwork ?: return false
    val activeNetwork =
        connectivityManager.getNetworkCapabilities(network) ?: return false

    return when {
        activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> true
        activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> true
        activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> true
        else -> false
    }
}

