import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {

  final String texto;
  final void Function() onClik;

  const ButtonWidget({
    required this.texto,
    required this.onClik,
    super.key,
    });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFFDB58),
        fixedSize: Size(110, 90),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onClik,
      child: Text(
        texto,
        style: TextStyle(
          color: Color(0xFF003366),
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
