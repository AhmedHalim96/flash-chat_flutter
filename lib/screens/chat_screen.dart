import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = "/chat";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = Firestore.instance;

  String msg;
  final messageTextController = TextEditingController();

  @override
  void initState() {
    this.getCurrentUser();
    super.initState();
  }

  getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pushNamed(context, WelcomeScreen.id);
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
            MessagesStream(
              firestore: _firestore,
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        msg = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () async {
                      messageTextController.clear();
                      try {
                        await _firestore.collection('messages').add({
                          "text": msg,
                          "sender": loggedInUser.email,
                          "timeStamp": DateTime.now()
                        });
                      } catch (e) {
                        print(e);
                      }
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

class MessagesStream extends StatelessWidget {
  MessagesStream({@required this.firestore});
  final Firestore firestore;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('messages').orderBy('timeStamp').snapshots(),
      builder: (context, snapshot) {
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        if (snapshot.hasData) {
          for (var message in messages) {
            messageBubbles.add(MessageBubble(
              sender: message.data['sender'],
              text: message.data['text'],
            ));
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
              children: messageBubbles,
            ),
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({@required this.sender, @required this.text});
  final String text;
  final String sender;

  @override
  Widget build(BuildContext context) {
    bool belongsToUser = loggedInUser.email == sender;
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            belongsToUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12.0,
            ),
          ),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: !belongsToUser ? Radius.zero : Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
              topRight: belongsToUser ? Radius.zero : Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ),
            elevation: 5.0,
            color: belongsToUser ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                '$text',
                style: TextStyle(
                  fontSize: 16.0,
                  color: belongsToUser ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
