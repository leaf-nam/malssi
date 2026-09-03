import 'package:firebase/firebase.dart';

class FirestoreRefs {
  // Auth collection
  final Collection auth = collection('auth');

  // Quotes collection
  final Collection quotes = collection('quotes');

  // Comments collection
  final Collection comments = collection('comments');

  // Categories collection
  final Collection categories = collection('categories');

  // Submissions collection
  final Collection submissions = collection('submissions');

  // Users collection
  final Collection users = collection('users');
}