import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/auth_provider.dart';
import 'web_login.dart';
import 'web_admin_shell.dart';

class WebRoot extends StatefulWidget {
  const WebRoot({super.key});

  @override
  State<WebRoot> createState() => _WebRootState();
}

class _WebRootState extends State<WebRoot> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthCheckSession());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return WebAdminShell(employee: state.employee);
        }
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const WebLoginScreen();
      },
    );
  }
}
