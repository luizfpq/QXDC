#!/usr/bin/env bash
#!/usr/bin/env bash
# author:     Luiz Quirino
# since:       v0.0.1
# created:   --/--/----
# modified: --/--/----
#adicionando ao fim da linha, seu pacote será instalado
APPLICATIONS="firmware-linux-nonfree libgl1-mesa-dri xserver-xorg-video-ati firmware-amd-graphics mesa-vulkan-drivers libvulkan1 vulkan-tools vulkan-utils vulkan-validationlayers mesa-opencl-icd"

installAmdGpu() {
  clear
  echo "Instalando dependencias e drivers de vídeo..."
  echo .
  echo .
  #sudo apt-get update > /dev/null
  for application in ${APPLICATIONS[@]}
    do
      echo "Instalando $application..."
      sudo apt-get install -qq -o=Dpkg::Use-Pty=0 $application -y &>> /tmp/QXDCinstall.log
    done
}

installAmdGpu
