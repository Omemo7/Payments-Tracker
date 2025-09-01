import 'package:payments_tracker_flutter/models/account_model.dart';

class ChosenAccount{
  ChosenAccount._internal();

  static final ChosenAccount _instance=ChosenAccount._internal();

  factory ChosenAccount()=>_instance;

  AccountModel? account;
}