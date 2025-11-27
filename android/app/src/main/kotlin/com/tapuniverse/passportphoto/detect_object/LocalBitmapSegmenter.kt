package com.tapuniverse.passportphoto.detect_object

import android.app.ActivityManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.util.Log
import com.google.mlkit.vision.objects.ObjectDetector
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import org.tensorflow.lite.DataType
import org.tensorflow.lite.InterpreterApi
import org.tensorflow.lite.nnapi.NnApiDelegate
import org.tensorflow.lite.support.common.FileUtil
import org.tensorflow.lite.support.common.TensorOperator
import org.tensorflow.lite.support.common.ops.NormalizeOp
import org.tensorflow.lite.support.image.ImageProcessor
import org.tensorflow.lite.support.image.TensorImage
import org.tensorflow.lite.support.image.ops.ResizeOp
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer
import org.tensorflow.lite.support.tensorbuffer.TensorBufferFloat
import java.io.ByteArrayOutputStream

class LocalBitmapSegmenter constructor(context: Context) {
    private val TAG = "LocalBitmapSegmenter"
//    private lateinit var objectDetector: ObjectDetector
//    private val expandPercent = 3
    private var tensorImage = TensorImage(DataType.FLOAT32)
    private lateinit var imageProcessor: ImageProcessor
    private var tflite: InterpreterApi? = null
    private var SMART_AI_MIN_MEMORY = 2000000000

    companion object {
        const val LOCAL_MASK_SIZE = 320
//        val SEGMENTATION_USING_API = false
    }

    fun Bitmap.toSendByteArray(): ByteArray {
        val stream = ByteArrayOutputStream()
        stream.use {
            this.compress(Bitmap.CompressFormat.PNG, 100, it)
            return stream.toByteArray()
        }
    }

    init {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        val totalMem = memoryInfo.totalMem
        Log.d(TAG, "Memory info: avail mem: ${memoryInfo.availMem}")
        Log.d(TAG, "Memory info: total mem: ${memoryInfo.totalMem}")
        Log.d(TAG, "Memory info: threshold mem: ${memoryInfo.threshold}")
        Log.d(TAG, "Memory info: low mem: ${memoryInfo.lowMemory}")
        Log.d(TAG, "Memory info:---")

        if (totalMem > SMART_AI_MIN_MEMORY) {
            CoroutineScope(Dispatchers.IO).launch {
                imageProcessor = ImageProcessor.Builder()
                    .add(ResizeOp(320, 320, ResizeOp.ResizeMethod.NEAREST_NEIGHBOR))
                    .add(
                        NormalizeOp(
                            floatArrayOf(0.485f, 0.456f, 0.406f),
                            floatArrayOf(0.229f, 0.224f, 0.225f)
                        )
                    )
                    .add(TensorOperator { input ->
                        val data = input.floatArray
                        for (i in data.indices) {
                            data[i] /= 1000f
                        }
                        val output =
                            TensorBufferFloat.createFixedSize(input.shape, DataType.FLOAT32)
                        output.loadArray(data, input.shape)
                        return@TensorOperator output
                    })
                    .build()
                Log.i(TAG, "after imageProcessor")
                val tfLiteModel = FileUtil.loadMappedFile(context, "u2net_float32.tflite")
                Log.i(TAG, "after imageProcessor")

                val interpreterOptions = InterpreterApi.Options()
                interpreterOptions.numThreads = 4
                try {
                    Log.d(TAG, "NNapi delegate: ")
                    val nnApiDelegateOptions = NnApiDelegate.Options()
                    nnApiDelegateOptions.useNnapiCpu = false
                    nnApiDelegateOptions.maxNumberOfDelegatedPartitions = 1
                    Log.d(
                        TAG,
                        "acceleratorName: ${nnApiDelegateOptions.useNnapiCpu} ${nnApiDelegateOptions.maxNumberOfDelegatedPartitions}"
                    )
                    val nnApiDelegate = NnApiDelegate(nnApiDelegateOptions)
                    interpreterOptions.addDelegate(nnApiDelegate)
                    tflite = InterpreterApi.create(tfLiteModel, interpreterOptions)
                    Log.d(TAG, "Tflite: $tflite")
                } catch (nnapiException: Exception) {
                    nnapiException.printStackTrace()
                    try {
                        tflite = InterpreterApi.create(tfLiteModel, InterpreterApi.Options())
                        Log.d(TAG, "Tflite: $tflite")
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }
    }


    fun segmentPathBitmap(bitmap: Bitmap): Flow<SegmentResult> {
        return flow {
            Log.d(TAG, "segmentPathBitmap: START")
            try {
                val startTime = System.nanoTime()

                val outputTensorBuffer = TensorBuffer.createFixedSize(
                    intArrayOf(1, LOCAL_MASK_SIZE, LOCAL_MASK_SIZE, 1),
                    DataType.FLOAT32
                )
                tensorImage.load(bitmap)
                tensorImage = imageProcessor.process(tensorImage)
                if (tflite == null) {
                    emit(SegmentResult(null, ResultCode.TF_LITE_NOT_INITIALIZED))
                    return@flow
                }
                tflite?.run(tensorImage.buffer, outputTensorBuffer.buffer)
                Log.d(TAG, "segmentPathBitmap: Done running")

                val endTfLiteRunTime = System.nanoTime()

                Log.d(TAG, "segmentPathBitmap: start create bitmap")

                val floatArray = outputTensorBuffer.floatArray
                val min = floatArray.min()
                val max = floatArray.max()
                val colors = IntArray(floatArray.size)
                var transBelow50 = 0
                for (i in floatArray.indices) {
                    val color = (floatArray[i] - min) / (max - min)
                    colors[i] = Color.argb(color, color, color, color)
                    if (color < 0.5f) transBelow50++;
                }

                Log.d(
                    TAG,
                    "SEGMENTATION_PATH - " + "Percent transBelow50 : ${transBelow50.toFloat() / colors.size * 100f}"
                )
                val bitmapResult = Bitmap.createBitmap(
                    colors,
                    LOCAL_MASK_SIZE,
                    LOCAL_MASK_SIZE,
                    Bitmap.Config.ARGB_8888
                )

                val endTime = System.nanoTime()

                Log.d(
                    TAG,
                    "SEGMENTATION_PATH - " + "Run run model: ${(endTfLiteRunTime - startTime) / 1000000}, total time including creating bitmap: ${(endTime - startTime) / 1000000}"
                )
                val percentTransBelow50 = transBelow50.toFloat() / colors.size
                if (percentTransBelow50 > 0.97) {
                    emit(SegmentResult(null, ResultCode.FAIL))
                    return@flow
                }
                emit(SegmentResult(bitmapResult, ResultCode.SUCCESS))
            } catch (e: Exception) {
                Log.e(TAG, "segmentPathBitmap got ERROR", e)
                e.printStackTrace()
                emit(SegmentResult(null, ResultCode.FAIL))
            }
        }.flowOn(Dispatchers.IO)
    }

    private fun generateRandomColor(number: Int): Int {
        val hue = (number * 137.508f) % 360
        return Color.HSVToColor(floatArrayOf(hue, 0.5f, 0.75f))
    }
}