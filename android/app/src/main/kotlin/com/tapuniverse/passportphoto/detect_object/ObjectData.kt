package com.tapuniverse.passportphoto.detect_object

import android.graphics.Rect

/**
 * @param boundingBox: dùng để detect touch vào đối tượng nào
 * @param maskingBox: Dùng trong generating mask
 */
data class ObjectData(var id: Int = -1, var boundingBox: Rect = Rect(), var maskingBox: Rect = Rect(), var maskData: ByteArray? = null) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as ObjectData

        if (id != other.id) return false
        if (boundingBox != other.boundingBox) return false
        if (maskData != null) {
            if (other.maskData == null) return false
            if (!maskData.contentEquals(other.maskData)) return false
        } else if (other.maskData != null) return false

        return true
    }

    override fun hashCode(): Int {
        var result = id
        result = 31 * result + boundingBox.hashCode()
        result = 31 * result + (maskData?.contentHashCode() ?: 0)
        return result
    }
}