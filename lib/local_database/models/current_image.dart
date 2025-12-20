import 'dart:typed_data';

class CurrentImage {
  CurrentImage({
    required this.id,
    required this.image,
    required this.timestamp,
    required this.isShootThroughFastCamera,
    required this.lowResImage,
  });
  String id;
  Uint8List image;
  String timestamp;
  bool isShootThroughFastCamera;
  Uint8List lowResImage;
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image': image,
      'timestamp': timestamp,
      'is_shoot_through_fast_camera': isShootThroughFastCamera.toString(),
      'low_res_image': lowResImage,
    };
  }
}
