import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirestore() async {
  await FirebaseFirestore.instance.collection('test').add({
    'msg': 'hello from app',
    'time': DateTime.now().toString(),
  });
}
