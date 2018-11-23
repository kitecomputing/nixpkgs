{ stdenv
, fetchPypi
, python
, wrapPython
, unzip
, lib
}:

let isCross = stdenv.buildPlatform != stdenv.hostPlatform;

    crossSetup = lib.optionalString isCross ''
      export PYTHONXCPREFIX=${python}
      export CROSS_COMPILE=${stdenv.cc.targetPrefix}
      export CC=${stdenv.cc}
      export LDSHARED="${stdenv.cc} -shared"
    '';

# Should use buildPythonPackage here somehow
in stdenv.mkDerivation rec {
  pname = "setuptools";
  version = "40.2.0";
  name = "${python.libPrefix}-${pname}-${version}";

  src = fetchPypi {
    inherit pname version;
    extension = "zip";
    sha256 = "47881d54ede4da9c15273bac65f9340f8929d4f0213193fa7894be384f2dcfa6";
  };

  nativeBuildInputs = [ unzip wrapPython ];
  buildInputs = [ python ];
  doCheck = false;  # requires pytest
  installPhase = ''
      dst=$out/${python.sitePackages}
      mkdir -p $dst
      export PYTHONPATH="$dst:$PYTHONPATH"
      ${crossSetup}
      ${python.nativePython.interpreter} setup.py install --prefix=$out
      wrapPythonPrograms
  '';

  pythonPath = [];

  meta = with stdenv.lib; {
    description = "Utilities to facilitate the installation of Python packages";
    homepage = https://pypi.python.org/pypi/setuptools;
    license = with licenses; [ psfl zpl20 ];
    platforms = python.meta.platforms;
    priority = 10;
  };
}
