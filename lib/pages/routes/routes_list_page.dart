import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/pill.dart';
import 'package:offroad_nav/pages/routes/routes_stream_list.dart';

class RoutesListPage extends StatefulWidget {
  const RoutesListPage({super.key});

  @override
  State<RoutesListPage> createState() => _RoutesListPageState();
}

class _RoutesListPageState extends State<RoutesListPage> {
  final _search = TextEditingController();
  RoutesTab _tab = RoutesTab.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NewAppBar(
        title: 'Routes',
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: backgroundMainColor,
      body: Column(
        children: [
          // поиск
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: padding12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radius16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // табы
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(child: Pill(
                  text: 'All routes', 
                  selected: _tab == RoutesTab.all, 
                  onTap:  () {setState(() => _tab = RoutesTab.all);}
                  )),
                const SizedBox(width: 12),
                Expanded(child: Pill(text: 'My routes', selected:  _tab == RoutesTab.mine, onTap:  () {
                  setState(() => _tab = RoutesTab.mine);
                })),
              ],
            ),
          ),
          // список
          Expanded(
            child: RoutesStreamList(
              tab: _tab,
              searchText: _search.text,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: AppButton(
          text: 'Make a route',
          onPressed: () => Navigator.pushReplacementNamed(context, '/makeroutepage'),
        ),
      ),
    );
  }
}
