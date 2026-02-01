import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final height = isMobile ? 52.0 : 56.0;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppColors.borderCyan,
              width: 1,
            ),
            backgroundColor: AppColors.backgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () {
            if (!isLoading) {
              onPressed();
            }
          },
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
