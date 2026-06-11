import 'package:flutter_test/flutter_test.dart';
import 'package:audiscan/features/auth/models/auth_models.dart';

void main() {
  group('UserModel', () {
    const jsonDoctor = {
      'id': 'uuid-doctor-1',
      'email': 'doctor@audiscan.com',
      'full_name': 'Dr. Juan Pérez',
      'role': 'doctor',
      'license_number': 'MP-12345',
      'medico_id': null,
    };

    const jsonAsistente = {
      'id': 'uuid-asistente-1',
      'email': 'secretaria@audiscan.com',
      'full_name': 'Ana López',
      'role': 'assistant',
      'license_number': null,
      'medico_id': 'uuid-doctor-1',
    };

    const jsonPaciente = {
      'id': 'uuid-paciente-1',
      'email': 'paciente@mail.com',
      'full_name': 'Carlos Rojas',
      'role': 'paciente',
      'license_number': null,
      'medico_id': null,
    };

    test('fromJson parsea todos los campos del doctor', () {
      final usuario = UserModel.fromJson(jsonDoctor);

      expect(usuario.id, 'uuid-doctor-1');
      expect(usuario.email, 'doctor@audiscan.com');
      expect(usuario.fullName, 'Dr. Juan Pérez');
      expect(usuario.role, 'doctor');
      expect(usuario.licenseNumber, 'MP-12345');
      expect(usuario.medicoId, isNull);
    });

    test('fromJson parsea asistente con medicoId', () {
      final usuario = UserModel.fromJson(jsonAsistente);

      expect(usuario.medicoId, 'uuid-doctor-1');
      expect(usuario.licenseNumber, isNull);
    });

    test('fromJson parsea paciente con campos opcionales nulos', () {
      final usuario = UserModel.fromJson(jsonPaciente);

      expect(usuario.licenseNumber, isNull);
      expect(usuario.medicoId, isNull);
    });

    test('isDoctor retorna true solo para rol doctor', () {
      expect(UserModel.fromJson(jsonDoctor).isDoctor, isTrue);
      expect(UserModel.fromJson(jsonAsistente).isDoctor, isFalse);
      expect(UserModel.fromJson(jsonPaciente).isDoctor, isFalse);
    });

    test('isAssistant retorna true solo para rol assistant', () {
      expect(UserModel.fromJson(jsonAsistente).isAssistant, isTrue);
      expect(UserModel.fromJson(jsonDoctor).isAssistant, isFalse);
    });

    test('isPaciente retorna true solo para rol paciente', () {
      expect(UserModel.fromJson(jsonPaciente).isPaciente, isTrue);
      expect(UserModel.fromJson(jsonDoctor).isPaciente, isFalse);
    });
  });

  group('AuthResponse', () {
    const jsonRespuesta = {
      'access_token': 'eyJ.token.test',
      'user': {
        'id': 'uuid-1',
        'email': 'doctor@audiscan.com',
        'full_name': 'Dr. Juan Pérez',
        'role': 'doctor',
        'license_number': 'MP-12345',
        'medico_id': null,
      },
    };

    test('fromJson parsea el token de acceso', () {
      final respuesta = AuthResponse.fromJson(jsonRespuesta);

      expect(respuesta.accessToken, 'eyJ.token.test');
    });

    test('fromJson parsea el usuario anidado dentro de la respuesta', () {
      final respuesta = AuthResponse.fromJson(jsonRespuesta);

      expect(respuesta.user.email, 'doctor@audiscan.com');
      expect(respuesta.user.isDoctor, isTrue);
    });
  });
}
