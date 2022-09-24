import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FormPage(),
    );
  }
}

class FormPage extends StatefulWidget {
  const FormPage({Key? key}) : super(key: key);

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  File? file;
  String? imgUrl;
  TextEditingController hexCode = TextEditingController();
  TextEditingController type = TextEditingController();
  TextEditingController label = TextEditingController();
  TextEditingController unit = TextEditingController();

  //
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  TrackingModel trackingModel = TrackingModel();

  Future<String?> uploadFile(File file) async {
    String? imgUrl;
    final int name = DateTime.now().millisecondsSinceEpoch;
    var ext = file.path.split('.').last;
    log('@@ this is extension : $ext');
    try {
      await FirebaseStorage.instance.ref('img/$name.$ext').putFile(file);
      imgUrl = await storage.ref('outpass/$name.$ext').getDownloadURL();
    } on FirebaseException catch (e) {
      // e.g, e.code == 'canceled'
      print(e.message);
    }
    return imgUrl;
  }

  Future<bool> createTrack(TrackingModel model) async {
    var res = false;

    try {
      await _firebaseFirestore.collection('track').doc().set(model.toMap());
      res = true;
    } on FirebaseException catch (e) {
      res = false;
      log(e.message!);
    }

    return res;
  }

  void pickProfile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      file = File(result.files.single.path!);
      imgUrl = await uploadFile(file!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              SizedBox(
                height: 20,
              ),
              Text(
                'Details',
                style: Theme.of(context).textTheme.headline4!.copyWith(
                      color: Colors.blueAccent,
                      fontSize: 20,
                    ),
              ),
              SizedBox(
                height: 10,
              ),
              InkWell(
                onTap: () {
                  pickProfile();
                },
                child: file == null
                    ? Image.network(
                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                        height: 100,
                      )
                    : CircleAvatar(
                        radius: 60,
                        backgroundImage: Image.file(file!).image,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CustomTextField(
                  controller: label,
                  hintText: 'Label',
                  onChanged: (val) {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CustomTextField(
                  controller: unit,
                  hintText: 'Unit',
                  onChanged: (val) {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CustomTextField(
                  controller: type,
                  hintText: 'Type',
                  onChanged: (val) {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CustomTextField(
                  controller: hexCode,
                  hintText: 'Hexcode',
                  onChanged: (val) {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    trackingModel = TrackingModel(
                      link: imgUrl,
                      hexCode: hexCode.text,
                      type: type.text,
                      unit: unit.text,
                      label: label.text,
                    );
                    createTrack(trackingModel);
                  },
                  child: Text('Submit'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.black,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.black,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: 1,
          horizontal: 10,
        ),
      ),
    );
  }
}

class TrackingModel {
  String? label;
  String? link;
  String? type;
  String? unit;
  String? hexCode;
  TrackingModel({
    this.label,
    this.link,
    this.type,
    this.unit,
    this.hexCode,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'link': link,
      'type': type,
      'unit': unit,
      'hexCode': hexCode,
    };
  }

  factory TrackingModel.fromMap(Map<String, dynamic> map) {
    return TrackingModel(
      label: map['label'] != null ? map['label'] as String : null,
      link: map['link'] != null ? map['link'] as String : null,
      type: map['type'] != null ? map['type'] as String : null,
      unit: map['unit'] != null ? map['unit'] as String : null,
      hexCode: map['hexCode'] != null ? map['hexCode'] as String : null,
    );
  }
}
