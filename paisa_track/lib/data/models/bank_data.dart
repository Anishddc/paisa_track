import 'package:flutter/material.dart';

class Bank {
  final String id;
  final String name;
  final String logoPath;
  final String imageUrl;
  final Color backgroundColor;
  final bool isPopular;
  final IconData? icon;

  const Bank({
    required this.id,
    required this.name,
    this.logoPath = '',
    this.imageUrl = '',
    this.backgroundColor = Colors.white,
    this.isPopular = false,
    this.icon,
  });
  
  // Get a default icon based on the bank type
  static IconData getDefaultIcon(String id) {
    if (id.contains('wallet') || 
        id == 'esewa' || 
        id == 'khalti' || 
        id == 'imepay' || 
        id == 'connectips' || 
        id == 'fonepay' ||
        id == 'prabhupay' ||
        id == 'qpay' ||
        id == 'ipay' ||
        id == 'moco') {
      return Icons.account_balance_wallet;
    }
    return Icons.account_balance;
  }
  
  // Check if there's a valid logo to display
  bool get hasLogo => logoPath.isNotEmpty;
}

/// Class to provide data for Nepali banks and digital wallets
class NepalBankData {
  
  /// Get a list of major Nepali banks
  static List<Bank> getNepaliBanks() {
    return [
      const Bank(
        id: 'adbl',
        name: 'Agriculture Development Bank Limited',
        logoPath: 'assets/banks/adbl.png',
        isPopular: true,
        backgroundColor: Color(0xFFE3F2FD),
        icon: Icons.account_balance,
      ),
      const Bank(
        id: 'bfc',
        name: 'Best Finance Company Ltd',
        logoPath: 'assets/banks/bfc.png',
        backgroundColor: Color(0xFFE8EAF6),
        icon: Icons.business,
      ),
      const Bank(
        id: 'cfcl',
        name: 'Central Finance Ltd',
        logoPath: 'assets/banks/cfcl.png',
        backgroundColor: Color(0xFFE0F7FA),
        icon: Icons.account_balance,
      ),
      const Bank(
        id: 'citizens',
        name: 'Citizens Bank International Limited',
        logoPath: 'assets/banks/citizens.png',
        backgroundColor: Color(0xFFF3E5F5),
      ),
      const Bank(
        id: 'corbl',
        name: 'Corporate Development Bank Ltd.',
        logoPath: 'assets/banks/corbl.png',
        backgroundColor: Color(0xFFE8F5E9),
      ),
      const Bank(
        id: 'everest',
        name: 'Everest Bank Limited',
        logoPath: 'assets/banks/everest.png',
        isPopular: true,
        backgroundColor: Color(0xFFE1F5FE),
      ),
      const Bank(
        id: 'edbl',
        name: 'Excel Development Bank Ltd',
        logoPath: 'assets/banks/edbl.png',
        backgroundColor: Color(0xFFFFF3E0),
      ),
      const Bank(
        id: 'global_ime',
        name: 'Global IME Bank Limited',
        logoPath: 'assets/banks/global_ime.png',
        isPopular: true,
        backgroundColor: Color(0xFFE8EAF6),
      ),
      const Bank(
        id: 'goodwill',
        name: 'Goodwill Finance Limited',
        logoPath: 'assets/banks/goodwill.png',
        backgroundColor: Color(0xFFE0F2F1),
      ),
      const Bank(
        id: 'gurkhas',
        name: 'Gurkhas Finance Limited',
        logoPath: 'assets/banks/gurkhas.png',
        backgroundColor: Color(0xFFF1F8E9),
      ),
      const Bank(
        id: 'himalayan',
        name: 'Himalayan Bank Limited',
        logoPath: 'assets/banks/himalayan.png',
        isPopular: true,
        backgroundColor: Color(0xFFEDE7F6),
      ),
      const Bank(
        id: 'icfc',
        name: 'ICFC Finance Limited',
        logoPath: 'assets/banks/icfc.png',
        backgroundColor: Color(0xFFFCE4EC),
      ),
      const Bank(
        id: 'janaki',
        name: 'Janaki Finance Company Ltd',
        logoPath: 'assets/banks/janaki.png',
        backgroundColor: Color(0xFFE0F7FA),
      ),
      const Bank(
        id: 'jyoti',
        name: 'Jyoti Bikas Bank Limited',
        logoPath: 'assets/banks/jyoti.png',
        backgroundColor: Color(0xFFEFF8FF),
      ),
      const Bank(
        id: 'kamana',
        name: 'Kamana Sewa Bikas Bank Limited',
        logoPath: 'assets/banks/kamana.png',
        backgroundColor: Color(0xFFE8F5E9),
      ),
      const Bank(
        id: 'kumari',
        name: 'Kumari Bank Limited',
        logoPath: 'assets/banks/kumari.png',
        isPopular: true,
        backgroundColor: Color(0xFFF3E5F5),
      ),
      const Bank(
        id: 'laxmi_sunrise',
        name: 'LaxmiSunrise Bank Limited',
        logoPath: 'assets/banks/laxmi_sunrise.png',
        isPopular: true,
        backgroundColor: Color(0xFFFFEBEE),
      ),
      const Bank(
        id: 'lumbini',
        name: 'Lumbini Bikas Bank Limited',
        logoPath: 'assets/banks/lumbini.png',
        backgroundColor: Color(0xFFE1F5FE),
      ),
      const Bank(
        id: 'machhapuchhre',
        name: 'Machhapuchchhre Bank Limited',
        logoPath: 'assets/banks/machhapuchhre.png',
        isPopular: true,
        backgroundColor: Color(0xFFEDE7F6),
      ),
      const Bank(
        id: 'manjushree',
        name: 'Manjushree Finance Limited',
        logoPath: 'assets/banks/manjushree.png',
        backgroundColor: Color(0xFFF3E5F5),
      ),
      const Bank(
        id: 'miteri',
        name: 'Miteri Development Bank Limited',
        logoPath: 'assets/banks/miteri.png',
        backgroundColor: Color(0xFFE0F2F1),
      ),
      const Bank(
        id: 'muktinath',
        name: 'Muktinath Bikas Bank Limited',
        logoPath: 'assets/banks/muktinath.png',
        backgroundColor: Color(0xFFF1F8E9),
      ),
      const Bank(
        id: 'nic_asia',
        name: 'NIC Asia Bank Limited',
        logoPath: 'assets/banks/nic_asia.png',
        isPopular: true,
        backgroundColor: Color(0xFFFBE9E7),
      ),
      const Bank(
        id: 'nmb',
        name: 'NMB Bank Limited',
        logoPath: 'assets/banks/nmb.png',
        isPopular: true,
        backgroundColor: Color(0xFFE3F2FD),
      ),
      const Bank(
        id: 'nabil',
        name: 'Nabil Bank Limited',
        logoPath: 'assets/banks/nabil.png',
        isPopular: true,
        backgroundColor: Color(0xFFE8EAF6),
      ),
      const Bank(
        id: 'nepal_bank',
        name: 'Nepal Bank Limited',
        logoPath: 'assets/banks/nepal_bank.png',
        backgroundColor: Color(0xFFE0F7FA),
      ),
      const Bank(
        id: 'nifra',
        name: 'Nepal Infrastructure Bank Ltd',
        logoPath: 'assets/banks/nifra.png',
        backgroundColor: Color(0xFFF3E5F5),
      ),
      const Bank(
        id: 'nepal_sbi',
        name: 'Nepal SBI Bank Limited',
        logoPath: 'assets/banks/nepal_sbi.png',
        backgroundColor: Color(0xFFE8F5E9),
      ),
      const Bank(
        id: 'pokhara',
        name: 'Pokhara Finance Ltd',
        logoPath: 'assets/banks/pokhara.png',
        backgroundColor: Color(0xFFE1F5FE),
      ),
      const Bank(
        id: 'prabhu',
        name: 'Prabhu Bank Limited',
        logoPath: 'assets/banks/prabhu.png',
        isPopular: true,
        backgroundColor: Color(0xFFFFF3E0),
      ),
      const Bank(
        id: 'prime',
        name: 'Prime Commercial Bank Limited',
        logoPath: 'assets/banks/prime.png',
        isPopular: true,
        backgroundColor: Color(0xFFE8EAF6),
      ),
      const Bank(
        id: 'progressive',
        name: 'Progressive Finance Co. Ltd',
        logoPath: 'assets/banks/progressive.png',
        backgroundColor: Color(0xFFE0F2F1),
      ),
      const Bank(
        id: 'rastriya',
        name: 'Rastriya Banijya Bank Limited',
        logoPath: 'assets/banks/rastriya.png',
        isPopular: true,
        backgroundColor: Color(0xFFF1F8E9),
      ),
      const Bank(
        id: 'reliance',
        name: 'Reliance Finance Ltd',
        logoPath: 'assets/banks/reliance.png',
        backgroundColor: Color(0xFFEDE7F6),
      ),
      const Bank(
        id: 'samriddhi',
        name: 'Samriddhi Finance Company Ltd',
        logoPath: 'assets/banks/samriddhi.png',
        backgroundColor: Color(0xFFFCE4EC),
      ),
      const Bank(
        id: 'sanima',
        name: 'Sanima Bank Ltd',
        logoPath: 'assets/banks/sanima.png',
        isPopular: true,
        backgroundColor: Color(0xFFE0F7FA),
      ),
      const Bank(
        id: 'saptakoshi',
        name: 'Saptakoshi Development Bank Ltd',
        logoPath: 'assets/banks/saptakoshi.png',
        backgroundColor: Color(0xFFEFF8FF),
      ),
      const Bank(
        id: 'shangrila',
        name: 'Shangrila Development Bank Ltd',
        logoPath: 'assets/banks/shangrila.png',
        backgroundColor: Color(0xFFE8F5E9),
      ),
      const Bank(
        id: 'shine_resunga',
        name: 'Shine Resunga Development Bank Ltd',
        logoPath: 'assets/banks/shine_resunga.png',
        backgroundColor: Color(0xFFF3E5F5),
      ),
      const Bank(
        id: 'shree',
        name: 'Shree Investment & Finance Co. Ltd.',
        logoPath: 'assets/banks/shree.png',
        backgroundColor: Color(0xFFFFEBEE),
      ),
      const Bank(
        id: 'siddhartha',
        name: 'Siddhartha Bank Limited',
        logoPath: 'assets/banks/siddhartha.png',
        isPopular: true,
        backgroundColor: Color(0xFFE1F5FE),
      ),
      const Bank(
        id: 'sindu',
        name: 'Sindu Bikash Bank Limited',
        logoPath: 'assets/banks/sindu.png',
        backgroundColor: Color(0xFFEDE7F6),
      ),
      const Bank(
        id: 'scb',
        name: 'Standard Chartered Bank Nepal Limited',
        logoPath: 'assets/banks/scb.png',
        isPopular: true,
        backgroundColor: Color(0xFFF3E5F5),
      ),
      const Bank(
        id: 'mahalaxmi',
        name: 'Mahalaxmi Bikas Bank Ltd.',
        logoPath: 'assets/banks/mahalaxmi.png',
        backgroundColor: Color(0xFFE0F2F1),
      ),
      // Only show the "other_wallet" entry
      const Bank(
        id: 'other_wallet',
        name: 'Other Digital Wallet',
        logoPath: 'assets/icons/wallet.png',
        backgroundColor: Color(0xFF607D8B),
        icon: Icons.account_balance_wallet,
      ),
    ];
  }

  /// Get a list of popular digital wallets in Nepal
  static List<Bank> getNepaliDigitalWallets() {
    return [
      const Bank(
        id: 'esewa',
        name: 'eSewa',
        logoPath: 'assets/wallets/esewa.png',
        imageUrl: 'https://esewa.com.np/common/images/esewa_logo.png',
        backgroundColor: Color(0xFF60BB46),
        isPopular: true,
        icon: Icons.account_balance_wallet,
      ),
      const Bank(
        id: 'khalti',
        name: 'Khalti',
        logoPath: 'assets/wallets/khalti.png',
        imageUrl: 'https://khalti.com/static/images/khalti-logo.svg',
        backgroundColor: Color(0xFF5C2D91),
        isPopular: true,
        icon: Icons.account_balance_wallet,
      ),
      const Bank(
        id: 'imepay',
        name: 'IME Pay',
        logoPath: 'assets/wallets/imepay.png',
        imageUrl: 'https://imepay.com.np/wp-content/uploads/2021/08/logo-full.png',
        backgroundColor: Color(0xFFE91E63),
        isPopular: true,
        icon: Icons.account_balance_wallet,
      ),
      const Bank(
        id: 'connectips',
        name: 'ConnectIPS',
        logoPath: 'assets/wallets/connectips.png',
        imageUrl: 'https://connectips.com/images/logo.png',
        backgroundColor: Color(0xFF1565C0),
        icon: Icons.account_balance_wallet,
      ),
      const Bank(
        id: 'fonepay',
        name: 'Fonepay',
        logoPath: 'assets/wallets/fonepay.png',
        imageUrl: 'https://fonepay.com/assets/img/logo-fonepay.png',
        backgroundColor: Color(0xFF00B8D4),
        icon: Icons.account_balance_wallet,
      ),
      const Bank(
        id: 'prabhupay',
        name: 'Prabhu Pay',
        logoPath: 'assets/wallets/prabhupay.png',
        imageUrl: 'https://prabhupay.com/images/logo.png',
        backgroundColor: Color(0xFFFF5722),
        icon: Icons.account_balance_wallet,
      ),
      const Bank(
        id: 'qpay',
        name: 'QPay',
        logoPath: 'assets/wallets/qpay.png',
        imageUrl: 'https://qpay.com.np/assets/img/logo.png',
        backgroundColor: Color(0xFF6A1B9A),
        icon: Icons.account_balance_wallet,
      ),
      const Bank(
        id: 'ipay',
        name: 'iPay',
        logoPath: 'assets/wallets/ipay.png',
        imageUrl: 'https://ipay.com.np/assets/images/logo.png',
        backgroundColor: Color(0xFF29B6F6),
        icon: Icons.account_balance_wallet,
      ),
      const Bank(
        id: 'moco',
        name: 'MoCo',
        logoPath: 'assets/wallets/moco.png',
        imageUrl: 'https://moco.com.np/assets/img/logo.png',
        backgroundColor: Color(0xFFFF5722),
        icon: Icons.account_balance_wallet,
      ),
    ];
  }
} 