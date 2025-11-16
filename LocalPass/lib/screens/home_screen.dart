import 'package:flutter/material.dart';
import 'package:localpass/models/event.dart'; // Import the model
import 'package:localpass/services/auth_service.dart';
import 'package:localpass/services/firestore_service.dart'; // Import the service

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  final AuthService _authService = AuthService();
  // Create an instance of the FirestoreService
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
      // We no longer have a static Center widget
      // We replace it with a StreamBuilder
      body: StreamBuilder<List<Event>>(
        stream: _firestoreService.getEvents(), // Listen to the getEvents stream
        builder: (context, snapshot) {
          // 1. Check for errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 2. Check if the stream is loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 3. We have data!
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No events found.'));
          }

          // Get the list of events from the snapshot
          final events = snapshot.data!;

          // 4. Use a ListView.builder to display each event
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              // This is a simple placeholder card
              // We'll make a custom widget for this next
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text('${event.category} - ${event.date.toDate().toString()}'),
                  trailing: Text(event.cost == 0 ? 'Free' : '\$${event.cost}'),
                  onTap: () {
                    // TODO: In Stage 3, navigate to Event Details Screen
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