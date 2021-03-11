#! /usr/bin/bash

export currentDir=$PWD
nixCommands=()
addNixCommand (){
  nixCommands+=($1)
}

nixHelp (){
  echo "Available commands:"
  for cmd in "${nixCommands[@]}"; do echo "- $cmd" ; done
}

printNixEnv () {
  echo "Here is your work environement"
  echo "nativeBuildInputs:"
  for x in $nativeBuildInputs; do printf "  "; echo $x | cut -d "-" -f "2-"; done
  echo "buildInputs:"
  for x in $buildInputs; do printf "  "; echo $x | cut -d "-" -f "2-"; done
  echo "propagatedBuildInputs:"
  for x in $propagatedBuildInputs; do printf "  "; echo $x | cut -d "-" -f "2-"; done
  echo "you can pass option --arg override '{coq = \"x.y\"; ...}' to nix-shell to change packages versions"
}
addNixCommand printNixEnv

nixEnv () {
  for x in $buildInputs; do echo $x; done
  for x in $propagatedBuildInputs; do echo $x; done
}
addNixCommand nixEnv

generateNixDefault () {
  cat $toolboxDir/project-default.nix > $currentDir/default.nix
  HASH=$(git ls-remote https://github.com/coq-community/coq-nix-toolbox refs/heads/master | cut -f1)
  sed -i "s/<coq-nix-toolbox-sha256>/$HASH/" $currentDir/default.nix
}
addNixCommand generateNixDefault

updateNixpkgsUnstable (){
  HASH=$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/nixpkgs-unstable | cut -f1);
  URL=https://github.com/NixOS/nixpkgs/archive/$HASH.tar.gz
  SHA256=$(nix-prefetch-url --unpack $URL)
  mkdir -p $currentDir/$configSubDir
  echo "fetchTarball {
    url = $URL;
    sha256 = \"$SHA256\";
  }" > $currentDir/$configSubDir/nixpkgs.nix
}
addNixCommand updateNixpkgsUnstable

updateNixpkgsMaster (){
  HASH=$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/master | cut -f1)
  URL=https://github.com/NixOS/nixpkgs/archive/$HASH.tar.gz
  SHA256=$(nix-prefetch-url --unpack $URL)
  mkdir -p $currentDir/$configSubDir
  echo "fetchTarball {
    url = $URL;
    sha256 = \"$SHA256\";
  }" > $currentDir/$configSubDir/nixpkgs.nix
}
addNixCommand updateNixpkgsMaster

updateNixpkgs (){
  if [[ -n "$1" ]]
  then if [[ -n "$2" ]]; then B=$2; else B="master"; fi
       HASH=$(git ls-remote https://github.com/$1/nixpkgs refs/heads/$B | cut -f1)
       URL=https://github.com/$1/nixpkgs/archive/$HASH.tar.gz
       SHA256=$(nix-prefetch-url --unpack $URL)
       mkdir -p $currentDir/$configSubDir
       echo "fetchTarball {
         url = $URL;
         sha256 = \"$SHA256\";
       }" > $currentDir/$configSubDir/nixpkgs.nix
  else
      echo "error: usage: updateNixpkgs <github username> [branch]"
      echo "otherwise use updateNixpkgsUnstable or updateNixpkgsMaster"
  fi
}
addNixCommand updateNixpkgs

nixMedley (){
    echo $jsonMedley
}
addNixCommand nixMedley

nixMedleys (){
    echo $jsonMedleys
}
addNixCommand nixMedleys

initNixConfig (){
  F=$currentDir/$configSubDir/config.nix;
  if [[ -f $F ]]
    then echo "$F already exists"
    else if [[ -n "$1" ]]
      then echo "{" > $F
           echo "  coq-attribute = \"$1\";" >> $F
           echo "  overrides = {};" >> $F
           echo "}" >> $F
           chmod u+w $F
      else echo "usage: initNixConfig pname"
    fi
  fi
}
addNixCommand initNixConfig

fetchCoqOverlay (){
  F=$nixpkgs/pkgs/development/coq-modules/$1/default.nix
  D=$currentDir/$configSubDir/coq-overlays/$1/
  if [[ -f "$F" ]]
    then mkdir -p $D; cp $F $D; chmod u+w ${D}default.nix;
         git add ${D}default.nix
         echo "You may now amend ${D}default.nix"
    else echo "usage: fetchCoqOverlay pname"
  fi
}
addNixCommand fetchCoqOverlay

cachedMake (){
  vopath="$(env -i nix-build)/lib/coq/$coq_version/user-contrib/$logpath"
  dest=$currentDir/$realpath
  if [[ -d vopath ]]
  then echo "Compiling/Fetching and copying vo from $vopath to $realpath"
       rsync -r --ignore-existing --include=*/ $vopath/* $dest
  else echo "Error: cannot find compiled $logpath, check your .nix/config.nix"
  fi
}
addNixCommand cachedMake

if [[ -f $emacsBin ]]
then
emacs (){
  F=$currentDir/.emacs
  if ! [[ -f "$F" ]]
  then cp -u $emacsInit $F
  fi
  $emacsBin -q --load $F $*
}
addNixCommand emacs
fi