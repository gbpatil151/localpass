import 'package:flutter/material.dart';
import 'package:localpass/models/event.dart';
import 'package:localpass/services/firestore_service.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;


  final FirestoreService _firestoreService = FirestoreService();


  EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    String eventDate = event.date.toDate().toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            InfoRow(icon: Icons.calendar_today, text: eventDate),
            SizedBox(height: 8),
            InfoRow(icon: Icons.category, text: event.category),
            SizedBox(height: 8),
            InfoRow(icon: Icons.person, text: 'Hosted by ${event.organizer}'),
            SizedBox(height: 8),
            InfoRow(
              icon: Icons.location_on,
              text: 'Location (Lat: ${event.location.latitude}, Lng: ${event.location.longitude})',
            ),
            SizedBox(height: 24),
            Text(
              'About this event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 32),


            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: () async {
                  try {

                    await _firestoreService.getPass(event);


                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pass for "${event.title}" acquired!'),
                        backgroundColor: Colors.green,
                      ),
                    );


                    Navigator.of(context).pop();

                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(event.cost == 0 ? 'Get Free Pass' : 'Get Pass for \$${event.cost}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for the icon rows
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({Key? key, required this.icon, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}