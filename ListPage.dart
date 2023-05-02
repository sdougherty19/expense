import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:expense_report/AppDrawer.dart';
import 'package:cached_network_image/cached_network_image.dart';

//Start Search Delegate Class
class DataSearch extends SearchDelegate {
  final List<dynamic> data;

  DataSearch({required this.data});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final suggestionsList = query.isEmpty
        ? data
        : data.where((item) {
      return item.values
          .any((value) => value.toString().toLowerCase().contains(query.toLowerCase()));
    }).toList();

    return ListView.builder(
      itemCount: suggestionsList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${suggestionsList[index]['employee']}'),
              Text('Company:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${suggestionsList[index]['company']}'),
              Text('Vendor:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${suggestionsList[index]['vendor']}'),
              Text('Dollars:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$${suggestionsList[index]['dollars']}'),
            ],
          ),
          onTap: () {
            close(context, suggestionsList[index]);
          },
        );
      },
    );
  }



  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionsList = query.isEmpty
        ? data
        : data.where((item) {
      return item.values
          .any((value) => value.toString().toLowerCase().contains(query.toLowerCase()));
    }).toList();

    return ListView.builder(
      itemCount: suggestionsList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${suggestionsList[index]['employee']}'),
              Text('Company:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${suggestionsList[index]['company']}'),
              Text('Vendor:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${suggestionsList[index]['vendor']}'),
              Text('Dollars:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$${suggestionsList[index]['dollars']}'),
            ],
          ),
          onTap: () {
            close(context, suggestionsList[index]);
          },
        );
      },
    );
  }
}//End Search Delegate Class


class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<dynamic> _data = [];
  List<dynamic> _filteredData = [];


  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(
        Uri.parse('https://appdata.netstoic.com/expense_rpt/exp_getdata.php'));

    if (response.statusCode == 200) {
      setState(() {
        _data = jsonDecode(response.body);
        _filteredData = _data;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> updateStatus(int id, String newStatus) async {
    final response = await http.post(
      Uri.parse('https://appdata.netstoic.com/expense_rpt/update_status.php'),
      body: {'id': id.toString(), 'status': newStatus},
    );

    if (response.statusCode == 200) {
      fetchData(); // Refresh the data
    } else {
      throw Exception('Failed to update status');
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<String> uniqueStatusOptions = {
      'Approved',
      'Returned for Review',
      'Rejected'
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Status Update'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final selectedResult = await showSearch(
                context: context,
                delegate: DataSearch(data: _data),
              );

              if (selectedResult != null) {
                setState(() {
                  _filteredData = _data.where((item) {
                    return item['employee'] == selectedResult['employee'] &&
                        item['company'] == selectedResult['company'] &&
                        item['vendor'] == selectedResult['vendor'] &&
                        item['dollars'] == selectedResult['dollars'];
                  }).toList();
                });
              }
            },

          ),
        ],
      ),
      drawer: AppDrawer(),
      body: ListView.builder(
        itemCount: _filteredData.length,
        itemBuilder: (context, index) {
          final item = _filteredData[index];
          String status = item['status'] ?? 'Default Status';

          if (!uniqueStatusOptions.contains(status)) {
            uniqueStatusOptions.add(status);
          }

          return Container(
            margin: EdgeInsets.symmetric(vertical: 4.0),
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? Colors.black : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              title: Row(
                children: [
              Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company:', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text('${item['company'] ?? ''}', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black)),
                  Text('Employee:', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text('${item['employee'] ?? ''}', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black)),
                  Text('Vendor:', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text('${item['vendor'] ?? ''}', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black)),
                  Text('Transaction Date:', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text('${item['trans_date'] ?? ''}', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black)),
                  Text('Business Purpose:', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text('${item['business_purpose'] ?? ''}', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black)),
                  Text('Expense Type:', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text('${item['expense_type'] ?? ''}', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black)),
                  Text('Dollars:', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text('\$${item['dollars'] ?? ''}', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black)),
                  Text('Corporate Credit Card:', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text('${item['corp_cc'] ?? ''}', style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black)),
                  const SizedBox(height: 8.0),

                  DropdownButton<String>(
                    value: item['status'] ?? 'Default Status',
                    items: uniqueStatusOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: TextStyle(
                                color:
                                index % 2 == 0 ? Colors.white : Colors.black)),
                        //child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      updateStatus(int.parse(item['id']), newValue!);
                    },
                    dropdownColor:
                    index % 2 == 0 ? Colors.black : Colors.grey.shade300,
                  ),
                  SizedBox(height: 8.0),

                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            contentPadding: EdgeInsets.zero,
                            content: CachedNetworkImage(
                              imageUrl: item['img_url'],
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Close'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text('View Image', style: TextStyle(color: index % 2 == 0 ? Colors.black : Colors.white)),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(index % 2 == 0 ? Colors.white : Colors.black),
                    ),
                  ),




                ],
              ),
            ),

            ]
            ),
          ),
          );
        },
      ),
    );
  }
}
