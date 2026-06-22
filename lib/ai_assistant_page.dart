// lib/ai_assistant_page.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

/* ══════════════════════════════════════════════════
   AI ASSISTANT PAGE
   Smart car-rental advisor powered by AI.
   Strictly limited to rental-related topics.
══════════════════════════════════════════════════ */

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _loading = false;

  // Quick suggestion chips
  final List<String> _suggestions = [
    '🚗 What documents do I need to rent?',
    '💰 How is the rental price calculated?',
    '📅 Can I cancel a booking?',
    '🔑 How do I list my car?',
    '⭐ Tips for a first-time renter?',
    '🛡️ Is my car insured during rental?',
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(_ChatMsg(
      role: 'assistant',
      text: 'Hello! I\'m your AirCar AI assistant 🚗\n\nI can help you with:\n• Rental process & requirements\n• Understanding bookings & pricing\n• Tips for renting or listing a car\n• Document requirements\n\nWhat would you like to know?',
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMsg(role: 'user', text: text.trim()));
      _loading = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    // Simulate AI response with built-in knowledge base
    final response = await _getAiResponse(text.trim());

    if (mounted) {
      setState(() {
        _messages.add(_ChatMsg(role: 'assistant', text: response));
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  /// Local AI knowledge base for rental-related questions.
  /// In production, connect to a real LLM API (e.g. Claude).
  Future<String> _getAiResponse(String question) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final q = question.toLowerCase();

    // ── Documents
    if (q.contains('document') || q.contains('id') || q.contains('license') || q.contains('هوية') || q.contains('رخصة')) {
      return '📋 **Required Documents**\n\nTo complete a booking on AirCar you need:\n\n1. 🪪 **National ID** — A clear photo of your national identity card\n2. 🚗 **Driving License** — A valid, unexpired driver\'s license\n\nBoth must be uploaded before sending your booking request. The car owner reviews them before confirming.\n\n💡 *Tip: Make sure photos are clear and all text is readable.*';
    }

    // ── Price / cost
    if (q.contains('price') || q.contains('cost') || q.contains('pay') || q.contains('sar') || q.contains('سعر') || q.contains('تكلفة')) {
      return '💰 **How Pricing Works**\n\nAirCar pricing is straightforward:\n\n• **Daily rate** — Each car has a price per day set by the owner\n• **Total** = Price/day × Number of days\n• Minimum booking is 1 day\n\nExample: A car at 180 SAR/day for 3 days = **540 SAR total**\n\n💡 *Use the price filter (Low→High) on the home screen to find cars within your budget.*';
    }

    // ── Cancel / cancellation
    if (q.contains('cancel') || q.contains('cancell') || q.contains('إلغاء')) {
      return '❌ **Cancellation Policy**\n\nYou can cancel a **pending** booking request at any time — simply go to:\n\n📍 My Bookings → Pending tab → Cancel Request\n\nOnce a booking is **confirmed** by the owner, cancellation terms depend on the individual owner. Contact the owner through the booking details.\n\n💡 *Always book for the exact dates you need to avoid complications.*';
    }

    // ── List car / owner
    if (q.contains('list') || q.contains('owner') || q.contains('add car') || q.contains('my car') || q.contains('اضافة') || q.contains('مالك')) {
      return '🔑 **Listing Your Car**\n\nSwitch to **Owner Mode** using the toggle in the top bar, then:\n\n1. Tap **Add Car** from the dashboard or menu\n2. Fill in: title, city, year, price/day, specs\n3. Add a clear photo URL\n4. Tap **List My Car**\n\nYour car is now live! 🎉\n\n**Managing requests:**\n• Go to Owner → Booking Requests\n• Review renter documents\n• Accept ✅ or Reject ❌\n\n💡 *Set a competitive price by browsing similar cars in your city.*';
    }

    // ── First time tips
    if (q.contains('first') || q.contains('tip') || q.contains('beginner') || q.contains('new') || q.contains('أول')) {
      return '⭐ **Tips for First-Time Renters**\n\n1. **Prepare documents early** — ID & license ready to upload\n2. **Check dates carefully** — Confirm pickup and return dates\n3. **Read the car description** — Check transmission, fuel type, seats\n4. **Filter by city** — Find cars near you\n5. **Sort by price** — Use Low→High to find budget options\n6. **Wait for confirmation** — Pending means the owner hasn\'t responded yet\n\n💡 *Confirmed = you\'re all set! Enjoy your trip 🚗*';
    }

    // ── Insurance
    if (q.contains('insur') || q.contains('accident') || q.contains('damage') || q.contains('تأمين')) {
      return '🛡️ **Insurance & Liability**\n\nInsurance coverage depends on the car owner\'s arrangement. We recommend:\n\n• **Ask the owner** about existing car insurance before booking\n• **Drive carefully** — you are responsible for the vehicle during rental\n• **Document the car condition** when you pick it up (photos recommended)\n• **Report any issues** immediately to the owner\n\n⚠️ *AirCar connects renters and owners. Always communicate clearly with the car owner about insurance details.*';
    }

    // ── Booking process
    if (q.contains('book') || q.contains('how to rent') || q.contains('process') || q.contains('حجز') || q.contains('كيف')) {
      return '📖 **How to Book a Car**\n\nSimple 4-step process:\n\n1. 🔍 **Browse** — Search & filter cars on the Home screen\n2. 📅 **Select dates** — Pick your rental period\n3. 📄 **Upload docs** — National ID + Driving License\n4. 📤 **Send request** — Owner reviews & confirms\n\n**Booking status:**\n• ⏳ **Pending** — Awaiting owner approval\n• ✅ **Confirmed** — You\'re good to go!\n• ❌ **Rejected** — Try different dates or another car\n\n💡 *Check My Bookings to track all your requests.*';
    }

    // ── Mode switching
    if (q.contains('switch') || q.contains('mode') || q.contains('renter') || q.contains('تبديل')) {
      return '🔄 **Switching Between Modes**\n\nEvery AirCar account has TWO modes:\n\n🚗 **Renter Mode** — Browse & book cars\n🔑 **Owner Mode** — List & manage your cars\n\nTo switch:\n• Tap the **mode button** in the top-right of the app bar\n• Or use the **Drawer menu** (tap the ☰ icon)\n\nYou can switch freely anytime. Your bookings and cars are always saved!';
    }

    // ── Off-topic / default
    if (q.contains('weather') || q.contains('sports') || q.contains('food') || q.contains('news') || q.contains('movie')) {
      return '🚗 I\'m specialized in AirCar rental topics only.\n\nI can help with:\n• Booking process & requirements\n• Pricing & calculations\n• Listing your car\n• Document requirements\n• Cancellation & policies\n\nWhat rental question can I answer for you?';
    }

    // ── Default response
    return '🤔 I\'m not sure about that specific question.\n\nHere are things I can definitely help with:\n\n• **Booking process** — How to rent a car step by step\n• **Documents needed** — ID & license requirements\n• **Pricing** — How costs are calculated\n• **Listing a car** — How to become an owner\n• **Cancellations** — Booking management\n\nFeel free to ask any of the above! 😊';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Assistant',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('Rental advice & support',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _messages.clear();
                      _messages.add(_ChatMsg(
                        role: 'assistant',
                        text: 'Chat cleared! How can I help you? 🚗',
                      ));
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.refresh,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // ── Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length && _loading) {
                  return const _TypingIndicator();
                }
                final msg = _messages[i];
                return _ChatBubble(msg: msg);
              },
            ),
          ),

          // ── Suggestion chips (only when few messages)
          if (_messages.length <= 2)
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  return GestureDetector(
                    onTap: () => _send(_suggestions[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.divider),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Text(_suggestions[i],
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMain,
                              fontWeight: FontWeight.w500)),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // ── Input bar
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.divider),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ask about renting or listing a car...',
                      hintStyle: TextStyle(
                          color: AppTheme.textSub, fontSize: 13),
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: _send,
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _send(_ctrl.text),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ── Chat message model ── */
class _ChatMsg {
  final String role; // 'user' | 'assistant'
  final String text;
  _ChatMsg({required this.role, required this.text});
}

/* ── Chat bubble ── */
class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: AppTheme.softShadow,
                border: isUser
                    ? null
                    : Border.all(color: AppTheme.divider),
              ),
              child: _buildText(msg.text, isUser),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(Icons.person,
                  color: AppTheme.textSub, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildText(String text, bool isUser) {
    // Simple markdown-like bold (**text**)
    final parts = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((line) {
        if (line.isEmpty) return const SizedBox(height: 4);
        final boldRegex = RegExp(r'\*\*(.*?)\*\*');
        if (!boldRegex.hasMatch(line)) {
          return Text(
            line,
            style: TextStyle(
              color: isUser ? Colors.white : AppTheme.textMain,
              fontSize: 13,
              height: 1.5,
            ),
          );
        }
        final spans = <TextSpan>[];
        int last = 0;
        for (final m in boldRegex.allMatches(line)) {
          if (m.start > last) {
            spans.add(TextSpan(text: line.substring(last, m.start)));
          }
          spans.add(TextSpan(
            text: m.group(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ));
          last = m.end;
        }
        if (last < line.length) {
          spans.add(TextSpan(text: line.substring(last)));
        }
        return RichText(
          text: TextSpan(
            style: TextStyle(
                color: isUser ? Colors.white : AppTheme.textMain,
                fontSize: 13,
                height: 1.5),
            children: spans,
          ),
        );
      }).toList(),
    );
  }
}

/* ── Typing indicator ── */
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: AppTheme.softShadow,
              border: Border.all(color: AppTheme.divider),
            ),
            child: FadeTransition(
              opacity: _anim,
              child: Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
