import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/accordion_card.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/features/friends/data/repositories/friend_requests_repository.dart';
import 'package:offroad_nav/features/home/presentation/widgets/empty_notifications.dart';
import 'package:offroad_nav/features/home/presentation/widgets/notification_card.dart';
import 'package:offroad_nav/features/home/presentation/widgets/pills_row.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _requestsRepo = FriendRequestsRepository();

  String currentUid = '';
  bool _loading = true;

  List<FriendRequestModel> incomingRequests = [];
  List<FriendRequestModel> outgoingRequests = [];

  int _filterIndex = 0; // 0 = All, 1 = Friends (пока только)

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    currentUid = user?.uid ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    if (currentUid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);

    final incoming = await _requestsRepo.getIncomingRequests(currentUid);
    final outgoing = await _requestsRepo.getOutgoingRequests(currentUid);

    if (!mounted) return;
    setState(() {
      incomingRequests = incoming;
      outgoingRequests = outgoing;
      _loading = false;
    });
  }

  Future<void> _acceptRequest(FriendRequestModel request) async {
    await _requestsRepo.acceptRequest(currentUid: currentUid, request: request);
    await _loadData();
  }

  Future<void> _rejectRequest(FriendRequestModel request) async {
    await _requestsRepo.rejectRequest(request);
    await _loadData();
  }

  Future<void> _cancelSentRequest(FriendRequestModel request) async {
    await _requestsRepo.cancelSentRequest(request);
    await _loadData();
  }

  bool get _hasAnyNotifications =>
      incomingRequests.isNotEmpty || outgoingRequests.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NewAppBar(
        title: "Notification",
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: backgroundMainColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAnyNotifications
          ? EmptyNotifications(onBackHome: () => Navigator.pop(context))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  PillsRow(
                    items: const ["All", "Friends", "Assign by me", "@Mention"],
                    selectedIndex: _filterIndex,
                    onSelect: (i) => setState(() => _filterIndex = i),
                    scrollable: true,
                  ),
                  const SizedBox(height: 12),

                  // Сейчас у нас только friend-notifs, поэтому фильтры пока простые:
                  if (_filterIndex == 0 || _filterIndex == 1) ...[
                    AccordionCard(
                      title: "Friend requests",
                      count: incomingRequests.length,
                      initiallyExpanded: true,
                      child: incomingRequests.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text("No incoming requests"),
                            )
                          : Column(
                              children: [
                                for (final req in incomingRequests) ...[
                                  NotificationCard(
                                    title: req.email,
                                    subtitle: "Wants to add you",
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.12),
                                      child: const Icon(Icons.person_add_alt_1, color: chipBgColor,),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.check, color: const Color.fromARGB(255, 11, 124, 15)),
                                          onPressed: () => _acceptRequest(req),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close_rounded, color: errorColor),
                                          onPressed: () => _rejectRequest(req),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),

                    AccordionCard(
                      title: "Awaiting confirmation",
                      count: outgoingRequests.length,
                      initiallyExpanded: true,
                      child: outgoingRequests.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text("No outgoing requests"),
                            )
                          : Column(
                              children: [
                                for (final req in outgoingRequests) ...[
                                  NotificationCard(
                                    title: req.email,
                                    subtitle: "Waiting for reply",
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.12),
                                      child: const Icon(Icons.add_alarm_rounded, color:chipBgColor),
                                    ),
                                    trailing: IconButton(
                                    icon: Icon(Icons.close_rounded, color: errorColor),
                                    onPressed: () => _cancelSentRequest(req),
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
                    ),
                  ],

                  // Заготовка на будущее: если выбрали Groups/Competitions — пока пусто.
                  if (_filterIndex >= 2) ...[
                    const SizedBox(height: 20),
                    const _InlineEmpty(
                      text: "No notifications in this category yet",
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final List<Widget> actions;

  const _ActionTile({
    required this.title,
    required this.leadingIcon,
    required this.actions,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Icon(leadingIcon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final String text;
  const _InlineEmpty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: Text(text)),
    );
  }
}
