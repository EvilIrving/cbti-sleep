package com.videoeditor.di

import android.content.Context
import com.videoeditor.data.repository.VideoRepository
import com.videoeditor.domain.usecase.VideoProcessingUseCase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    
    @Provides
    @Singleton
    fun provideVideoRepository(
        @ApplicationContext context: Context
    ): VideoRepository {
        return VideoRepository(context)
    }
    
    @Provides
    @Singleton
    fun provideVideoProcessingUseCase(): VideoProcessingUseCase {
        return VideoProcessingUseCase()
    }
}
