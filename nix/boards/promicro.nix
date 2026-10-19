# SparkFun Pro Micro 5 V/16 MHz (ATmega32U4, Caterina bootloader).
pkgs:
let
  inherit (pkgs) lib;
  core = "${pkgs.arduino-core-unwrapped}/share/arduino";
in
rec {
  # Leonardo build: same MCU and Caterina loader as the Pro Micro 5 V.
  # ino: the sketch file; libraries: source trees (flake = false inputs),
  # each linked under its own name; flags: extra C++ flags (-DFOO).
  mkFirmware =
    {
      name,
      ino,
      libraries ? { },
      flags ? null,
    }:
    pkgs.runCommand name { } ''
      mkdir -p libs build sketch/firmware $out
      ${lib.concatStrings (lib.mapAttrsToList (n: src: "ln -s ${src} libs/${n}\n") libraries)}
      cp ${ino} sketch/firmware/firmware.ino
      ${core}/arduino-builder \
        -hardware ${core}/hardware \
        -tools ${core}/tools-builder \
        -tools ${core}/hardware/tools/avr \
        -built-in-libraries ${core}/libraries \
        ${lib.optionalString (libraries != { }) "-libraries libs "}-fqbn arduino:avr:leonardo \
        ${
          lib.optionalString (flags != null) "-prefs 'compiler.cpp.extra_flags=${flags}' "
        }-build-path "$PWD/build" \
        -warnings default \
        sketch/firmware/firmware.ino
      cp build/firmware.ino.hex $out/firmware.hex
    '';

  # 1200 bps touch resets Caterina into its loader (8 s window); the loader
  # re-enumerates under the same ttyACM name, so match by USB id instead.
  mkFlash =
    name: fw:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.avrdude
        pkgs.coreutils
      ];
      text = ''
        port=''${1:-/dev/ttyACM0}
        # Leonardo loader, Pro Micro 5V, Pro Micro 3V3
        is_loader() {
          d=/sys/class/tty/''${1##*/}/device/..
          [ -r "$d/idVendor" ] || return 1
          case "$(cat "$d/idVendor"):$(cat "$d/idProduct")" in
            2341:0036|2a03:0036|1b4f:9205|1b4f:9203) return 0 ;;
          esac
          return 1
        }
        find_loader() {
          for _ in $(seq "$1"); do
            for p in /dev/ttyACM*; do
              [ -e "$p" ] && is_loader "$p" && { echo "$p"; return 0; }
            done
            sleep 0.1
          done
          return 1
        }
        loader=$(find_loader 1 || true)
        if [ -z "$loader" ] && [ -e "$port" ]; then
          echo "1200 bps touch on $port"
          stty -F "$port" 1200 || true
          loader=$(find_loader 50 || true)
        fi
        if [ -z "$loader" ]; then
          echo "no bootloader: short RST to GND twice now"
          loader=$(find_loader 150 || true)
        fi
        [ -n "$loader" ] || { echo "no bootloader appeared"; exit 1; }
        echo "bootloader on $loader"
        sleep 0.3
        avrdude -p atmega32u4 -c avr109 -P "$loader" -b 57600 -D \
          -U flash:w:${fw}/firmware.hex:i
      '';
    };

  devPackages = [
    pkgs.avrdude
    pkgs.picocom
  ];

  console = "picocom -b 115200 --omap crlf --echo /dev/ttyACM0";
}
