import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point') // required for background isolate
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Init Firebase in the background isolate if needed
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  // TODO: handle background message (analytics, prefetch, etc.)
  // print('BG message: ${message.messageId} data=${message.data}');
}
