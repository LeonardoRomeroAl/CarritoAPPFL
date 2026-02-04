import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/product_service.dart';
import 'services/linea_service.dart';
import 'services/cart_service.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/linea_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/delivery_screen.dart';
import 'screens/address_selection_screen.dart';
import 'screens/checkout_review_screen.dart';
import 'screens/new_address_screen.dart';
import 'screens/edit_address_screen.dart';
import 'screens/order_success_screen.dart';
import 'screens/help_screen.dart';
import 'screens/purchases_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/purchase_detail_screen.dart';
import 'screens/personal_data_screen.dart';
import 'screens/my_addresses_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/terms_and_conditions_screen.dart';
import 'screens/about_lf_screen.dart';
import 'screens/tracking_list_screen.dart';
import 'screens/tracking_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiService = ApiService();
  await apiService.init();

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (_) => ProductProvider(ProductService(apiService)),
          update: (_, auth, prev) => prev!..fetchProducts(), // Recargar si cambia Auth? o init
        ),
        ChangeNotifierProvider(create: (_) => LineaProvider(LineaService(apiService))),
        ChangeNotifierProvider(create: (_) => CartProvider(CartService(apiService))),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'Microsip POS Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF111927),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginCheckWrapper(),
          '/home': (context) => const HomeScreen(),
          '/cart': (context) => const CartScreen(),
          '/delivery': (context) => const DeliveryScreen(),
          '/address/select': (context) => const AddressSelectionScreen(),
          '/checkout-review': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
            return CheckoutReviewScreen(
              deliveryType: args['deliveryType'] as String? ?? 'domicilio',
              addressTitle: args['addressTitle'] as String? ?? '',
              addressLine: args['addressLine'] as String? ?? '',
            );
          },
          '/address/new': (context) => const NewAddressScreen(),
          '/address/edit': (context) => const EditAddressScreen(),
          '/order-success': (context) => const OrderSuccessScreen(),
          '/help': (context) => const HelpScreen(),
          '/purchases': (context) => const PurchasesScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/profile/personal': (context) => const PersonalDataScreen(),
          '/profile/addresses': (context) => const MyAddressesScreen(),
          '/profile/billing': (context) => const BillingScreen(),
          '/profile/settings': (context) => const SettingsScreen(),
          '/terms': (context) => const TermsAndConditionsScreen(),
          '/about': (context) => const AboutLfScreen(),
          '/purchase-detail': (context) => const PurchaseDetailScreen(),
          '/profile/tracking': (context) => const TrackingListScreen(),
          '/tracking-detail': (context) => const TrackingDetailScreen(),
        },
      ),
    );
  }
}

class LoginCheckWrapper extends StatefulWidget {
  const LoginCheckWrapper({super.key});

  @override
  State<LoginCheckWrapper> createState() => _LoginCheckWrapperState();
}

class _LoginCheckWrapperState extends State<LoginCheckWrapper> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}
