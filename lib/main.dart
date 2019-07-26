import 'dart:io';   
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  runApp(MyApp());
}

final ThemeData kIOSTheme = ThemeData(
    primarySwatch: Colors.orange,
    primaryColor: Colors.grey[100],
    primaryColorBrightness: Brightness.light);

final ThemeData kDefaultTheme = ThemeData(
    primarySwatch: Colors.amber, accentColor: Colors.amberAccent[400]);

final googleSignIn = GoogleSignIn();
final auth = FirebaseAuth.instance;

Future<Null> _ensureLoggedIn() async {
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
  await _ensureLoggedIn();
  _sendMessage(text: text);
}



class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chat Concierge",
      debugShowCheckedModeBanner: false,
      theme: Theme.of(context).platform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  ChatScreen({Key key}) : super(key: key);

  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    _ensureLoggedIn();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      top: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text("Concierge Chat"),
          centerTitle: true,
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
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
                          return ChatMessage(r[index].data);
                        },
                      );
                  }
                },
              ),
            ),
            Divider(
              height: 1.0,
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: TextComposer(),
            )
          ],
        ),
      ),
    );
  }
}

class TextComposer extends StatefulWidget {
  TextComposer({Key key}) : super(key: key);

  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  final TextEditingController _textEditingController = TextEditingController();
  bool _isComposing = false;

  void reset() {
    _textEditingController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: Theme.of(context).platform == TargetPlatform.iOS
            ? BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200])))
            : null,
        child: Row(
          children: <Widget>[
            Container(
              child: IconButton(
                icon: Icon(Icons.photo_camera),
                onPressed: () async {
                  await _ensureLoggedIn();
                  File imgFile =
                      await ImagePicker.pickImage(source: ImageSource.camera);
                  if (imgFile == null) return;
                  StorageUploadTask task = FirebaseStorage.instance
                      .ref()
                      .child(googleSignIn.currentUser.id.toString() +
                          DateTime.now().millisecondsSinceEpoch.toString())
                      .putFile(imgFile);
                  String downloadUrl =
                      await (await task.onComplete).ref.getDownloadURL();
                  _sendMessage(imgUrl: downloadUrl);
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: _textEditingController,
                decoration:
                    InputDecoration.collapsed(hintText: "Enviar uma mensagem"),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Theme.of(context).platform == TargetPlatform.iOS
                  ? CupertinoButton(
                      child: Text("Enviar"),
                      onPressed: _isComposing
                          ? () {
                              _handleSubmitted(_textEditingController.text);
                              reset();
                            }
                          : null)
                  : IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _isComposing
                          ? () {
                              _handleSubmitted(_textEditingController.text);
                              reset();
                            }
                          : null,
                    ),
            )
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final Map<String, dynamic> data;

  ChatMessage(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: data["imgUrl"] != null
                      ? Image.network(
                          data["imgUrl"],
                          width: 250.0,
                        )
                      : Text(
                          data["text"],
                          style: TextStyle(color: Colors.white),
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
