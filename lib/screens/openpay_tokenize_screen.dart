import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OpenpayTokenizeResult {
  final String tokenId;
  final String deviceSessionId;

  OpenpayTokenizeResult({required this.tokenId, required this.deviceSessionId});
}

class OpenpayTokenizeScreen extends StatefulWidget {
  final String merchantId;
  final String publicKey;

  const OpenpayTokenizeScreen({
    super.key,
    required this.merchantId,
    required this.publicKey,
  });

  @override
  State<OpenpayTokenizeScreen> createState() => _OpenpayTokenizeScreenState();
}

class _OpenpayTokenizeScreenState extends State<OpenpayTokenizeScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  void _forceFocusCardNumber() {
    _controller.runJavaScript("""
      try {
        var el = document.getElementById('card_number');
        if (el) { el.focus(); }
      } catch (e) {}
    """);
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'OpenpayChannel',
        onMessageReceived: (message) {
          try {
            final Map<String, dynamic> data =
                json.decode(message.message) as Map<String, dynamic>;
            final tokenId = (data['tokenId'] ?? '').toString().trim();
            final deviceSessionId = (data['deviceSessionId'] ?? '').toString().trim();

            if (tokenId.isEmpty || deviceSessionId.isEmpty) {
              final err = (data['error'] ?? 'Tokenización fallida').toString();
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(err)));
              }
              return;
            }

            Navigator.of(context).pop(OpenpayTokenizeResult(
              tokenId: tokenId,
              deviceSessionId: deviceSessionId,
            ));
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
              });
            }
          },
          onProgress: (progress) {
            // Algunos WebViews no disparan onPageFinished si hay scripts externos.
            // Deja de bloquear la pantalla cuando ya hay progreso suficiente.
            if (mounted && progress >= 70 && _loading) {
              setState(() {
                _loading = false;
              });
              _forceFocusCardNumber();
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
              });
            }
            _forceFocusCardNumber();
          },
        ),
      )
      ..loadHtmlString(_buildHtml(widget.merchantId, widget.publicKey));

    // Failsafe: evita que un spinner permanente bloquee los inputs.
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _loading) {
        setState(() {
          _loading = false;
        });
      }
    });
  }

  String _buildHtml(String merchantId, String publicKey) {
    final safeMerchant = merchantId.replaceAll("'", "\\'");
    final safeKey = publicKey.replaceAll("'", "\\'");

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="https://openpay.s3.amazonaws.com/openpay.v1.min.js"></script>
    <script type="text/javascript" src="https://openpay.s3.amazonaws.com/openpay-data.v1.min.js"></script>
    <style>
      body { font-family: Arial, sans-serif; padding: 16px; }
      .field { margin-bottom: 12px; }
      input { width: 100%; padding: 10px; font-size: 16px; }
      button { width: 100%; padding: 12px; font-size: 16px; }
      .hint { color: #666; font-size: 12px; margin-top: 4px; }
      .err { color: #b00020; font-size: 14px; margin: 8px 0; }
    </style>
  </head>
  <body>
    <h3>Pagar con tarjeta</h3>
    <div class="field">
      <input id="holder_name" type="text" placeholder="Nombre del titular" autocapitalize="words" autocorrect="off" autocomplete="off" />
    </div>
    <div class="field">
      <input id="card_number" type="tel" placeholder="Número de tarjeta" inputmode="numeric" autocorrect="off" autocomplete="off" />
      <div class="hint">Ejemplo sandbox: 4111111111111111</div>
    </div>
    <div class="field">
      <input id="expiration_month" type="tel" placeholder="Mes (MM)" inputmode="numeric" autocorrect="off" autocomplete="off" />
    </div>
    <div class="field">
      <input id="expiration_year" type="tel" placeholder="Año (YY)" inputmode="numeric" autocorrect="off" autocomplete="off" />
    </div>
    <div class="field">
      <input id="cvv2" type="password" placeholder="CVV" inputmode="numeric" autocorrect="off" autocomplete="off" />
    </div>
    <div id="err" class="err"></div>
    <button onclick="createToken()">Generar token</button>

    <script>
      OpenPay.setId('$safeMerchant');
      OpenPay.setApiKey('$safeKey');
      OpenPay.setSandboxMode(true);

      var deviceSessionId = OpenPay.deviceData.setup();

      function send(msg) {
        if (window.OpenpayChannel && window.OpenpayChannel.postMessage) {
          window.OpenpayChannel.postMessage(msg);
        } else if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('OpenpayChannel', msg);
        }
      }

      function createToken() {
        document.getElementById('err').innerText = '';

        var cardData = {
          holder_name: document.getElementById('holder_name').value,
          card_number: document.getElementById('card_number').value,
          expiration_month: document.getElementById('expiration_month').value,
          expiration_year: document.getElementById('expiration_year').value,
          cvv2: document.getElementById('cvv2').value
        };

        OpenPay.token.create(cardData, function (response) {
          var tokenId = response.data && response.data.id ? response.data.id : '';
          send(JSON.stringify({ tokenId: tokenId, deviceSessionId: deviceSessionId }));
        }, function (response) {
          var desc = response.data && response.data.description ? response.data.description : 'Error creando token.';
          document.getElementById('err').innerText = desc;
          send(JSON.stringify({ tokenId: '', deviceSessionId: '', error: desc }));
        });
      }

      // Fix Android: fuerza el foco real del input y muestra teclado.
      function bindFocus(id) {
        var el = document.getElementById(id);
        if (!el) return;
        el.addEventListener('click', function() {
          try { el.focus(); el.scrollIntoView({behavior: 'smooth', block: 'center'}); } catch(e) {}
        });
        el.addEventListener('focus', function() {
          try { el.scrollIntoView({behavior: 'smooth', block: 'center'}); } catch(e) {}
        });
        el.addEventListener('touchend', function() {
          try { el.focus(); el.scrollIntoView({behavior: 'smooth', block: 'center'}); } catch(e) {}
        });
      }

      setTimeout(function(){
        bindFocus('holder_name');
        bindFocus('card_number');
        bindFocus('expiration_month');
        bindFocus('expiration_year');
        bindFocus('cvv2');
        try { document.getElementById('card_number').focus(); } catch(e) {}
      }, 300);

      // Reintenta foco un par de veces por si el teclado no aparece en el primer render.
      (function focusRetry(){
        var tries = 0;
        var timer = setInterval(function(){
          tries++;
          try {
            var el = document.getElementById('card_number');
            if (el) { el.focus(); }
          } catch(e) {}
          if (tries >= 6) { clearInterval(timer); }
        }, 400);
      })();

      // Si el usuario toca cualquier parte del formulario, forzamos foco al input.
      document.addEventListener('touchend', function(){
        try {
          var active = document.activeElement;
          if (!active || active.tagName !== 'INPUT') {
            var el = document.getElementById('card_number');
            if (el) { el.focus(); }
          }
        } catch(e) {}
      }, {passive:true});
    </script>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final title = kIsWeb ? 'Openpay (Web)' : 'Openpay';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const IgnorePointer(
              ignoring: true,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
