package com.videoeditor.ui.screens.editor

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.videoeditor.R
import com.videoeditor.domain.model.CropRect
import com.videoeditor.domain.usecase.ProcessingResult
import com.videoeditor.ui.components.CropBoxOverlay
import com.videoeditor.ui.components.VideoPlayer
import com.videoeditor.ui.theme.DarkBackground
import com.videoeditor.ui.theme.YellowAccent
import kotlin.math.roundToLong

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VideoEditorScreen(
    videoUri: Uri,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: VideoEditorViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()
    
    // Load video when screen opens
    LaunchedEffect(videoUri) {
        viewModel.loadVideo(videoUri)
    }
    
    // Handle processing results
    uiState.processingResult?.let { result ->
        when (result) {
            is ProcessingResult.Success -> {
                LaunchedEffect(result) {
                    // Handle success - could show success message or navigate
                }
            }
            is ProcessingResult.Error -> {
                LaunchedEffect(result) {
                    // Show error message
                }
            }
            else -> {}
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.video_editor),
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.W600
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Back",
                            tint = Color.White
                        )
                    }
                },
                actions = {
                    Button(
                        onClick = {
                            val outputDir = context.getExternalFilesDir(null)
                            if (outputDir != null) {
                                viewModel.processVideo(outputDir, isPreview = false)
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color.Transparent
                        ),
                        enabled = uiState.processingResult !is ProcessingResult.Loading
                    ) {
                        if (uiState.processingResult is ProcessingResult.Loading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                color = YellowAccent
                            )
                        } else {
                            Icon(
                                imageVector = Icons.Default.FileUpload,
                                contentDescription = null,
                                tint = YellowAccent,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = stringResource(R.string.export),
                            color = YellowAccent,
                            fontWeight = FontWeight.W600,
                            fontSize = 14.sp
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Black
                )
            )
        },
        containerColor = Color.Black
    ) { paddingValues ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = YellowAccent)
            }
        } else {
            uiState.videoInfo?.let { videoInfo ->
                Column(
                    modifier = modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                ) {
                    // Video player with crop overlay
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f)
                    ) {
                        VideoPlayer(
                            uri = videoUri,
                            isPlaying = uiState.isPlaying,
                            onPlayingChanged = viewModel::updatePlayingState,
                            onPositionChanged = viewModel::updateCurrentPosition,
                            seekToPosition = uiState.trimRange?.startMs
                        )
                        
                        if (uiState.isCropEnabled && uiState.cropRect != null) {
                            CropBoxOverlay(
                                cropRect = uiState.cropRect!!,
                                videoSize = androidx.compose.ui.geometry.Size(
                                    videoInfo.width.toFloat(),
                                    videoInfo.height.toFloat()
                                ),
                                onCropRectChanged = viewModel::updateCropRect
                            )
                        }
                        
                        // Crop size display
                        if (uiState.isCropEnabled && uiState.cropRect != null) {
                            Card(
                                modifier = Modifier
                                    .align(Alignment.TopStart)
                                    .padding(8.dp),
                                colors = CardDefaults.cardColors(
                                    containerColor = Color.Black.copy(alpha = 0.7f)
                                )
                            ) {
                                Text(
                                    text = stringResource(
                                        R.string.crop_size,
                                        uiState.cropRect!!.width.toInt(),
                                        uiState.cropRect!!.height.toInt()
                                    ),
                                    color = Color.White,
                                    fontSize = 12.sp,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                )
                            }
                        }
                    }
                    
                    // Timeline section
                    TimelineSection(
                        videoInfo = videoInfo,
                        trimRange = uiState.trimRange,
                        onTrimRangeChanged = viewModel::updateTrimRange,
                        modifier = Modifier.height(180.dp)
                    )
                    
                    // Crop ratio buttons
                    if (uiState.isCropEnabled) {
                        CropRatioButtons(
                            onRatioSelected = viewModel::setCropRatio,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        )
                    }
                    
                    // Bottom toolbar
                    BottomToolbar(
                        isPlaying = uiState.isPlaying,
                        isCropEnabled = uiState.isCropEnabled,
                        isMuted = uiState.isMuted,
                        isProcessing = uiState.processingResult is ProcessingResult.Loading,
                        onPlayPauseClick = {
                            viewModel.updatePlayingState(!uiState.isPlaying)
                        },
                        onCropToggle = viewModel::toggleCropEnabled,
                        onMuteToggle = viewModel::toggleMute,
                        onPreviewClick = {
                            val outputDir = context.cacheDir
                            viewModel.processVideo(outputDir, isPreview = true)
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun TimelineSection(
    videoInfo: com.videoeditor.domain.model.VideoInfo,
    trimRange: com.videoeditor.domain.model.TrimRange?,
    onTrimRangeChanged: (Long, Long) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(horizontal = 12.dp)
    ) {
        // Placeholder for thumbnails (simplified)
        LazyRow(
            modifier = Modifier
                .fillMaxWidth()
                .height(70.dp),
            horizontalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            items(10) { index ->
                Box(
                    modifier = Modifier
                        .size(70.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color.Gray)
                )
            }
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Trim slider
        trimRange?.let { range ->
            RangeSlider(
                value = range.startMs.toFloat()..range.endMs.toFloat(),
                onValueChange = { newRange ->
                    onTrimRangeChanged(
                        newRange.start.roundToLong(),
                        newRange.endInclusive.roundToLong()
                    )
                },
                valueRange = 0f..videoInfo.duration.toFloat(),
                colors = SliderDefaults.colors(
                    thumbColor = YellowAccent,
                    activeTrackColor = YellowAccent
                ),
                modifier = Modifier.fillMaxWidth()
            )
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Duration display
        trimRange?.let { range ->
            Card(
                modifier = Modifier.align(Alignment.CenterHorizontally),
                colors = CardDefaults.cardColors(
                    containerColor = Color.Black.copy(alpha = 0.7f)
                )
            ) {
                Text(
                    text = stringResource(
                        R.string.current_trim_duration,
                        formatDuration(range.durationMs)
                    ),
                    color = Color.White,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.W500,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
                )
            }
        }
    }
}

@Composable
private fun CropRatioButtons(
    onRatioSelected: (Float) -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = Color.Gray.copy(alpha = 0.9f)
        ),
        shape = RoundedCornerShape(26.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            RatioButton(stringResource(R.string.ratio_1_1), Icons.Default.CropSquare) { onRatioSelected(1f) }
            RatioButton(stringResource(R.string.ratio_4_3), Icons.Default.Crop32) { onRatioSelected(4f/3f) }
            RatioButton(stringResource(R.string.ratio_16_9), Icons.Default.Crop169) { onRatioSelected(16f/9f) }
            RatioButton(stringResource(R.string.ratio_3_4), Icons.Default.CropPortrait) { onRatioSelected(3f/4f) }
            RatioButton(stringResource(R.string.ratio_free), Icons.Default.CropFree) { onRatioSelected(0f) }
        }
    }
}

@Composable
private fun RatioButton(
    label: String,
    icon: ImageVector,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .size(44.dp)
            .clip(RoundedCornerShape(16.dp))
    ) {
        IconButton(
            onClick = onClick,
            modifier = Modifier.size(32.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = YellowAccent,
                modifier = Modifier.size(14.dp)
            )
        }
        Text(
            text = label,
            color = YellowAccent,
            fontSize = 9.sp,
            fontWeight = FontWeight.W600
        )
    }
}

@Composable
private fun BottomToolbar(
    isPlaying: Boolean,
    isCropEnabled: Boolean,
    isMuted: Boolean,
    isProcessing: Boolean,
    onPlayPauseClick: () -> Unit,
    onCropToggle: () -> Unit,
    onMuteToggle: () -> Unit,
    onPreviewClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = Color.Gray.copy(alpha = 0.9f)
        ),
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp, horizontal = 20.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            ToolButton(
                icon = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                label = if (isPlaying) stringResource(R.string.pause) else stringResource(R.string.play),
                isActive = isPlaying,
                onClick = onPlayPauseClick
            )
            
            ToolButton(
                icon = Icons.Default.Crop,
                label = stringResource(R.string.crop),
                isActive = isCropEnabled,
                onClick = onCropToggle
            )
            
            ToolButton(
                icon = if (isMuted) Icons.Default.VolumeOff else Icons.Default.VolumeUp,
                label = if (isMuted) stringResource(R.string.mute) else stringResource(R.string.audio),
                isActive = isMuted,
                onClick = onMuteToggle
            )
            
            ToolButton(
                icon = Icons.Default.Preview,
                label = stringResource(R.string.preview),
                isActive = isProcessing,
                onClick = onPreviewClick,
                enabled = !isProcessing
            )
        }
    }
}

@Composable
private fun ToolButton(
    icon: ImageVector,
    label: String,
    isActive: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        IconButton(
            onClick = onClick,
            enabled = enabled
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = if (isActive) YellowAccent else Color.Gray,
                modifier = Modifier.size(24.dp)
            )
        }
        Text(
            text = label,
            color = if (isActive) YellowAccent else Color.Gray,
            fontSize = 12.sp,
            fontWeight = FontWeight.W500
        )
    }
}

private fun formatDuration(milliseconds: Long): String {
    val totalSeconds = milliseconds / 1000
    val minutes = totalSeconds / 60
    val seconds = totalSeconds % 60
    return String.format("%02d:%02d", minutes, seconds)
}
