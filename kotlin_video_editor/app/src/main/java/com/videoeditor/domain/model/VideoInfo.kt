package com.videoeditor.domain.model

import android.net.Uri

data class VideoInfo(
    val uri: Uri,
    val path: String,
    val duration: Long, // in milliseconds
    val width: Int,
    val height: Int,
    val frameRate: Float = 30f,
    val size: Long, // in bytes
    val displayName: String
)

data class CropRect(
    val x: Float,
    val y: Float,
    val width: Float,
    val height: Float
) {
    companion object {
        fun fullScreen(videoWidth: Float, videoHeight: Float) = CropRect(
            x = 0f,
            y = 0f,
            width = videoWidth,
            height = videoHeight
        )
    }
}

data class TrimRange(
    val startMs: Long,
    val endMs: Long
) {
    val durationMs: Long get() = endMs - startMs
}

data class VideoEditSettings(
    val trimRange: TrimRange? = null,
    val cropRect: CropRect? = null,
    val isMuted: Boolean = false,
    val outputQuality: OutputQuality = OutputQuality.MEDIUM
)

enum class OutputQuality(val crf: Int, val preset: String) {
    HIGH(18, "medium"),
    MEDIUM(23, "medium"),
    LOW(28, "fast")
}
