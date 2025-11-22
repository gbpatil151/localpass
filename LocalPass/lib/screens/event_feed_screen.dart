import 'package:flutter/material.dart';
import 'package:localpass/models/event.dart';
import 'package:localpass/services/auth_service.dart';
import 'package:localpass/services/firestore_service.dart';
import 'package:localpass/screens/event_details_screen.dart';


class EventFeedScreen extends StatelessWidget {
  EventFeedScreen({Key? key}) : super(key: key);

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LocalPass Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _authService.signOut();
            },
          ),
        ],
      ),

      body: StreamBuilder<List<Event>>(
        stream: _firestoreService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No events found.'));
          }

          final events = snapshot.data!;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text('${event.category} - ${event.date.toDate().toString()}'),
                  trailing: Text(event.cost == 0 ? 'Free' : '\$${event.cost}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(event: event),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}