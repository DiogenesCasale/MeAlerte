import 'package:flutter/material.dart';

void main() {
  runApp(MeAlerteApp());
}

class MeAlerteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeAlerte',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: Colors.white,
          secondary: Colors.redAccent,
        ),
        iconTheme: IconThemeData(color: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    Center(child: Text('Lembretes', style: TextStyle(fontSize: 24))),
    Center(child: Text('Medicamentos', style: TextStyle(fontSize: 24))),
    Center(child: Text('Exames', style: TextStyle(fontSize: 24))),
    Center(child: Text('Menu', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.alarm),
      label: 'Lembrete',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.medication),
      label: 'Medicamentos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment),
      label: 'Exames',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu),
      label: 'Menu',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
      ),
    );
  }
}
