package com.videoeditor

import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.videoeditor.ui.screens.editor.VideoEditorScreen
import com.videoeditor.ui.screens.picker.VideoPickerScreen

@Composable
fun VideoEditorApp(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = "picker"
    ) {
        composable("picker") {
            VideoPickerScreen(
                onVideoSelected = { uri ->
                    navController.navigate("editor/${Uri.encode(uri.toString())}")
                }
            )
        }
        
        composable("editor/{videoUri}") { backStackEntry ->
            val videoUriString = backStackEntry.arguments?.getString("videoUri")
            val videoUri = Uri.parse(Uri.decode(videoUriString))
            
            VideoEditorScreen(
                videoUri = videoUri,
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
    }
}
