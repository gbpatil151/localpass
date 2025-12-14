import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localpass/services/firestore_service.dart';

// Admin screen for creating new events
class AddEventScreen extends StatefulWidget {
  const AddEventScreen({Key? key}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _organizerController = TextEditingController();
  final _costController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  // State Variables
  String _selectedCategory = "Community";
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1)); // Default tomorrow
  TimeOfDay _selectedTime = TimeOfDay(hour: 10, minute: 0);

  final List<String> _categories = ["Food", "Music", "Sports", "Community", "Workshop"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin: Add Event')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // TITLE
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Event Title'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              // DESCRIPTION
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),

              SizedBox(height: 10),

              // ROW: COST & CATEGORY
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: InputDecoration(labelText: 'Cost (\$)', hintText: '0 for free'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(labelText: 'Category'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              // ORGANIZER
              TextFormField(
                controller: _organizerController,
                decoration: InputDecoration(labelText: 'Organizer Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),

              SizedBox(height: 20),

              // DATE PICKER
              ListTile(
                title: Text("Date: ${_selectedDate.toLocal().toString().split(' ')[0]} at ${_selectedTime.format(context)}"),
                trailing: Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey)),
                onTap: _pickDateTime,
              ),

              SizedBox(height: 20),

              // LOCATION HELPERS
              Text("Location Coordinates", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _latController, decoration: InputDecoration(labelText: 'Latitude'))),
                  SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _lngController, decoration: InputDecoration(labelText: 'Longitude'))),
                ],
              ),
              TextButton.icon(
                icon: Icon(Icons.my_location),
                label: Text("Use My Current Location"),
                onPressed: _fillCurrentLocation,
              ),

              SizedBox(height: 30),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.all(16)),
                  child: Text("PUBLISH EVENT", style: TextStyle(fontSize: 18, color: Colors.white)),
                  onPressed: _submitForm,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Opens date and time pickers
  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    TimeOfDay? time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  // Fills location fields with current GPS coordinates
  Future<void> _fillCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });
    }
  }

  // Validates form and creates event in Firestore
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Combine selected date and time
    final eventDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute
    );

    try {
      await _firestoreService.addEvent(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        date: eventDateTime,
        category: _selectedCategory,
        cost: int.parse(_costController.text.trim()),
        organizer: _organizerController.text.trim(),
        latitude: double.parse(_latController.text.trim()),
        longitude: double.parse(_lngController.text.trim()),
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event Published!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}