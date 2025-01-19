{
  description = "ZJWT - Another JWT encoder / decoder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = 
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "zjwt";
        src = self;
        buildPhase = "zig build";
        installPhase = "install -t $out/bin zjwt";
      };
  };
}
