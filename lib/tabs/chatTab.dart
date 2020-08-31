import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mentor_digishala/loginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

//https://stackoverflow.com/questions/16126579/how-do-i-format-a-date-with-dart
// DateTime today = new DateTime.now();
final DateTime now = DateTime.now();
// final DateFormat formatter = DateFormat('yyyy-MM-dd');
// final String formattedDate = formatter.format(now);

class chatTab extends StatefulWidget {
  @override
  _chatTabState createState() => _chatTabState();
}

class _chatTabState extends State<chatTab> {
  final clearMessage = TextEditingController();
  final _firestore = Firestore.instance;
  final _auth = FirebaseAuth.instance;
  FirebaseUser loggedInUser;
  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
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
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('messages')
                .orderBy('time', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator(
                        backgroundColor: Colors.yellowAccent));
              }
              final messages = snapshot.data.documents.reversed;
              List<Bubble> messageWidgets = [];
              for (var message in messages) {
                final messageText = message.data['text'];
                final messageSender = message.data['sender'];
                final messageTime = message.data['time'];
                final currentUser = loggedInUser.email;
                final messageWidget = Bubble(
                  sender: messageSender,
                  text: messageText,
                  time: messageTime,
                  itsMeOrNot: currentUser == messageSender,
                );
                messageWidgets.add(messageWidget);
              }
              return Expanded(
                child: ListView(
                  reverse: true,
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                  children: messageWidgets,
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: clearMessage,
                    onChanged: (value) {
                      messageText = value;
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                      hintText: 'Type your message here...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                FlatButton(
                  onPressed: () {
                    //send functionality
                    clearMessage.clear(); // Clears the message
                    _firestore.collection('messages').add({
                      'text': messageText,
                      'sender': loggedInUser.email,
                      'time': Timestamp.now().millisecondsSinceEpoch,
                    });
                  },
                  child: Text(
                    'Send',
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Bubble extends StatelessWidget {
  Bubble({this.sender, this.text, this.itsMeOrNot, this.time});

  final String sender;
  final String text;
  final bool itsMeOrNot;
  final int time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            itsMeOrNot ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender, style: TextStyle(fontSize: 11.0)),
          Material(
            borderRadius: itsMeOrNot
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0)),
            elevation: 10.0,
            shadowColor: itsMeOrNot ? Colors.blue : Colors.white70,
            color: itsMeOrNot ? Colors.lightBlue : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text('${text}',
                  style: TextStyle(
                      fontSize: 16.0,
                      color: itsMeOrNot ? Colors.white : Colors.black)),
            ),
          ),
          Text('${DateFormat.jms().format(now)}',
              style: TextStyle(fontSize: 9.0)),
        ],
      ),
    );
  }
}
