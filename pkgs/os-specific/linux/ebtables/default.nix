{ lib, stdenv, fetchurl, enableStatic ? false }:

stdenv.mkDerivation rec {
  name = "ebtables-${version}";
  version = "2.0.10-4";

  src = fetchurl {
    url = "mirror://sourceforge/ebtables/ebtables-v${version}.tar.gz";
    sha256 = "0pa5ljlk970yfyhpf3iqwfpbc30j8mgn90fapw9cfz909x47nvyw";
  };

  makeFlags =
    [ "LIBDIR=$(out)/lib" "BINDIR=$(out)/sbin" "MANDIR=$(out)/share/man"
      "ETCDIR=$(out)/etc" "INITDIR=$(TMPDIR)" "SYSCONFIGDIR=$(out)/etc/sysconfig"
      "LOCALSTATEDIR=/var" "CC=${stdenv.cc.targetPrefix}cc"
    ];

  patches = lib.optional stdenv.hostPlatform.isMusl ./musl-compatibility.patch ++
            lib.optional stdenv.hostPlatform.isAarch32 ./no-as-needed.patch;

  preBuild =
    ''
      substituteInPlace Makefile --replace '-o root -g root' ""
    '';

  buildFlags = if enableStatic then [ "static" ] else null ;

  installPhase = if enableStatic then ''
    mkdir -p $out/bin
    cp static $out/bin/ebtables

    mkdir -p $out/etc
    cp ethertypes $out/etc/ethertypes
  '' else null;

  NIX_CFLAGS_COMPILE =
    ["-Wno-error"] ++
    lib.optionals stdenv.hostPlatform.isMusl [
      "-D__THROW="
      "-Du_int8_t=uint8_t"
      "-Du_int32_t=uint32_t"
    ];

  preInstall = "mkdir -p $out/etc/sysconfig";

  meta = with stdenv.lib; {
    description = "A filtering tool for Linux-based bridging firewalls";
    homepage = http://ebtables.sourceforge.net/;
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
