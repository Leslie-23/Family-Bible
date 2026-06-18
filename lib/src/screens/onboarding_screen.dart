import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/family_bible_config.dart';
import '../models/local_user.dart';
import '../providers/local_user_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finishWithoutAccount,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _page = page);
                },
                children: [
                  _IntroPage(
                    icon: Icons.family_restroom_rounded,
                    title: FamilyBibleConfig.appName,
                    body:
                        'A shared Bible space for reading, notes, highlights, and family check-ins.',
                  ),
                  const _IntroPage(
                    icon: Icons.sticky_note_2_rounded,
                    title: 'Reflect Together',
                    body:
                        'Keep notes on verses and prepare to share them with your family group.',
                  ),
                  _NativeAuthPage(
                    formKey: _formKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    onGoogle: () => _showComingSoon('Google sign-in'),
                    onApple: () => _showComingSoon('Apple sign-in'),
                    onContinue: _finishWithNativeAccount,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  ...List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 6),
                      height: 8,
                      width: _page == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _page == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _page == 2 ? _finishWithNativeAccount : _next,
                    icon: Icon(
                      _page == 2
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(_page == 2 ? 'Start' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finishWithoutAccount() async {
    await ref.read(localUserProvider.notifier).completeOnboarding();
  }

  Future<void> _finishWithNativeAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(localUserProvider.notifier).saveUser(
          LocalUser(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          ),
        );
  }

  Future<void> _showComingSoon(String provider) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$provider is coming soon'),
          content: const Text(
            'For now, continue with the native Family Bible account flow. '
            'Your family notes can be connected to Google or Apple later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue native'),
            ),
          ],
        );
      },
    );
  }
}

class _IntroPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _IntroPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 84,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _NativeAuthPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onContinue;

  const _NativeAuthPage({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.onGoogle,
    required this.onApple,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Text(
          'Set up your native account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use this for now. Social sign-in will be added after the backend '
          'credentials are ready.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onGoogle,
          icon: const Icon(Icons.g_mobiledata_rounded),
          label: const Text('Continue with Google'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onApple,
          icon: const Icon(Icons.apple_rounded),
          label: const Text('Continue with Apple'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Divider(color: Theme.of(context).colorScheme.outline),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('or'),
            ),
            Expanded(
              child: Divider(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 2) {
                    return 'Enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Continue native'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
