import 'package:botovod/SourceManager.dart';

const String dropbox_clientId = 'test-flutter-dropbox';
const String dropbox_key = 'in8lujceyv87egp';
const String dropbox_secret = '4bybsy7fw3ah7q3';

class AuthManager {
  AuthManager._();

  // Static instance variable
  static AuthManager? _instance;

  String credentials = "";

  static AuthManager get instance {
    _instance ??= AuthManager._();
    return _instance!;
  }

  Future<bool> shouldAuth(ImageSource source) async {
    if (!authRequiredForSource(source)) {
      return false;
    }

    return await isAuthorized(source);
  }

  static authRequiredForSource(ImageSource source) {
    switch (source) {
      case ImageSource.device:
        return false;
      case ImageSource.dropbox:
        return true;
    }
  }

  void loadItems() async {

  }

  Future<String> getUsername() async {
    return "botovod";
  }

  Future<bool> tryAuth(ImageSource source) async {
    if (await isLoggedIn()) {
      await loginWithCredentials();
      return true;
    }

    await tryLogin();

    if (await isLoggedIn()) {
      return true;
    }

    return false;
  }

  Future<bool> isAuthorized(ImageSource source) async {
    switch (source) {
      case ImageSource.dropbox:
        return await isLoggedIn();
      default:
        return true;
    }
  }

  Future initDropbox() async {
  }

  Future tryLogin() async {
  }

  Future loginWithCredentials() async {

  }

  Future logout() async {
  }



  Future getCredentials() async {
    credentials = "botovod";
  }

  Future isLoggedIn() async {
    await getCredentials();

    return credentials != "";
  }


}