class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cleanride-b.onrender.com/api',
  );

  static const paymentReturnUrl = String.fromEnvironment(
    'PAYMENT_RETURN_URL',
    defaultValue: 'https://washcleanride.netlify.app/payment/success',
  );
}
