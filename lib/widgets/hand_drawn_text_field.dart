import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 手绘风格文本输入框组件
class HandDrawnTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? prefixEmoji;
  final String? suffixEmoji;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final String? errorText;
  final bool autofocus;
  final FocusNode? focusNode;

  const HandDrawnTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixEmoji,
    this.suffixEmoji,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<HandDrawnTextField> createState() => _HandDrawnTextFieldState();
}

class _HandDrawnTextFieldState extends State<HandDrawnTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Row(
            children: [
              if (widget.prefixEmoji != null) ...[
                Text(
                  widget.prefixEmoji!,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.labelText!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: hasError
                      ? AppTheme.errorColor
                      : _isFocused
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.enabled
                    ? AppTheme.surfaceColor
                    : Colors.grey.shade100,
                widget.enabled
                    ? AppTheme.backgroundColor
                    : Colors.grey.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: hasError
                  ? AppTheme.errorColor
                  : _isFocused
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
              width: _isFocused ? 2.0 : 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: hasError
                          ? AppTheme.errorColor.withValues(alpha: 0.2)
                          : AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            autofocus: widget.autofocus,
            style: TextStyle(
              color: widget.enabled
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: AppTheme.textHint,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: widget.maxLines == 1
                    ? AppTheme.spacingMedium
                    : AppTheme.spacingLarge,
              ),
              prefixIcon: widget.prefixEmoji != null && widget.labelText == null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Text(
                        widget.prefixEmoji!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon: widget.suffixEmoji != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8, right: 12),
                      child: Text(
                        widget.suffixEmoji!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              counterText: '',
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('❌', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
