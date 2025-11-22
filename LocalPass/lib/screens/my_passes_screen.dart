import 'package:flutter/material.dart';
import 'package:localpass/models/pass.dart';
import 'package:localpass/services/firestore_service.dart';

class MyPassesScreen extends StatelessWidget {
  MyPassesScreen({Key? key}) : super(key: key);

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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

            _PassList(
              status: 'upcoming',
              firestoreService: _firestoreService,
            ),

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
                trailing: status == 'upcoming'
                    ? ElevatedButton(
                  onPressed: () {
                    // TODO: Stage 4: Implement Check-In logic
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