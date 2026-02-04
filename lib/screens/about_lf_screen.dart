import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutLfScreen extends StatelessWidget {
  static const String siteUrl = '';

  const AboutLfScreen({super.key});

  Future<void> _openWebsite(BuildContext context) async {
    if (siteUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta configurar el link del sitio web.')),
      );
      return;
    }

    final uri = Uri.tryParse(siteUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link inválido.')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de LF Comercializadora'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Acerca de nosotros',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 2),
              const Text(
                'LF Comercializadora',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              const SizedBox(height: 16),
              ClipOval(
                child: Image.asset(
                  'MicrosipAPI/LOGO2.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'En LF Comercializadora somos una empresa\n'
                'enfocada en la comercialización de materiales para\n'
                'la construcción, orientada a brindar soluciones\n'
                'prácticas, confiables y accesibles tanto para\n'
                'proyectos pequeños como para obras de mayor\n'
                'escala.\n',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.35),
              ),
              const Text(
                'Nuestro objetivo es facilitar el acceso a materiales\n'
                'de calidad a través de procesos simples, atención\n'
                'clara y una experiencia de compra eficiente,\n'
                'apoyándonos en la tecnología para acercarnos\n'
                'más a nuestros clientes.\n',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.35),
              ),
              const Text(
                'Trabajamos día a día para convertirnos en un\n'
                'aliado confiable en cada etapa del proyecto, desde\n'
                'la planeación hasta la ejecución.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.35),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => _openWebsite(context),
                  child: const Text('Visitar sitio web'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
