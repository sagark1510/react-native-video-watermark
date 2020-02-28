import React, { PureComponent } from 'react';
import { Text, SafeAreaView, TouchableOpacity, CameraRoll, ActivityIndicator } from 'react-native';
import VideoWatermark from 'react-native-video-watermark';
import ImagePicker from 'react-native-image-crop-picker';
import VideoPlayer from 'react-native-video';

class VideoWatermarkScreen extends PureComponent {
  state = {
    videoUri: null,
    imgUri: null,
    video: null,
    converting: false,
  };
  render() {
    return (
      <SafeAreaView>
        <TouchableOpacity
          onPress={async () => {
            const videoUri = await ImagePicker.openPicker({ mediaType: 'video' });
            console.log(videoUri);
            this.setState({ videoUri: videoUri.path.replace('file://', '') });
          }}
          style={{ padding: 40 }}
        >
          <Text>Selected Video</Text>
        </TouchableOpacity>
        <TouchableOpacity
          onPress={async () => {
            const imgUri = await ImagePicker.openPicker({ mediaType: 'photo' });
            this.setState({ imgUri: imgUri.path.replace('file://', '') });
          }}
          style={{ padding: 40 }}
        >
          <Text>Selected Image</Text>
        </TouchableOpacity>
        <TouchableOpacity
          onPress={() => {
            console.log('convert started');
            this.setState({ converting: true });
            VideoWatermark.convert(this.state.videoUri, this.state.imgUri, convertedVideo => {
              setTimeout(() => {
                console.log('came');
                console.log(convertedVideo);
                this.setState({ video: convertedVideo, converting: false });
                CameraRoll.saveToCameraRoll(convertedVideo);
              }, 5000);
            });
          }}
          style={{ padding: 40 }}
        >
          <Text>Convert</Text>
        </TouchableOpacity>
        {this.state.converting ? <ActivityIndicator size="large" color="white" /> : null}
        {this.state.video && (
          <VideoPlayer
            source={{ uri: this.state.video }}
            style={{
              width: 200,
              height: 200,
            }}
            resizeMode="contain"
            paused={false}
          />
        )}
      </SafeAreaView>
    );
  }
}

export default VideoWatermarkScreen;
