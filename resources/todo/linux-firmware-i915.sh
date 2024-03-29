#!/usr/bin/env bash
# author:     Luiz Quirino
# since:       v0.0.1
# created:   --/--/----
# modified: --/--/----
sudo mkdir  /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/bxt_dmc_ver1.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/bxt_dmc_ver1_07.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/bxt_guc_32.0.3.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/bxt_guc_ver8_7.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/bxt_guc_ver9_29.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/bxt_huc_ver01_07_1398.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/bxt_huc_ver01_8_2893.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/cnl_dmc_ver1_06.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/cnl_dmc_ver1_07.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/glk_dmc_ver1_04.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/glk_guc_32.0.3.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/glk_huc_ver03_01_2893.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/icl_dmc_ver1_07.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/icl_guc_32.0.3.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/icl_huc_ver8_4_3238.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/kbl_dmc_ver1.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/kbl_dmc_ver1_01.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/kbl_dmc_ver1_04.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/kbl_guc_32.0.3.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/kbl_guc_ver9_14.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/kbl_guc_ver9_39.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/kbl_huc_ver02_00_1810.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_dmc_ver1.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_dmc_ver1_23.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_dmc_ver1_26.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_dmc_ver1_27.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_guc_32.0.3.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_guc_ver1.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_guc_ver4.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_guc_ver6.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_guc_ver6_1.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_guc_ver9_33.bin -o /lib/firmware/i915/
sudo axel -n 5 -a https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/i915/skl_huc_ver01_07_1398.bin -o /lib/firmware/i915/
