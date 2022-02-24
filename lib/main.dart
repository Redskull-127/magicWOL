import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:magic/list.dart';
import 'package:magic/model.dart';
import 'package:magic/testing.dart';
import 'package:wake_on_lan/wake_on_lan.dart';
import 'dbhelper.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    importance: Importance.high,
    playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A bg message just showed up :  ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  var auth = FirebaseMessaging.instance.getToken();
  print(auth);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ));
      }
      if (notification!.title == "Message") {
        print("Message Printed");
        flutterLocalNotificationsPlugin.show(
            0,
            'New Update!!!',
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            payload: 'Update(Simple)');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text('${notification.title}'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text('${notification.body}')],
                  ),
                ),
              );
            });
      }
    });
  }

  void wol() async {
    String ip = '192.168.1.255';
    String mac = 'AA:BB:CC:DD:EE:FF';
    if (!IPv4Address.validate(ip)) return;
    if (!MACAddress.validate(mac)) return;

    // Create the IPv4 and MAC objects
    IPv4Address ipv4Address = IPv4Address.from(ip);
    MACAddress macAddress = MACAddress.from(mac);
    WakeOnLAN.from(ipv4Address, macAddress, port: 55).wake();
  }

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
              contentTextStyle:
                  const TextStyle(color: Colors.amber, fontSize: 20),
              backgroundColor: Colors.grey,
              content: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    TextField(
                      controller: myip,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter IP',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50, bottom: 10),
                      child: TextField(
                        controller: mymac,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter MAC (00:00:00:00:00:00)',
                        ),
                      ),
                    ),
                    Form(
                        key: _formKey,
                        child: TextButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await DatabaseHandler()
                                    .inserttodo(todo(
                                        title: myip.text,
                                        description: mymac.text,
                                        id: Random().nextInt(50)))
                                    .whenComplete(() => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const MyApp()),
                                        ));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: const Text('Processing Data')),
                                );
                              }
                            },
                            child: const Text(
                              "Next",
                              style: TextStyle(color: Colors.amber),
                            )))
                  ])));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        actions: [
          FloatingActionButton(
            tooltip: "Add a device!",
            hoverColor: Colors.grey,
            backgroundColor: Colors.transparent,
            onPressed: add,
            child: const Icon(
              Icons.add,
              color: Colors.amber,
              size: 35,
            ),
          )
        ],
        title: const Text(
          "Magic Wake",
          style: TextStyle(
              color: Color.fromARGB(255, 224, 212, 212),
              fontFamily: "lato",
              fontSize: 26),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                height: 600,
                width: 100,
                child: FloatingActionButton(
                  heroTag: "new",
                  backgroundColor: Colors.transparent,
                  hoverColor: Colors.grey,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ListScreen()),
                    );
                  },
                  child: const Icon(
                    Icons.settings_power,
                    color: Colors.amber,
                    size: 100,
                  ),
                )),
            Padding(
                padding: EdgeInsets.only(bottom: 0),
                child: Container(
                  height: 60,
                  width: 150,
                  child: Column(children: const [
                    Text("DESIGNED BY\n",
                        style: TextStyle(color: Colors.grey, letterSpacing: 4)),
                    Text(
                      "MEER TARBANI",
                      style: TextStyle(
                          color: Colors.grey,
                          letterSpacing: 1,
                          fontFamily: "Lato"),
                    ),
                  ]),
                ))
          ],
        ),
      ),
    );
  }
}
