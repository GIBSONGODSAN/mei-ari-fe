import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'section_form_screen.dart';

class DepartmentListScreen extends StatefulWidget {
  @override
  _DepartmentListScreenState createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  List<dynamic> departments = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    const url = 'https://meiari-qns-be.onrender.com/api/surveys/departments';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          departments = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Departments List'),
        backgroundColor: Colors.blue,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                child: Text(errorMessage, style: TextStyle(color: Colors.red)),
              )
              : ListView.builder(
                itemCount: departments.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.account_balance, color: Colors.blue),
                    title: Text(departments[index]['departmentName']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SectionFormScreen(
                                departmentId: departments[index]['_id'],
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
