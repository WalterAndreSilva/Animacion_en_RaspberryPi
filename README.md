# Animación en Raspberry Pi
### Laboratorio de Organización del computador (FAMAF-UNC)

Este repositorio contiene el código de una animación ejecutada en una Raspberry Pi 3, emulada mediante QEMU.

La pantalla está configurada con una resolución de 640×480 píxeles utilizando el formato de color ARGB de 32 bits.

La animación se genera escribiendo directamente en la memoria del framebuffer, estableciendo el color de cada píxel que posteriormente es renderizado en la pantalla.

![captura](url "captura")


## Instalar Qemu
Tener acualizados los repositorios
```bash
$ sudo apt update
```
Instalar AARCH64 TOOLCHAIN
```bash
$ sudo apt install gcc-aarch64-linux-gnu
```
Instalar QEMU ARM (incluye aarch64)
```bash
$ sudo apt install qemu-system-arm
```
Install GDB (si se quiere debuggear)
```bash
$ sudo apt install gdb-multiarch
```
Configuar GDB para que sea mas amigable
```bash
$ wget -P ~ git.io/.gdbinit
```

## Uso

El archivo _Makefile_ contiene lo necesario para construir el proyecto.

**Para correr el proyecto ejecutar**

```bash
$ make run
```
Esto construirá el código y ejecutará qemu para su emulación

## Estructura

* **[app.s](app.s)** Este archivo contiene a apliación. Todo el hardware ya está inicializado anteriormente.
* **[start.s](start.s)** Este archivo realiza la inicialización del hardwar
* **[Makefile](Makefile)** Archivo que describe como construir el software _(que ensamblador utilizar, que salida generar, etc)_
* **[memmap](memmap)** Este archivo contiene la descripción de la distribución de la memoria del programa y donde colocar cada sección.