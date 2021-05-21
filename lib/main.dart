import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyHomePage(
    title: "App",
  ));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterTts flutterTts = FlutterTts();
  CameraImage img;
  CameraController controller;
  bool isBusy = false;
  String result = "";
  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future speak() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.setVolume(0.8);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(result);
  }

  iniCamera() {
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        controller.startImageStream((image) => {
              if (!isBusy) {isBusy = true, img = image, startImageLabeling()}
            });
      });
    });
  }

  @override
  Future<void> dispose() async {
    controller?.dispose();
    super.dispose();
  }

  //Load the model
  loadModel() async {
    String res = await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt",
        numThreads: 1, // defaults to 1
        isAsset:
            true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            false // defaults to false, set to true to use GPU delegate
        );
    print(res);
  }

  //do image labeling
  startImageLabeling() async {
    var recognitions = await Tflite.runModelOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 5, // defaults to 5
        threshold: 0.1, // defaults to 0.1
        asynch: true // defaults to true
        );
    result = "";

    recognitions.forEach((element) {
      result += element["label"] +
          "  " +
          (element["confidence"] as double).toStringAsFixed(2) +
          "\n";
    });

    setState(() {
      // ignore: unnecessary_statements
      result;
    });

    isBusy = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('images/img2.jpg'), fit: BoxFit.fill),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: Container(
                          margin: EdgeInsets.only(top: 100),
                          height: 220,
                          width: 320,
                          child: Image.asset('images/lcd2.jpg')),
                    ),
                    Center(
                      child: FlatButton(
                        child: Container(
                          margin: EdgeInsets.only(top: 118),
                          height: 177,
                          width: 310,
                          child: img == null
                              ? Container(
                                  width: 140,
                                  height: 150,
                                  child: Icon(
                                    Icons.videocam,
                                    color: Colors.white,
                                  ),
                                )
                              : AspectRatio(
                                  aspectRatio: controller.value.aspectRatio,
                                  child: CameraPreview(controller),
                                ),
                        ),
                        onPressed: () {
                          iniCamera();
                          speak();
                        },
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 50),
                    child: SingleChildScrollView(
                        child: Text(
                      '$result',
                      style: TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          fontFamily: 'finger_paint'),
                      textAlign: TextAlign.center,
                    )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
