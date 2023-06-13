import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo.is',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MyHomePage(title: 'Todo.is Login Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  DateTime currentBackPressTime = DateTime.now();
  Future<UserCredential?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      if (googleAuth != null) {
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        final GoogleSignInAccount? currentUser =
            await _googleSignIn.signInSilently();
        final GoogleSignInAuthentication? currentUserAuth =
            await currentUser?.authentication;

        if (currentUserAuth != null) {
          print(currentUserAuth.idToken);

          final GoogleSignInAuthentication? idToken =
              await currentUser?.authentication;
          print('idToken');
          print(idToken?.accessToken);

          controller.loadRequest(Uri.parse(
              'https://todo.is/mobilegooglelogin?token=${idToken?.accessToken}'));

          //_navigateToWebView();
          // Credentials sent successfully
          print('Google credentials sent to the Laravel app');
          //_navigateToWebView();
        } else {
          // Error sending credentials
          _showErrorSnackBar('Google Sign-In Error');
        }

        return userCredential;
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      _showErrorSnackBar('Google Sign-In Error: $e');
    }

    return null;
  }

  Future<UserCredential?> _signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AuthCredential credential =
            FacebookAuthProvider.credential(result.accessToken!.token);

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        // Send Facebook credentials to Laravel app
        controller.loadRequest(Uri.parse(
            'https://todo.is/mobilefacebooklogin?token=' +
                result.accessToken!.token));

        _navigateToWebView();

        return userCredential;
      } else if (result.status == LoginStatus.cancelled) {
        _showErrorSnackBar('Facebook Sign-In Cancelled');
        _navigateToWebView();
      } else if (result.status == LoginStatus.failed) {
        _showErrorSnackBar('Facebook Sign-In Failed: ${result.message}');
      }
    } catch (e) {
      print('Facebook Sign-In Error: $e');
      _showErrorSnackBar('Facebook Sign-In Error: $e');
    }

    return null;
  }

  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.yofffddutube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(Uri.parse('https://todo.is/login'));
  Future<List<String>> _androidFilePicker(
      final FileSelectorParams params) async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      return [file.uri.toString()];
    }
    return [];
  }

  void addFileSelectionListener() async {
    if (Platform.isAndroid) {
      final androidController = controller.platform as AndroidWebViewController;
      await androidController.setOnShowFileSelector(_androidFilePicker);
    }
  }

  void _navigateToWebView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewWidget(controller: controller),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller
        .loadRequest(Uri.parse('https://todo.is/login'))
        .whenComplete(() => {
              Timer(Duration(seconds: 2), () {
                controller.runJavaScript(
                  'jQuery("#google-login-btn").clone().insertAfter("#google-login-btn");jQuery("#google-login-btn").remove();jQuery("#facebook-login-btn").remove();jQuery("#google-login-btn").click(function(e){e.preventDefault();e.stopPropagation();Toaster.postMessage("User Agent: " + navigator.userAgent);});',
                );
              })
            });
    addFileSelectionListener();
    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {
          if (url.startsWith('https://todo.is/login')) {
            Timer(Duration(seconds: 2), () {
              controller.runJavaScript(
                'jQuery("#google-login-btn").clone().insertAfter("#google-login-btn");jQuery("#google-login-btn").remove();jQuery("#facebook-login-btn").remove();jQuery("#google-login-btn").click(function(e){e.preventDefault();e.stopPropagation();Toaster.postMessage("User Agent: " + navigator.userAgent);});',
              );
            });
            //return NavigationDecision.prevent;
          }
        },
        onPageFinished: (String url) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          print(request.url);
          if (request.url.startsWith('https://todo.is/login')) {
            Timer(Duration(seconds: 2), () {
              controller.runJavaScript(
                'jQuery("#google-login-btn").clone().insertAfter("#google-login-btn");jQuery("#google-login-btn").remove();jQuery("#facebook-login-btn").remove();jQuery("#google-login-btn").click(function(e){e.preventDefault();e.stopPropagation();Toaster.postMessage("User Agent: " + navigator.userAgent);});',
              );
            });
            //return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
    controller.addJavaScriptChannel(
      'Toaster',
      onMessageReceived: (JavaScriptMessage message) {
        print(message.message);
        _signInWithGoogle();
      },
    );

    return WillPopScope(
        onWillPop: () => _exitApp(context),
        child: Scaffold(
            // appBar: AppBar(
            //   title: Text(widget.title),
            // ),
            body: Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: WebViewWidget(controller: controller),
        )));
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text(widget.title),
    //   ),
    //   body: Padding(
    //     padding: EdgeInsets.all(16.0),
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: <Widget>[
    //         TextField(
    //           controller: _emailController,
    //           decoration: InputDecoration(
    //             labelText: 'Email',
    //           ),
    //         ),
    //         SizedBox(height: 16.0),
    //         TextField(
    //           controller: _passwordController,
    //           decoration: InputDecoration(
    //             labelText: 'Password',
    //           ),
    //           obscureText: true,
    //         ),
    //         SizedBox(height: 16.0),
    //         ElevatedButton(
    //           onPressed: () {
    //             // Handle login with email and password
    //             String email = _emailController.text;
    //             String password = _passwordController.text;
    //             // Perform the login logic here

    //             _loginToLaravelApp(email, password);
    //           },
    //           child: Text('Login'),
    //         ),
    //         SizedBox(height: 16.0),
    //         const Text(
    //           'Or sign in with:',
    //         ),
    //         SizedBox(height: 16.0),
    //         Column(
    //           children: [
    //             ElevatedButton.icon(
    //               onPressed: _signInWithGoogle,
    //               style: ElevatedButton.styleFrom(
    //                 primary: Colors.red, // Customize the button color
    //                 onPrimary: Colors.white, // Customize the text color
    //                 minimumSize: Size(200, 48), // Set a fixed button size
    //               ),
    //               icon: Icon(Icons.g_translate),
    //               label: const Text('Google Sign-In'),
    //             ),
    //             SizedBox(height: 16.0),
    //             ElevatedButton.icon(
    //               onPressed: _signInWithFacebook,
    //               style: ElevatedButton.styleFrom(
    //                 primary: Colors.blue, // Customize the button color
    //                 onPrimary: Colors.white, // Customize the text color
    //                 minimumSize: Size(200, 48), // Set a fixed button size
    //               ),
    //               icon: Icon(Icons.facebook),
    //               label: const Text('Facebook Sign-In'),
    //             ),
    //           ],
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }

  Future<bool> _exitApp(BuildContext context) async {
    if (await controller.canGoBack()) {
      print("onwill goback");
      print(await controller.canGoBack());

      controller.goBack();
      return Future.value(false);
    } else {
      DateTime now = DateTime.now();
      print("currentBackPressTime");
      print(currentBackPressTime);
      if (currentBackPressTime == null ||
          now.difference(currentBackPressTime) > Duration(seconds: 2)) {
        currentBackPressTime = now;
        Fluttertoast.showToast(msg: 'press back button again to exit');
        return Future.value(false);
      } else {
        print('else');
        return Future.value(true);
      }
    }
  }

  Future<void> _loginToLaravelApp(String email, String password) async {
    controller.loadRequest(Uri.parse('https://todo.is/login'));
    // controller.runJavaScript('jQuery(document).ready(function(){alert()})');

    _navigateToWebView();
    // final url = Uri.parse('https://todo.is/mobileapplogin');

    // final response = await http.post(
    //   url,
    //   body: {
    //     'email': email,
    //     'password': password,
    //   },
    // );

    // if (response.statusCode == 200) {
    //   // Successful login
    //   print('Login successful');
    //   _navigateToWebView();
    // } else {
    //   // Failed to login
    //   _showErrorSnackBar('Login failed: ${response.body}');
    // }
  }
}
