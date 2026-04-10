{
  lib,
  stdenvNoCC,
  bun,
  fetchFromGitHub,
  makeBinaryWrapper,
  nodejs_22,
  nix-update-script,
  writableTmpDirAsHomeHook,
}:

let
  pname = "meridian";
  version = "1.34.1";

  src = fetchFromGitHub {
    owner = "rynfar";
    repo = "meridian";
    tag = "meridian-v${version}";
    hash = "sha256-DtL+cKr9deCcv2ytoefnKVGdTHRgGbFGCTOvik0qxYE=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${pname}-node_modules";
    inherit version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars;

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      bun install --frozen-lockfile --ignore-scripts --no-progress
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/node_modules
      cp -R node_modules/. $out/node_modules
      runHook postInstall
    '';

    dontFixup = true;

    outputHash = "sha256-CbCbuBPgHBSTYUqHqVBW1nGeWk8lBr45rBGzFbvwN8A=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit pname version src node_modules;

  nativeBuildInputs = [
    bun
    makeBinaryWrapper
    nodejs_22
  ];

  configurePhase = ''
    runHook preConfigure
    cp -R ${node_modules}/node_modules node_modules
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    bun build bin/cli.ts src/proxy/server.ts \
      --outdir dist --target node --splitting \
      --external @anthropic-ai/claude-agent-sdk \
      --entry-naming '[name].js'
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/meridian
    cp -R dist $out/lib/meridian/dist
    cp -R node_modules $out/lib/meridian/node_modules
    cp package.json $out/lib/meridian/package.json

    mkdir -p $out/bin
    makeBinaryWrapper ${nodejs_22}/bin/node $out/bin/meridian \
      --add-flags "$out/lib/meridian/dist/cli.js"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "meridian-v(.*)"
    ];
  };

  meta = {
    description = "Local proxy bridging Claude Code SDK to the Anthropic API";
    homepage = "https://github.com/rynfar/meridian";
    license = lib.licenses.mit;
    mainProgram = "meridian";
  };
})
