import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/features/friends/data/repositories/friend_requests_repository.dart';
import 'package:offroad_nav/features/friends/data/repositories/friends_repository.dart';

class MyFriendsPage extends StatefulWidget {
  const MyFriendsPage({super.key});

  @override
  State<MyFriendsPage> createState() => _MyFriendsPageState();
}

class _MyFriendsPageState extends State<MyFriendsPage> {
  final _friendsRepo = FriendsRepository();
  final _requestsRepo = FriendRequestsRepository();
  
  String currentUid = '';

  List<FriendRequestModel> incomingRequests = [];
  List<FriendRequestModel> outgoingRequests = [];
  List<Friend> friends = [];

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
    if (currentUid.isEmpty) return;

    final incoming = await _requestsRepo.getIncomingRequests(currentUid);
    final outgoing = await _requestsRepo.getOutgoingRequests(currentUid);
    final myFriends = await _friendsRepo.getFriends(currentUid);

    if (!mounted) return;
    setState(() {
      incomingRequests = incoming;
      outgoingRequests = outgoing;
      friends = myFriends;
    });
  }

  Future<void> _acceptRequest(FriendRequestModel  request) async {
   await _requestsRepo.acceptRequest(
      currentUid: currentUid,
      request: request,
    );
    await _loadData();
  }

  Future<void> _rejectRequest(FriendRequestModel  request) async {
    await _requestsRepo.rejectRequest(request);
    await _loadData();
  }

  Future<void> _removeFriend(String friendId) async {
    await _friendsRepo.removeFriend(currentUid, friendId);
    await _loadData();
  }

  Future<void> _cancelSentRequest(FriendRequestModel request) async {
    await _requestsRepo.cancelSentRequest(request);
    await _loadData();
  }

  // Future<String> _getEmail(String uid) async {
  //   final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  //   return doc['email'] ?? 'unknown';
  // }

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
          // --- Friend requests ---
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
            "Friend requests", 
            style: TextStyle(fontWeight: FontWeight.bold)
            ),
          ),
          ...incomingRequests.map((req) {
            // final uid = req.fromUserId;
            // return FutureBuilder<String>(
            //   // future: _getEmail(uid),
            //   builder: (context, snapshot) {
                return ListTile(
                  title: Text(req.email),
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
          }),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Friends", 
              style: TextStyle(fontWeight: FontWeight.bold)
            ),
          ),
          ...friends.map((f) {
            // показываем имя или email
            final title = f.name.isNotEmpty ? f.name : f.email;
            return ListTile(
              title: Text(title),
              subtitle: f.email.isNotEmpty ? Text(f.email) : null,
              trailing: IconButton(
                icon: deleteIcon,
                tooltip: 'Delete a friend',
                onPressed: () => _removeFriend(f.uid),
              ),
            );
          }),

          // --- Outgoing requests ---
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Awaiting confirmation", 
              style: TextStyle(fontWeight: FontWeight.bold)
            ),
          ),
          ...outgoingRequests.map((req) {
            // final uid = req.toUserId;
            // return FutureBuilder<String>(
            //   future: _getEmail(uid),
            //   builder: (context, snapshot) {
                return ListTile(
                  title: Text(req.email),
                  subtitle: const Text('Awaiting confirmation'),
                  trailing: IconButton(
                    icon: cancelIcon,
                    tooltip: 'Cancel request',
                    onPressed: () => _cancelSentRequest(req),
                  ),
                );
          }),
        ],
      ),
    );
  }
}