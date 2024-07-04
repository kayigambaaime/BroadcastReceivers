import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tab Drawer Navigation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  late Battery _battery;
  late StreamSubscription<BatteryState> _batteryStateSubscription;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load the saved theme mode
    _loadThemeMode();

    // Subscribe to connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        Fluttertoast.showToast(msg: "Internet Disconnected");
      } else {
        Fluttertoast.showToast(msg: "Internet Connected");
      }
    });

    // Monitor battery level
    _battery = Battery();
    _battery.batteryLevel.then((level) {
      if (level >= 90) {
        Fluttertoast.showToast(msg: "Battery is over 90% and charging");
      }
    });

    // Monitor battery state changes
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen((BatteryState state) async {
      if (state == BatteryState.charging) {
        int level = await _battery.batteryLevel;
        if (level >= 90) {
          Fluttertoast.showToast(msg: "Battery is over 90% and charging");
        }
      }
    });
  }

  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      if (isDarkMode) {
        WidgetsBinding.instance.window.platformDispatcher.platformBrightness =
            Brightness.dark;
      } else {
        WidgetsBinding.instance.window.platformDispatcher.platformBrightness =
            Brightness.light;
      }
    });
  }

  void _toggleThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('isDarkMode', isDarkMode);
      if (isDarkMode) {
        WidgetsBinding.instance.window.platformDispatcher.platformBrightness =
            Brightness.dark;
      } else {
        WidgetsBinding.instance.window.platformDispatcher.platformBrightness =
            Brightness.light;
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _batteryStateSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tab Navigation Example'),
        actions: [
          Switch(
            value: isDarkMode,
            onChanged: (value) {
              _toggleThemeMode();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Navigation Drawer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.login),
              title: Text('Sign In'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Sign Up'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.calculate),
              title: Text('Calculator'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2);
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SignInScreen(),
          SignUpScreen(),
          CalculatorScreen(),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.blue,
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.login),
              text: 'Sign In',
            ),
            Tab(
              icon: Icon(Icons.person_add),
              text: 'Sign Up',
            ),
            Tab(
              icon: Icon(Icons.calculate),
              text: 'Calculator',
            ),
          ],
        ),
      ),
    );
  }
}

class SignInScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign In Screen',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential =
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignedInScreen()),
                  );
                } on FirebaseAuthException catch (e) {
                  Fluttertoast.showToast(msg: e.message!);
                }
              },
              child: Text('Sign In'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential = await signInWithGoogle();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignedInScreen()),
                  );
                } on FirebaseAuthException catch (e) {
                  Fluttertoast.showToast(msg: e.message!);
                }
              },
              child: Text('Sign In with Google'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential = await signInWithFacebook();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignedInScreen()),
                  );
                } on FirebaseAuthException catch (e) {
                  Fluttertoast.showToast(msg: e.message!);
                }
              },
              child: Text('Sign In with Facebook'),
            ),
          ],
        ),
      ),
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();

    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(result.accessToken!.token);

    return await FirebaseAuth.instance
        .signInWithCredential(facebookAuthCredential);
  }
}

class SignedInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
      ),
      body: Center(
        child: Text(
          'Welcome! You are now signed in.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign Up Screen',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_passwordController.text ==
                    _confirmPasswordController.text) {
                  try {
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignedUpScreen()),
                    );
                  } on FirebaseAuthException catch (e) {
                    Fluttertoast.showToast(msg: e.message!);
                  }
                } else {
                  Fluttertoast.showToast(msg: "Passwords do not match");
                }
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignedUpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
      ),
      body: Center(
        child: Text(
          'Welcome! You are now signed up.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class CalculatorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Calculation();
  }
}

class Calculation extends StatefulWidget {
  @override
  _CalculationState createState() => _CalculationState();
}

class _CalculationState extends State<Calculation> {
  List<dynamic> inputList = [0];
  String output = '0';

  void _handleClear() {
    setState(() {
      inputList = [0];
      output = '0';
    });
  }

  void _handlePress(String input) {
    setState(() {
      if (_isOperator(input)) {
        if (inputList.last is int) {
          inputList.add(input);
          output += input;
        }
      } else if (input == '=') {
        while (inputList.length > 2) {
          int firstNumber = inputList.removeAt(0) as int;
          String operator = inputList.removeAt(0);
          int secondNumber = inputList.removeAt(0) as int;
          int partialResult = 0;

          if (operator == '+') {
            partialResult = firstNumber + secondNumber;
          } else if (operator == '-') {
            partialResult = firstNumber - secondNumber;
          } else if (operator == '*') {
            partialResult = firstNumber * secondNumber;
          } else if (operator == '/') {
            partialResult = firstNumber ~/ secondNumber;
            // Protect against division by zero
            if (secondNumber == 0) {
              partialResult = firstNumber;
            }
          }

          inputList.insert(0, partialResult);
        }

        output = '${inputList[0]}';
      } else {
        int? inputNumber = int.tryParse(input);
        if (inputNumber != null) {
          if (inputList.last is int &&
              !_isOperator(output[output.length - 1])) {
            int lastNumber = (inputList.last as int);
            lastNumber = lastNumber * 10 + inputNumber;
            inputList.last = lastNumber;

            output =
                output.substring(0, output.length - 1) + lastNumber.toString();
          } else {
            inputList.add(inputNumber);
            output += input;
          }
        }
      }
    });
  }

  bool _isOperator(String input) {
    return input == "+" || input == "-" || input == "*" || input == "/";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Calculator")),
      body: Column(
        children: <Widget>[
          TextField(
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              border: InputBorder.none,
            ),
            controller: TextEditingController()..text = output,
            readOnly: true,
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              children: <Widget>[
                for (var i = 0; i <= 9; i++)
                  TextButton(
                    child: Text("$i", style: TextStyle(fontSize: 25)),
                    onPressed: () => _handlePress("$i"),
                  ),
                TextButton(
                  child: Text("C", style: TextStyle(fontSize: 25)),
                  onPressed: _handleClear,
                ),
                TextButton(
                  child: Text("+", style: TextStyle(fontSize: 25)),
                  onPressed: () => _handlePress("+"),
                ),
                TextButton(
                  child: Text("-", style: TextStyle(fontSize: 25)),
                  onPressed: () => _handlePress("-"),
                ),
                TextButton(
                  child: Text("*", style: TextStyle(fontSize: 25)),
                  onPressed: () => _handlePress("*"),
                ),
                TextButton(
                  child: Text("/", style: TextStyle(fontSize: 25)),
                  onPressed: () => _handlePress("/"),
                ),
                TextButton(
                  child: Text("=", style: TextStyle(fontSize: 25)),
                  onPressed: () => _handlePress("="),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
