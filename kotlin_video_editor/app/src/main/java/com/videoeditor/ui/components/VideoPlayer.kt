package com.videoeditor.ui.components

import android.net.Uri
import android.view.ViewGroup
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ui.PlayerView

@Composable
fun VideoPlayer(
    uri: Uri,
    modifier: Modifier = Modifier,
    isPlaying: Boolean = false,
    onPlayingChanged: (Boolean) -> Unit = {},
    onPositionChanged: (Long) -> Unit = {},
    seekToPosition: Long? = null
) {
    val context = LocalContext.current
    
    val exoPlayer = remember {
        ExoPlayer.Builder(context).build().apply {
            setMediaItem(MediaItem.fromUri(uri))
            prepare()
        }
    }
    
    // Handle play/pause state
    LaunchedEffect(isPlaying) {
        if (isPlaying) {
            exoPlayer.play()
        } else {
            exoPlayer.pause()
        }
    }
    
    // Handle seek
    LaunchedEffect(seekToPosition) {
        seekToPosition?.let { position ->
            exoPlayer.seekTo(position)
        }
    }
    
    // Listen to player state changes
    DisposableEffect(exoPlayer) {
        val listener = object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                super.onPlaybackStateChanged(playbackState)
            }
            
            override fun onIsPlayingChanged(playing: Boolean) {
                super.onIsPlayingChanged(playing)
                onPlayingChanged(playing)
            }
        }
        
        exoPlayer.addListener(listener)
        
        // Position tracking
        val positionUpdateJob = kotlinx.coroutines.GlobalScope.launch {
            while (true) {
                onPositionChanged(exoPlayer.currentPosition)
                kotlinx.coroutines.delay(100) // Update every 100ms
            }
        }
        
        onDispose {
            positionUpdateJob.cancel()
            exoPlayer.removeListener(listener)
            exoPlayer.release()
        }
    }
    
    AndroidView(
        factory = { context ->
            PlayerView(context).apply {
                player = exoPlayer
                useController = false // We'll handle controls ourselves
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            }
        },
        modifier = modifier.fillMaxSize()
    )
}
