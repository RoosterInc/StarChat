import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          // App Info
          'app_name': 'Email OTP',
          'app_subtitle': 'Secure Authentication',
          
          // Authentication
          'email_sign_in': 'Email OTP Sign-In',
          'enter_email': 'Enter your email to receive an OTP for sign-in.',
          'email': 'Email',
          'send_otp': 'Send OTP',
          'enter_otp': 'Enter the OTP sent to your email.',
          'otp_expires_in': 'OTP expires in @seconds seconds.',
          'otp': 'OTP',
          'verify_otp': 'Verify OTP',
          'resend_otp': 'Resend OTP',
          'resend_otp_in': 'Resend OTP in @seconds seconds',
          'change_email': 'Change Email',
          
          // Email Management
          'using_saved_email': 'Using your previously saved email',
          'clear_saved_email': 'Clear Saved Email',
          'clear_saved_email_confirmation': 'This will clear your saved email address. You will need to enter it again next time.',
          'clear': 'Clear',
          
          // Splash Screen
          'checking_session': 'Checking session...',
          'initializing': 'Initializing app...',
          
          // General
          'success': 'Success',
          'error': 'Error',
          'cancel': 'Cancel',
          'wait': 'Wait',
          
          // Messages
          'otp_sent': 'OTP sent to your email',
          'failed_to_send_otp': 'Failed to send OTP',
          'failed_to_verify_otp': 'Failed to verify OTP',
          'invalid_email': 'Invalid Email',
          'invalid_email_message': 'Please enter a valid email address.',
          'invalid_otp': 'Invalid OTP',
          'invalid_otp_message': 'Please enter a valid 6-digit OTP.',
          'no_internet': 'No Internet',
          'check_internet': 'Please check your internet connection.',
          'otp_expired': 'OTP Expired',
          'otp_expired_message': 'Your OTP has expired. Please request a new one.',
          
          // Home Page
          'logout': 'Logout',
          'home_page': 'Home Page',
          'signed_in': 'You are now signed in!',
          
          // Error Messages
          'too_many_requests': 'Too many requests. Please try again later.',
          'server_error': 'Server error. Please try again later.',
          'unexpected_error': 'An unexpected error occurred.',
          'unauthorized': 'Unauthorized. Please request a new OTP.',
        },
        'es_ES': {
          // App Info
          'app_name': 'Email OTP',
          'app_subtitle': 'Autenticación Segura',
          
          // Authentication
          'email_sign_in': 'Inicio de Sesión con OTP por Email',
          'enter_email': 'Ingresa tu email para recibir un OTP para iniciar sesión.',
          'email': 'Email',
          'send_otp': 'Enviar OTP',
          'enter_otp': 'Ingresa el OTP enviado a tu email.',
          'otp_expires_in': 'OTP expira en @seconds segundos.',
          'otp': 'OTP',
          'verify_otp': 'Verificar OTP',
          'resend_otp': 'Reenviar OTP',
          'resend_otp_in': 'Reenviar OTP en @seconds segundos',
          'change_email': 'Cambiar Email',
          
          // Email Management
          'using_saved_email': 'Usando tu email guardado anteriormente',
          'clear_saved_email': 'Limpiar Email Guardado',
          'clear_saved_email_confirmation': 'Esto eliminará tu dirección de email guardada. Necesitarás ingresarla nuevamente la próxima vez.',
          'clear': 'Limpiar',
          
          // Splash Screen
          'checking_session': 'Verificando sesión...',
          'initializing': 'Inicializando aplicación...',
          
          // General
          'success': 'Éxito',
          'error': 'Error',
          'cancel': 'Cancelar',
          'wait': 'Esperar',
          
          // Messages
          'otp_sent': 'OTP enviado a tu email',
          'failed_to_send_otp': 'Error al enviar OTP',
          'failed_to_verify_otp': 'Error al verificar OTP',
          'invalid_email': 'Email Inválido',
          'invalid_email_message': 'Por favor ingresa una dirección de email válida.',
          'invalid_otp': 'OTP Inválido',
          'invalid_otp_message': 'Por favor ingresa un OTP válido de 6 dígitos.',
          'no_internet': 'Sin Internet',
          'check_internet': 'Por favor verifica tu conexión a internet.',
          'otp_expired': 'OTP Expirado',
          'otp_expired_message': 'Tu OTP ha expirado. Por favor solicita uno nuevo.',
          
          // Home Page
          'logout': 'Cerrar Sesión',
          'home_page': 'Página Principal',
          'signed_in': '¡Has iniciado sesión exitosamente!',
          
          // Error Messages
          'too_many_requests': 'Demasiadas solicitudes. Por favor intenta más tarde.',
          'server_error': 'Error del servidor. Por favor intenta más tarde.',
          'unexpected_error': 'Ocurrió un error inesperado.',
          'unauthorized': 'No autorizado. Por favor solicita un nuevo OTP.',
        },
      };
}