import 'package:csc_picker/csc_picker.dart';
import 'package:flutter/material.dart';
import 'package:vpool/constants/colors.dart';
import 'package:vpool/main.dart';

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

TextEditingController firstNameController = TextEditingController();
TextEditingController lastNameController = TextEditingController();
TextEditingController phoneNumberController = TextEditingController();
String dropdownVal = "Male";
String? countryValue = "";
String? stateValue = "";
String? cityValue = "";

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<String>> menuItems = [
      const DropdownMenuItem(value: "Male", child: Text("Male")),
      const DropdownMenuItem(value: "Female", child: Text("Female")),
      const DropdownMenuItem(value: "Other", child: Text("Other")),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
        surfaceTintColor: appPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: "First Name",
              ),
            ),
            TextFormField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: "Last Name",
              ),
            ),
            TextFormField(
              controller: phoneNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Phone Number",
              ),
            ),
            const SizedBox(height: 20),
            const Text("Gender"),
            DropdownButton(
                value: dropdownVal,
                onChanged: (val) {
                  setState(() {
                    dropdownVal = val!;
                    print(dropdownVal);
                  });
                },
                items: menuItems),
            const SizedBox(height: 10),
            const Text("Home Town"),
            const SizedBox(height: 10),
            CSCPicker(
              flagState: CountryFlag.DISABLE,
              onCountryChanged: (value) {
                setState(() {
                  countryValue = value;
                });
              },
              onStateChanged: (value) {
                setState(() {
                  stateValue = value;
                });
              },
              onCityChanged: (value) {
                setState(() {
                  cityValue = value;
                });
              },
            ),
            const SizedBox(height: 10),
            const Text(
              "*Fill all fields to continue",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.85,
                child: Text(
                  "By continuing, you agree to our Terms of Service and Privacy Policy.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (firstNameController.text.isEmpty ||
                      lastNameController.text.isEmpty ||
                      phoneNumberController.text.isEmpty ||
                      countryValue == "" ||
                      stateValue == "" ||
                      cityValue == "") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        content: const Text("Fill all fields to continue"),
                      ),
                    );
                    return;
                  }
                  await supabase.from('user_data').insert({
                    'First Name': firstNameController.text.trim().toUpperCase(),
                    'Last Name': lastNameController.text.trim().toUpperCase(),
                    'Phone': phoneNumberController.text.trim(),
                    'Gender': dropdownVal.trim().toUpperCase(),
                    'Country': countryValue,
                    'State': stateValue,
                    'City': cityValue,
                  }).then((value) => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false));
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 13),
                  backgroundColor: elemntPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "PROCEED",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  supabase.auth.signOut().then((value) =>
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/', (route) => false));
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 13),
                  backgroundColor: elemntPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
