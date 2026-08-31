ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 34306jit

# Optimización agresiva y eliminación de símbolos muertos para reducir tamaño
$(TWEAK_NAME)_CCFLAGS = -std=c++17 -fno-rtti -DNDEBUG -O3 -flto -Wall -Wno-unused-variable -Wno-unused-function -Wno-unused-value -fvisibility=hidden -ffunction-sections -fdata-sections -I./JRMemory -I./fmt
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -O3 -flto -Wall -Wno-unused-variable -Wno-unused-function -Wno-unused-value -fvisibility=hidden -ffunction-sections -fdata-sections -I./JRMemory -I./fmt

# Frameworks esenciales limpios (removidos extras que inflan o generan dylibs fantasma)
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics CoreText OpenGLES Metal MetalKit

# Enlace de librerías estáticas y optimizador de enlace (-dead_strip)
$(TWEAK_NAME)_LDFLAGS += Other/libdobby_fixed.a -Wl,-dead_strip

# Archivos fuente explícitos para evitar escaneos recursivos erróneos
$(TWEAK_NAME)_FILES = ImGuiDrawView.mm \
                      oxorany/oxorany.cpp \
                      $(wildcard Esp/*.mm) \
                      $(wildcard Esp/*.m) \
                      $(wildcard Esp/*.cpp) \
                      $(wildcard IMGUI/*.cpp) \
                      $(wildcard IMGUI/*.mm) \
                      $(wildcard Helper/*.cpp) \
                      $(wildcard Helper/*.mm) \
                      $(wildcard Helper/*.m) \
                      $(wildcard fmt/*.cc)

include $(THEOS_MAKE_PATH)/tweak.mk

# Forzar limpieza total de símbolos de depuración tras empaquetar
after-stage::
	@echo "Limpiando símbolos y reduciendo peso del binario..."
	@strip -x "$(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/$(TWEAK_NAME).dylib"
