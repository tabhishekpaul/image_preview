// Importing necessary packages for web support, state management, and UI components.
import 'dart:ui_web'; // Required for web-specific UI handling.
import 'dart:html'
    as html; // Provides access to the HTML DOM to manipulate images and fullscreen modes.
import 'package:get/get.dart'; // State management package that makes reactivity simple and efficient.
import 'dart:js_util'
    as js_util; // Enables interaction with JavaScript from Dart, needed for fullscreen functionalities.
import 'package:flutter/material.dart'; // Core Flutter package for building the UI and managing layout.
import 'package:flutter_web_plugins/flutter_web_plugins.dart'; // Used to register custom web views in Flutter Web.

/// Global variable to store the HTML image element.
/// This is used in the custom view factory to display an image on the webpage.
html.ImageElement? globalImageElement;

void main() {
  // Ensures that the Flutter bindings are initialized, which is essential for Flutter web apps.
  WidgetsFlutterBinding.ensureInitialized();

  // Registers a custom view factory with the platform view registry.
  // This creates an HTML image element to be displayed on the web.
  platformViewRegistry.registerViewFactory('imageElement', (int viewId) {
    return globalImageElement ?? html.ImageElement()
      ..style.objectFit =
          'contain' // Ensures the image fits within the available space.
      ..src = 'assets/placeholder.png'; // Default placeholder image source.
  });

  // Set the URL strategy for routing, using path-based URLs in Flutter web.
  setUrlStrategy(PathUrlStrategy());

  // Runs the application, launching the main widget.
  runApp(const Main());
}

/// Main widget that initializes the entire application.
class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    // The `GetMaterialApp` is the entry point for the application that sets up routing and theming.
    return GetMaterialApp(
      title: 'Image Display & Fullscreen', // Sets the title of the application.
      theme:
          ThemeData(primarySwatch: Colors.blue), // Sets the theme of the app.
      home: HomePage(), // Home page widget is displayed when the app launches.
    );
  }
}

/// Controller class to manage the state of the image and fullscreen toggle.
class ImageController extends GetxController {
  // Observable state variables that trigger UI updates when changed.
  var imageUrl = 'assets/placeholder.png'.obs;
  var isMenuOpen = false.obs;
  var isDimmed = false.obs;
  var isFullScreen = false.obs;

  @override
  void onInit() {
    super.onInit();
    _createImageElement(); // Initializes the image element when the controller is first created.
  }

  /// Creates the image element and attaches event listeners for interaction.
  void _createImageElement() {
    globalImageElement = html.ImageElement()
      ..style.objectFit =
          'contain' // Ensures the image adjusts to the container's size.
      ..style.transition = 'opacity 0.5s' // Smooth opacity transition effect.
      ..onDoubleClick.listen(
          (event) => toggleFullScreen()); // Toggles fullscreen on double-click.
    globalImageElement!.src = imageUrl.value; // Sets the initial image source.
  }

  /// Updates the image URL and updates the source of the image element.
  void updateImageUrl(String url) {
    imageUrl.value = url;
    globalImageElement?.src = url;
  }

  /// Toggles the menu state (open or closed).
  void toggleMenu() {
    isMenuOpen.value = !isMenuOpen.value;
    isDimmed.value = isMenuOpen.value; // Dims the screen when the menu is open.
  }

  /// Closes the menu and resets the dim state.
  void closeMenu() {
    isMenuOpen.value = false;
    isDimmed.value = false;
  }

  /// Toggles fullscreen mode based on the current state (enter or exit).
  void toggleFullScreen() {
    if (html.document.fullscreenElement == null) {
      enterFullScreen();
    } else {
      exitFullScreen();
    }
  }

  /// Enters fullscreen mode by requesting the document element to go fullscreen.
  void enterFullScreen() {
    final html.Element elem = html.document.documentElement!;
    if (html.document.fullscreenElement == null) {
      if (js_util.hasProperty(elem, 'requestFullscreen')) {
        js_util.callMethod(elem, 'requestFullscreen', []);
      } else if (js_util.hasProperty(elem, 'webkitRequestFullscreen')) {
        js_util.callMethod(elem, 'webkitRequestFullscreen', []);
      } else if (js_util.hasProperty(elem, 'msRequestFullscreen')) {
        js_util.callMethod(elem, 'msRequestFullscreen', []);
      }
    }
    closeMenu(); // Close the menu once fullscreen is entered.
  }

  /// Exits fullscreen mode if the document is currently in fullscreen.
  void exitFullScreen() {
    if (html.document.fullscreenElement != null) {
      if (js_util.hasProperty(html.document, 'exitFullscreen')) {
        js_util.callMethod(html.document, 'exitFullscreen', []);
      } else if (js_util.hasProperty(html.document, 'webkitExitFullscreen')) {
        js_util.callMethod(html.document, 'webkitExitFullscreen', []);
      } else if (js_util.hasProperty(html.document, 'msExitFullscreen')) {
        js_util.callMethod(html.document, 'msExitFullscreen', []);
      }
    }
    closeMenu(); // Close the menu once fullscreen is exited.
  }
}

/// HomePage widget, the main UI screen that allows the user to interact with the app.
class HomePage extends StatelessWidget {
  HomePage({super.key});
  final ImageController controller = Get.put(
      ImageController()); // The controller for managing image-related actions.
  final TextEditingController _urlController =
      TextEditingController(); // Controller for the URL input field.

  /// Updates the image source when the user enters a valid URL.
  void _showImage() {
    if (_urlController.text.isNotEmpty) {
      controller.updateImageUrl(_urlController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size =
        MediaQuery.sizeOf(context); // Retrieves the screen size for layout.

    return Scaffold(
      // Floating action button to toggle the menu.
      floatingActionButton: FloatingActionButton(
        onPressed: controller.toggleMenu, // Toggles the menu on press.
        child: Obx(
          () => AnimatedRotation(
            turns: controller.isMenuOpen.value
                ? 0.125
                : 0, // Animates rotation when menu opens.
            duration: Duration(milliseconds: 300),
            child: Icon(Icons.add),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Displays the HTML element for the image.
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                height: size.height * 0.5,
                width: size.width,
                child: Center(
                  child: HtmlElementView(viewType: 'imageElement'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText:
                        'Enter Image URL', // Prompts the user for an image URL.
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed:
                    _showImage, // Updates the image source when the button is pressed.
                child: Text('Show Image'),
              ),
            ],
          ),
          // Menu overlay that dims the background when open.
          Obx(() => controller.isDimmed.value
              ? GestureDetector(
                  onTap: controller.closeMenu,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: controller.isDimmed.value ? 0.5 : 0.0,
                    child: Container(color: Colors.black),
                  ),
                )
              : SizedBox.shrink()),
          Positioned(
            bottom: 20,
            right: 20,
            child: Obx(
              () => SizedBox(
                height: size.height,
                width: size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Displays the menu with fullscreen options.
                    if (controller.isMenuOpen.value)
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: controller.enterFullScreen,
                                child: MenuOption(
                                  "Enter full screen",
                                  Icons.fullscreen_outlined,
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Divider(),
                              ),
                              InkWell(
                                onTap: controller.exitFullScreen,
                                child: MenuOption(
                                  "Exit full screen",
                                  Icons.fullscreen_exit_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A custom widget to display a menu option with an icon and text.
class MenuOption extends StatelessWidget {
  const MenuOption(this.name, this.icon, {super.key});
  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: EdgeInsets.only(right: 5),
              child: Icon(icon),
            ),
          ),
          TextSpan(text: name),
        ],
      ),
    );
  }
}
