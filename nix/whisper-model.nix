{ pkgs, lib }:
pkgs.stdenvNoCC.mkDerivation rec {
  pname = "whisper-cpp-model-base";
  version = "1.0";
  src = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
    hash = "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4=";
  };
  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/share/whisper-cpp-models/ggml-base.bin
    runHook postInstall
  '';
  meta = with lib; {
    description = "Whisper.cpp ggml-base.bin model (142 MB, multilingual)";
    homepage = "https://huggingface.co/ggerganov/whisper.cpp";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
