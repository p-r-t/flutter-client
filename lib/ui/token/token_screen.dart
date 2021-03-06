import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/token/token_actions.dart';
import 'package:invoiceninja_flutter/ui/app/app_bottom_bar.dart';
import 'package:invoiceninja_flutter/ui/app/forms/save_cancel_buttons.dart';
import 'package:invoiceninja_flutter/ui/app/list_scaffold.dart';
import 'package:invoiceninja_flutter/ui/app/entities/entity_actions_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/list_filter.dart';
import 'package:invoiceninja_flutter/ui/token/token_list_vm.dart';
import 'package:invoiceninja_flutter/ui/token/token_presenter.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

import 'token_screen_vm.dart';

class TokenScreen extends StatelessWidget {
  const TokenScreen({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  static const String route = '/$kSettings/$kSettingsTokens';

  final TokenScreenVM viewModel;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    //final company = state.company;
    final userCompany = state.userCompany;
    final localization = AppLocalization.of(context);
    final listUIState = state.uiState.tokenUIState.listUIState;
    final isInMultiselect = listUIState.isInMultiselect();

    return ListScaffold(
      entityType: EntityType.token,
      isChecked: isInMultiselect &&
          listUIState.selectedIds.length == viewModel.tokenList.length,
      showCheckbox: isInMultiselect,
      onHamburgerLongPress: () => store.dispatch(StartTokenMultiselect()),
      onCheckboxChanged: (value) {
        final tokens = viewModel.tokenList
            .map<TokenEntity>((tokenId) => viewModel.tokenMap[tokenId])
            .where((token) => value != listUIState.isSelected(token.id))
            .toList();

        handleTokenAction(context, tokens, EntityAction.toggleMultiselect);
      },
      appBarTitle: ListFilter(
        placeholder: localization.searchTokens,
        filter: state.tokenListState.filter,
        onFilterChanged: (value) {
          store.dispatch(FilterTokens(value));
        },
      ),
      appBarActions: [
        if (viewModel.isInMultiselect)
          SaveCancelButtons(
            saveLabel: localization.done,
            onSavePressed: listUIState.selectedIds.isEmpty
                ? null
                : (context) async {
                    final tokens = listUIState.selectedIds
                        .map<TokenEntity>(
                            (tokenId) => viewModel.tokenMap[tokenId])
                        .toList();

                    await showEntityActionsDialog(
                      entities: tokens,
                      context: context,
                      multiselect: true,
                      completer: Completer<Null>()
                        ..future.then<dynamic>(
                            (_) => store.dispatch(ClearTokenMultiselect())),
                    );
                  },
            onCancelPressed: (context) =>
                store.dispatch(ClearTokenMultiselect()),
          ),
      ],
      body: TokenListBuilder(),
      bottomNavigationBar: AppBottomBar(
        entityType: EntityType.token,
        tableColumns: TokenPresenter.getAllTableFields(userCompany),
        defaultTableColumns: TokenPresenter.getDefaultTableFields(userCompany),
        onSelectedSortField: (value) {
          store.dispatch(SortTokens(value));
        },
        sortFields: [
          TokenFields.name,
        ],
        onSelectedState: (EntityState state, value) {
          store.dispatch(FilterTokensByState(state));
        },
        onCheckboxPressed: () {
          if (store.state.tokenListState.isInMultiselect()) {
            store.dispatch(ClearTokenMultiselect());
          } else {
            store.dispatch(StartTokenMultiselect());
          }
        },
        onSelectedCustom1: (value) =>
            store.dispatch(FilterTokensByCustom1(value)),
        onSelectedCustom2: (value) =>
            store.dispatch(FilterTokensByCustom2(value)),
        onSelectedCustom3: (value) =>
            store.dispatch(FilterTokensByCustom3(value)),
        onSelectedCustom4: (value) =>
            store.dispatch(FilterTokensByCustom4(value)),
      ),
      floatingActionButton: state.prefState.isMenuFloated &&
              userCompany.canCreate(EntityType.token)
          ? FloatingActionButton(
              heroTag: 'token_fab',
              backgroundColor: Theme.of(context).primaryColorDark,
              onPressed: () {
                createEntityByType(
                    context: context, entityType: EntityType.token);
              },
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
              tooltip: localization.newToken,
            )
          : null,
    );
  }
}
