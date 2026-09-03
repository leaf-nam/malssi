import 'package:malssi/core/constants/collection_names.dart';

/// Firestore collection path holder.
///
/// Holds document-path helpers only (no Firebase SDK types) until the
/// Firestore backend is connected. Always use [CollectionNames] constants;
/// do not hard-code collection strings elsewhere.
class FirestoreRefs {
  const FirestoreRefs();

  static const String authPath = CollectionNames.auth;
  static const String quotesPath = CollectionNames.quotes;
  static const String commentsPath = CollectionNames.comments;
  static const String categoriesPath = CollectionNames.categories;
  static const String submissionsPath = CollectionNames.submissions;
  static const String usersPath = CollectionNames.users;

  static String docPath(String collectionPath, String docId) => '$collectionPath/$docId';
}
