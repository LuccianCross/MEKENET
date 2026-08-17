// Import the Flutter Material Design library
// This gives us access to Material Design widgets (Scaffold, AppBar, etc.)
import 'package:flutter/material.dart';

// The entry point of the application
// This function is called when the app starts
void main() {
  // Run the app by calling runApp() with our root widget (MyApp)
  runApp(const MyApp());
}

// MyApp is a StatelessWidget - it doesn't change state
// It's the root widget that builds the entire application
class MyApp extends StatelessWidget {
  // Constructor with a super key parameter
  // The 'const' keyword allows for compile-time optimization
  const MyApp({super.key});

  // The build method is required for all widgets
  // It describes what the UI should look like
  @override
  Widget build(BuildContext context) {
    // MaterialApp is the root widget for Material Design apps
    // It provides navigation, theming, and other core features
    return MaterialApp(
      // The title appears in the task manager / window title
      title: 'Flutter Demo',
      
      // ThemeData defines the visual theme of the app
      theme: ThemeData(
        // colorScheme creates a color palette from a seed color
        // This enables dynamic color theming (Material 3 feature)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        
        // useMaterial3 enables the latest Material Design 3 features
        useMaterial3: true,
      ),
      
      // home is the default route / first screen shown
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

// MyHomePage is a StatefulWidget - it can change state
// Stateful widgets are used when the UI needs to update dynamically
class MyHomePage extends StatefulWidget {
  // Required parameter 'title' passed from the parent
  const MyHomePage({super.key, required this.title});

  // Final means this value cannot change after initialization
  final String title;

  // createState() is called when Flutter needs to create the State object
  // This is where we link the widget to its state
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// The State class holds the mutable state for MyHomePage
// The underscore (_) makes it private to this file
class _MyHomePageState extends State<MyHomePage> {
  // _counter is a private variable that holds the count
  // It starts at 0
  int _counter = 0;

  // _incrementCounter is a method that increases _counter
  // It uses setState() to tell Flutter that the UI needs to rebuild
  void _incrementCounter() {
    // setState() schedules a rebuild of the widget
    // All changes to state variables must happen inside setState()
    setState(() {
      // Increment the counter by 1
      _counter++;
    });
  }

  // The build method is called:
  // 1. When the widget is first created
  // 2. When setState() is called (state changes)
  // 3. When parent widget rebuilds
  @override
  Widget build(BuildContext context) {
    // Scaffold is a Material Design layout structure
    // It provides app bars, body, floating action buttons, drawers, etc.
    return Scaffold(
      // AppBar is the top navigation bar
      appBar: AppBar(
        // backgroundColor uses the inverse primary color from the theme
        // This creates a nice contrast effect
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        
        // title displays the text passed from the parent widget
        // widget.title accesses the title from MyHomePage
        title: Text(widget.title),
      ),
      
      // body is the main content of the screen
      body: Center(
        // Center widget centers its child both horizontally and vertically
        child: Column(
          // Column arranges children vertically (top to bottom)
          // mainAxisAlignment controls how children are arranged along the main axis (vertical)
          mainAxisAlignment: MainAxisAlignment.center,
          
          // children is a list of widgets to display vertically
          children: <Widget>[
            // First child: A text label
            const Text(
              'You have pushed the button this many times:',
            ),
            
            // Second child: The counter value displayed as a string
            Text(
              '$_counter', // Convert integer to string using string interpolation
              style: Theme.of(context).textTheme.headlineMedium, // Large bold text style
            ),
          ],
        ),
      ),
      
      // floatingActionButton is a circular button that floats above the content
      floatingActionButton: FloatingActionButton(
        // onPressed is a callback function when the button is tapped
        onPressed: _incrementCounter, // Call our increment method
        
        // tooltip appears when the user long-presses the button (accessibility)
        tooltip: 'Increment',
        
        // child is the icon displayed inside the button
        child: const Icon(Icons.add), // Plus icon from Material Icons
      ),
    );
  }
}