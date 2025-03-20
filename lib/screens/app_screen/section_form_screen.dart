import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SectionFormScreen extends StatefulWidget {
  final String departmentId;

  const SectionFormScreen({super.key, required this.departmentId});

  @override
  _SectionFormScreenState createState() => _SectionFormScreenState();
}

class _SectionFormScreenState extends State<SectionFormScreen> {
  List<dynamic> sections = [];
  int currentSectionIndex = 0;
  bool isLoading = true;
  String errorMessage = '';
  Map<String, Map<String, String>> formResponses = {};
  List<dynamic> fields = [];
  Map<String, TextEditingController> textControllers = {};
  Map<String, String?> selectedOptions = {};
  Map<String, String?> fieldErrors = {};

  @override
  void initState() {
    super.initState();
    fetchSections();
  }

  Future<void> fetchSections() async {
    final url =
        'https://meiari-qns-be.onrender.com/api/surveys/sections/${widget.departmentId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          sections = data;
          if (sections.isNotEmpty) {
            fetchFields(sections[currentSectionIndex]['_id']);
          }
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load sections';
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

  Future<void> fetchFields(String sectionId) async {
    final url =
        'https://meiari-qns-be.onrender.com/api/surveys/${widget.departmentId}/sections/$sectionId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          fields = data['fields'];
          textControllers.clear();
          selectedOptions.clear();
          fieldErrors.clear();

          for (var field in fields) {
            if (isFirstOrLastSection()) {
              textControllers[field['key']] = TextEditingController();
            } else {
              selectedOptions[field['key']] = null;
            }
            fieldErrors[field['key']] = null;
          }
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load form questions';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  bool isFirstOrLastSection() {
    return currentSectionIndex == 0 ||
        currentSectionIndex == sections.length - 1;
  }

  bool validateForm() {
    bool isValid = true;
    setState(() {
      fieldErrors.clear();
      for (var field in fields) {
        if (isFirstOrLastSection()) {
          if (textControllers[field['key']]!.text.isEmpty) {
            fieldErrors[field['key']] = "This field is required";
            isValid = false;
          }
        } else {
          if (selectedOptions[field['key']] == null) {
            fieldErrors[field['key']] = "Please select Yes or No";
            isValid = false;
          }
        }
      }
    });
    return isValid;
  }

  void nextSection() {
    if (!validateForm()) return;

    formResponses[sections[currentSectionIndex]['_id']] = {
      for (var field in fields)
        field['key']:
            isFirstOrLastSection()
                ? textControllers[field['key']]!.text
                : selectedOptions[field['key']]!,
    };

    if (currentSectionIndex < sections.length - 1) {
      setState(() {
        currentSectionIndex++;
        fetchFields(sections[currentSectionIndex]['_id']);
      });
    } else {
      submitForm();
    }
  }

  void submitForm() async {
    if (!validateForm()) return;

    // Structure the collected responses with section names
    List<Map<String, dynamic>> structuredResponses = [];

    for (var section in sections) {
      String sectionId = section['_id'];
      String sectionName = section['name'];

      if (formResponses.containsKey(sectionId)) {
        structuredResponses.add({
          "sectionId": sectionId,
          "sectionName": sectionName,
          "questions":
              formResponses[sectionId]!.entries.map((entry) {
                return {"question": entry.key, "answer": entry.value};
              }).toList(),
        });
      }
    }

    // Print structured responses in console
    print("=== FORM SUBMISSION DATA ===");
    prettyPrintJson(structuredResponses);

    // Send to API
    final url = 'http://127.0.0.1:8000/app/generate-and-upload-report/';
    print("Sending request to $url...");
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "departmentId": widget.departmentId,
          "responses": structuredResponses,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Form Submitted Successfully!")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission Failed! Try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(sections[currentSectionIndex]['name'])),
      body: ListView(
        children: [
          for (var field in fields)
            isFirstOrLastSection()
                ? TextField(
                  controller: textControllers[field['key']],
                  decoration: InputDecoration(
                    labelText: field['key'],
                    errorText: fieldErrors[field['key']],
                  ),
                )
                : Column(
                  children: [
                    Text(field['key']),
                    Row(
                      children: [
                        Radio(
                          value: "Yes",
                          groupValue: selectedOptions[field['key']],
                          onChanged:
                              (value) => setState(
                                () => selectedOptions[field['key']] = value,
                              ),
                        ),
                        Text("Yes"),
                        Radio(
                          value: "No",
                          groupValue: selectedOptions[field['key']],
                          onChanged:
                              (value) => setState(
                                () => selectedOptions[field['key']] = value,
                              ),
                        ),
                        Text("No"),
                      ],
                    ),
                  ],
                ),
          ElevatedButton(
            onPressed: nextSection,
            child: Text(
              currentSectionIndex == sections.length - 1 ? "Submit" : "Next",
            ),
          ),
        ],
      ),
    );
  }
}

void prettyPrintJson(dynamic jsonData) {
  const int chunkSize = 800; // Print in small chunks to avoid truncation
  String jsonString = jsonEncode(jsonData);
  for (int i = 0; i < jsonString.length; i += chunkSize) {
    print(
      jsonString.substring(
        i,
        i + chunkSize > jsonString.length ? jsonString.length : i + chunkSize,
      ),
    );
  }
}
