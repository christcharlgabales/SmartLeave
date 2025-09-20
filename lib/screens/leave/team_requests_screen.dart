// lib/screens/leave/team_requests_screen.dart
import 'package:flutter/material.dart';

class TeamRequestsScreen extends StatelessWidget {
  const TeamRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Requests'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Team Requests - Coming Soon'),
          ],
        ),
      ),
    );
  }
}