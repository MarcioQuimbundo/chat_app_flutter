import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
void main() {
  Firestore.instance.collection("teste").document("teste").setData({"teste1":"teste2"});
  runApp(MaterialApp(home: HomePage(),));
}


class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
    );
  }
}