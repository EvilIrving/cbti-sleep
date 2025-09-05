package com.videoeditor

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class VideoEditorApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
    }
}
