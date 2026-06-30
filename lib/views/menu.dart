import 'package:dot_navigation_bar/dot_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:quotes_app/views/themes/colors.dart';

import 'templates/create_quote_page_template.dart';
import 'templates/my_profile_page_template.dart';
import 'templates/quotes_page_template.dart';
import 'widgets/empty_state.dart';

enum _SelectedTab { quotes, create, favorite, profile }

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  _SelectedTab _selectedTab = _SelectedTab.quotes;

  void _handleIndexChanged(int i) {
    setState(() {
      _selectedTab = _SelectedTab.values[i];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _SelectedTab.values.indexOf(_selectedTab),
        children: const [
          QuotesPage(),
          CreateQuotePage(showBackButton: false),
          Scaffold(
            body: SafeArea(
              child: EmptyState(
                description: 'Favorite quotes will appear here.',
              ),
            ),
          ),
          MyProfile(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: DotNavigationBar(
        currentIndex: _SelectedTab.values.indexOf(_selectedTab),
        onTap: _handleIndexChanged,
        dotIndicatorColor: MyColors.black,
        backgroundColor: MyColors.secondary,
        enableFloatingNavBar: false,
        paddingR: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        enablePaddingAnimation: false,
        selectedItemColor: MyColors.secondary,
        items: [
          DotNavigationBarItem(icon: _navIcon(_SelectedTab.quotes, 'Quotes')),
          DotNavigationBarItem(
            icon: _navIcon(_SelectedTab.create, 'Create quote'),
          ),
          DotNavigationBarItem(
            icon: _navIcon(_SelectedTab.favorite, 'Favorites'),
          ),
          DotNavigationBarItem(icon: _navIcon(_SelectedTab.profile, 'Profile')),
        ],
      ),
    );
  }

  Widget _navIcon(_SelectedTab tab, String label) {
    final isSelected = _selectedTab == tab;
    String asset;

    switch (tab) {
      case _SelectedTab.quotes:
        asset = isSelected
            ? "assets/images/ic_quotes_filled.png"
            : "assets/images/ic_quotes_outlined.png";
        break;
      case _SelectedTab.create:
        asset = isSelected
            ? "assets/images/ic_create_filled.png"
            : "assets/images/ic_create_outlined.png";
        break;
      case _SelectedTab.favorite:
        asset = isSelected
            ? "assets/images/ic_favorite_filled.png"
            : "assets/images/ic_favorite_outlined.png";
        break;
      case _SelectedTab.profile:
        asset = isSelected
            ? "assets/images/ic_user_filled.png"
            : "assets/images/ic_user_outlined.png";
        break;
    }

    return Semantics(
      label: label,
      selected: isSelected,
      child: Image.asset(asset, width: 24),
    );
  }
}
