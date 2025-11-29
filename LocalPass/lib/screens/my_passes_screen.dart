import 'package:flutter/material.dart';
import 'package:localpass/models/pass.dart';
import 'package:localpass/services/firestore_service.dart';

class MyPassesScreen extends StatelessWidget {
  MyPassesScreen({Key? key}) : super(key: key);

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Upcoming and Used
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Passes'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Upcoming', icon: Icon(Icons.timer)),
              Tab(text: 'Used', icon: Icon(Icons.check_circle_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Upcoming Passes
            _PassList(
              status: 'upcoming',
              firestoreService: _firestoreService,
            ),
            // Tab 2: Used Passes
            _PassList(
              status: 'used',
              firestoreService: _firestoreService,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widget to handle the list and stream logic
class _PassList extends StatelessWidget {
  final String status;
  final FirestoreService firestoreService;

  const _PassList({required this.status, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pass>>(
      stream: firestoreService.getPasses(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading passes.'));
        }

        final passes = snapshot.data ?? [];

        if (passes.isEmpty) {
          return Center(child: Text('No $status passes yet.'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemCount: passes.length,
          itemBuilder: (context, index) {
            final pass = passes[index];
            return Card(
              child: ListTile(
                title: Text(pass.eventName),
                subtitle: Text('Acquired: ${pass.acquiredDate.toDate().toString().split(' ')[0]}'),

                // === CHECK-IN BUTTON LOGIC ===
                trailing: status == 'upcoming'
                    ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      // 1. Feedback to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Verifying location...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // 2. Call the Check-In Logic
                      await firestoreService.checkIn(pass);

                      // 3. Success Message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Check-in Successful! Welcome!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // The StreamBuilder will automatically update the UI
                      // and move the pass to the "Used" tab.

                    } catch (e) {
                      // 4. Error Message (e.g., Too far away)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          // Remove "Exception: " text to make it cleaner
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Check-In'),
                )
                    : Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}