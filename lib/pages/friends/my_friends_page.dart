import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/images.dart';

class MyFriendsPage extends StatefulWidget {
  const MyFriendsPage({super.key});

  @override
  State<MyFriendsPage> createState() => _MyFriendsPageState();
}

class _MyFriendsPageState extends State<MyFriendsPage> {
  String currentUid = '';
  List<DocumentSnapshot> requests = [];
  List<DocumentSnapshot> friends = [];
  List<DocumentSnapshot> outgoingRequests = [];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUid = user.uid;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final requestsSnapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to_user_id', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .get();

    final friendsSnapshot = await FirebaseFirestore.instance
        .collection('friends')
        .where('user_id', isEqualTo: currentUid)
        .get();

    final outgoingRequestsSnapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from_user_id', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      requests = requestsSnapshot.docs;
      friends = friendsSnapshot.docs;
      outgoingRequests = outgoingRequestsSnapshot.docs;
    });
  }

  Future<void> _acceptRequest(DocumentSnapshot request) async {
    final fromUserId = request['from_user_id'];
    final reqId = request.id;

    // Добавляем друг другу
    await FirebaseFirestore.instance.collection('friends').add({
      'user_id': currentUid,
      'friend_id': fromUserId,
      'created_at': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('friends').add({
      'user_id': fromUserId,
      'friend_id': currentUid,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Удаляем сам запрос
    await FirebaseFirestore.instance.collection('friend_requests').doc(reqId).delete();

    _loadData();
  }

  Future<void> _rejectRequest(DocumentSnapshot request) async {
    final reqId = request.id;

    await FirebaseFirestore.instance.collection('friend_requests').doc(reqId).delete();

    _loadData();
  }

  Future<void> _removeFriend(String friendId) async {
    final friendsRef = FirebaseFirestore.instance.collection('friends');

    final myFriends = await friendsRef
        .where('user_id', isEqualTo: currentUid)
        .where('friend_id', isEqualTo: friendId)
        .get();

    final theirFriends = await friendsRef
        .where('user_id', isEqualTo: friendId)
        .where('friend_id', isEqualTo: currentUid)
        .get();

    for (final doc in [...myFriends.docs, ...theirFriends.docs]) {
      await doc.reference.delete();
    }

    _loadData();
  }

  Future<void> _cancelSentRequest(DocumentSnapshot request) async {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(request.id)
        .delete();

    _loadData();
  }

  Future<String> _getEmail(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc['email'] ?? 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NewAppBar(
        title: "My friends",
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Friend requests", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...requests.map((req) {
            final uid = req['from_user_id'];
            return FutureBuilder<String>(
              future: _getEmail(uid),
              builder: (context, snapshot) {
                return ListTile(
                  title: Text(snapshot.data ?? 'Loading...'),
                  subtitle: const Text('Friend request'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: checkIcon,
                        tooltip: 'Accept',
                        onPressed: () => _acceptRequest(req),
                      ),
                      IconButton(
                        icon: closeIcon,
                        tooltip: 'Reject',
                        onPressed: () => _rejectRequest(req),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Friends", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...friends.map((doc) {
            final uid = doc['friend_id'];
            return FutureBuilder<String>(
              future: _getEmail(uid),
              builder: (context, snapshot) {
                return ListTile(
                  title: Text(snapshot.data ?? 'Loading...'),
                  trailing: IconButton(
                    icon: deleteIcon,
                    tooltip: 'Delete a friend',
                    onPressed: () => _removeFriend(uid),
                  ),
                );
              },
            );
          }),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Awaiting confirmation", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...outgoingRequests.map((req) {
            final uid = req['to_user_id'];
            return FutureBuilder<String>(
              future: _getEmail(uid),
              builder: (context, snapshot) {
                return ListTile(
                  title: Text(snapshot.data ?? 'Loading...'),
                  subtitle: const Text('Awaiting confirmation'),
                  trailing: IconButton(
                    icon: cancelIcon,
                    tooltip: 'Cancel request',
                    onPressed: () => _cancelSentRequest(req),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}