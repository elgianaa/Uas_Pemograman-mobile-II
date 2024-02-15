import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rest_api/screen/add_page_.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  int _currentIndex = 0;
  bool isLoading = true;
  List items = [];
  List filteredItems = [];
  TextEditingController searchController = TextEditingController();

  // Tambahkan variabel boolean untuk menentukan apakah notifikasi Home harus ditampilkan atau tidak
  bool showHomeNotification = true;

  @override
  void initState() {
    super.initState();
    fetchTodo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Todo List',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: navigateToAddPage,
              label: const Text('Add Todo'),
            )
          : null,
      body: Column(
        children: [
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  filterTodoList(value);
                },
                decoration: const InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          Visibility(
            visible: isLoading,
            child: const Center(child: CircularProgressIndicator()),
            replacement: RefreshIndicator(
              onRefresh: fetchTodo,
              child: _currentIndex == 0
                  ? TodoListWidget(
                      items: filteredItems,
                      onDelete: deleteById,
                      onEdit: navigateToEditPage)
                  : Container(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              // Tampilkan notifikasi hanya jika showHomeNotification bernilai true
              if (showHomeNotification) {
                HomeInfoDialog.show(context);
              }
              break;
            case 1:
              SettingsInfoDialog.show(context);
              break;
            case 2:
              ProfileInfoDialog.show(context);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
            backgroundColor: Colors.red,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Colors.teal,
          ),
        ],
      ),
    );
  }

  void filterTodoList(String query) {
    setState(() {
      filteredItems = items
          .where((item) =>
              item['title']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              item['description']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  void navigateToEditPage(Map item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTodoPage(todo: item),
      ),
    );

    if (result != null && result is bool && result) {
      fetchTodo();
      showSuccessMessage(context, 'Todo edited successfully');
    }
  }

  Future<void> navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTodoPage(todo: {}),
      ),
    );

    if (result != null && result is bool && result) {
      fetchTodo();
      showSuccessMessage(context, 'Todo added successfully');
    }
  }

  Future<void> deleteById(String id) async {
    final url = 'https://api.nstack.in/v1/todos/$id';
    final uri = Uri.parse(url);
    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      final filtered = items.where((element) => element['_id'] != id).toList();
      setState(() {
        items = filtered;
        filteredItems = filtered;
      });
      showSuccessMessage(context, 'Todo deleted successfully');
    } else {
      showErrorMessage(context, 'Deletion Failed');
    }
  }

  Future<void> fetchTodo() async {
    final url = 'https://api.nstack.in/v1/todos?page=1&limit=10';
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['items'] as List;
      setState(() {
        items = result;
        filteredItems = result;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void showErrorMessage(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showSuccessMessage(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class TodoListWidget extends StatelessWidget {
  final List items;
  final Function(Map) onEdit;
  final Function(String) onDelete;

  const TodoListWidget(
      {Key? key,
      required this.items,
      required this.onEdit,
      required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map;
        final id = item['_id'] as String;
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(item['title']),
          subtitle: Text(item['description']),
          trailing: PopupMenuButton(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit(item);
              } else if (value == 'delete') {
                onDelete(id);
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Text('Edit'),
                  value: 'edit',
                ),
                PopupMenuItem(
                  child: Text('Delete'),
                  value: 'delete',
                ),
              ];
            },
          ),
        );
      },
    );
  }
}

class HomeInfoDialog {
  static void show(BuildContext context) {
    // Tambahkan logika untuk menampilkan notifikasi hanya jika di halaman Home
    if (Navigator.of(context).canPop()) {
      // Halaman Home
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Home Information'),
            content: Text('This is the Home information.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}

class SettingsInfoDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings Information'),
          content: SettingsInfoDialogContent(),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Widget SettingsInfoDialogContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('Language'),
          subtitle: Text('English'),
          onTap: () {
            // TODO: Implement logic for changing language
            // You can show a dialog or navigate to a language setting page
          },
        ),
        ListTile(
          title: Text('Notification'),
          subtitle: Text('On'),
          onTap: () {
            // TODO: Implement logic for changing notification settings
            // You can show a dialog or navigate to a notification setting page
          },
        ),
        ListTile(
          title: Text('Theme'),
          subtitle: Text('Light'),
          onTap: () {
            // TODO: Implement logic for changing theme
            // You can show a dialog or navigate to a theme setting page
          },
        ),
      ],
    );
  }
}

class ProfileInfoDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Profile Information'),
          content: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  'data:image/jpeg;base64,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',
                ),
              ),
              SizedBox(height: 16),
              Text('Name : Elgiana Liva'),
              Text('Npm  : 21552011326'),
              Text('Kelas: TIF RP 221PB'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
