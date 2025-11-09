import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/models/group.dart';
import 'package:offroad_nav/data/groups_data.dart';
import 'package:offroad_nav/services/groups_repository.dart';
import 'package:offroad_nav/pages/groups/group_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final TextEditingController _searchController = TextEditingController();
  final GroupsRepository _groupsRepository = GroupsRepository();
  List<Group> _filteredGroups = [];
  List<Group> _allGroups = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterGroups);
    
    // Initialize repository and load initial data
    _groupsRepository.initialize();
    _loadInitialData();
    
    // Listen to groups changes
    _groupsRepository.groupsStream.listen((groups) {
      if (mounted) {
        setState(() {
          _allGroups = groups;
          _filterGroups();
        });
      }
    });
  }

  void _loadInitialData() {
    setState(() {
      _allGroups = _groupsRepository.groups.isNotEmpty 
          ? _groupsRepository.groups 
          : GroupsData.getMockGroups();
      _filterGroups();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterGroups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = _allGroups;
      } else {
        _filteredGroups = _allGroups.where((group) {
          return group.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  String _extractPhoto(Map<String, dynamic> user) {
    final candidates = [
      user['img'], 
      user['photoUrl'], 
      user['photoURL'], 
      user['avatar'], 
      user['photo'], 
      user['imageUrl']
    ];
    for (final v in candidates) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        titleWidget: const Text(
          'Groups',
          style: TextStyle(
            fontSize: fontSize20,
            fontWeight: FontWeight.w600,
            color: textMainColor,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(padding16),
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.only(bottom: padding16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(radius12),
                boxShadow: [
                  BoxShadow(
                    color: listShadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: textHintColor,
                    fontSize: fontSize16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: textHintColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: padding16,
                    vertical: padding12,
                  ),
                ),
              ),
            ),
            
            // Groups grid
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: padding16,
                  mainAxisSpacing: padding16,
                  childAspectRatio: 0.8,
                ),
                itemCount: _filteredGroups.length,
                itemBuilder: (context, index) {
                  final group = _filteredGroups[index];
                  return _GroupCard(
                    group: group,
                    onTap: () {
                      if (group.isAddNew) {
                        _showAddGroupDialog(context);
                      } else {
                        _showGroupDetailModal(context, group);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    String? selectedAvatar;
    
    final List<String> availableAvatars = [
      'assets/images/avatar_boy_01.svg',
      'assets/images/avatar_boy_02.svg',
      'assets/images/avatar_boy_03.svg',
      'assets/images/avatar_boy_04.svg',
      'assets/images/avatar_boy_05.svg',
      'assets/images/avatar_girl_01.svg',
      'assets/images/avatar_girl_02.svg',
      'assets/images/avatar_girl_03.svg',
      'assets/images/avatar_girl_04.svg',
      'assets/images/avatar_girl_05.svg',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Create group',
            style: TextStyle(
              fontSize: fontSize20,
              fontWeight: FontWeight.w600,
              color: textMainColor,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Group name input
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    labelStyle: TextStyle(color: textHintColor),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: buttonBackgroundColor),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                
                const SizedBox(height: height20),
                
                // Avatar selection
                const Text(
                  'Choose avatar',
                  style: TextStyle(
                    fontSize: fontSize16,
                    fontWeight: FontWeight.w500,
                    color: textMainColor,
                  ),
                ),
                
                const SizedBox(height: height12),
                
                // Avatar grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: availableAvatars.length,
                  itemBuilder: (context, index) {
                    final avatar = availableAvatars[index];
                    final isSelected = selectedAvatar == avatar;
                    
                    return GestureDetector(
                      onTap: () => setState(() => selectedAvatar = avatar),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? buttonBackgroundColor : listShadowColor,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: SvgPicture.asset(
                          avatar,
                          width: 40,
                          height: 40,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: textHintColor),
              ),
            ),
            ElevatedButton(
              onPressed: (nameController.text.isNotEmpty && selectedAvatar != null)
                  ? () async {
                      // Get current user info
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        try {
                          // Get user data from Firestore
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .get();
                          
                          final userData = userDoc.data() ?? {};
                          final userName = (userData['name'] ?? 
                              userData['displayName'] ?? 
                              currentUser.email?.split('@').first ?? 
                              'User').toString();
                          final userAvatar = _extractPhoto(userData);
                          
                          // Create current user as member
                          final currentUserMember = Member(
                            id: currentUser.uid,
                            name: userName,
                            avatarUrl: userAvatar,
                          );
                          
                          // Create new group with current user as member
                          final newGroup = Group(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameController.text.trim(),
                            avatarUrl: selectedAvatar!,
                            members: [currentUserMember],
                            leaderId: currentUser.uid,
                          );
                          
                          _groupsRepository.addGroup(newGroup);
                          setState(() {
                            _allGroups = _groupsRepository.groups;
                            _filterGroups();
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Group created successfully'),
                              backgroundColor: buttonBackgroundColor,
                            ),
                          );
                        } catch (e) {
                          // Fallback if Firestore fails
                          final currentUserMember = Member(
                            id: currentUser.uid,
                            name: currentUser.email?.split('@').first ?? 'User',
                            avatarUrl: 'assets/images/avatar_user.png',
                          );
                          
                          final newGroup = Group(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameController.text.trim(),
                            avatarUrl: selectedAvatar!,
                            members: [currentUserMember],
                            leaderId: currentUser.uid,
                          );
                          
                          _groupsRepository.addGroup(newGroup);
                          setState(() {
                            _allGroups = _groupsRepository.groups;
                            _filterGroups();
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Group created successfully'),
                              backgroundColor: buttonBackgroundColor,
                            ),
                          );
                        }
                      } else {
                        // No user logged in
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to create a group'),
                            backgroundColor: errorColor,
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBackgroundColor,
                foregroundColor: textMainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius8),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupDetailModal(BuildContext context, Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailPage(group: group),
      ),
    ).then((_) {
      // Refresh groups when returning from detail page
      setState(() {
        _allGroups = _groupsRepository.groups;
        _filterGroups();
      });
    });
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(radius16),
          boxShadow: [
            BoxShadow(
              color: listShadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(padding16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Аватар группы
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: group.isAddNew ? const Color(0xFFE0E0E0) : null,
                ),
                child: group.isAddNew
                    ? Image.asset(
                        'assets/images/group.png',
                        width: 30,
                        height: 30,
                        color: textMainColor,
                      )
                    : SvgPicture.asset(
                        group.avatarUrl,
                        width: 60,
                        height: 60,
                      ),
              ),
              
              const SizedBox(height: height12),
              
              // Название группы
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: fontSize16,
                  fontWeight: FontWeight.w600,
                  color: textMainColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: height8),
              
              // Member count (only for regular groups)
              if (!group.isAddNew)
                Text(
                  '${group.memberCount} members',
                  style: const TextStyle(
                    fontSize: fontSize12,
                    color: textHintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
