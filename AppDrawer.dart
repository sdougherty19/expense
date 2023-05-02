import 'package:flutter/material.dart';
import 'package:expense_report/main.dart';
import 'package:expense_report/ListPage.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey[300]), // Change the color to light grey
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add a logo
                Image.network(
                  'https://profileprecisionextrusions.com/wp-content/uploads/2015/04/logo.png',
                  height: 80, // You can adjust the height and width as needed
                  width: 80,
                ),
                SizedBox(height: 8),
                Text(
                  'Expense Report',
                  style: TextStyle(
                    color: Colors.black, // Change the text color to black
                    fontSize: 24, // Increase the font size
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text('Enter a New Expense'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
          Divider(color: Colors.grey), // Add a divider
          ListTile(
            title: Text('Details and Status Update'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
