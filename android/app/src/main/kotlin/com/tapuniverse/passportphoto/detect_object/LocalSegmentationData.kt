package com.tapuniverse.passportphoto.detect_object

data class LocalSegmentationData(var maskByteArray: ByteArray?, val objectData: HashMap<Int, ObjectData>) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as LocalSegmentationData

        if (!maskByteArray.contentEquals(other.maskByteArray)) return false
        if (objectData != other.objectData) return false

        return true
    }

    override fun hashCode(): Int {
        var result = maskByteArray.contentHashCode()
        result = 31 * result + objectData.hashCode()
        return result
    }

}