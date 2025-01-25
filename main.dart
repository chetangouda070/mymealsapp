import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class Fav extends StatelessWidget {
  final List favorites;
  final Function removeFromFavorites;

  const Fav(
      {Key? key, required this.favorites, required this.removeFromFavorites})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
      ),
      body: favorites.isEmpty
          ? const Center(
              child: Text(
                "No favorites added yet.",
                style: TextStyle(fontSize: 10),
              ),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final meal = favorites[index];
                return ListTile(
                  leading: Image.network(meal['strMealThumb']),
                  title: Text(meal['strMeal']),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      removeFromFavorites(meal);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authProvider.loginUser(
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Home(),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List meals = [];
  List favorites = [];

  Future<void> fetchMeals() async {
    final url =
        Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?f=c');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        meals = data['meals'];
      });
    } else {
      throw Exception('Failed to load meals');
    }
  }

  void toggleFavorite(Map meal) {
    setState(() {
      if (favorites.any((fav) => fav['idMeal'] == meal['idMeal'])) {
        // Remove from favorites
        favorites.removeWhere((fav) => fav['idMeal'] == meal['idMeal']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${meal['strMeal']} removed from favorites!'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Add to favorites
        favorites.add(meal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${meal['strMeal']} added to favorites!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food App'),
        backgroundColor: Colors.blue,
        elevation: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(meals: meals),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Fav(
                    favorites: favorites,
                    removeFromFavorites: toggleFavorite,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 10,
          ),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];
            final isFavorited =
                favorites.any((fav) => fav['idMeal'] == meal['idMeal']);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      meal['strMealThumb'],
                      height: double.infinity,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['strMeal'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isFavorited ? Colors.red : Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => toggleFavorite(meal),
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.white,
                          ),
                          label: Text(
                            isFavorited
                                ? "Remove from Favorites"
                                : "Add to Favorites",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final List meals;

  CustomSearchDelegate({required this.meals});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredMeals = meals
        .where((meal) => meal['strMeal']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filteredMeals.length,
      itemBuilder: (context, index) {
        final meal = filteredMeals[index];
        return ListTile(
          title: Text(meal['strMeal']),
          leading: Image.network(meal['strMealThumb']),
          onTap: () {
            close(context, meal);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredMeals = meals
        .where((meal) => meal['strMeal']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filteredMeals.length,
      itemBuilder: (context, index) {
        final meal = filteredMeals[index];
        return ListTile(
          title: Text(meal['strMeal']),
          leading: Image.network(meal['strMealThumb']),
          onTap: () {
            query = meal['strMeal'];
            showResults(context);
          },
        );
      },
    );
  }
}

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _userName;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthProvider() {
    _initializeUser();
  }

  User? get user => _user;
  String? get userName => _userName;

  Future<void> _initializeUser() async {
    _user = _auth.currentUser;
    // if (_user != null) {
    //   await _fetchUserName();
    // }
    notifyListeners();
  }

  // Future<void> _fetchUserName() async {
  //   if (_user != null) {bbbbbb
  //     final doc = await _firestore.collection('users').doc(_user!.uid).get();
  //     _userName = doc.data()?['name'];
  //   }
  // }

  Future<void> registerUser(String email, String password, String name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

      // Save the user's name in Firestore
      await _firestore.collection('users').doc(_user!.uid).set({'name': name});

      // Fetch the username after registration
      _userName = name;
      notifyListeners();
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;

      // Fetch the username after login
      // await _fetchUserName();
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
    _user = null;
    _userName = null;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a FutureBuilder to ensure Firebase is initialized
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while waiting for Firebase to initialize
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // If the user is logged in, show the Home screen
            return Home();
          } else {
            // If the user is not logged in, show the Signup screen
            return SignupScreen();
          }
        });
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Sign up the user
                  await authProvider.registerUser(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                      _nameController.text.trim());

                  // Save the user's name in Firestore
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await _firestore
                        .collection('users')
                        .doc(user.uid)
                        .set({'name': _nameController.text.trim()});
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Home(),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  final List cart;

  const CartScreen({Key? key, required this.cart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final meal = cart[index];
                return ListTile(
                  leading: Image.network(meal['strMealThumb']),
                  title: Text(meal['strMeal']),
                );
              },
            ),
    );
  }
}
