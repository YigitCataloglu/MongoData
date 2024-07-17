import 'package:flutter/material.dart';
import 'package:proje1/anasayfa.dart';

void main() => runApp(anasayfa());

class anasayfa extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Sayfa'),
        shadowColor: Colors.red,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => proje()),
            );
          },
          child: Text('VERI TABANINA BAGLAN'),
        ),
      ),
    );
  }
}
