ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 34306jit

# Configuración de compilación C++ y C
$(TWEAK_NAME)_CCFLAGS = -std=c++17 -fno-rtti -DNDEBUG -Wall -Wno-unused-variable -Wno-unused-function -Wno-unused-value -fvisibility=hidden -I./JRMemory -I./fmt
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wall -Wno-unused-variable -Wno-unused-function -Wno-unused-value -fvisibility=hidden -I./JRMemory -I./fmt

# Frameworks necesarios para la interfaz gráfica y el sistema
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController JRMemory

# Enlace de librerías estáticas y frameworks personalizados
$(TWEAK_NAME)_LDFLAGS += Other/libdobby_fixed.a -F./JRMemory

# Archivos fuente adaptados a tu nueva estructura de carpetas
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
