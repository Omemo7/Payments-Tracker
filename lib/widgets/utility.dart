import 'package:flutter/material.dart';
import 'package:intl/intl.dart';




class Utility {

  static String customNumberFormat(double number){
    String f='#,##0.00';
    return NumberFormat(f).format(number);
  }

  static Widget handleNumberAppearanceForOverflow({
    required double number,
    required Color color,
    required double fontSize,
    String preText ='',
    TextAlign textAlign = TextAlign.left,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Tooltip(
      preferBelow: false,
      message: customNumberFormat(number),
      child: Text(
        "$preText ${customNumberFormat(number)}" ,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        maxLines: 1,
        textAlign: textAlign,
      ),
    );
  }
}
