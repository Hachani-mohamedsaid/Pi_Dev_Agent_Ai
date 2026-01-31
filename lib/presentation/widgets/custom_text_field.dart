import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.readOnly = false,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.controller,
    this.validator,
    this.keyboardType,
    this.onChanged,
    this.focusNode,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final bool readOnly;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _errorText;
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();

  String? _validateValue(String? value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorText = error;
            });
          }
        });
      }
      return error;
    }
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorText = null;
          });
        }
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: isMobile ? 4 : 8,
            bottom: isMobile ? 6 : 8,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: AppColors.textCyan200,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: isMobile ? 50 : 56,
          child: TextFormField(
            key: _fieldKey,
            focusNode: widget.focusNode,
            controller: widget.controller,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            validator: _validateValue,
            onChanged: (value) {
              if (_errorText != null && mounted) {
                setState(() {
                  _errorText = null;
                });
              }
              widget.onChanged?.call(value);
            },
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: isMobile ? 15 : 16,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.4),
                fontSize: isMobile ? 15 : 16,
              ),
              prefixIcon: Icon(
                widget.icon,
                color: AppColors.cyan400.withOpacity(0.6),
                size: isMobile ? 20 : 22,
              ),
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixIconTap,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: widget.suffixIcon,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                borderSide: BorderSide(
                  color: _errorText != null ? Colors.red : AppColors.borderCyan,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                borderSide: BorderSide(
                  color: _errorText != null ? Colors.red : AppColors.borderCyan,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                borderSide: BorderSide(
                  color: _errorText != null ? Colors.red : AppColors.cyan400,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 14 : 16,
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              isDense: true,
            ),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: EdgeInsets.only(
              top: isMobile ? 4 : 6,
              left: isMobile ? 4 : 8,
            ),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: Colors.red,
                fontSize: isMobile ? 12 : 13,
              ),
            ),
          ),
      ],
    );
  }
}
