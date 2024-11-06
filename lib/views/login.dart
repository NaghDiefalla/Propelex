import 'package:get/get.dart';
import 'package:propelex/views/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  TextEditingController emailControler = TextEditingController();
  TextEditingController passwordControler = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  RxBool _isLightTheme = false.obs;

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  _saveThemeStatus() async {
    SharedPreferences pref = await _prefs;
    pref.setBool('theme', _isLightTheme.value);
  }

  _getThemeStatus() async {
    var _isLight = _prefs.then((SharedPreferences prefs) {
      return prefs.getBool('theme') != null ? prefs.getBool('theme') : true;
    }).obs;
    _isLightTheme.value = (await _isLight.value)!;
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
        actions: [
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
                  style: Theme.of(context).textTheme.headline1?.copyWith(
                        fontSize: size.width * 0.1,
                      )),
              const SizedBox(
                height: 100,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
                style: Theme.of(context).textTheme.bodyText1,
              ),
              MaterialButton(
                onPressed: () => {
                  if (_formkey.currentState!.validate())
                    {Get.offAll(() => HomePage())}
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
                  style: Theme.of(context).textTheme.bodyText1,
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
