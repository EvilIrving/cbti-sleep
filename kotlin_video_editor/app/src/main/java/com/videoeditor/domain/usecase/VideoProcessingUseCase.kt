package com.videoeditor.domain.usecase

import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.ReturnCode
import com.videoeditor.domain.model.VideoEditSettings
import com.videoeditor.domain.model.VideoInfo
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

sealed class ProcessingResult {
    object Loading : ProcessingResult()
    data class Progress(val percentage: Int) : ProcessingResult()
    data class Success(val outputPath: String) : ProcessingResult()
    data class Error(val message: String) : ProcessingResult()
}

@Singleton
class VideoProcessingUseCase @Inject constructor() {

    fun processVideo(
        videoInfo: VideoInfo,
        settings: VideoEditSettings,
        outputPath: String,
        isPreview: Boolean = false
    ): Flow<ProcessingResult> = flow {
        emit(ProcessingResult.Loading)
        
        try {
            val command = buildFFmpegCommand(videoInfo, settings, outputPath, isPreview)
            
            val session = FFmpegKit.execute(command)
            val returnCode = session.returnCode
            
            if (ReturnCode.isSuccess(returnCode)) {
                emit(ProcessingResult.Success(outputPath))
            } else {
                emit(ProcessingResult.Error("FFmpeg failed with code: $returnCode"))
            }
        } catch (e: Exception) {
            emit(ProcessingResult.Error("Processing failed: ${e.message}"))
        }
    }.flowOn(Dispatchers.IO)

    private fun buildFFmpegCommand(
        videoInfo: VideoInfo,
        settings: VideoEditSettings,
        outputPath: String,
        isPreview: Boolean
    ): String {
        val commands = mutableListOf<String>()
        
        // Input timing (trim)
        settings.trimRange?.let { trim ->
            commands.add("-ss")
            commands.add(formatDuration(trim.startMs))
            commands.add("-t")
            commands.add(formatDuration(trim.durationMs))
        }
        
        // Input file
        commands.add("-i")
        commands.add("'${videoInfo.path}'")
        
        // Video filters
        val filters = mutableListOf<String>()
        
        // Crop filter
        settings.cropRect?.let { crop ->
            val w = crop.width.toInt()
            val h = crop.height.toInt()
            val x = crop.x.toInt()
            val y = crop.y.toInt()
            filters.add("crop=$w:$h:$x:$y")
        }
        
        // Preview optimizations
        if (isPreview) {
            // Scale down for preview
            if (videoInfo.width > 1280 || videoInfo.height > 720) {
                if (videoInfo.width > videoInfo.height) {
                    filters.add("scale=1280:720:force_original_aspect_ratio=decrease")
                } else {
                    filters.add("scale=720:1280:force_original_aspect_ratio=decrease")
                }
            }
            // Reduce frame rate for preview
            val targetFps = if (videoInfo.frameRate > 15f) 15f else videoInfo.frameRate
            filters.add("fps=$targetFps")
        }
        
        if (filters.isNotEmpty()) {
            commands.add("-vf")
            commands.add("\"${filters.joinToString(",")}\"")
        }
        
        // Audio handling
        if (settings.isMuted) {
            commands.add("-an")
        } else {
            commands.add("-c:a")
            commands.add("copy")
        }
        
        // Video encoding
        val needsReencoding = settings.cropRect != null || isPreview
        if (needsReencoding) {
            commands.add("-c:v")
            commands.add("libx264")
            commands.add("-preset")
            commands.add(if (isPreview) "ultrafast" else settings.outputQuality.preset)
            commands.add("-crf")
            commands.add(if (isPreview) "28" else settings.outputQuality.crf.toString())
        } else {
            commands.add("-c:v")
            commands.add("copy")
        }
        
        // Output optimizations
        commands.add("-movflags")
        commands.add("+faststart")
        
        // Output file
        commands.add("'$outputPath'")
        
        return commands.joinToString(" ")
    }
    
    private fun formatDuration(milliseconds: Long): String {
        val totalSeconds = milliseconds / 1000
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        return String.format("%02d:%02d:%02d", hours, minutes, seconds)
    }
}
