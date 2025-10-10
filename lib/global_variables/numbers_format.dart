import 'package:flutter/material.dart';

class NumbersFormat{
  NumbersFormat._internal();

  static final NumbersFormat _instance=NumbersFormat._internal();

  factory NumbersFormat()=>_instance;

  String format='#,##0.00';
}