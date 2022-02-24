import 'dart:math';

import 'package:flutter/material.dart';
import 'dbhelper.dart';
import 'model.dart';
import 'package:wake_on_lan/wake_on_lan.dart';

void ListApp() {
  runApp(const ListScreen());
}

class ListScreen extends StatefulWidget {
  const ListScreen({Key? key}) : super(key: key);

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  DatabaseHandler? handler;
  Future<List<todo>>? _todo;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    handler!.initializeDB().whenComplete(() async {
      setState(() {
        scaff();
        _todo = getList();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void scaff() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Swipe to Delete Entry!')),
    );
  }

  Future<List<todo>> getList() async {
    return await handler!.todos();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _todo = getList();
    });
  }

  void tes() {
    print("testDone");
  }

  void moreop() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: const Text("Select"),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                    onPressed: () {},
                    child: const Text(
                      "Select",
                      style: TextStyle(color: Colors.amber),
                    )),
                ElevatedButton(
                    onPressed: () {},
                    child: const Text("Delete",
                        style: const TextStyle(color: Colors.amber)))
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: const Text('Select'),
        actions: [
          IconButton(
              onPressed: () {
                void add() {
                  final myip = TextEditingController();
                  final mymac = TextEditingController();
                  print("working");
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                            actionsAlignment: MainAxisAlignment.center,
                            alignment: Alignment.center,
                            contentTextStyle: const TextStyle(
                                color: Colors.amber, fontSize: 20),
                            backgroundColor: Colors.grey,
                            content: Center(
                                child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                  TextField(
                                    controller: myip,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Enter IP',
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 50, bottom: 10),
                                    child: TextField(
                                      controller: mymac,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText:
                                            'Enter MAC (00:00:00:00:00:00)',
                                      ),
                                    ),
                                  ),
                                  Form(
                                      key: _formKey,
                                      child: TextButton(
                                          onPressed: () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              await DatabaseHandler()
                                                  .inserttodo(todo(
                                                      title: myip.text,
                                                      description: mymac.text,
                                                      id: Random().nextInt(50)))
                                                  .whenComplete(() =>
                                                      Navigator.pop(context));
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Processing Data')),
                                              );
                                            }
                                          },
                                          child: const Text(
                                            "Next",
                                            style:
                                                TextStyle(color: Colors.amber),
                                          )))
                                ])));
                      });
                }

                add();
              },
              icon: const Icon(
                Icons.add,
                size: 25,
              ))
        ],
      ),
      body: FutureBuilder<List<todo>>(
        future: _todo,
        builder: (BuildContext context, AsyncSnapshot<List<todo>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final items = snapshot.data ?? <todo>[];
            return Scrollbar(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Dismissible(
                        direction: DismissDirection.startToEnd,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: const Icon(Icons.delete_forever),
                        ),
                        key: ValueKey<int>(items[index].id),
                        onDismissed: (DismissDirection direction) async {
                          await handler!.deletetodo(items[index].id);
                          setState(() {
                            items.remove(items[index]);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: const Text('Deleted')),
                          );
                        },
                        child: InkWell(
                          onTap: () {
                            void wake() async {
                              String ip = items[index].title;
                              String mac = items[index].description.toString();
                              if (!IPv4Address.validate(ip)) {
                                print(items[index].title);
                                print("Ip invalid");
                                return;
                              }
                              if (!MACAddress.validate(mac)) {
                                print(items[index].description.toString());
                                print("Mac invalid");
                                return;
                              }

                              // Create the IPv4 and MAC objects
                              IPv4Address ipv4Address = IPv4Address.from(ip);
                              MACAddress macAddress = MACAddress.from(mac);

                              // Send the WOL packet
                              // Port parameter is optional, set to 55 here as an example, but defaults to port 9
                              WakeOnLAN.from(ipv4Address, macAddress, port: 55)
                                  .wake()
                                  .whenComplete(() =>
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '${items[index].title} Woken')),
                                      ));
                            }

                            wake();
                          },
                          child: Card(
                              color: Colors.grey,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8.0),
                                title: Text(
                                  items[index].title,
                                  style: const TextStyle(
                                      color: Colors.amber, fontSize: 26),
                                ),
                                subtitle: Text(
                                  items[index].description.toString(),
                                  style: const TextStyle(
                                      color: Colors.amber, fontSize: 18),
                                ),
                              )),
                        ));
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
