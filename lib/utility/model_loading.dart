import 'package:tflite/tflite.dart';

loadModel() async {
  await Tflite.loadModel(
    model: "assets/model.tflite",
    labels: "assets/labels.txt",
  );
}
