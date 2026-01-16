import 'package:flutter/material.dart';
import 'package:close_view/core/constants/app_colors.dart';

class MicButton extends StatelessWidget {
  final bool estaEscuchando;
  final VoidCallback onPressed;


  const MicButton(
      {super.key, required this.estaEscuchando, required this.onPressed});


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: estaEscuchando ? Colors.redAccent : AppColors.acento,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (estaEscuchando ? Colors.red : AppColors.acento)
                    .withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 5,
              )
            ]
        ),
        child: Icon(
          estaEscuchando ? Icons.stop : Icons.mic,
          size: 35,
          color: AppColors.fondo,
        ),
      ),
    );
  }
}