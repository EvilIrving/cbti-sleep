package com.videoeditor.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.videoeditor.domain.model.CropRect
import kotlin.math.max
import kotlin.math.min

enum class DragMode {
    NONE, MOVE, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT,
    TOP, BOTTOM, LEFT, RIGHT
}

@Composable
fun CropBoxOverlay(
    cropRect: CropRect,
    videoSize: Size,
    onCropRectChanged: (CropRect) -> Unit,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    var dragMode by remember { mutableStateOf(DragMode.NONE) }
    var isDragging by remember { mutableStateOf(false) }
    
    Box(modifier = modifier.fillMaxSize()) {
        // Background overlay
        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(Unit) {
                    detectDragGestures(
                        onDragStart = { offset ->
                            val rect = androidx.compose.ui.geometry.Rect(
                                offset = Offset(cropRect.x, cropRect.y),
                                size = Size(cropRect.width, cropRect.height)
                            )
                            
                            dragMode = if (rect.contains(offset)) {
                                DragMode.MOVE
                            } else {
                                DragMode.NONE
                            }
                            isDragging = true
                        },
                        onDragEnd = {
                            dragMode = DragMode.NONE
                            isDragging = false
                        },
                        onDrag = { change ->
                            if (dragMode == DragMode.MOVE) {
                                val newX = (cropRect.x + change.x).coerceIn(
                                    0f, 
                                    videoSize.width - cropRect.width
                                )
                                val newY = (cropRect.y + change.y).coerceIn(
                                    0f, 
                                    videoSize.height - cropRect.height
                                )
                                
                                onCropRectChanged(
                                    cropRect.copy(x = newX, y = newY)
                                )
                            }
                        }
                    )
                }
        ) {
            drawCropOverlay(
                cropRect = androidx.compose.ui.geometry.Rect(
                    offset = Offset(cropRect.x, cropRect.y),
                    size = Size(cropRect.width, cropRect.height)
                ),
                canvasSize = size,
                isDragging = isDragging
            )
        }
        
        // Corner handles
        val handleSize = with(density) { 20.dp.toPx() }
        val touchPadding = with(density) { 8.dp.toPx() }
        
        // Top-left handle
        DragHandle(
            icon = Icons.Default.NorthWest,
            modifier = Modifier
                .offset(
                    x = with(density) { (cropRect.x - handleSize / 2).toDp() },
                    y = with(density) { (cropRect.y - handleSize / 2).toDp() }
                ),
            onDrag = { change ->
                val newX = (cropRect.x + change.x).coerceIn(0f, cropRect.x + cropRect.width - 40f)
                val newY = (cropRect.y + change.y).coerceIn(0f, cropRect.y + cropRect.height - 40f)
                val newWidth = cropRect.width - (newX - cropRect.x)
                val newHeight = cropRect.height - (newY - cropRect.y)
                
                onCropRectChanged(
                    CropRect(newX, newY, newWidth, newHeight)
                )
            }
        )
        
        // Top-right handle
        DragHandle(
            icon = Icons.Default.NorthEast,
            modifier = Modifier
                .offset(
                    x = with(density) { (cropRect.x + cropRect.width - handleSize / 2).toDp() },
                    y = with(density) { (cropRect.y - handleSize / 2).toDp() }
                ),
            onDrag = { change ->
                val newY = (cropRect.y + change.y).coerceIn(0f, cropRect.y + cropRect.height - 40f)
                val newWidth = (cropRect.width + change.x).coerceIn(40f, videoSize.width - cropRect.x)
                val newHeight = cropRect.height - (newY - cropRect.y)
                
                onCropRectChanged(
                    cropRect.copy(y = newY, width = newWidth, height = newHeight)
                )
            }
        )
        
        // Bottom-left handle
        DragHandle(
            icon = Icons.Default.SouthWest,
            modifier = Modifier
                .offset(
                    x = with(density) { (cropRect.x - handleSize / 2).toDp() },
                    y = with(density) { (cropRect.y + cropRect.height - handleSize / 2).toDp() }
                ),
            onDrag = { change ->
                val newX = (cropRect.x + change.x).coerceIn(0f, cropRect.x + cropRect.width - 40f)
                val newWidth = cropRect.width - (newX - cropRect.x)
                val newHeight = (cropRect.height + change.y).coerceIn(40f, videoSize.height - cropRect.y)
                
                onCropRectChanged(
                    CropRect(newX, cropRect.y, newWidth, newHeight)
                )
            }
        )
        
        // Bottom-right handle
        DragHandle(
            icon = Icons.Default.SouthEast,
            modifier = Modifier
                .offset(
                    x = with(density) { (cropRect.x + cropRect.width - handleSize / 2).toDp() },
                    y = with(density) { (cropRect.y + cropRect.height - handleSize / 2).toDp() }
                ),
            onDrag = { change ->
                val newWidth = (cropRect.width + change.x).coerceIn(40f, videoSize.width - cropRect.x)
                val newHeight = (cropRect.height + change.y).coerceIn(40f, videoSize.height - cropRect.y)
                
                onCropRectChanged(
                    cropRect.copy(width = newWidth, height = newHeight)
                )
            }
        )
        
        // Edge handles
        // Top handle
        DragHandle(
            icon = Icons.Default.North,
            modifier = Modifier
                .offset(
                    x = with(density) { (cropRect.x + cropRect.width / 2 - handleSize / 2).toDp() },
                    y = with(density) { (cropRect.y - handleSize / 2).toDp() }
                ),
            isCircle = true,
            onDrag = { change ->
                val newY = (cropRect.y + change.y).coerceIn(0f, cropRect.y + cropRect.height - 40f)
                val newHeight = cropRect.height - (newY - cropRect.y)
                
                onCropRectChanged(
                    cropRect.copy(y = newY, height = newHeight)
                )
            }
        )
        
        // Bottom handle
        DragHandle(
            icon = Icons.Default.South,
            modifier = Modifier
                .offset(
                    x = with(density) { (cropRect.x + cropRect.width / 2 - handleSize / 2).toDp() },
                    y = with(density) { (cropRect.y + cropRect.height - handleSize / 2).toDp() }
                ),
            isCircle = true,
            onDrag = { change ->
                val newHeight = (cropRect.height + change.y).coerceIn(40f, videoSize.height - cropRect.y)
                
                onCropRectChanged(
                    cropRect.copy(height = newHeight)
                )
            }
        )
        
        // Left handle
        DragHandle(
            icon = Icons.Default.West,
            modifier = Modifier
                .offset(
                    x = with(density) { (cropRect.x - handleSize / 2).toDp() },
                    y = with(density) { (cropRect.y + cropRect.height / 2 - handleSize / 2).toDp() }
                ),
            isCircle = true,
            onDrag = { change ->
                val newX = (cropRect.x + change.x).coerceIn(0f, cropRect.x + cropRect.width - 40f)
                val newWidth = cropRect.width - (newX - cropRect.x)
                
                onCropRectChanged(
                    CropRect(newX, cropRect.y, newWidth, cropRect.height)
                )
            }
        )
        
        // Right handle
        DragHandle(
            icon = Icons.Default.East,
            modifier = Modifier
                .offset(
                    x = with(density) { (cropRect.x + cropRect.width - handleSize / 2).toDp() },
                    y = with(density) { (cropRect.y + cropRect.height / 2 - handleSize / 2).toDp() }
                ),
            isCircle = true,
            onDrag = { change ->
                val newWidth = (cropRect.width + change.x).coerceIn(40f, videoSize.width - cropRect.x)
                
                onCropRectChanged(
                    cropRect.copy(width = newWidth)
                )
            }
        )
    }
}

@Composable
private fun DragHandle(
    icon: ImageVector,
    modifier: Modifier = Modifier,
    isCircle: Boolean = false,
    onDrag: (Offset) -> Unit
) {
    Box(
        modifier = modifier
            .size(32.dp) // Touch area
            .pointerInput(Unit) {
                detectDragGestures { change ->
                    onDrag(change)
                }
            },
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(20.dp)
                .background(
                    color = Color.White,
                    shape = if (isCircle) CircleShape else RoundedCornerShape(4.dp)
                )
                .border(
                    width = 2.dp,
                    color = Color.Blue,
                    shape = if (isCircle) CircleShape else RoundedCornerShape(4.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = Color.Blue,
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

private fun DrawScope.drawCropOverlay(
    cropRect: Rect,
    canvasSize: Size,
    isDragging: Boolean
) {
    // Draw mask overlay
    val maskColor = Color.Black.copy(alpha = 0.6f)
    
    // Top
    drawRect(
        color = maskColor,
        topLeft = Offset.Zero,
        size = Size(canvasSize.width, cropRect.top)
    )
    
    // Bottom
    drawRect(
        color = maskColor,
        topLeft = Offset(0f, cropRect.bottom),
        size = Size(canvasSize.width, canvasSize.height - cropRect.bottom)
    )
    
    // Left
    drawRect(
        color = maskColor,
        topLeft = Offset(0f, cropRect.top),
        size = Size(cropRect.left, cropRect.height)
    )
    
    // Right
    drawRect(
        color = maskColor,
        topLeft = Offset(cropRect.right, cropRect.top),
        size = Size(canvasSize.width - cropRect.right, cropRect.height)
    )
    
    // Draw crop box border
    drawRect(
        color = if (isDragging) Color.Blue else Color.White,
        topLeft = cropRect.topLeft,
        size = cropRect.size,
        style = androidx.compose.ui.graphics.drawscope.Stroke(
            width = if (isDragging) 3f else 2f
        )
    )
    
    // Draw grid lines when dragging
    if (isDragging) {
        val gridColor = Color.White.copy(alpha = 0.8f)
        
        // Vertical lines
        val thirdWidth = cropRect.width / 3
        drawLine(
            color = gridColor,
            start = Offset(cropRect.left + thirdWidth, cropRect.top),
            end = Offset(cropRect.left + thirdWidth, cropRect.bottom),
            strokeWidth = 1f
        )
        drawLine(
            color = gridColor,
            start = Offset(cropRect.left + thirdWidth * 2, cropRect.top),
            end = Offset(cropRect.left + thirdWidth * 2, cropRect.bottom),
            strokeWidth = 1f
        )
        
        // Horizontal lines
        val thirdHeight = cropRect.height / 3
        drawLine(
            color = gridColor,
            start = Offset(cropRect.left, cropRect.top + thirdHeight),
            end = Offset(cropRect.right, cropRect.top + thirdHeight),
            strokeWidth = 1f
        )
        drawLine(
            color = gridColor,
            start = Offset(cropRect.left, cropRect.top + thirdHeight * 2),
            end = Offset(cropRect.right, cropRect.top + thirdHeight * 2),
            strokeWidth = 1f
        )
    }
}
