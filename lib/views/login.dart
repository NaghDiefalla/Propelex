import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  TextEditingController emailControler = TextEditingController();
  TextEditingController passwordControler = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  final RxBool _isLightTheme = false.obs;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();


  Future<void> _getThemeStatus() async {
    var isLight = _prefs.then((SharedPreferences prefs) {
      return prefs.getBool('theme') ?? true;
    }).obs;
    _isLightTheme.value = (await isLight.value);
    Get.changeThemeMode(_isLightTheme.value ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  void initState() {
    _getThemeStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          // ObxValue(
          //   (data) => Switch(
          //     value: _isLightTheme.value,
          //     onChanged: (val) {
          //       _isLightTheme.value = val;
          //       Get.changeThemeMode(
          //         _isLightTheme.value ? ThemeMode.light : ThemeMode.dark,
          //       );
          //       _saveThemeStatus();
          //     },
          //   ),
          //   false.obs,
          // ),
        ],
      ),
      body: Form(
        key: _formkey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("A New Begining.",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: size.width * 0.1,
                      )),
              const SizedBox(
                height: 100,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                      width: 30, image: AssetImage('assets/icons/google.png')),
                  SizedBox(width: 40),
                  Image(
                      width: 30, image: AssetImage('assets/icons/facebook.png'))
                ],
              ),
              const SizedBox(
                height: 50,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    borderRadius: const BorderRadius.all(Radius.circular(20))),
                child: TextFormField(
                  controller: emailControler,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Enter your email idiot.";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: "Email"),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    borderRadius: const BorderRadius.all(Radius.circular(20))),
                child: TextFormField(
                  controller: passwordControler,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Enter your password idiot.";
                    }
                    return null;
                  },
                  obscureText: true,
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: "Password"),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                "Forgot Password?",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              MaterialButton(
                onPressed: () => {
                  if (_formkey.currentState!.validate())
                    {Get.offAll(() => const HomePage())}
                },
                elevation: 0,
                padding: const EdgeInsets.all(18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: const Center(
                    child: Text(
                  "Login",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )),
              ),
              const SizedBox(
                height: 30,
              ),
              Center(
                child: Text(
                  "Create account",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
