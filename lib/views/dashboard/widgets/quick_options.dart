import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TUNButton extends StatelessWidget {
  const TUNButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        onPressed: () {
          showSheet(
            context: context,
            builder: (_, type) {
              return AdaptiveSheetScaffold(
                type: type,
                body: generateListView(
                  generateSection(
                    items: [
                      if (system.isDesktop) const TUNItem(),
                      if (system.isMacOS) const AutoSetSystemDnsItem(),
                      const TunStackItem(),
                    ],
                  ),
                ),
                title: appLocalizations.tun,
              );
            },
          );
        },
        info: Info(
          label: appLocalizations.tun,
          iconData: Icons.stacked_line_chart,
        ),
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.options,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.adjustSize(-2).toLight,
                  ),
                ),
              ),
              Consumer(
                builder: (_, ref, _) {
                  final enable = ref.watch(
                    patchClashConfigProvider.select(
                      (state) => state.tun.enable,
                    ),
                  );
                  return Switch(
                    value: enable,
                    onChanged: (value) {
                      ref
                          .read(patchClashConfigProvider.notifier)
                          .update((state) => state.copyWith.tun(enable: value));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SystemProxyButton extends StatelessWidget {
  const SystemProxyButton({super.key});

  @override
  Widget build(BuildContext context) {
    final height = system.isDesktop ? getWidgetHeight(2) : getWidgetHeight(1);
    return SizedBox(
      height: height,
      child: CommonCard(
        onPressed: () {
          showSheet(
            context: context,
            builder: (_, type) {
              return AdaptiveSheetScaffold(
                type: type,
                body: generateListView(
                  generateSection(
                    items: [
                      const SystemProxyItem(),
                      const SystemProxyHostItem(),
                      BypassDomainItem(),
                    ],
                  ),
                ),
                title: appLocalizations.systemProxy,
              );
            },
          );
        },
        info: Info(
          label: appLocalizations.systemProxy,
          iconData: Icons.shuffle,
        ),
        child: system.isDesktop
            ? _SystemProxyButtonDesktop(height: height)
            : _SystemProxyButtonSwitchOnly(),
      ),
    );
  }
}

class _SystemProxyButtonSwitchOnly extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: TooltipText(
              text: Text(
                appLocalizations.options,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.adjustSize(-2)
                    .toLight,
              ),
            ),
          ),
          Consumer(
            builder: (_, ref, _) {
              final systemProxy = ref.watch(
                networkSettingProvider.select((state) => state.systemProxy),
              );
              return Switch(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: systemProxy,
                onChanged: (value) {
                  ref.read(networkSettingProvider.notifier).update(
                      (state) => state.copyWith(systemProxy: value));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SystemProxyButtonDesktop extends ConsumerWidget {
  const _SystemProxyButtonDesktop({required this.height});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final systemProxyHost = ref.watch(
      networkSettingProvider.select((state) => state.systemProxyHost),
    );
    final optionsAsync = ref.watch(systemProxyHostOptionsProvider);

    return Container(
      padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.options,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.adjustSize(-2)
                        .toLight,
                  ),
                ),
              ),
              Switch(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: systemProxy,
                onChanged: (value) {
                  ref.read(networkSettingProvider.notifier).update(
                      (state) => state.copyWith(systemProxy: value));
                },
              ),
            ],
          ),
          SizedBox(height: 6),
          Expanded(
            child: optionsAsync.when(
              data: (options) {
                final optionsList =
                    List<SystemProxyHostOption>.from(options);
                final found = optionsList
                    .where((o) => o.address == systemProxyHost)
                    .toList();
                final current = found.isNotEmpty
                    ? found.first
                    : SystemProxyHostOption(
                        systemProxyHost,
                        appLocalizations
                            .systemProxyHostUnavailable(systemProxyHost),
                      );
                if (found.isEmpty) optionsList.add(current);
                if (optionsList.length < 2) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      current.address == '127.0.0.1'
                          ? appLocalizations.systemProxyHostLocalhost
                          : current.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.adjustSize(-1),
                    ),
                  );
                }
                final thumbColor =
                    Theme.of(context).colorScheme.secondaryContainer;
                return Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                  ),
                  child: CommonTabBar<SystemProxyHostOption>(
                    groupValue: current,
                    onValueChanged: (value) {
                      if (value != null) {
                        ref.read(networkSettingProvider.notifier).update(
                            (state) => state.copyWith(
                                systemProxyHost: value.address));
                      }
                    },
                    thumbColor: thumbColor,
                    children: Map.fromEntries(
                      optionsList.map(
                        (opt) => MapEntry(
                          opt,
                          Container(
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              opt.address == '127.0.0.1'
                                  ? appLocalizations.systemProxyHostLocalhost
                                  : opt.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.adjustSize(-1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => SizedBox.shrink(),
              error: (_, __) => SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class VpnButton extends StatelessWidget {
  const VpnButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        onPressed: () {
          showSheet(
            context: context,
            builder: (_, type) {
              return AdaptiveSheetScaffold(
                type: type,
                body: generateListView(
                  generateSection(
                    items: [
                      const VPNItem(),
                      const VpnSystemProxyItem(),
                      const TunStackItem(),
                    ],
                  ),
                ),
                title: 'VPN',
              );
            },
          );
        },
        info: Info(label: 'VPN', iconData: Icons.stacked_line_chart),
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.options,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.adjustSize(-2).toLight,
                  ),
                ),
              ),
              Consumer(
                builder: (_, ref, _) {
                  final enable = ref.watch(
                    vpnSettingProvider.select((state) => state.enable),
                  );
                  return Switch(
                    value: enable,
                    onChanged: (value) {
                      ref
                          .read(vpnSettingProvider.notifier)
                          .update((state) => state.copyWith(enable: value));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
