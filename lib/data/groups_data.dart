import '../models/group.dart';

class GroupsData {
  static List<Group> getMockGroups() {
    return [
      // Специальная группа "Add new"
      Group(
        id: 'add_new',
        name: 'Add new',
        avatarUrl: 'assets/images/person_add.svg',
        members: [],
        isAddNew: true,
        leaderId: '',
      ),
      
      // Единственная группа
      Group(
        id: 'group1',
        name: 'Offroad Adventures',
        avatarUrl: 'assets/images/avatar_boy_01.svg',
        members: [
          Member(id: '1', name: 'Alex Johnson', avatarUrl: 'assets/images/avatar_boy_01.svg'),
          Member(id: '2', name: 'Maria Garcia', avatarUrl: 'assets/images/avatar_girl_01.svg'),
          Member(id: '3', name: 'David Smith', avatarUrl: 'assets/images/avatar_boy_02.svg'),
        ],
        leaderId: '1',
        activeRouteId: 'route1',
      ),
    ];
  }
}
