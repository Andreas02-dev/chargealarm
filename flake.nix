{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs = { nixpkgs.follows = "nixpkgs"; };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  
  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default =
              let
                inherit (inputs) android-nixpkgs;
                sdk = (import android-nixpkgs { }).sdk (sdkPkgs:
                  with sdkPkgs; [
                    build-tools-30-0-3
                    build-tools-34-0-0
                    cmdline-tools-latest
                    emulator
                    platform-tools
                    platforms-android-34
                    platforms-android-33
                    platforms-android-31
                    platforms-android-28
                    system-images-android-34-google-apis-playstore-x86-64
                    ndk-26-1-10909125
                  ]);
              in
              devenv.lib.mkShell {
                inherit inputs pkgs;

                modules = [
                  ({ pkgs, config, ... }:
                    {

                      # https://devenv.sh/basics/
                      # dotenv.enable = true;
                      env.ANDROID_AVD_HOME = "${config.env.DEVENV_ROOT}/.android/avd";
                      env.ANDROID_SDK_ROOT = "${sdk}/share/android-sdk";
                      env.ANDROID_HOME = config.env.ANDROID_SDK_ROOT;
                      env.GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/share/android-sdk/build-tools/34.0.0/aapt2";
                      # Fix GL error when starting emulator
                      env.LD_LIBRARY_PATH="${pkgs.libglvnd}/lib";
                      
                      # https://devenv.sh/packages/
                      packages = with pkgs; [
                        git
                        openssl
                        pkg-config
                        cargo-deny
                        cargo-edit
                        cargo-watch
                        rust-analyzer
                        # buildInputs
                        at-spi2-atk
                        atkmm
                        cairo
                        gdk-pixbuf
                        glib
                        gobject-introspection
                        gobject-introspection.dev
                        gtk3
                        harfbuzz
                        librsvg
                        libsoup_3
                        pango
                        webkitgtk_4_1
                        webkitgtk_4_1.dev
                      ];

                      # https://devenv.sh/scripts/
                      # Create the initial AVD that's needed by the emulator
                      scripts.create-avd.exec = "avdmanager create avd --force --name phone --package 'system-images;android-34;google_apis_playstore;x86_64' --device 'pixel_7_pro'";
                      scripts.start-avd.exec = "emulator -avd phone";

                      # https://devenv.sh/processes/
                      # These processes will all run whenever we run `devenv run`
                      # processes.grovero-app.exec = "flutter run lib/main.dart";

                      enterShell = ''
                        mkdir -p $ANDROID_AVD_HOME
                        export PATH="${sdk}/bin:$PATH"
                        export NDK_HOME="$ANDROID_SDK_ROOT/ndk/$(ls -1 $ANDROID_SDK_ROOT/ndk)"
                      '';

                      # https://devenv.sh/languages/
                      languages.javascript = {
                        enable = true;
                        npm.enable = true;
                        yarn.enable = true;
                        corepack.enable = true;
                        bun.enable = true;
                      };
                      languages.typescript = {
                        enable = true;
                      };
                      languages.deno = {
                        enable = true;
                      };
                      languages.java = {
                        enable = true;
                        gradle.enable = false;
                        jdk.package = pkgs.jdk;
                      };
                      languages.rust = {
                        enable = true;
                        # https://devenv.sh/reference/options/#languagesrustchannel
                        channel = "stable";
                        targets = [
                          "aarch64-linux-android"
                          "armv7-linux-androideabi"
                          "i686-linux-android"
                          "x86_64-linux-android"
                        ];
                      };

                      # See full reference at https://devenv.sh/reference/options/
                    })
                ];
              };
          });
    };
}
