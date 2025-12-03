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
              Tab(text: 'History', icon: Icon(Icons.history)), // Renamed Tab
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Upcoming Passes (Uses the new getUpcomingPasses)
            _PassList(
              stream: _firestoreService.getUpcomingPasses(),
              isHistory: false,
              firestoreService: _firestoreService,
            ),
            // Tab 2: History (Uses the new getPassHistory)
            _PassList(
              stream: _firestoreService.getPassHistory(),
              isHistory: true,
              firestoreService: _firestoreService,
            ),
          ],
        ),
      ),
    );
  }
}

class _PassList extends StatelessWidget {
  final Stream<List<Pass>> stream; // Now accepts a stream directly
  final bool isHistory;
  final FirestoreService firestoreService;

  const _PassList({
    required this.stream,
    required this.isHistory,
    required this.firestoreService
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pass>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading passes.'));
        }

        final passes = snapshot.data ?? [];

        if (passes.isEmpty) {
          return Center(child: Text(isHistory ? 'No history yet.' : 'No upcoming passes.'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemCount: passes.length,
          itemBuilder: (context, index) {
            final pass = passes[index];
            return Card(
              // Change color for expired passes to make them distinct
              color: pass.status == 'expired' ? Colors.grey[200] : Colors.white,
              child: ListTile(
                title: Text(
                  pass.eventName,
                  style: TextStyle(
                    color: pass.status == 'expired' ? Colors.grey : Colors.black,
                    decoration: pass.status == 'expired' ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text('Status: ${pass.status.toUpperCase()}'),

                // === TRAILING ICON LOGIC ===
                trailing: _buildTrailingWidget(context, pass),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrailingWidget(BuildContext context, Pass pass) {
    if (pass.status == 'upcoming') {
      // Show Check-In Button
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _handleCheckIn(context, pass),
        child: Text('Check-In'),
      );
    } else if (pass.status == 'used') {
      // Green Check for Used
      return Icon(Icons.check_circle, color: Colors.green, size: 30);
    } else {
      // Red/Grey Cross for Expired
      return Icon(Icons.cancel, color: Colors.grey, size: 30);
    }
  }

  void _handleCheckIn(BuildContext context, Pass pass) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verifying location...'), duration: Duration(seconds: 1)),
      );

      await firestoreService.checkIn(pass);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in Successful!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}