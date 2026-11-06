import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Modal para ingresar el código numérico de 5 dígitos y unirse a una sala existente.
class JoinRoomDialog extends StatefulWidget {
  final void Function(String roomCode)? onJoin;

  const JoinRoomDialog({
    super.key,
    this.onJoin,
  });

  /// Muestra el diálogo modal y retorna el código de 5 dígitos si el usuario confirma.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const JoinRoomDialog(),
    );
  }

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    } else {
      setState(() {});
    }
  }

  void _submitCode() {
    final code = _codeController.text.trim();
    if (code.length != 5 || int.tryParse(code) == null) {
      setState(() {
        _errorMessage = 'El código debe tener exactamente 5 dígitos numéricos.';
      });
      return;
    }

    if (widget.onJoin != null) {
      widget.onJoin!(code);
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final bool isCodeComplete = _codeController.text.trim().length == 5;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF141728),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF2B3356),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado con icono y botón cerrar
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.hashtag,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unirse a Partida',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ingresa el código de 5 dígitos',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const FaIcon(
                      FontAwesomeIcons.xmark,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Pídele al anfitrión (Game Master) el código numérico de la sala para conectarte desde cualquier lugar:',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Campo de entrada estilizado para código de 5 dígitos
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorMessage != null
                        ? const Color(0xFFF43F5E)
                        : isCodeComplete
                            ? const Color(0xFF10B981)
                            : const Color(0xFF334155),
                    width: 1.6,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  key: const Key('join_room_code_field'),
                  controller: _codeController,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 5,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 14,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    hintText: '•••••',
                    hintStyle: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 14,
                      fontFamily: 'monospace',
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _submitCode(),
                ),
              ),

              // Mensaje de error si la validación falla
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.circleExclamation,
                      color: Color(0xFFF43F5E),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFF43F5E),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(
                          color: Color(0xFF334155),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      key: const Key('join_room_confirm_button'),
                      onPressed: isCodeComplete ? _submitCode : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        disabledBackgroundColor:
                            const Color(0xFF2563EB).withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: isCodeComplete ? 8 : 0,
                        shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          FaIcon(
                            FontAwesomeIcons.rightToBracket,
                            size: 15,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Unirse a Sala',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
