/// Constantes globales de la aplicación.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Claves de almacenamiento seguro de la sesión.
class StorageKeys {
  StorageKeys._();

  static const String token = 'auth_token';
  static const String usuario = 'session_usuario';
}

/// Roles de usuario soportados por el sistema.
class AppRoles {
  AppRoles._();

  static const String responsable = 'responsable';
  static const String conductor = 'conductor';
}

/// Estados del bloqueo vehicular.
class EstadoVehiculo {
  EstadoVehiculo._();

  static const String bloqueado = 'bloqueado';
  static const String operativo = 'operativo';
  static const String sinInformacion = 'desconocido';
}

/// Resultados posibles de una prueba de alcohol.
class ResultadoPrueba {
  ResultadoPrueba._();

  static const String normal = 'normal';
  static const String bloqueado = 'bloqueado';
  static const String errorLectura = 'error de lectura';
}

/// Frecuencia por defecto del envío de ubicación.
class UbicacionConfig {
  UbicacionConfig._();

  /// Durante cuánto se considera "reciente" una ubicación
  /// para el responsable.
  static const Duration maxEdadReciente = Duration(minutes: 5);

  /// Frecuencia por defecto del envío periódico.
  static const Duration frecuenciaPorDefecto = Duration(seconds: 60);

  /// Opciones de frecuencia disponibles para el conductor.
  static const List<Duration> frecuenciasDisponibles = [
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(minutes: 5),
  ];
}

/// Formateadores de fecha/hora reutilizables.
class Formatos {
  Formatos._();

  static final DateFormat fechaHora = DateFormat('dd/MM/yyyy - HH:mm');
  static final DateFormat fecha = DateFormat('dd/MM/yyyy');
  static final DateFormat hora = DateFormat('HH:mm:ss');
  static final DateFormat soloHora = DateFormat('HH:mm');
  static final DateFormat apiFecha = DateFormat('yyyy-MM-dd');
  static final DateFormat apiHora = DateFormat('HH:mm:ss');

  /// Convierte un valor desconocido en `int` de forma segura.
  static int? toInt(Object? valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor.toString());
  }

  /// Convierte un valor desconocido en `double` de forma segura.
  static double toDouble(Object? valor, [double defecto = 0]) {
    if (valor == null) return defecto;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? defecto;
  }

  /// Presenta una cadena de estado normalizada (minúsculas) para comparaciones.
  static String normalizarEstado(String? estado) =>
      (estado ?? '').trim().toLowerCase();

  /// Color semántico para un estado conocido.
  static Color colorDeEstado(String? estado) {
    final e = normalizarEstado(estado);
    if (e == EstadoVehiculo.bloqueado ||
        e == 'desconectado' ||
        e == 'bloqueada' ||
        e == 'sin conexión' ||
        e == 'error' ||
        e == 'rechazada' ||
        e == 'no disponible') {
      return Colors.red;
    }
    if (e == EstadoVehiculo.operativo ||
        e == 'conectado' ||
        e == 'normal' ||
        e == 'disponible' ||
        e == 'compartiendo' ||
        e == 'activa' ||
        e == 'leída') {
      return Colors.green;
    }
    if (e == 'pendiente' || e == 'advertencia' || e == 'inactiva') {
      return Colors.orange;
    }
    return Colors.grey;
  }
}