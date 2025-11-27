import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameC =
      TextEditingController(text: "Nayla");
  final TextEditingController emailC =
      TextEditingController(text: "Nayla@gmail.com");
  final TextEditingController passC = TextEditingController(text: "password123");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFF4C6C50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Bagian Header Melengkung + Foto Profile
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4C6C50),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(70),
                      bottomRight: Radius.circular(70),
                    ),
                  ),
                ),

                /// Foto Profil
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -50,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 55,
                            backgroundImage: AssetImage("assets/nayla.png"),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.camera_alt,
                                  size: 18, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 70),

            /// Nama
            buildInputField(
              label: "Nama :",
              controller: nameC,
              isPassword: false,
            ),

            /// Email
            buildInputField(
              label: "Email :",
              controller: emailC,
              isPassword: false,
            ),

            /// Password
            buildInputField(
              label: "Password :",
              controller: passC,
              isPassword: true,
            ),

            const SizedBox(height: 20),

            /// Tombol Simpan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF4C6C50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _showConfirmDialog(context);
                  },
                  child: const Text(
                    "Simpan",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// WIDGET INPUT FIELD
  Widget buildInputField({
    required String label,
    required TextEditingController controller,
    required bool isPassword,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              suffixIcon: const Icon(Icons.edit, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // POPUP KONFIRMASI DITEMPATKAN DI SINI
  // ==============================
  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Konfirmasi",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Apakah Anda yakin ingin\nmenyimpan?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4C6C50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: tambahkan fungsi simpan
                      },
                      child: const Text(
                        "Simpan",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
