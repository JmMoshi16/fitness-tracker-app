import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PREMIUM CARD COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

/// Premium card with soft shadows and glow effects
class FitCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool showBorder;
  final bool showGlow;

  const FitCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius = 20,
    this.onTap,
    this.gradient,
    this.showBorder = true,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? kDarkCard : kLightCard);
    
    return GestureDetector(
      onTap: onTap != null ? () { HapticFeedback.lightImpact(); onTap!(); } : null,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: showBorder ? Border.all(
            color: isDark ? kDarkBorder : kLightBorder,
            width: isDark ? 0.5 : 1,
          ) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.04),
              blurRadius: isDark ? 16 : 8,
              offset: const Offset(0, 4),
            ),
            if (showGlow && isDark)
              BoxShadow(
                color: kOrangeGlow.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Hero card with gradient background for dashboard
class HeroCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const HeroCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.radius = 24,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = gradientColors ?? [kOrange, kOrangeDark];
    
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BUTTON COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

/// Premium gradient button with glow effect
class FitButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double? width;
  final List<Color>? colors;
  final bool isSecondary;

  const FitButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.height = 56,
    this.width,
    this.colors,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnColors = colors ?? [kOrange, kOrangeDark];
    
    return GestureDetector(
      onTap: isLoading ? null : () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: isSecondary ? null : LinearGradient(
            colors: btnColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: isSecondary ? (isDark ? kDarkCard : kLightCard) : null,
          borderRadius: BorderRadius.circular(16),
          border: isSecondary ? Border.all(
            color: isDark ? kDarkBorder : kLightBorder,
            width: 1.5,
          ) : null,
          boxShadow: [
            if (!isSecondary)
              BoxShadow(
                color: btnColors[0].withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isSecondary ? (isDark ? kDarkText : kLightText) : Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSecondary ? (isDark ? kDarkText : kLightText) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Compact action button for quick actions
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: FitCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isDark ? kDarkText : kLightText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STAT & METRIC COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

/// Stat tile for displaying metrics
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isCompact;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: FitCard(
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 12 : 16,
          horizontal: isCompact ? 8 : 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 18 : 20,
                color: isDark ? kDarkText : kLightText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isDark ? kDarkSubtext : kLightSubtext,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini stat for inline display
class MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const MiniStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor ?? Colors.white70, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? kDarkText : kLightText)),
        if (action != null)
          GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(color: kOrange, fontWeight: FontWeight.w600, fontSize: 13))),
      ],
    );
  }
}

// ── Skeleton Loader ──────────────────────────────────────────────────────────
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, required this.width, required this.height, this.radius = 12});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(_anim.value * 0.12),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: kOrange.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, size: 44, color: kOrange.withOpacity(0.6))),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? kDarkText : kLightText)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 13), textAlign: TextAlign.center),
            if (actionLabel != null) ...[const SizedBox(height: 20), FitButton(label: actionLabel!, onTap: onAction!, width: 160, height: 46)],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// THEME TOGGLE
// ══════════════════════════════════════════════════════════════════════════════

/// Premium animated theme toggle switch
class ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const ThemeToggle({super.key, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 60,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? kDarkCard : kLightBorder,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? kDarkBorder : kLightBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kOrange, kOrangeDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kOrange.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fit Input ────────────────────────────────────────────────────────────────
class FitInput extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;

  const FitInput({super.key, required this.controller, this.label, this.hint, this.prefixIcon, this.keyboardType = TextInputType.text, this.obscure = false, this.suffix, this.validator, this.onChanged, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? kDarkText : kLightText, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: kOrange, size: 20) : null,
        suffixIcon: suffix,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WORKOUT CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Premium workout card with gradient icon
class WorkoutCard extends StatelessWidget {
  final String title;
  final String type;
  final int duration;
  final String? notes;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WorkoutCard({
    super.key,
    required this.title,
    required this.type,
    required this.duration,
    this.notes,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.getWorkoutColor(type);
    final icon = AppTheme.getWorkoutIcon(type);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: FitCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? kDarkText : kLightText,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.timer_outlined, size: 14, color: isDark ? kDarkSubtext : kLightSubtext),
                      const SizedBox(width: 4),
                      Text(
                        '$duration min',
                        style: TextStyle(
                          color: isDark ? kDarkSubtext : kLightSubtext,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (notes != null && notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? kDarkTertiary : kLightTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null || onDelete != null)
              Column(
                children: [
                  if (onEdit != null) _actionBtn(Icons.edit_outlined, kInfo, onEdit!),
                  if (onEdit != null && onDelete != null) const SizedBox(height: 8),
                  if (onDelete != null) _actionBtn(Icons.delete_outline_rounded, kError, onDelete!),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
