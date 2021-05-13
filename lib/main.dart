import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:roboadda_beta/no_internet_connec.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

final _messangerKey = GlobalKey<ScaffoldMessengerState>();

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(MaterialApp(
    scaffoldMessengerKey: _messangerKey,
    home: AnimatedSplashScreen(
      splash: Image.asset(
        'images/logo.png',
      ),
      nextScreen: MyApp(),
      splashTransition: SplashTransition.scaleTransition,
      backgroundColor: Colors.white,
      duration: 3000,
      splashIconSize: 170,
      animationDuration: Duration(milliseconds: 1200),
    ),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

DateTime currentBackPressTime;

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();
  StreamSubscription _subscription;

  InAppWebViewController webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  Future<bool> _exitApp(BuildContext context) async {
    if (await webViewController.canGoBack()) {
      webViewController.goBack();
    } else {
      DateTime now = DateTime.now();
      if (currentBackPressTime == null ||
          now.difference(currentBackPressTime) > Duration(seconds: 2)) {
        currentBackPressTime = now;
        _messangerKey.currentState
            .showSnackBar(SnackBar(content: Text('Tap back again to leave')));

        return Future.value(false);
      }
      SystemNavigator.pop();
      return Future.value(true);
    }
    return Future.value(false);
  }

  @override
  void initState() {
    super.initState();
    checkConnection();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.red,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  bool _noInternet = false;

  void checkConnection() async {
    _subscription = InternetConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case InternetConnectionStatus.connected:
          if (_noInternet) {
            webViewController.reload();

            setState(() {
              _noInternet = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.green,
                  content: Text(
                    "Back online. Please wait a few moments to reload",
                  )),
            );
          }
          break;
        case InternetConnectionStatus.disconnected:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                duration: Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
                content: Text("No Internect Connection")),
          );
          setState(() {
            _noInternet = true;
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Robo',
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  'আড্ডা',
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.red[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
              child: Column(children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  InAppWebView(
                    key: webViewKey,
                    initialUrlRequest: URLRequest(
                        url: Uri.parse("https://roboadda.com.bd/courses/")),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    androidOnPermissionRequest:
                        (controller, origin, resources) async {
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                      var uri = navigationAction.request.url;

                      if ((uri.toString())
                          .startsWith('https://www.youtube.com/')) {
                        _launchURL(uri.toString());
                        print('blocking navigation to $uri}');
                        return NavigationActionPolicy.CANCEL;
                      } else if ((uri.toString())
                          .startsWith('https://www.facebook.com/')) {
                        _launchURL(uri.toString());
                        print('blocking navigation to $uri}');
                        return NavigationActionPolicy.CANCEL;
                      } else if ((uri.toString())
                          .startsWith('https://www.instagram.com/')) {
                        _launchURL(uri.toString());
                        print('blocking navigation to $uri}');
                        return NavigationActionPolicy.CANCEL;
                      } else if ((uri.toString())
                          .startsWith('https://www.linkedin.com/')) {
                        _launchURL(uri.toString());
                        print('blocking navigation to $uri}');
                        return NavigationActionPolicy.CANCEL;
                      } else if ((uri.toString()).startsWith('mailto:')) {
                        _launchURL(uri.toString());
                        print('blocking navigation to $uri}');
                        return NavigationActionPolicy.CANCEL;
                      } else if ((uri.toString()).startsWith('intent:')) {
                        _messangerKey.currentState.showSnackBar(SnackBar(
                            content:
                                Text('Please visit our official website')));

                        print('blocking navigation to $uri}');
                        return NavigationActionPolicy.CANCEL;
                      } else {
                        return NavigationActionPolicy.ALLOW;
                      }
                    },
                    onLoadStop: (controller, url) async {
                      pullToRefreshController.endRefreshing();
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onLoadError: (controller, url, code, message) {
                      pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                        urlController.text = this.url;
                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print(consoleMessage);
                    },
                  ),
                  _noInternet ? NoInternetConnection() : Container(),
                  Center(
                    child: progress < 1.0
                        ? SpinKitRipple(
                            color: Colors.red,
                          )
                        : Container(),
                  ),
                ],
              ),
            ),
          ]))),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
