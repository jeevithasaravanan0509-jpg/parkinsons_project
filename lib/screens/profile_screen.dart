import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String _fullName = 'Patient';
  String _email = '';
  String _age = '';
  String _emergencyContact = '';

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emergencyController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _emergencyController = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final document = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = document.data();

      if (data != null) {
        _fullName = data['fullName'] as String? ?? user.displayName ?? 'Patient';
        _email = data['email'] as String? ?? user.email ?? '';
        _age = data['age']?.toString() ?? '';
        _emergencyContact =
            data['emergencyContact'] as String? ?? '';
      } else {
        _fullName = user.displayName ?? 'Patient';
        _email = user.email ?? '';
      }

      _nameController.text = _fullName;
      _ageController.text = _age;
      _emergencyController.text = _emergencyContact;
    } catch (e) {
      _showMessage('Unable to load your profile.');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('No authenticated user found.');
      return;
    }

    final name = _nameController.text.trim();
    final age = _ageController.text.trim();
    final emergencyContact = _emergencyController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'uid': user.uid,
          'fullName': name,
          'email': user.email ?? '',
          'age': age,
          'emergencyContact': emergencyContact,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await user.updateDisplayName(name);

      _fullName = name;
      _age = age;
      _emergencyContact = emergencyContact;

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
      }

      _showMessage('Profile updated successfully.');
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Unable to update your profile.',
      );
    } catch (e) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F9FE),
        foregroundColor: const Color(0xFF25324A),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _isEditing = !_isEditing;

                        if (_isEditing) {
                          _nameController.text = _fullName;
                          _ageController.text = _age;
                          _emergencyController.text =
                              _emergencyContact;
                        }
                      });
                    },
              icon: Icon(
                _isEditing
                    ? Icons.close_rounded
                    : Icons.edit_rounded,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                30,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Profile avatar
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8F0FF),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6385E5)
                              .withValues(alpha: 0.12),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 58,
                      color: Color(0xFF6385E5),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    _fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF25324A),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    user?.email ?? _email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A8499),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Personal information card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 18,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF25324A),
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_isEditing) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline_rounded,
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _ageController,
                            label: 'Age',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _emergencyController,
                            label: 'Emergency Contact',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isSaving ? null : _saveProfile,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_rounded,
                                    ),
                              label: Text(
                                _isSaving
                                    ? 'Saving...'
                                    : 'Save Changes',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF6385E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          _buildInfoRow(
                            icon: Icons.person_outline_rounded,
                            title: 'Full Name',
                            value: _fullName,
                          ),

                          const Divider(height: 28),

                          _buildInfoRow(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: _email,
                          ),

                          const Divider(height: 28),

                          _buildInfoRow(
                            icon: Icons.cake_outlined,
                            title: 'Age',
                            value: _age.isEmpty
                                ? 'Not added'
                                : _age,
                          ),

                          const Divider(height: 28),

                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            title: 'Emergency Contact',
                            value: _emergencyContact.isEmpty
                                ? 'Not added'
                                : _emergencyContact,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Privacy / safety card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF6385E5),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your profile information is linked to your secure Firebase account.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: Color(0xFF52627A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE3E8F2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFF6385E5),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6385E5),
            size: 21,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF8A94A8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF303C52),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}