{
  lib,
  fetchPnpmDeps,
  nodejs,
  pnpm_10,
  typescript,
  pnpmConfigHook,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  makeBinaryWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "actual-flow";
  version = "0.0.18";

  src = fetchFromGitHub {
    owner = "lunchflow";
    repo = "actual-flow";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wd3wiWFKvu6/WKhRGp8fiSV5y/aHMcj35q2yVLBr7Ec=";
  };

  nativeBuildInputs = [
    nodejs
    typescript
    pnpmConfigHook
    pnpm_10
    makeBinaryWrapper
  ];

  pnpmWorkspaces = [ "actual-flow" ];
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      pnpmWorkspaces
      ;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-3/D4vkKZpr6U76E0sDioAxqRkBh5HrdQRGM9mz+l1eI=";
  };

  buildInputs = [ nodejs ];

  buildPhase = ''
    runHook preBuild

    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/actual-flow
    mkdir $out/bin
    rm -rf dist/*.map
    mv dist/* $out/lib/actual-flow
    mv node_modules $out/lib/actual-flow

    makeBinaryWrapper ${lib.getExe nodejs} $out/bin/actual-flow \
      --add-flags "$out/lib/actual-flow/index.js" \
      --set NODE_PATH "$out/lib/actual-flow/node_modules"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Connect multiple open banking providers to your Actual Budget server.";
    homepage = "https://github.com/lunchflow/actual-flow";
    maintainers = with lib.maintainers; [ shellhazard ];
    mainProgram = "actual-flow";
  };
})
