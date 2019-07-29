import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(MyApp());
}

final googleSignIn = GoogleSignIn();
final auth = FirebaseAuth.instance;

Future<Null> googleLogin() async{
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null) user = await googleSignIn.signIn();
  if (await auth.currentUser() == null) {
    final GoogleSignInAuthentication googleAuth =
        await googleSignIn.currentUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await auth.signInWithCredential(credential);
  }
}

void _sendMessage({String text, String imgUrl}) {
  Firestore.instance.collection("messages").add({
    "text": text,
    "imgUrl": imgUrl,
    "senderName": googleSignIn.currentUser.displayName,
    "senderPhotoUrl": googleSignIn.currentUser.photoUrl
  });
}

_handleSubmitted(String text) async {
  await googleLogin();
  _sendMessage(text: text);
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Chat Jam",
      home: TelaChat(),
    );
  }
}


class TelaChat extends StatefulWidget {
  _TelaChatState createState() => _TelaChatState();
}

class _TelaChatState extends State<TelaChat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Jam", style: TextStyle(fontSize: 16),),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
                stream: Firestore.instance.collection("messages").snapshots(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.done:
                    case ConnectionState.waiting:
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                      break;
                    default:
                      return ListView.builder(
                        reverse: true,
                        itemCount: snapshot.data.documents.length,
                        itemBuilder: (context, index) {
                          List r = snapshot.data.documents.reversed.toList();
                          return Messages(r[index].data);
                        },
                      );
                  }
                },
              ),
          ),
          EditorTexto(),
        ],
      ),
    );
  }
}

class Messages extends StatelessWidget {
  final Map<String, dynamic> data;
  Messages(this.data);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundImage: NetworkImage(data["senderPhotoUrl"]),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data["senderName"],
                  style: TextStyle(fontSize: 16),
                ),
                Container(
                  child: data["imgUrl"] != null
                      ? Image.network(
                          data["imgUrl"],
                          width: 250.0,
                        )
                      : Text(
                          data["text"],
                          style: TextStyle(color: Colors.black),
                        ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class EditorTexto extends StatefulWidget {
  _EditorTextoState createState() => _EditorTextoState();
}

class _EditorTextoState extends State<EditorTexto> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.photo_camera),
          onPressed: () {},
        ),
        Expanded(
          child: TextField(
            decoration: InputDecoration.collapsed(hintText: "Enviar Mensagem"),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: () {},
        )
      ],
    );
  }
}