import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  final List<String> camErrors;

  ErrorPage({required this.camErrors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hatalı Kameralar'),
      ),
      body: ListView.builder(
        itemCount: camErrors.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(camErrors[index]),
          );
        },
      ),
    );
  }
}
