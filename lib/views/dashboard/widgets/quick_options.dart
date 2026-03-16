import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/state.dart';
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

class SystemProxyButton extends ConsumerWidget {
  const SystemProxyButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: getWidgetHeight(system.isDesktop ? 2 : 1),
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
                      if (system.isDesktop) const SystemProxyHostItem(),
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
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.adjustSize(-2).toLight,
                      ),
                    ),
                  ),
                  Consumer(
                    builder: (_, ref, _) {
                      final systemProxy = ref.watch(
                        networkSettingProvider.select(
                            (state) => state.systemProxy),
                      );
                      return Switch(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: systemProxy,
                        onChanged: (value) {
                          ref
                              .read(networkSettingProvider.notifier)
                              .update(
                                (state) => state.copyWith(systemProxy: value),
                              );
                        },
                      );
                    },
                  ),
                ],
              ),
              if (system.isDesktop) const _SystemProxyHostSelector(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemProxyHostSelector extends ConsumerWidget {
  const _SystemProxyHostSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemProxyHost = ref.watch(
      networkSettingProvider.select((state) => state.systemProxyHost),
    );
    final optionsAsync = ref.watch(systemProxyHostOptionsProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final options = await ref.read(systemProxyHostOptionsProvider.future);
          final optionsList = List<SystemProxyHostOption>.from(options);
          final found =
              optionsList.where((o) => o.address == systemProxyHost).toList();
          final current = found.isNotEmpty
              ? found.first
              : SystemProxyHostOption(
                  systemProxyHost,
                  appLocalizations.systemProxyHostUnavailable(systemProxyHost),
                );
          if (found.isEmpty) optionsList.add(current);
          final value = await globalState.showCommonDialog<SystemProxyHostOption>(
            child: OptionsDialog<SystemProxyHostOption>(
              title: appLocalizations.systemProxyHost,
              options: optionsList,
              value: current,
              textBuilder: (opt) =>
                  opt.address == '127.0.0.1'
                      ? appLocalizations.systemProxyHostLocalhost
                      : opt.label,
            ),
          );
          if (value != null && context.mounted) {
            ref.read(networkSettingProvider.notifier).update(
                (state) => state.copyWith(systemProxyHost: value.address));
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Row(
            children: [
              Expanded(
                child: TooltipText(
                  text: Text(
                    optionsAsync.when(
                      data: (options) {
                        final found = options
                            .where((o) => o.address == systemProxyHost)
                            .toList();
                        if (found.isNotEmpty) {
                          return Text(
                            found.first.address == '127.0.0.1'
                                ? appLocalizations.systemProxyHostLocalhost
                                : found.first.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.adjustSize(-2)
                                .toLight,
                          );
                        }
                        return Text(
                          appLocalizations.systemProxyHostUnavailable(
                              systemProxyHost),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.adjustSize(-2)
                              .toLight,
                        );
                      },
                      loading: () => Text(
                        systemProxyHost,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.adjustSize(-2)
                            .toLight,
                      ),
                      error: (_, __) => Text(
                        systemProxyHost,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.adjustSize(-2)
                            .toLight,
                      ),
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
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
