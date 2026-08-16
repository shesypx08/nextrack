import 'package:flutter/material.dart';

class EmailSentScreen extends StatelessWidget {
  const EmailSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'NEXTRACK',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E0854),
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF4A4454),
              size: 24.0,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support center is available offline.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF4B0AAA),
                ),
              );
            },
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 24.0,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              Center(
                                child: Stack(
                                  children: [

                                    Container(
                                      width: 112.0,
                                      height: 112.0,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 16.0,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: const Color(0xFFF3EDF5),
                                          width: 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: 74.0,
                                        height: 74.0,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEADDFF),
                                          borderRadius: BorderRadius.circular(16.0),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.mark_email_read_outlined,
                                          size: 40.0,
                                          color: Color(0xFF4B0AAA),
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 32.0,
                                        height: 32.0,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4B0AAA),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 8.0,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32.0),


                              const Text(
                                'Email Sent!',
                                style: TextStyle(
                                  fontSize: 26.0,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B1B1D),
                                  letterSpacing: -0.5,
                                ),
                              ),

                              const SizedBox(height: 12.0),


                              const Text(
                                "We've sent a password reset link to your email address. Please check your inbox.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF5C5468),
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 28.0),


                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5EFF7),
                                  borderRadius: BorderRadius.circular(14.0),
                                  border: Border.all(
                                    color: const Color(0xFFE8DFF2),
                                    width: 1.0,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFF4B0AAA),
                                        size: 20.0,
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF4A4454),
                                              height: 1.4,
                                              fontFamily: 'sans-serif',
                                            ),
                                            children: [
                                              TextSpan(
                                                text: "If you don't see the email within 5 minutes, check your ",
                                              ),
                                              TextSpan(
                                                text: "spam folder",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF1B1B1D),
                                                ),
                                              ),
                                              TextSpan(
                                                text: " or try again.",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),


                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56.0,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B0AAA),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                              ),
                              child: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12.0),


                          SizedBox(
                            width: double.infinity,
                            height: 56.0,
                            child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This feature is not available yet.'),
                                    ),
                                  );
                                },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8E1EF),
                                foregroundColor: const Color(0xFF4A4454),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                              ),
                              child: const Text(
                                'Resend Link',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32.0),


                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24.0,
                                height: 4.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4B0AAA),
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              Container(
                                width: 24.0,
                                height: 4.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE4E2E4),
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
