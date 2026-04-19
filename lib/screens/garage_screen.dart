import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class GarageScreen extends StatefulWidget {
  final Map<String, String> carDetails;
  final String? loanId;
  final void Function(String, {int? stepDelta}) setActiveTab;
  final void Function(String, [Map<String, dynamic>? data, String? scannerMode, String? pendingDocType]) setStep;

  const GarageScreen({
    super.key,
    required this.carDetails,
    this.loanId,
    required this.setActiveTab,
    required this.setStep,
  });

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  // Toggle States
  bool _insuranceExpiry = true;
  bool _equityAlerts = true;

  // Document States
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    final docs = await ApiService.getUserDocuments();
    if (!mounted) return;
    setState(() {
      _documents = docs;
    });
  }

  Future<void> _handleDocTap(String docType) async {
    final docList = _documents.where((d) => d['doc_type'] == docType).toList();
    final isUploaded = docList.isNotEmpty;

     if (isUploaded) {
      // 1. View Document
      final url = Uri.parse(docList.first['file_url']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open document")),
        );
      }
    } else {
      _showDocumentOptionsSheet(docType);
    }
  }

  void _showDocumentOptionsSheet(String docType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Add Document",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.pop(context);
                  widget.setStep('scanner', null, 'garage', docType);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text("Choose from Library"),
                onTap: () {
                  Navigator.pop(context);
                  _handleFileUpload(docType);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleFileUpload(String docType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      _showLoadingDialog("Uploading document...");
      try {
        await ApiService.uploadGarageDocument(
          result.files.single.path!,
          docType,
          loanId: widget.loanId,
        );
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        _fetchDocuments(); // Refresh the list
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFF8FAFC);
    const colorSlate800 = Color(0xFF1E293B);
    const colorGreen = Color(0xFF00CA50);
    const colorNavy = Color(0xFF003366);

    final car = widget.carDetails;
    final trim = (car['trim'] ?? '').trim();
    final plate = (car['plate'] ?? '').trim();
    final vin = (car['vin'] ?? '').trim();

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Minimal Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.setActiveTab('home'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        size: 24,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "My Garage",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorSlate800,
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. Scrollable Content ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Vehicle Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueGrey.shade50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: colorBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.car,
                                  size: 24,
                                  color: colorNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${car['year']} ${car['make']} ${car['model']}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorSlate800,
                                  ),
                                ),
                                if (trim.isNotEmpty || plate.isNotEmpty)
                                  Text(
                                    [trim, plate]
                                        .where((value) => value.isNotEmpty)
                                        .join(' • '),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (vin.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "VIN",
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueGrey.shade600,
                                      ),
                                    ),
                                    Text(
                                      vin,
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 12,
                                        color: colorSlate800,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: vin));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "VIN copied to clipboard",
                                          style: GoogleFonts.outfit(),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        width: 200,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      LucideIcons.copy,
                                      size: 16,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Documents Section
                  _sectionTitle("DOCUMENTS"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueGrey.shade50),
                    ),
                    child: Column(
                      children: [
                        _buildDocItem("Bill of Sale", "bill_of_sale", true),
                        _buildDocItem("Insurance Policy", "insurance", true),
                        _buildDocItem("Registration", "registration", false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notifications Section
                  _sectionTitle("NOTIFICATIONS"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueGrey.shade50),
                    ),
                    child: Column(
                      children: [
                        _buildToggleItem(
                          "Insurance Expiry",
                          LucideIcons.bell,
                          _insuranceExpiry,
                          (v) => setState(() => _insuranceExpiry = v),
                          true,
                          colorGreen,
                        ),
                        _buildToggleItem(
                          "Equity Alerts",
                          LucideIcons.trendingUp,
                          _equityAlerts,
                          (v) => setState(() => _equityAlerts = v),
                          false,
                          colorGreen,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDocItem(String title, String docType, bool showDivider) {
    // Check if the document exists in our fetched data
    final docList = _documents.where((d) => d['doc_type'] == docType).toList();
    final isUploaded = docList.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: () => _handleDocTap(docType),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? Colors.green.shade50
                        : const Color(0xFFE6F0FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isUploaded
                        ? LucideIcons.checkCircle2
                        : LucideIcons.image,
                    size: 18,
                    color: isUploaded
                        ? const Color(0xFF00CA50)
                        : const Color(0xFF003366),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (isUploaded)
                        Text(
                          "Tap to view",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.blueGrey.shade400,
                          ),
                        )
                      else
                        Text(
                          "Tap to upload photo",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.blueGrey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  isUploaded ? LucideIcons.externalLink : LucideIcons.camera,
                  size: 16,
                  color: isUploaded
                      ? Colors.blueGrey.shade300
                      : const Color(0xFF003366),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: Colors.blueGrey.shade50),
      ],
    );
  }

  Widget _buildToggleItem(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    bool showDivider,
    Color activeColor,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.blueGrey.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: activeColor,
                activeTrackColor: activeColor.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: Colors.blueGrey.shade50),
      ],
    );
  }
}
