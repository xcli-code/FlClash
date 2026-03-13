import 'dart:io';

/// Represents one option for system proxy bind address (address + display label).
class SystemProxyHostOption {
  const SystemProxyHostOption(this.address, this.label);
  final String address;
  final String label;
}

/// Returns options for system proxy host: localhost plus LAN IPv4 addresses from
/// network interfaces (with interface name as label).
Future<List<SystemProxyHostOption>> getSystemProxyHostOptions() async {
  const localhostOption = SystemProxyHostOption('127.0.0.1', '127.0.0.1 (localhost)');
  final list = <SystemProxyHostOption>[localhostOption];
  try {
    final interfaces = await NetworkInterface.list(includeLoopback: false)
      ..sort((a, b) {
        if (a.isWifi && !b.isWifi) return -1;
        if (!a.isWifi && b.isWifi) return 1;
        if (a.includesIPv4 && !b.includesIPv4) return -1;
        if (!a.includesIPv4 && b.includesIPv4) return 1;
        return 0;
      });
    for (final interface in interfaces) {
      final addresses = interface.addresses.where((a) => a.isIPv4).toList();
      for (final addr in addresses) {
        list.add(SystemProxyHostOption(
          addr.address,
          '${addr.address} (${interface.name})',
        ));
      }
    }
  } catch (_) {}
  return list;
}

extension NetworkInterfaceExt on NetworkInterface {
  bool get isWifi {
    final nameLowCase = name.toLowerCase();
    if (nameLowCase.contains('wlan') ||
        nameLowCase.contains('wi-fi') ||
        nameLowCase == 'en0' ||
        nameLowCase == 'eth0') {
      return true;
    }

    return false;
  }

  bool get includesIPv4 {
    return addresses.any((addr) => addr.isIPv4);
  }
}

extension InternetAddressExt on InternetAddress {
  bool get isIPv4 {
    return type == InternetAddressType.IPv4;
  }
}
