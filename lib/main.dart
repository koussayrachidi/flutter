import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Student Information'),
        ),
        body: StudentInfo(),
      ),
    );
  }
}

class StudentInfo extends StatefulWidget {
  @override
  _StudentInfoState createState() => _StudentInfoState();
}

class _StudentInfoState extends State<StudentInfo> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dobPlaceController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController mathGradeController = TextEditingController();
  TextEditingController scienceGradeController = TextEditingController();
  TextEditingController historyGradeController = TextEditingController();
  XFile? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      _selectedImage = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // Top: Image for the Photo
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: Text('Choose Photo'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: Text('Take Photo'),
                  ),
                ],
              ),
              SizedBox(height: 8),
              _selectedImage == null
                  ? Placeholder(
                      fallbackHeight: 150,
                      fallbackWidth: double.infinity,
                    )
                  : Image.file(
                      File(_selectedImage!.path),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
            ],
          ),
          SizedBox(height: 16),

          // Top Left: Text Fields for First Name, Last Name
          _buildTextField('First Name', firstNameController),
          _buildTextField('Last Name', lastNameController),
          SizedBox(height: 16),

          // Middle: Text Fields for Date of Birth, Place, Address
          _buildTextField('Date of Birth', dobPlaceController),
          _buildTextField('Place', addressController),
          SizedBox(height: 16),

          // Right: List of Subjects and Input Fields for Grades
          _buildSubject('Math', mathGradeController),
          _buildSubject('Science', scienceGradeController),
          _buildSubject('History', historyGradeController),

          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              Map<String, dynamic> newStudent = {
                'firstName': firstNameController.text,
                'lastName': lastNameController.text,
                'dob': dobPlaceController.text,
                'dobPlace': addressController.text,
                'imagePath': _selectedImage?.path,
                "grades": {
                  'math': mathGradeController.text,
                  'science': scienceGradeController.text,
                  'history': historyGradeController.text,
                }
              };

              // Send a POST request to the JSON server to add the new student
              await addStudentToServer(newStudent);

              // Add logic to handle adding a new student
              print('Add Student button pressed');
            },
            child: Text('Add Student'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentListPage(selectedImagePath: _selectedImage?.path),
                ),
              );
            },
            child: Text('Students list'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildSubject(String subject, TextEditingController gradeController) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(subject),
        subtitle: _buildTextField('Grade', gradeController),
      ),
    );
  }

  Future<void> addStudentToServer(Map<String, dynamic> newStudent) async {
    final url =
        'http://192.168.164.19:3000/students'; // Replace with your server URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(newStudent),
      );

      if (response.statusCode == 201) {
        // Student added successfully
        print('Student added successfully');
      } else {
        // Error adding student
        print('Error adding student. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or server error
      print('Error adding student: $e');
    }
  }
}

class StudentListPage extends StatefulWidget {
  final String? selectedImagePath;

  const StudentListPage({Key? key, this.selectedImagePath}) : super(key: key);

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  static const studentsPerPage = 4;
  int currentPage = 1;

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];

  TextEditingController filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final url = 'http://192.168.164.19:3000/students';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> studentData = json.decode(response.body);
        setState(() {
          students = List<Map<String, dynamic>>.from(studentData);
          filteredStudents = List<Map<String, dynamic>>.from(students);
        });
      } else {
        print('Error fetching students. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  List<Map<String, dynamic>> getStudentsForCurrentPage() {
    final startIndex = (currentPage - 1) * studentsPerPage;
    final endIndex = startIndex + studentsPerPage;
    return filteredStudents.sublist(
      startIndex,
      endIndex.clamp(
          0, filteredStudents.length), // Ensure endIndex is within bounds
    );
  }

  void filterStudents(String name) {
    setState(() {
      filteredStudents = students
          .where((student) => '${student['firstName']} ${student['lastName']}'
              .toLowerCase()
              .contains(name.toLowerCase()))
          .toList();
    });
  }

  bool _isInAgeRange(Map<String, dynamic> student) {
    final dob = student['dob'] as String?;
    if (dob != null) {
      final birthDate = DateTime.parse(dob);
      final currentDate = DateTime.now();
      final age = currentDate.year - birthDate.year;

      return age >= 18; // Change the age limit as needed
    }

    return false;
  }

  void filterStudentsByAge() {
    setState(() {
      filteredStudents = students
          .where((student) =>
              _isInAgeRange(student) &&
              '${student['firstName']} ${student['lastName']}'
                  .toLowerCase()
                  .contains(filterController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: filterController,
                    onChanged: (value) {
                      filterStudents(value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Filter by Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: filterStudentsByAge,
                  child: Text('Filter by Age'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: getStudentsForCurrentPage().length,
              itemBuilder: (context, index) {
                final currentStudents = getStudentsForCurrentPage();
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: currentStudents[index]['imagePath'] !=
                              null
                          ? FileImage(File(currentStudents[index]['imagePath']))
                          : null,
                    ),
                    title: Text(
                      '${currentStudents[index]['firstName']} ${currentStudents[index]['lastName']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date of Birth: ${currentStudents[index]['dob']}'),
                        Text('Place: ${currentStudents[index]['dobPlace']}'),
                        Text('Address: ${currentStudents[index]['address']}'),
                      ],
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            'Math: ${currentStudents[index]['grades']['math']}'),
                        Text(
                            'Science: ${currentStudents[index]['grades']['science']}'),
                        Text(
                            'History: ${currentStudents[index]['grades']['history']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentPage = (currentPage - 1).clamp(1, totalPages);
                  });
                },
                child: Text('Previous Page'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentPage = (currentPage + 1).clamp(1, totalPages);
                  });
                },
                child: Text('Next Page'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int get totalPages {
    return (filteredStudents.length / studentsPerPage).ceil();
  }
}
