package me.vyoo;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

import com.daasuu.mp4compose.composer.Mp4Composer;
import com.daasuu.mp4compose.filter.GlWatermarkFilter;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;

import android.net.Uri;
import android.util.Log;
import android.graphics.BitmapFactory;

public class VideoWatermarkModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public VideoWatermarkModule(ReactApplicationContext reactContext) {
      super(reactContext);
      this.reactContext = reactContext;
  }

  @Override
  public String getName() {
      return "VideoWatermark";
  }

  @ReactMethod
  public void convert(String videoPath, String imagePath, Callback callback) {
      watermarkVideoWithImage(videoPath, imagePath, callback);
  }

  public void watermarkVideoWithImage(String videoPath, String imagePath, final Callback callback) {
    File destFile = new File(this.getReactApplicationContext().getFilesDir(), "converted.mp4");
      if (!destFile.exists()) {
          try {
              destFile.createNewFile();
          } catch (IOException e) {
              e.printStackTrace();
          }
      }
      final String destinationPath = destFile.getPath();

      try {
          new Mp4Composer(Uri.fromFile(new File(videoPath)), destinationPath, reactContext)
                  .filter(new GlWatermarkFilter(BitmapFactory.decodeStream(reactContext.getContentResolver().openInputStream(Uri.fromFile(new File(imagePath))))))
                  .listener(new Mp4Composer.Listener() {
                      @Override
                      public void onProgress(double progress) {
                          Log.e("Progress", progress + "");
                      }
                      @Override
                      public void onCompleted() {
                          callback.invoke(destinationPath);
                      }

                      @Override
                      public void onCanceled() {
                        
                      }

                      @Override
                      public void onFailed(Exception exception) {
                          exception.printStackTrace();
                      }
                  }).start();
      } catch (FileNotFoundException e) {
          e.printStackTrace();
      }
  }
}