{ lib
, runCommand
, xorg
, cacert
, unzip

, flutterPlatform
, flutter
, hash
}:

let
  flutterPlatforms = [
    "android"
    "ios"
    "web"
    "linux"
    "windows"
    "macos"
    "fuchsia"
    "universal"
  ];

  flutter' = flutter.override {
    # Use a version of Flutter with just enough capabilities to download
    # artifacts.
    supportedTargetFlutterPlatforms = [ ];
  };
in
runCommand "flutter-artifacts-${flutterPlatform}"
{
  nativeBuildInputs = [ xorg.lndir flutter' unzip ];

  NIX_FLUTTER_TOOLS_VM_OPTIONS = "--root-certs-file=${cacert}/etc/ssl/certs/ca-bundle.crt";

  outputHash = hash;
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";

  passthru = {
    inherit flutterPlatform;
  };
} ''
  export FLUTTER_ROOT="$NIX_BUILD_TOP"
  lndir -silent '${flutter'}' "$FLUTTER_ROOT"
  rm -rf "$FLUTTER_ROOT/bin/cache"
  mkdir "$FLUTTER_ROOT/bin/cache"

  HOME="$(mktemp -d)" flutter precache -v '--${flutterPlatform}' ${builtins.concatStringsSep " " (map (p: "'--no-${p}'") (lib.remove flutterPlatform flutterPlatforms))}
  rm -rf "$FLUTTER_ROOT/bin/cache/lockfile"
  find "$FLUTTER_ROOT" -type l -lname '${flutter'}/*' -delete

  cp -r bin/cache "$out"
''
