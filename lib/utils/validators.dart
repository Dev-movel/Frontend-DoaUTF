class Validators {
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A senha é obrigatória.';
    }

    if (value.length < 8) {
      return 'A senha deve ter no mínimo 8 caracteres.';
    }

    int metCriteria = 0;
    if (RegExp(r'[A-Z]').hasMatch(value)) metCriteria++;
    if (RegExp(r'[a-z]').hasMatch(value)) metCriteria++;
    if (RegExp(r'[0-9]').hasMatch(value)) metCriteria++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=\[\]\/\\]').hasMatch(value)) metCriteria++;

    if (metCriteria < 3) {
      return 'Inclua pelo menos 3: maiúscula, minúscula, número ou símbolo.';
    }

    return null;
  }
}