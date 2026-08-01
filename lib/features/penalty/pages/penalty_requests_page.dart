import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';
import 'package:pragatix/features/penalty/pages/tabs/cc_inbox_tab.dart';
import 'package:pragatix/features/penalty/pages/tabs/my_requests_tab.dart';
import 'package:pragatix/features/penalty/services/penalty_service.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class PenaltyRequestsPage extends StatelessWidget {
  final bool isCC;

  const PenaltyRequestsPage({super.key, required this.isCC});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          PenaltyProvider(PenaltyService(context.read<AuthProvider>()))
            ..loadMyRequests()
            ..loadCcInbox(),
      child: DefaultTabController(
        length: isCC ? 2 : 1,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Penalty Requests',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1E293B),
            bottom: TabBar(
              indicatorColor: const Color(0xFF11998e),
              labelColor: const Color(0xFF11998e),
              unselectedLabelColor: Colors.grey,
              tabs: [
                if (isCC) const Tab(text: 'My Class'),
                const Tab(text: 'My Requests'),
              ],
            ),
          ),
          body: TabBarView(
            children: [if (isCC) const CcInboxTab(), const MyRequestsTab()],
          ),
        ),
      ),
    );
  }
}
