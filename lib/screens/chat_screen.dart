import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat/google_sign_in.dart';

class ChatScreen extends StatefulWidget {
  static const String id = 'chatScreen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _firestore = Firestore.instance;
  final _auth = FirebaseAuth.instance;
  FirebaseUser logInUser;
  String messageText;
  final messageTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (myGoogleUser == null) {
      getCurrentUser();
    } else {
      logInUser = myGoogleUser;
    }
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        logInUser = user;
        print(logInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

//  Future getMessages() async {
//    final messages = await _firestore.collection("messages").getDocuments();
//    for (var message in messages.documents) {
//      print(message.data);
//    }
//  }

//  void getMessageStream() async {
//    await for (var snapshot in _firestore.collection("messages").snapshots()) {
//      for (var message in snapshot.documents) {
//        print(message.data);
//      }
//    }
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                if (myGoogleUser == null) {
                  _auth.signOut();
                } else {
                  signOutGoogle();
                }
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection("messages").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                        child: CircularProgressIndicator(
                      backgroundColor: Colors.lightBlueAccent,
                    ));
                  }
                  final messages = snapshot.data.documents.reversed;
                  List<MessageBubble> messageBubbles = [];
                  for (var message in messages) {
                    final messageSender = message.data["sender"];
                    final messageText = message.data["text"];

                    final messageBubble = MessageBubble(
                      messageSender: messageSender,
                      messageText: messageText,
                      isMe: messageSender == logInUser.email,
                    );

                    messageBubbles.add(messageBubble);
                  }
                  return Expanded(
                      child: ListView(
                          reverse: true,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 20),
                          children: messageBubbles));
                }),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      print(logInUser.email);
                      print(messageText);
                      _firestore.collection("messages").add(
                          {"sender": logInUser.email, "text": messageText});
                      //Implement send functionality.
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.messageSender, this.messageText, this.isMe});
  final String messageSender;
  final String messageText;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry myBorderRadius = BorderRadius.only(
        topRight: Radius.circular(25),
        bottomLeft: Radius.circular(25),
        bottomRight: Radius.circular(25));
    if (isMe) {
      myBorderRadius = BorderRadius.only(
          topLeft: Radius.circular(25),
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25));
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(messageSender),
          Material(
            borderRadius: myBorderRadius,
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                "$messageText",
                style: TextStyle(
                    fontSize: 20, color: isMe ? Colors.white : Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
    ;
  }
}
