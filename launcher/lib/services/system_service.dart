import 'dart:io';

/// Servizio per interagire con il sistema Linux sottostante.
/// Gestisce: spegnimento, luminosità, volume, WiFi, stampanti.
class SystemService {
  // Singleton
  static final SystemService _instance = SystemService._internal();
  factory SystemService() => _instance;
  SystemService._internal();

  /// Verifica se siamo su Linux
  bool get isLinux => Platform.isLinux;

  /// Spegne il computer
  /// Usa systemctl poweroff su Linux
  Future<bool> shutdown() async {
    if (!isLinux) {
      // Su macOS/Windows non eseguiamo lo spegnimento per sicurezza durante lo sviluppo
      print('[SystemService] Spegnimento simulato (non su Linux)');
      return false;
    }

    try {
      // Prova prima con systemctl (sistemi systemd)
      final result = await Process.run('systemctl', ['poweroff']);
      if (result.exitCode == 0) {
        return true;
      }

      // Fallback a shutdown -h now
      final fallbackResult = await Process.run('shutdown', ['-h', 'now']);
      return fallbackResult.exitCode == 0;
    } catch (e) {
      print('[SystemService] Errore spegnimento: $e');
      return false;
    }
  }

  /// Riavvia il computer
  Future<bool> reboot() async {
    if (!isLinux) {
      print('[SystemService] Riavvio simulato (non su Linux)');
      return false;
    }

    try {
      final result = await Process.run('systemctl', ['reboot']);
      return result.exitCode == 0;
    } catch (e) {
      print('[SystemService] Errore riavvio: $e');
      return false;
    }
  }

  /// Ottiene la luminosità corrente dello schermo (0.0 - 1.0)
  Future<double> getBrightness() async {
    if (!isLinux) return 1.0;

    try {
      // Prova a leggere dal backlight di sistema
      final backlightDir = Directory('/sys/class/backlight');
      if (await backlightDir.exists()) {
        final entries = await backlightDir.list().toList();
        if (entries.isNotEmpty) {
          final backlightPath = entries.first.path;
          final maxBrightness = int.parse(
            await File('$backlightPath/max_brightness').readAsString().then((s) => s.trim())
          );
          final currentBrightness = int.parse(
            await File('$backlightPath/brightness').readAsString().then((s) => s.trim())
          );
          return currentBrightness / maxBrightness;
        }
      }

      // Fallback: usa xrandr per ottenere la luminosità
      final result = await Process.run('xrandr', ['--verbose']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'Brightness:\s+([\d.]+)').firstMatch(output);
        if (match != null) {
          return double.tryParse(match.group(1)!) ?? 1.0;
        }
      }
    } catch (e) {
      print('[SystemService] Errore lettura luminosità: $e');
    }
    return 1.0;
  }

  /// Imposta la luminosità dello schermo (0.0 - 1.0)
  Future<bool> setBrightness(double value) async {
    if (!isLinux) {
      print('[SystemService] Luminosità simulata: $value');
      return false;
    }

    // Limita il valore tra 0.1 e 1.0 (non permettiamo schermo completamente nero)
    value = value.clamp(0.1, 1.0);

    try {
      // Prova con il backlight di sistema
      final backlightDir = Directory('/sys/class/backlight');
      if (await backlightDir.exists()) {
        final entries = await backlightDir.list().toList();
        if (entries.isNotEmpty) {
          final backlightPath = entries.first.path;
          final maxBrightness = int.parse(
            await File('$backlightPath/max_brightness').readAsString().then((s) => s.trim())
          );
          final newBrightness = (maxBrightness * value).round();

          // Richiede permessi root, prova con pkexec
          final result = await Process.run('pkexec', [
            'bash', '-c', 'echo $newBrightness > $backlightPath/brightness'
          ]);
          if (result.exitCode == 0) return true;
        }
      }

      // Fallback: usa xrandr
      // Prima ottieni il nome del display
      final queryResult = await Process.run('xrandr', ['--query']);
      if (queryResult.exitCode == 0) {
        final output = queryResult.stdout as String;
        final match = RegExp(r'^(\S+)\s+connected', multiLine: true).firstMatch(output);
        if (match != null) {
          final displayName = match.group(1)!;
          final result = await Process.run('xrandr', [
            '--output', displayName,
            '--brightness', value.toStringAsFixed(2)
          ]);
          return result.exitCode == 0;
        }
      }
    } catch (e) {
      print('[SystemService] Errore impostazione luminosità: $e');
    }
    return false;
  }

  /// Ottiene il volume corrente (0.0 - 1.0)
  Future<double> getVolume() async {
    if (!isLinux) return 0.5;

    try {
      // Usa pactl (PulseAudio/PipeWire)
      final result = await Process.run('pactl', ['get-sink-volume', '@DEFAULT_SINK@']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'(\d+)%').firstMatch(output);
        if (match != null) {
          return int.parse(match.group(1)!) / 100.0;
        }
      }

      // Fallback: amixer
      final amixerResult = await Process.run('amixer', ['get', 'Master']);
      if (amixerResult.exitCode == 0) {
        final output = amixerResult.stdout as String;
        final match = RegExp(r'\[(\d+)%\]').firstMatch(output);
        if (match != null) {
          return int.parse(match.group(1)!) / 100.0;
        }
      }
    } catch (e) {
      print('[SystemService] Errore lettura volume: $e');
    }
    return 0.5;
  }

  /// Imposta il volume (0.0 - 1.0)
  Future<bool> setVolume(double value) async {
    if (!isLinux) {
      print('[SystemService] Volume simulato: $value');
      return false;
    }

    value = value.clamp(0.0, 1.0);
    final percentage = (value * 100).round();

    try {
      // Prova con pactl (PulseAudio/PipeWire)
      final result = await Process.run('pactl', [
        'set-sink-volume', '@DEFAULT_SINK@', '$percentage%'
      ]);
      if (result.exitCode == 0) return true;

      // Fallback: amixer
      final amixerResult = await Process.run('amixer', [
        'set', 'Master', '$percentage%'
      ]);
      return amixerResult.exitCode == 0;
    } catch (e) {
      print('[SystemService] Errore impostazione volume: $e');
    }
    return false;
  }

  /// Ottiene la lista delle reti WiFi disponibili
  Future<List<WifiNetwork>> getWifiNetworks() async {
    if (!isLinux) {
      // Reti di esempio per sviluppo
      return [
        WifiNetwork(ssid: 'Casa', signalStrength: 90, isSecured: true, isConnected: true),
        WifiNetwork(ssid: 'Vicino', signalStrength: 45, isSecured: true, isConnected: false),
      ];
    }

    try {
      // Usa nmcli per ottenere le reti
      final result = await Process.run('nmcli', [
        '-t', '-f', 'SSID,SIGNAL,SECURITY,IN-USE',
        'device', 'wifi', 'list'
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final networks = <WifiNetwork>[];

        for (final line in output.split('\n')) {
          if (line.isEmpty) continue;
          final parts = line.split(':');
          if (parts.length >= 4 && parts[0].isNotEmpty) {
            networks.add(WifiNetwork(
              ssid: parts[0],
              signalStrength: int.tryParse(parts[1]) ?? 0,
              isSecured: parts[2].isNotEmpty && parts[2] != '--',
              isConnected: parts[3] == '*',
            ));
          }
        }

        // Ordina per potenza del segnale
        networks.sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
        return networks;
      }
    } catch (e) {
      print('[SystemService] Errore lettura reti WiFi: $e');
    }
    return [];
  }

  /// Connette a una rete WiFi
  Future<bool> connectToWifi(String ssid, String? password) async {
    if (!isLinux) {
      print('[SystemService] Connessione WiFi simulata: $ssid');
      return false;
    }

    try {
      List<String> args;
      if (password != null && password.isNotEmpty) {
        args = ['device', 'wifi', 'connect', ssid, 'password', password];
      } else {
        args = ['device', 'wifi', 'connect', ssid];
      }

      final result = await Process.run('nmcli', args);
      return result.exitCode == 0;
    } catch (e) {
      print('[SystemService] Errore connessione WiFi: $e');
    }
    return false;
  }

  /// Disconnette dalla rete WiFi corrente
  Future<bool> disconnectWifi() async {
    if (!isLinux) return false;

    try {
      final result = await Process.run('nmcli', ['device', 'disconnect', 'wlan0']);
      return result.exitCode == 0;
    } catch (e) {
      print('[SystemService] Errore disconnessione WiFi: $e');
    }
    return false;
  }

  /// Ottiene la lista delle stampanti disponibili
  Future<List<Printer>> getPrinters() async {
    if (!isLinux) {
      return [
        Printer(name: 'Stampante di prova', isDefault: true, status: 'Pronta'),
      ];
    }

    try {
      // Usa lpstat per ottenere le stampanti
      final result = await Process.run('lpstat', ['-p', '-d']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final printers = <Printer>[];

        String? defaultPrinter;
        final defaultMatch = RegExp(r'system default destination: (\S+)').firstMatch(output);
        if (defaultMatch != null) {
          defaultPrinter = defaultMatch.group(1);
        }

        final printerMatches = RegExp(r'printer (\S+).*?(enabled|disabled)', multiLine: true)
            .allMatches(output);

        for (final match in printerMatches) {
          final name = match.group(1)!;
          final isEnabled = match.group(2) == 'enabled';
          printers.add(Printer(
            name: name,
            isDefault: name == defaultPrinter,
            status: isEnabled ? 'Pronta' : 'Non disponibile',
          ));
        }

        return printers;
      }
    } catch (e) {
      print('[SystemService] Errore lettura stampanti: $e');
    }
    return [];
  }

  /// Stampa un file
  Future<bool> printFile(String filePath, {String? printerName}) async {
    if (!isLinux) {
      print('[SystemService] Stampa simulata: $filePath');
      return false;
    }

    try {
      final args = <String>[];
      if (printerName != null) {
        args.addAll(['-P', printerName]);
      }
      args.add(filePath);

      final result = await Process.run('lp', args);
      return result.exitCode == 0;
    } catch (e) {
      print('[SystemService] Errore stampa: $e');
    }
    return false;
  }
}

/// Modello per una rete WiFi
class WifiNetwork {
  final String ssid;
  final int signalStrength; // 0-100
  final bool isSecured;
  final bool isConnected;

  WifiNetwork({
    required this.ssid,
    required this.signalStrength,
    required this.isSecured,
    required this.isConnected,
  });
}

/// Modello per una stampante
class Printer {
  final String name;
  final bool isDefault;
  final String status;

  Printer({
    required this.name,
    required this.isDefault,
    required this.status,
  });
}
