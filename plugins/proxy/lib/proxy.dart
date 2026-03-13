import 'dart:io';

import "package:path/path.dart";

import 'proxy_platform_interface.dart';

enum ProxyTypes { http, https, socks }

class Proxy extends ProxyPlatform {
  @override
  Future<bool?> startProxy(
    String host,
    int port, [
    List<String> bypassDomain = const [],
  ]) async {
    return switch (Platform.operatingSystem) {
      "macos" => await _startProxyWithMacos(host, port, bypassDomain),
      "linux" => await _startProxyWithLinux(host, port, bypassDomain),
      "windows" => await ProxyPlatform.instance.startProxy(host, port, bypassDomain),
      String() => false,
    };
  }

  @override
  Future<bool?> stopProxy() async {
    return switch (Platform.operatingSystem) {
      "macos" => await _stopProxyWithMacos(),
      "linux" => await _stopProxyWithLinux(),
      "windows" => await ProxyPlatform.instance.stopProxy(),
      String() => false,
    };
  }

  Future<bool> _startProxyWithLinux(String host, int port, List<String> bypassDomain) async {
    try {
      final homeDir = Platform.environment['HOME']!;
      final configDir = join(homeDir, ".config");
      final cmdList = List<List<String>>.empty(growable: true);
      final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
      final isKDE = desktop == "KDE";
      if (isKDE) {
        cmdList.add(
          [
            "kwriteconfig5",
            "--file",
            "$configDir/kioslaverc",
            "--group",
            "Proxy Settings",
            "--key",
            "ProxyType",
            "1"
          ],
        );
        cmdList.add(
          [
            "kwriteconfig5",
            "--file",
            "$configDir/kioslaverc",
            "--group",
            "Proxy Settings",
            "--key",
            "NoProxyFor",
            bypassDomain.join(",")
          ],
        );
      } else {
        cmdList.add(
          ["gsettings", "set", "org.gnome.system.proxy", "mode", "manual"],
        );
        final ignoreHosts = "\"['${bypassDomain.join("', '")}']\"";
        cmdList.add(
          [
            "gsettings",
            "set",
            "org.gnome.system.proxy",
            "ignore-hosts",
            ignoreHosts
          ],
        );
      }
      for (final type in ProxyTypes.values) {
        if (!isKDE) {
          cmdList.add(
            [
              "gsettings",
              "set",
              "org.gnome.system.proxy.${type.name}",
              "host",
              host
            ],
          );
          cmdList.add(
            [
              "gsettings",
              "set",
              "org.gnome.system.proxy.${type.name}",
              "port",
              "$port"
            ],
          );
          cmdList.add(
            [
              "gsettings",
              "set",
              "org.gnome.system.proxy.${type.name}",
              "port",
              "$port"
            ],
          );
          cmdList.add(
            [
              "gsettings",
              "set",
              "org.gnome.system.proxy.${type.name}",
              "port",
              "$port"
            ],
          );
        }
        if (isKDE) {
          cmdList.add(
            [
              "kwriteconfig5",
              "--file",
              "$configDir/kioslaverc",
              "--group",
              "Proxy Settings",
              "--key",
              "${type.name}Proxy",
              "${type.name}://$host:$port"
            ],
          );
        }
      }
      for (final cmd in cmdList) {
        await Process.run(cmd[0], cmd.sublist(1), runInShell: true);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _stopProxyWithLinux() async {
    try {
      final homeDir = Platform.environment['HOME']!;
      final configDir = join(homeDir, ".config/");
      final cmdList = List<List<String>>.empty(growable: true);
      final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
      final isKDE = desktop == "KDE";
      if (isKDE) {
        cmdList.add(
          [
            "kwriteconfig5",
            "--file",
            "$configDir/kioslaverc",
            "--group",
            "Proxy Settings",
            "--key",
            "ProxyType",
            "0"
          ],
        );
      } else {
        cmdList.add(
          ["gsettings", "set", "org.gnome.system.proxy", "mode", "none"],
        );
      }
      for (final cmd in cmdList) {
        await Process.run(cmd[0], cmd.sublist(1));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _startProxyWithMacos(String host, int port, List<String> bypassDomain) async {
    try {
      final devices = await _getNetworkDeviceListWithMacos();
      for (final dev in devices) {
        await Future.wait([
          Process.run(
            "/usr/sbin/networksetup",
            ["-setwebproxystate", dev, "on"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            ["-setwebproxy", dev, host, "$port"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            ["-setsecurewebproxystate", dev, "on"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            ["-setsecurewebproxy", dev, host, "$port"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            ["-setsocksfirewallproxystate", dev, "on"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            ["-setsocksfirewallproxy", dev, host, "$port"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            [
              "-setproxybypassdomains",
              dev,
              bypassDomain.join(","),
            ],
          ),
        ]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _stopProxyWithMacos() async {
    try {
      final devices = await _getNetworkDeviceListWithMacos();
      for (final dev in devices) {
        await Future.wait([
          Process.run(
            "/usr/sbin/networksetup",
            ["-setautoproxystate", dev, "off"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            ["-setwebproxystate", dev, "off"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            ["-setsecurewebproxystate", dev, "off"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            ["-setsocksfirewallproxystate", dev, "off"],
          ),
          Process.run(
            "/usr/sbin/networksetup",
            ["-setproxybypassdomains", dev, ""],
          ),
        ]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> _getNetworkDeviceListWithMacos() async {
    final res = await Process.run(
        "/usr/sbin/networksetup", ["-listallnetworkservices"]);
    final lines = res.stdout.toString().split("\n");
    lines.removeWhere((element) => element.contains("*"));
    return lines;
  }
}
