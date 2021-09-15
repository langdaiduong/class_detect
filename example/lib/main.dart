import 'dart:async';
import 'dart:io';
//import 'dart:math';
//import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:image/image.dart' as img;

import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(new App());
const String ssd = "SSD MobileNet";
File val;
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File _image;
  List _recognitions;
  String _model = ssd;
  double _imageHeight;
  double _imageWidth;
  bool _busy = false;
  var detected;

  Future predictImagePickerCamera() async {
    final ImagePicker picker  = ImagePicker(); 
    //final image = await picker.getImage(source: ImageSource.gallery);
    final image = await picker.getImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {
      _image = File(image.path);
      _busy = true;
    });
    predictImage(_image);
  }
    Future predictImagePicker() async {
    final ImagePicker picker  = ImagePicker(); 
    final image = await picker.getImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _image = File(image.path);
      _busy = true;
    });
    predictImage(_image);
  }

  Future predictImage(File image) async {
    if (image == null) return;
    if (_model == ssd)
      await ssdMobileNet(image);

    new FileImage(image)
        .resolve(new ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _imageHeight = info.image.height.toDouble();
        _imageWidth = info.image.width.toDouble();
      });
    }));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _busy = true;

    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String res;
      if(_model==ssd)
        res = await Tflite.loadModel(
          model: "assets/model_best.tflite",
          labels: "assets/model.txt",
        );
      print(res);
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  Future ssdMobileNet(File image) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1,
    );
    // var imageBytes = (await rootBundle.load(image.path)).buffer;
    // img.Image oriImage = img.decodeJpg(imageBytes.asUint8List());
    // img.Image resizedImage = img.copyResize(oriImage, 300, 300);
    // var recognitions = await Tflite.detectObjectOnBinary(
    //   binary: imageToByteListUint8(resizedImage, 300),
    //   numResultsPerClass: 1,
    // );
    setState(() {
      _recognitions = recognitions;
    });
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }
  // onSelect(model) async {
  //   setState(() {
  //     _busy = true;
  //     _model = model;
  //     _recognitions = null;
  //   });
  //   await loadModel();

  //   if (_image != null)
  //     predictImage(_image);
  //   else
  //     setState(() {
  //       _busy = false;
  //     });
  // }
  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageHeight == null || _imageWidth == null) return [];
    double factorX = screen.width;
    double factorY = _imageHeight / _imageWidth * screen.width;
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);
    return _recognitions.map((re) {
      detected.add("${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%");
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(
              color: blue,
              width: 2,
            ),
          ),
          child: Text(
            "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 12.0,
            ),
          ),
        ),
      );
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];
    if (_model == "deeplab" && _recognitions != null) {
      stackChildren.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        child: _image == null
            ? Text('No image selected.')
            : Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        alignment: Alignment.topCenter,
                        image: MemoryImage(_recognitions),
                        fit: BoxFit.fill)),
                child: Opacity(opacity: 0.3, child: Image.file(_image))),
      ));
    } else {
      stackChildren.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        child: _image == null ? Text('No image selected.') : Image.file(_image),
      ));
    }
    if (_model == ssd ) {
      detected=[];
      stackChildren.addAll(renderBoxes(size));
      if (detected!=[]){
        print(detected);
      }
    }
    if (_busy) {
      stackChildren.add(const Opacity(
        child: ModalBarrier(dismissible: false, color: Colors.grey),
        opacity: 0.3,
      ));
      stackChildren.add(const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('tflite example app'),
      ),
      body: Stack(
        children: stackChildren,
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: predictImagePicker,
      //   tooltip: 'Pick Image',
      //   child: Icon(Icons.image),
      // ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: "Fltbtn2",
            child: Icon(Icons.camera_alt),
            onPressed: predictImagePickerCamera,
          ),
          SizedBox(width: 10,),
          FloatingActionButton(
            heroTag: "Fltbtn1",
            child: Icon(Icons.photo),
            onPressed: predictImagePicker,
          ),
        ],
      ),
    );
  }
}
