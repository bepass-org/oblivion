{ pkgs }:

with pkgs;

# Configure your development environment.
#
# Documentation: https://github.com/numtide/devshell
devshell.mkShell {
  name = "oblivion";
  motd = ''
    Entered the Android app development environment.
  '';
  env = [
    {
      name = "ANDROID_HOME";
      value = "${android-sdk}/share/android-sdk";
    }
    {
      name = "ANDROID_SDK_ROOT";
      value = "${android-sdk}/share/android-sdk";
    }
    {
      name = "JAVA_HOME";
      value = jdk11.home;
    }
    {
      name = "GOBIN";
      eval = "$HOME/go/bin";
    }
    {
      name = "PATH";
      eval = "$HOME/go/bin:$PATH";
    }
  ];
  packages = [
    android-studio
    android-sdk
    gradle
    jdk11
    go_1_21
  ];
}
