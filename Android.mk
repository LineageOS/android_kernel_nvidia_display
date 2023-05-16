#
# Copyright (C) 2023 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_PREBUILT_KERNEL),)

NVIDIA_DISPLAY_PATH := $(LOCAL_PATH)
KERNEL_OUT          := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
NVIDIA_DISPLAY_CC   := TARGET_ARCH=aarch64 CC=$(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)gcc LD=$(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)ld AR=$(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)ar CXX=$(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)g++ OBJCOPY=$(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)objcopy

include $(CLEAR_VARS)

LOCAL_MODULE        := nvidia-display
LOCAL_MODULE_SUFFIX := .ko
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(TARGET_OUT_VENDOR)/lib/modules

_nvidia-display_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_nvidia-display_ko := $(_nvidia-display_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_nvidia-display_ko): $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/$(BOARD_KERNEL_IMAGE_NAME)
	@mkdir -p $(dir $@)
	@cp -R $(NVIDIA_DISPLAY_PATH)/* $(dir $@)/
	$(hide) +$(KERNEL_MAKE_CMD) $(PATH_OVERRIDE) $(KERNEL_MAKE_FLAGS) $(NVIDIA_DISPLAY_CC) -C $(abspath $(dir $@)/src/nvidia) $(abspath $(dir $@)/kernel-open) all
	$(hide) +$(KERNEL_MAKE_CMD) $(PATH_OVERRIDE) $(KERNEL_MAKE_FLAGS) $(NVIDIA_DISPLAY_CC) -C $(abspath $(dir $@)/src/nvidia-modeset) $(abspath $(dir $@)/kernel-open) all
	@cp $(dir $@)/src/nvidia/_out/Linux_aarch64/nv-kernel.o $(dir $@)/kernel-open/nvidia/nv-kernel.o_binary
	@cp $(dir $@)/src/nvidia-modeset/_out/Linux_aarch64/nv-modeset-kernel.o $(dir $@)/kernel-open/nvidia-modeset/nv-modeset-kernel.o_binary
	$(hide) +$(KERNEL_MAKE_CMD) $(PATH_OVERRIDE) $(KERNEL_MAKE_FLAGS) -C $(TARGET_KERNEL_SOURCE) O=$(abspath $(KERNEL_OUT)) M=$(abspath $(dir $@)/kernel-open) ARCH=$(KERNEL_ARCH) NV_KERNEL_SOURCES=$(abspath $(TARGET_KERNEL_SOURCE)) NV_KERNEL_OUTPUT=$(abspath $(KERNEL_OUT)) NV_KERNEL_MODULES="nvidia nvidia-modeset nvidia-drm" NV_SPECTRE_V2=0 $(KERNEL_CROSS_COMPILE) modules
	modules=$$(find $(dir $@) -type f -name '*.ko'); \
	for f in $$modules; do \
		$(KERNEL_TOOLCHAIN_PATH)strip --strip-unneeded $$f; \
		cp $$f $(KERNEL_MODULES_OUT)/lib/modules; \
	done;
	touch $@

include $(BUILD_SYSTEM)/base_rules.mk
endif
