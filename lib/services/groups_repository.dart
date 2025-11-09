import 'dart:async';
import '../models/group.dart';
import '../data/groups_data.dart';

class GroupsRepository {
  static final GroupsRepository _instance = GroupsRepository._internal();
  factory GroupsRepository() => _instance;
  GroupsRepository._internal();

  final List<Group> _groups = [];
  final StreamController<List<Group>> _groupsController = StreamController<List<Group>>.broadcast();

  Stream<List<Group>> get groupsStream => _groupsController.stream;
  List<Group> get groups => List.unmodifiable(_groups);

  void initialize() {
    _groups.clear();
    _groups.addAll(GroupsData.getMockGroups());
    _groupsController.add(_groups);
  }

  void addGroup(Group group) {
    _groups.add(group);
    _groupsController.add(_groups);
  }

  void removeGroup(String groupId) {
    _groups.removeWhere((group) => group.id == groupId);
    _groupsController.add(_groups);
  }

  void addMemberToGroup(String groupId, Member member) {
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      
      // Проверяем, что участник еще не добавлен
      final isAlreadyMember = group.members.any((existingMember) => existingMember.id == member.id);
      if (isAlreadyMember) {
        return; // Участник уже в группе
      }
      
      final updatedMembers = [...group.members, member];
      _groups[groupIndex] = Group(
        id: group.id,
        name: group.name,
        avatarUrl: group.avatarUrl,
        members: updatedMembers,
        isAddNew: group.isAddNew,
        leaderId: group.leaderId,
        activeRouteId: group.activeRouteId,
      );
      _groupsController.add(_groups);
    }
  }

  void removeMemberFromGroup(String groupId, String memberId) {
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      final updatedMembers = group.members.where((member) => member.id != memberId).toList();
      _groups[groupIndex] = Group(
        id: group.id,
        name: group.name,
        avatarUrl: group.avatarUrl,
        members: updatedMembers,
        isAddNew: group.isAddNew,
        leaderId: group.leaderId,
        activeRouteId: group.activeRouteId,
      );
      _groupsController.add(_groups);
    }
  }

  Group? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  void updateGroupName(String groupId, String newName) {
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      _groups[groupIndex] = Group(
        id: group.id,
        name: newName,
        avatarUrl: group.avatarUrl,
        members: group.members,
        isAddNew: group.isAddNew,
        leaderId: group.leaderId,
        activeRouteId: group.activeRouteId,
      );
      _groupsController.add(_groups);
    }
  }

  void updateGroupAvatar(String groupId, String newAvatarUrl) {
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      _groups[groupIndex] = Group(
        id: group.id,
        name: group.name,
        avatarUrl: newAvatarUrl,
        members: group.members,
        isAddNew: group.isAddNew,
        leaderId: group.leaderId,
        activeRouteId: group.activeRouteId,
      );
      _groupsController.add(_groups);
    }
  }

  void setActiveRoute(String groupId, String? routeId) {
    final groupIndex = _groups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      _groups[groupIndex] = Group(
        id: group.id,
        name: group.name,
        avatarUrl: group.avatarUrl,
        members: group.members,
        isAddNew: group.isAddNew,
        leaderId: group.leaderId,
        activeRouteId: routeId,
      );
      _groupsController.add(_groups);
    }
  }

  void dispose() {
    _groupsController.close();
  }
}
