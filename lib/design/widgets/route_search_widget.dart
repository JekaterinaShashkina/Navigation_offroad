import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_detail_page.dart';
import 'package:offroad_nav/design/images.dart';

class RouteSearchWidget extends StatefulWidget {
  const RouteSearchWidget({Key? key}) : super(key: key);

  @override
  State<RouteSearchWidget> createState() => _RouteSearchWidgetState();
}

class _RouteSearchWidgetState extends State<RouteSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// Окно поиска
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(20),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search routes',
              suffixIcon: IconButton(
                icon: searchIcon,
                onPressed: () {
                  setState(() {
                    _searchQuery = _searchController.text.toLowerCase();
                  });
                },
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        /// Список результатов
        if (_searchQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height -
                  135 - // высота верхней панели
                  MediaQuery.of(context).viewInsets.bottom -
                  20,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('routes')
                  .where('isPrivate', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final routes = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
                    .where((route) =>
                        (route['name'] ?? '').toString().toLowerCase().contains(_searchQuery))
                    .toList();

                if (routes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No results found'),
                  );
                }

                return MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          route['name'] ?? 'Unnamed',
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          _showRoutesDetail(context, route);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showRoutesDetail(BuildContext context, Map<String, dynamic> route) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteDetailPage(
          name: route['name'] ?? 'Route',
          points: route['points'],
        ),
      ),
    );
  }
}