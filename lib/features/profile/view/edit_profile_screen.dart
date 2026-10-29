import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../core/widgets/aura/user_avatar.dart';
import '../../auth/view/auth_widgets.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _user = ref.read(authViewModelProvider).user;
  late final _name = TextEditingController(text: _user?.name);
  late final _phone = TextEditingController(text: _user?.phone);
  late final _city = TextEditingController(text: _user?.city);
  late String? _pic = _user?.profilePic;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  /// Small JPEG stored with the profile, so no separate file storage is needed.
  Future<void> _pick(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 320,
        maxHeight: 320,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _pic = 'data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Couldn\'t open the photo. Try again.')));
      }
    }
  }

  void _photoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GlassList(children: [
            GlassListRow(
              icon: CupertinoIcons.photo,
              title: 'Choose from gallery',
              onTap: () => _pick(ImageSource.gallery),
            ),
            GlassListRow(
              icon: CupertinoIcons.camera,
              title: 'Take a photo',
              onTap: () => _pick(ImageSource.camera),
            ),
            if (_pic != null && !_pic!.startsWith('avatar_'))
              GlassListRow(
                icon: CupertinoIcons.trash,
                title: 'Remove photo',
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _pic = 'avatar_green');
                },
              ),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authViewModelProvider.notifier).updateProfile(
          name: _name.text,
          phone: _phone.text,
          city: _city.text,
          profilePic: _pic,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final busy = ref.watch(authViewModelProvider).isLoading;
    return FormPage(
      title: 'Edit profile',
      children: [
        Center(
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _photoSheet,
            child: Stack(children: [
              UserAvatar(name: _name.text, pic: _pic, size: 96),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: a.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: a.bg, width: 2),
                  ),
                  child: Icon(CupertinoIcons.camera, size: 15, color: a.onAccent),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(CupertinoIcons.person, size: 19),
                ),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: _user?.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email (used to sign in)',
                  prefixIcon: Icon(CupertinoIcons.at, size: 19),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  prefixIcon: Icon(CupertinoIcons.phone, size: 19),
                ),
                validator: (v) {
                  final p = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                  if (p.isEmpty) return null;
                  return RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(p) ? null : 'Enter a 10-digit mobile number';
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'City or district (optional)',
                  prefixIcon: Icon(CupertinoIcons.location, size: 19),
                ),
              ),
              const SizedBox(height: 26),
              BusyButton(label: 'Save', busy: busy, onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}
