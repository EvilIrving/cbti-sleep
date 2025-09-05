package com.videoeditor.ui.screens.editor

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.videoeditor.data.repository.VideoRepository
import com.videoeditor.domain.model.*
import com.videoeditor.domain.usecase.ProcessingResult
import com.videoeditor.domain.usecase.VideoProcessingUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

data class VideoEditorUiState(
    val videoInfo: VideoInfo? = null,
    val isLoading: Boolean = false,
    val trimRange: TrimRange? = null,
    val cropRect: CropRect? = null,
    val isCropEnabled: Boolean = false,
    val isMuted: Boolean = false,
    val isPlaying: Boolean = false,
    val currentPosition: Long = 0L,
    val processingResult: ProcessingResult? = null,
    val error: String? = null
)

@HiltViewModel
class VideoEditorViewModel @Inject constructor(
    private val videoRepository: VideoRepository,
    private val videoProcessingUseCase: VideoProcessingUseCase
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(VideoEditorUiState())
    val uiState: StateFlow<VideoEditorUiState> = _uiState.asStateFlow()
    
    fun loadVideo(uri: Uri) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            
            try {
                val videoInfo = videoRepository.getVideoInfo(uri)
                if (videoInfo != null) {
                    val initialTrimRange = TrimRange(0L, videoInfo.duration)
                    val initialCropRect = CropRect.fullScreen(
                        videoInfo.width.toFloat(),
                        videoInfo.height.toFloat()
                    )
                    
                    _uiState.value = _uiState.value.copy(
                        videoInfo = videoInfo,
                        trimRange = initialTrimRange,
                        cropRect = initialCropRect,
                        isLoading = false
                    )
                } else {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "无法加载视频"
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = "加载视频失败: ${e.message}"
                )
            }
        }
    }
    
    fun updateTrimRange(startMs: Long, endMs: Long) {
        _uiState.value = _uiState.value.copy(
            trimRange = TrimRange(startMs, endMs)
        )
    }
    
    fun updateCropRect(cropRect: CropRect) {
        _uiState.value = _uiState.value.copy(cropRect = cropRect)
    }
    
    fun toggleCropEnabled() {
        _uiState.value = _uiState.value.copy(
            isCropEnabled = !_uiState.value.isCropEnabled
        )
    }
    
    fun toggleMute() {
        _uiState.value = _uiState.value.copy(
            isMuted = !_uiState.value.isMuted
        )
    }
    
    fun updatePlayingState(isPlaying: Boolean) {
        _uiState.value = _uiState.value.copy(isPlaying = isPlaying)
    }
    
    fun updateCurrentPosition(position: Long) {
        _uiState.value = _uiState.value.copy(currentPosition = position)
    }
    
    fun setCropRatio(ratio: Float) {
        val currentState = _uiState.value
        val videoInfo = currentState.videoInfo ?: return
        
        val width: Float
        val height: Float
        
        when {
            ratio == 0f -> {
                // 自由比例
                width = videoInfo.width.toFloat()
                height = videoInfo.height.toFloat()
            }
            ratio == 1f -> {
                // 1:1 正方形
                val size = minOf(videoInfo.width, videoInfo.height).toFloat()
                width = size
                height = size
            }
            ratio > 1f -> {
                // 横屏比例
                if (videoInfo.width.toFloat() / videoInfo.height > ratio) {
                    height = videoInfo.height.toFloat()
                    width = height * ratio
                } else {
                    width = videoInfo.width.toFloat()
                    height = width / ratio
                }
            }
            else -> {
                // 竖屏比例
                if (videoInfo.width.toFloat() / videoInfo.height > ratio) {
                    height = videoInfo.height.toFloat()
                    width = height * ratio
                } else {
                    width = videoInfo.width.toFloat()
                    height = width / ratio
                }
            }
        }
        
        val x = (videoInfo.width - width) / 2
        val y = (videoInfo.height - height) / 2
        
        updateCropRect(CropRect(x, y, width, height))
    }
    
    fun processVideo(outputDir: File, isPreview: Boolean = false) {
        val currentState = _uiState.value
        val videoInfo = currentState.videoInfo ?: return
        
        val settings = VideoEditSettings(
            trimRange = currentState.trimRange,
            cropRect = if (currentState.isCropEnabled) currentState.cropRect else null,
            isMuted = currentState.isMuted
        )
        
        val outputFileName = if (isPreview) {
            "preview_${System.currentTimeMillis()}.mp4"
        } else {
            "edited_${System.currentTimeMillis()}.mp4"
        }
        
        val outputPath = File(outputDir, outputFileName).absolutePath
        
        viewModelScope.launch {
            videoProcessingUseCase.processVideo(videoInfo, settings, outputPath, isPreview)
                .collect { result ->
                    _uiState.value = _uiState.value.copy(processingResult = result)
                }
        }
    }
    
    fun clearProcessingResult() {
        _uiState.value = _uiState.value.copy(processingResult = null)
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}
