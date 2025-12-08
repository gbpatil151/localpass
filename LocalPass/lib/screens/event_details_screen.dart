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
      appBar: AppBar(title: Text(event.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            InfoRow(icon: Icons.calendar_today, text: eventDate),
            SizedBox(height: 8),
            InfoRow(icon: Icons.category, text: event.category),
            SizedBox(height: 8),
            InfoRow(icon: Icons.person, text: 'Hosted by ${event.organizer}'),
            SizedBox(height: 8),
            InfoRow(
              icon: Icons.location_on,
              text:
              'Location (Lat: ${event.location.latitude.toStringAsFixed(4)}, Lng: ${event.location.longitude.toStringAsFixed(4)})',
            ),
            SizedBox(height: 24),
            Text('About this event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(event.description,
                style: TextStyle(fontSize: 16, height: 1.5)),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: () => _handleGetPassPress(context),
                child: Text(event.cost == 0
                    ? 'Get Free Pass'
                    : 'Get Pass for \$${event.cost}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGetPassPress(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Checking eligibility...'),
          duration: Duration(milliseconds: 800)),
    );

    try {
      Map<String, dynamic> check =
      await _firestoreService.checkPurchaseEligibility(event);
      String status = check['status'];

      if (status == 'sales_closed') {
        _showErrorDialog(context, 'Sales Closed',
            'Ticket sales close 1 hour before the event starts.');
      } else if (status == 'duplicate') {
        _showErrorDialog(context, 'Duplicate Pass',
            'You already have a pass for this event in your collection.');
      } else if (status == 'low_balance') {
        int balance = check['currentBalance'];
        num cost = event.cost;
        _showErrorDialog(context, 'Insufficient Funds',
            'You have \$$balance but this pass costs \$$cost.');
      } else if (status == 'ok') {
        int balance = check['currentBalance'];
        _showConfirmationDialog(context, balance);
      } else {
        _showErrorDialog(
            context, 'Error', check['message'] ?? 'Something went wrong.');
      }
    } catch (e) {
      _showErrorDialog(context, 'System Error', e.toString());
    }
  }

  void _showConfirmationDialog(BuildContext context, int currentBalance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Purchase'),
        content: Text('Pass Cost: \$${event.cost}\n'
            'Your Balance: \$$currentBalance\n\n'
            'Do you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _processPurchase(context);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processing transaction...')),
      );

      await _firestoreService.getPass(event);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Pass acquired successfully!'),
            backgroundColor: Colors.green),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Transaction Failed: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          )
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({Key? key, required this.icon, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
      ],
    );
  }
}