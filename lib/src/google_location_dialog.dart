import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_location_dialog/google_location_dialog.dart';

/// Callback called when user press an Address.
/// It receive the selected address.
typedef OnSelectAddress = FutureOr<void> Function(GoogleAddress address);

/// Callback called when user press keyboard main button or search icon
/// in [_SearchBar]. Used to search address
typedef OnSearchAddress = FutureOr<void> Function();

class DialogTexts {
  DialogTexts({
    required this.searchHint,
    required this.onEmpty,
    required this.close,
    required this.onError,
  });

  final String searchHint;
  final String onEmpty;
  final String close;
  final String onError;
}

class GoogleLocationDialog extends StatefulWidget {
  const GoogleLocationDialog({
    required AddressSearcherClient addressSearcherClient,
    required OnSelectAddress onSelectedAddress,
    required DialogTexts dialogTexts,
    super.key,
  })  : _onSelectedAddress = onSelectedAddress,
        _addressSearcherClient = addressSearcherClient,
        _dialogTexts = dialogTexts;

  final AddressSearcherClient _addressSearcherClient;
  final OnSelectAddress _onSelectedAddress;
  final DialogTexts _dialogTexts;

  @override
  State<GoogleLocationDialog> createState() => _GoogleLocationDialog();
}

class _GoogleLocationDialog extends State<GoogleLocationDialog> {
  late final TextEditingController _controller;
  final _addresses = <GoogleAddress>[];
  var _isloading = false;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StatefullDialog(
      builder: (context, innerSetState) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints.expand(
                height: constraints.maxHeight * .9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _SearchBar(
                    controller: _controller,
                    onSearchAddress: () => _searchLocation(innerSetState),
                    searchHint: widget._dialogTexts.searchHint,
                  ),
                  if (_isloading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_hasError)
                    Expanded(
                      child: _CenterLabel(
                        label: widget._dialogTexts.onError,
                      ),
                    )
                  else if (_addresses.isNotEmpty)
                    Expanded(
                      child: _PlacesList(
                        addresses: _addresses,
                        onSelectedAddress: widget._onSelectedAddress,
                      ),
                    )
                  else
                    Expanded(
                      child: _CenterLabel(
                        label: widget._dialogTexts.onEmpty,
                      ),
                    ),
                  _ButtonBar(
                    closeLabel: widget._dialogTexts.close,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _searchLocation(StateSetter innerSetState) async {
    if (_controller.text.trim().isEmpty) return;

    innerSetState(() {
      _isloading = true;
      _hasError = false;
    });

    try {
      final addresses =
          await widget._addressSearcherClient.searchAddressByQuery(
        _controller.text,
      );
      innerSetState(() => _isloading = false);
      innerSetState(
        () {
          _addresses
            ..clear()
            ..addAll(addresses);
        },
      );
    } catch (_) {
      innerSetState(() {
        _isloading = false;
        _hasError = true;
      });
      innerSetState(
        _addresses.clear,
      );
    }
  }
}

class _StatefullDialog extends StatelessWidget {
  const _StatefullDialog({
    required StatefulWidgetBuilder builder,
  }) : _builder = builder;

  final StatefulWidgetBuilder _builder;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, innerSetState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: _builder(context, innerSetState),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required TextEditingController controller,
    required OnSearchAddress onSearchAddress,
    required String searchHint,
  })  : _onSearchAddress = onSearchAddress,
        _controller = controller,
        _searchHint = searchHint;

  final TextEditingController _controller;
  final OnSearchAddress _onSearchAddress;
  final String _searchHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Row(
            children: [
              Flexible(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onEditingComplete: _onSearchAddress,
                  decoration: InputDecoration(
                    hintText: _searchHint,
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: _onSearchAddress,
                      icon: const Icon(Icons.search_rounded),
                    ),
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          color: Colors.black54,
        ),
      ],
    );
  }
}

class _PlacesList extends StatelessWidget {
  const _PlacesList({
    required List<GoogleAddress> addresses,
    required OnSelectAddress onSelectedAddress,
  })  : _addresses = addresses,
        _onSelectAddress = onSelectedAddress;

  final List<GoogleAddress> _addresses;
  final OnSelectAddress _onSelectAddress;

  @override
  Widget build(BuildContext context) {
    const divider = Divider(
      height: 1,
    );
    return ListView.separated(
      separatorBuilder: (context, index) => divider,
      itemCount: _addresses.length,
      itemBuilder: _builItem,
    );
  }

  Widget? _builItem(BuildContext context, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      title: Text(_addresses[index].name),
      onTap: () {
        _onSelectAddress(_addresses[index]);
        Navigator.pop(context);
      },
    );
  }
}

class _ButtonBar extends StatelessWidget {
  const _ButtonBar({
    required String closeLabel,
  }) : _closeLabel = closeLabel;

  final String _closeLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        const Divider(
          height: 1,
          color: Colors.black54,
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                style: ElevatedButton.styleFrom(
                  maximumSize: const Size(double.infinity, 36),
                  minimumSize: const Size(0, 36),
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(_closeLabel),
              ),
            ),
          ],
        )
      ],
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({required String label}) : _label = label;

  final String _label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(_label),
    );
  }
}
