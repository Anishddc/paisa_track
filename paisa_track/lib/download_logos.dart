import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'utils/logo_creator.dart';

// Class representing a logo to download
class LogoInfo {
  final String id;
  final String name;
  final String imageUrl;
  final String type; // 'bank' or 'wallet'

  LogoInfo({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.type,
  });
}

Future<void> main() async {
  // Ensure Flutter is initialized (needed for LogoCreator)
  WidgetsFlutterBinding.ensureInitialized();

  // Create directories if they don't exist
  final banksDir = Directory('assets/banks');
  final walletsDir = Directory('assets/wallets');
  
  if (!await banksDir.exists()) {
    await banksDir.create(recursive: true);
    print('Created directory: ${banksDir.path}');
  }
  
  if (!await walletsDir.exists()) {
    await walletsDir.create(recursive: true);
    print('Created directory: ${walletsDir.path}');
  }

  // List of bank logos to download
  final bankLogos = [
    LogoInfo(
      id: 'adbl',
      name: 'Agriculture Development Bank Limited',
      imageUrl: 'https://kisan.adbl.gov.np/Content/homepage/images/adbl%20.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'bfc',
      name: 'Best Finance Company Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/08/21/074051-bfc-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'cfcl',
      name: 'Central Finance Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/09/02/025918-cfcl-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'citizens',
      name: 'Citizens Bank International Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/12/26/012250-citizens-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'corbl',
      name: 'Corporate Development Bank Ltd.',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/08/22/101210-corbl-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'everest',
      name: 'Everest Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/09/07/035638-ebl-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'edbl',
      name: 'Excel Development Bank Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090153-edblpo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'global_ime',
      name: 'Global IME Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/08/07/020459-gbime-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'goodwill',
      name: 'Goodwill Finance Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/09/06/080148-gfcl-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'gurkhas',
      name: 'Gurkhas Finance Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/09/06/080148-gfcl-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'himalayan',
      name: 'Himalayan Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090157-hbld83.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'icfc',
      name: 'ICFC Finance Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/08/11/111154-icfc.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'janaki',
      name: 'Janaki Finance Company Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090158-jflpo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'jyoti',
      name: 'Jyoti Bikas Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/21/041118-jyoti-bikas-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'kamana',
      name: 'Kamana Sewa Bikas Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/09/02/113238-ksbbl-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'kumari',
      name: 'Kumari Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/08/18/074600-kbl-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'laxmi_sunrise',
      name: 'LaxmiSunrise Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/20/080418-laxmi-sunrise-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'lumbini',
      name: 'Lumbini Bikas Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/21/024114-lumbini-bikas-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'machhapuchhre',
      name: 'Machhapuchchhre Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/05/machhapuchchhre-bank-limited-removebg-preview.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'manjushree',
      name: 'Manjushree Finance Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090203-mfld85.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'miteri',
      name: 'Miteri Development Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/08/30/062210-mdb-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'muktinath',
      name: 'Muktinath Bikas Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090204-mnbblp.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'nic_asia',
      name: 'NIC Asia Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/02/18/092935-nic-asia-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'nmb',
      name: 'NMB Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/08/15/074756-nimb-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'nabil',
      name: 'Nabil Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/08/22/120236-nabil.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'nepal_bank',
      name: 'Nepal Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090148-nbld87.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'nifra',
      name: 'Nepal Infrastructure Bank Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/031428-nifra-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'nepal_sbi',
      name: 'Nepal SBI Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/13/102340-nepal-sbi-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'pokhara',
      name: 'Pokhara Finance Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090211-pflpo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'prabhu',
      name: 'Prabhu Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/12/24/014601-prabhu-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'prime',
      name: 'Prime Commercial Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/20/075732-prime-commercial-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'progressive',
      name: 'Progressive Finance Co. Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090211-proflp.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'reliance',
      name: 'Reliance Finance Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090212-rlflpo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'samriddhi',
      name: 'Samriddhi Finance Company Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/08/07/061119-samriddhi-finance.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'sanima',
      name: 'Sanima Bank Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/09/06/042721-sanima-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'saptakoshi',
      name: 'Saptakoshi Development Bank Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2024/09/04/032641-sapdbl-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'shangrila',
      name: 'Shangrila Development Bank Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/21/022553-shangrila-development-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'shine_resunga',
      name: 'Shine Resunga Development Bank Ltd',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/21/034510-shine-resunga-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'shree',
      name: 'Shree Investment & Finance Co. Ltd.',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/21/040524-shree-investment-finance-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'siddhartha',
      name: 'Siddhartha Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/08/070230-siddharth-bank-logo.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'sindu',
      name: 'Sindu Bikash Bank Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/08/22/105955-sindhu.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'scb',
      name: 'Standard Chartered Bank Nepal Limited',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/icons/2024/01/12/090124-scb.png',
      type: 'bank',
    ),
    LogoInfo(
      id: 'mahalaxmi',
      name: 'Mahalaxmi Bikas Bank Ltd.',
      imageUrl: 'https://cdn.arthakendra.com/sharehub/images/2025/01/28/080659-mahalaxmi-bikas-bank-logo.png',
      type: 'bank',
    ),
  ];

  // List of wallet logos to download
  final walletLogos = [
    LogoInfo(
      id: 'esewa',
      name: 'eSewa',
      imageUrl: 'https://esewa.com.np/common/images/esewa_logo.png',
      type: 'wallet',
    ),
    LogoInfo(
      id: 'khalti',
      name: 'Khalti',
      imageUrl: 'https://khalti.com/static/images/khalti-logo.svg',
      type: 'wallet',
    ),
    LogoInfo(
      id: 'imepay',
      name: 'IME Pay',
      imageUrl: 'https://imepay.com.np/assets/img/logo.png',
      type: 'wallet',
    ),
    LogoInfo(
      id: 'connectips',
      name: 'ConnectIPS',
      imageUrl: 'https://www.connectips.com/images/logo.png',
      type: 'wallet',
    ),
    LogoInfo(
      id: 'fonepay',
      name: 'FonePay',
      imageUrl: 'https://fonepay.com/images/logo.png',
      type: 'wallet',
    ),
    LogoInfo(
      id: 'prabhupay',
      name: 'Prabhu Pay',
      imageUrl: 'https://prabhupay.com/wp-content/uploads/2020/09/Prabhu-Pay-Logo-2048x746.png',
      type: 'wallet',
    ),
    LogoInfo(
      id: 'qpay',
      name: 'QPay',
      imageUrl: 'https://qpay.com.np/assets/img/logo.png',
      type: 'wallet',
    ),
    LogoInfo(
      id: 'ipay',
      name: 'iPay',
      imageUrl: 'https://ipay.com.np/assets/images/logo.png',
      type: 'wallet',
    ),
    LogoInfo(
      id: 'moco',
      name: 'MoCo',
      imageUrl: 'https://moco.com.np/assets/img/logo.png',
      type: 'wallet',
    ),
  ];

  // Create a placeholder for Rastriya Bank which doesn't have a URL
  try {
    await LogoCreator.createRastriyaBankLogo();
  } catch (e) {
    print('Error creating placeholder logo: $e');
  }

  // Download all logos
  final allLogos = [...bankLogos, ...walletLogos];
  int downloaded = 0;
  int failed = 0;

  for (final logo in allLogos) {
    if (logo.imageUrl.isEmpty) {
      print('Skipping ${logo.name} - no URL provided');
      continue;
    }

    final directory = logo.type == 'bank' ? 'assets/banks' : 'assets/wallets';
    final filename = '${logo.id}.png';
    final filePath = p.join(directory, filename);
    
    try {
      final response = await http.get(Uri.parse(logo.imageUrl));
      
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print('Downloaded ${logo.name} to $filePath');
        downloaded++;
      } else {
        print('Failed to download ${logo.name}: HTTP ${response.statusCode}');
        failed++;
      }
    } catch (e) {
      print('Error downloading ${logo.name}: $e');
      failed++;
    }
    
    // Small delay to be polite to the server
    await Future.delayed(Duration(milliseconds: 200));
  }

  print('Download complete. Downloaded: $downloaded, Failed: $failed');
} 