class ErrorHandling {
  static String getErrorMessage(Object e) {
    final message = e.toString().toLowerCase();

    if (message.contains('already exists')) {
      return 'Email already exists';
    }

    return 'Something went wrong';
  }

  static String? checkForm(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return "Please fill all fields";
    }

    if (!RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email)) {
      return "Please enter a valid email";
    }

    if (password.length < 6) {
      return "Password must be at least 6 characters";
    }

    return null;
  }
}
