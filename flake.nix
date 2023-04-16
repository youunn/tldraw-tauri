{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    fenix = { 
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, naersk, fenix, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };

        rust-toolchain = fenix.packages.${system}.complete.withComponents [
          "rustc"
          "cargo"
          "clippy"
          "rustfmt"
          "rust-src"
          "rust-analyzer"
        ];

        naersk1 = naersk.lib.${system}.override {
          cargo = rust-toolchain;
          rustc = rust-toolchain;
        };

        frontend = pkgs.mkYarnPackage {
          pname = "tldraw-app";
          version = "0.0.0";
          src = ./.;
          offlineCache = pkgs.fetchYarnDeps {
            yarnLock = ./yarn.lock;
            sha256 = "sha256-Z7C0dGA4qaRpj5aT7rX2khT6G9xoqLjueD5bVrCjDmE=";
          };
          packageJSON = ./package.json;

          buildPhase = ''
            export HOME=$(mktemp -d)
            yarn --offline run build
            cp -r deps/tldraw-app/dist $out
          '';

          distPhase = "true";
          dontInstall = true;
        };
      in rec {
        defaultPackage = naersk1.buildPackage rec {
          name = "tldraw";
          version = "0.0.0";
          src = ./src-tauri;
          copySources = [
            # "icons"
            # "tauri.conf.json"
            "."
          ];

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            dpkg
            pkg-config
          ];

          buildInputs = with pkgs; [
            openssl
            dbus
            glib
            gtk3
            libsoup
            webkitgtk
            librsvg
          ];

          postPatch = ''
            cp -r ${frontend} frontend
            substituteInPlace tauri.conf.json --replace '"distDir": "../dist",' '"distDir": "./frontend",'
          '';

          cargoBuildOptions = ops: ops ++ [
            "--features custom-protocol"
          ];
        };

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            nodePackages.yarn
            rust-toolchain
            pkg-config
            openssl
            curl
            wget
            dbus
            glib
            gtk3
            libsoup
            webkitgtk
            librsvg
          ];

          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
        };
      }
    );
}
