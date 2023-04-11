import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:minio/minio.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Report App',
      theme: darkTheme,
      home: MyHomePage(title: 'Expense Report Form'),
    );
  }
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  primaryColor: Colors.white,
  accentColor: Colors.white,
  textTheme: TextTheme(
    headline6: TextStyle(color: Colors.white),
    bodyText2: TextStyle(color: Colors.white),
  ),
);

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late File? _image = null;
  final picker = ImagePicker();
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _transactionDateController =
  TextEditingController();
  final TextEditingController _businessPurposeController =
  TextEditingController();
  final TextEditingController _expenseTypeController =
  TextEditingController();
  final TextEditingController _dollarsController = TextEditingController();
  late String _company = 'Profile Extrusion Company';
  late String _gl;
  late String _corporateCreditCard;
  late String _status;

  List<String> _companies = [
    'Profile Extrusion Company',
    'GPI',
    'GPI2',
    'AJ Glass',
    'CCN Enterprises LLC',
    'LS9',
    'MU6 LLC',
    'HST Innovations LLC',
    'AMD',
    'CAT5 Construction'
  ];

  List<String> _businessPurposes = [
    'Employee Meals',
    'Lodging',
    'Miscellaneous',
    'Rental Car',
    'Corporate Contributions',
    'Personal Car Mileage',
    'Air Travel',
    'Entertainment',
    'Outside Service Other',
    'Small Tools',
    'Corporate and Licensing Fees'
  ];

  List<String> _corporateCreditCards = [
    'Yes - a Credit Card was Used',
    'No - Personal Expense'
  ];

  List<String> _statuses = [
    'On Hold',
    'Ready for Processing',
    'Returned for Review',
    'Approved'
  ];

  Future getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<String?> uploadImageToS3(File image) async {
    final minio = Minio(
      endPoint: 's3.us-east-1.wasabisys.com',
      accessKey: 'U838PX8RD5761WY7IS7D',
      secretKey: 'N4mUU7AgOc7iPwGaRKkDnGgIDEpytrLCB9JAb5oi',
      useSSL: true,
    );

    final now = DateTime.now().toString();
    final filename = 'expense-report-image-$now.jpg';

    try {
      final bytes = await image.readAsBytes();
      final stream = Stream.fromIterable([bytes]);

      // Set the Expires header to 15 minutes in the future
      final expires = DateTime.now().add(Duration(minutes: 15)).toUtc().toIso8601String();

      await minio.putObject('appdevimages', filename, stream,
          metadata: {'Expires': expires});

      final endpoint = 'https://s3.us-east-1.wasabisys.com'; // Replace with your Minio server URL
      final url = '$endpoint/appdevimages/$filename';
      return url;
    } catch (e) {
      print('Error uploading image to S3: $e');
      return null;
    }
  }









  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get the values from the form fields
      final employee = _employeeController.text;
      final vendor = _vendorController.text;
      final transactionDate = _transactionDateController.text;
      final businessPurpose = _businessPurposeController.text;
      final expenseType = _expenseTypeController.text;
      final dollars = _dollarsController.text;

      // Determine the GL value based on the selected business purpose
      switch (businessPurpose) {
        case 'Employee Meals':
          _gl = '7817-800';
          break;
        case 'Lodging':
          _gl = '7818-800';
          break;
        case 'Miscellaneous':
          _gl = '7816-800';
          break;
        case 'Rental Car':
          _gl = '7821-800';
          break;
        case 'Corporate Contributions':
          _gl = '7839-800';
          break;
        case 'Personal Car Mileage':
          _gl = '7814-800';
          break;
        case 'Air Travel':
          _gl = '7820-800';
          break;
        case 'Entertainment':
          _gl = '7809-800';
          break;
        case 'Outside Service Other':
          _gl = '7822-800';
          break;
        case 'Small Tools':
          _gl = '7818-800';
          break;
        case 'Corporate and Licensing Fees':
          _gl = '7682-800';
          break;
      }

      // Send the form data to the PHP API
      final url = 'https://your-api-endpoint.com/upload_expense_report.php';
      final response = await http.post(Uri.parse(url), body: {
        'company': _company,
        'employee': employee,
        'vendor': vendor,
        'transaction_date': transactionDate,
        'business_purpose': businessPurpose,
        'gl': _gl,
        'expense_type': expenseType,
        'dollars': dollars,
        'corporate_credit_card': _corporateCreditCard,
        'status': _status,
      });

      if (response.statusCode == 200) {
        print('Form data submitted successfully');
      } else {
        print('Error submitting form data: ${response.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Company'),
                DropdownButtonFormField<String>(
                  value: _company,
                  items: _companies.map((company) {
                    return DropdownMenuItem<String>(
                      value: company,
                      child: Text(company),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _company = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a company';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text('Employee'),
                TextFormField(
                  controller: _employeeController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an employee';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text('Vendor'),
                TextFormField(
                  controller: _vendorController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a vendor';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text('Transaction Date'),
                TextFormField(
                  controller: _transactionDateController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a transaction date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text('Business Purpose'),
                DropdownButtonFormField<String>(
                  value: null,
                  items: _businessPurposes.map((businessPurpose) {
                    return DropdownMenuItem<String>(
                      value: businessPurpose,
                      child: Text(businessPurpose),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _businessPurposeController.text = value!;
                      switch (value) {
                        case 'Employee Meals':
                          _gl = '7817-800';
                          break;
                        case 'Lodging':
                          _gl = '7818-800';
                          break;
                        case 'Miscellaneous':
                          _gl = '7816-800';
                          break;
                        case 'Rental Car':
                          _gl = '7821-800';
                          break;
                        case 'Corporate Contributions':
                          _gl = '7839-800';
                          break;
                        case 'Personal Car Mileage':
                          _gl = '7814-800';
                          break;
                        case 'Air Travel':
                          _gl = '7820-800';
                          break;
                        case 'Entertainment':
                          _gl = '7809-800';
                          break;
                        case 'Outside Service Other':
                          _gl = '7822-800';
                          break;
                        case 'Small Tools':
                          _gl = '7818-800';
                          break;
                        case 'Corporate and Licensing Fees':
                          _gl = '7682-800';
                          break;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a business purpose';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text('Expense Type'),
                TextFormField(
                  controller: _expenseTypeController,
                ),
                SizedBox(height: 16),
                Text('Dollars'),
                TextFormField(
                  controller: _dollarsController,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                Text('Corporate Credit Card'),
                DropdownButtonFormField<String>(
                  value: null,
                  items: _corporateCreditCards.map((creditCard) {
                    return DropdownMenuItem<String>(
                      value: creditCard,
                      child: Text(creditCard),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _corporateCreditCard = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a corporate credit card option';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),


                Text('Status'),
                DropdownButtonFormField<String>(
                  value: null,
                  items: _statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a status';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text('Attach Receipt Image'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: getImageFromCamera,
                      child: Text('Camera'),
                    ),
                    ElevatedButton(
                      onPressed: getImageFromGallery,
                      child: Text('Gallery'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Center(
                  child: _image == null
                      ? Text('No image selected.')
                      : Image.file(_image!),
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Upload the image to S3 and get its URL
                        final imageUrl = await uploadImageToS3(_image!);

                        // Submit the form data and the image URL to the PHP API
                        final url = 'https://your-api-endpoint.com/upload_expense_report.php';
                        final response = await http.post(Uri.parse(url), body: {
                          'company': _company,
                          'employee': _employeeController.text,
                          'vendor': _vendorController.text,
                          'transaction_date': _transactionDateController.text,
                          'business_purpose': _businessPurposeController.text,
                          'gl': _gl,
                          'expense_type': _expenseTypeController.text,
                          'dollars': _dollarsController.text,
                          'corporate_credit_card': _corporateCreditCard,
                          'status': _status,
                          'image_url': imageUrl,
                        });

                        if (response.statusCode == 200) {
                          // Clear the form fields
                          //setState(() => _);
                          _employeeController.clear();
                          _vendorController.clear();
                          _transactionDateController.clear();
                          _expenseTypeController.clear();
                          _dollarsController.clear();
                          setState(() {_image = null;});
                          setState(() => {_status = null});

                          print('Form data submitted successfully');
                        } else {
                          print('Error submitting form data: ${response.body}');
                        }
                      }
                    },
                    child: Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
