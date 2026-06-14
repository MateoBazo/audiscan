import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';

class ShellResponsivo extends ConsumerWidget {
  final Widget child;
  final String rutaActual;

  const ShellResponsivo({
    super.key,
    required this.child,
    required this.rutaActual,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancho = MediaQuery.sizeOf(context).width;

    if (ancho < 720) return child;

    final usuario = ref.watch(authProvider).user;
    final esPaciente = usuario?.isPaciente == true;
    final extended = ancho >= 1100;
    final theme = Theme.of(context);

    final destinos = esPaciente ? _destinosPaciente : _destinosPersonal;
    final indice = _indiceActivo(rutaActual, esPaciente);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: indice,
            onDestinationSelected: (i) => context.go(destinos[i].ruta),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: extended
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hearing,
                            size: 26, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          'AudiScan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    )
                  : Icon(Icons.hearing,
                      size: 26, color: theme.colorScheme.primary),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: extended
                  ? TextButton.icon(
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Salir'),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Cerrar sesión',
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
            ),
            destinations: destinos
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icono),
                      label: Text(d.etiqueta),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _indiceActivo(String ruta, bool esPaciente) {
    if (esPaciente) {
      if (ruta.startsWith('/mi-portal/historial')) return 1;
      if (ruta.startsWith('/mi-portal/imagenes')) return 2;
      if (ruta.startsWith('/mi-portal/audiometrias')) return 3;
      return 0;
    }
    if (ruta.startsWith('/pacientes')) return 1;
    if (ruta.startsWith('/citas')) return 2;
    return 0;
  }
}

class _DestinoNav {
  final IconData icono;
  final String etiqueta;
  final String ruta;

  const _DestinoNav({
    required this.icono,
    required this.etiqueta,
    required this.ruta,
  });
}

const List<_DestinoNav> _destinosPersonal = [
  _DestinoNav(icono: Icons.home_outlined, etiqueta: 'Inicio', ruta: '/home'),
  _DestinoNav(
      icono: Icons.people_outline, etiqueta: 'Pacientes', ruta: '/pacientes'),
  _DestinoNav(
      icono: Icons.calendar_month_outlined,
      etiqueta: 'Agenda',
      ruta: '/citas'),
];

const List<_DestinoNav> _destinosPaciente = [
  _DestinoNav(icono: Icons.home_outlined, etiqueta: 'Inicio', ruta: '/home'),
  _DestinoNav(
      icono: Icons.folder_open_outlined,
      etiqueta: 'Historial',
      ruta: '/mi-portal/historial'),
  _DestinoNav(
      icono: Icons.image_outlined,
      etiqueta: 'Imágenes',
      ruta: '/mi-portal/imagenes'),
  _DestinoNav(
      icono: Icons.hearing_outlined,
      etiqueta: 'Audiometrías',
      ruta: '/mi-portal/audiometrias'),
];
