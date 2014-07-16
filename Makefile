INFOPLIST_FILE=Info.plist
SOURCES=\
	main.m \
	iPhoneHomeApp.m

CC=/usr/local/bin/arm-apple-darwin-gcc
CXX=/usr/local/bin/arm-apple-darwin-g++
CFLAGS=-fsigned-char
LD=$(CC)
LDFLAGS = -framework CoreFoundation -framework CoreFoundation -framework Foundation \
 -framework UIKit  -framework LayerKit  -framework CoreGraphics  \
 -framework GraphicsServices  -framework CoreSurface -framework SystemConfiguration \
 -framework OfficeImport -framework WebKit -lobjc -mmacosx-version-min=10.1


WRAPPER_NAME=$(PRODUCT_NAME).app
EXECUTABLE_NAME=$(PRODUCT_NAME)
SOURCES_ABS=$(addprefix $(SRCROOT)/,$(SOURCES))
INFOPLIST_ABS=$(addprefix $(SRCROOT)/,$(INFOPLIST_FILE))
OBJECTS=\
	$(patsubst %.c,%.o,$(filter %.c,$(SOURCES))) \
	$(patsubst %.cc,%.o,$(filter %.cc,$(SOURCES))) \
	$(patsubst %.cpp,%.o,$(filter %.cpp,$(SOURCES))) \
	$(patsubst %.m,%.o,$(filter %.m,$(SOURCES))) \
	$(patsubst %.mm,%.o,$(filter %.mm,$(SOURCES)))
OBJECTS_ABS=$(addprefix $(CONFIGURATION_TEMP_DIR)/,$(OBJECTS))
APP_ABS=$(BUILT_PRODUCTS_DIR)/$(WRAPPER_NAME)
PRODUCT_ABS=$(APP_ABS)/$(EXECUTABLE_NAME)

all: $(PRODUCT_ABS)
all: install

$(PRODUCT_ABS): $(APP_ABS) $(OBJECTS_ABS)
	$(LD) $(LDFLAGS) -o $(PRODUCT_ABS) $(OBJECTS_ABS)

$(APP_ABS): $(INFOPLIST_ABS)
	mkdir -p $(APP_ABS)
	cp $(INFOPLIST_ABS) $(APP_ABS)/

$(CONFIGURATION_TEMP_DIR)/%.o: $(SRCROOT)/%.m
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

install: $(PRODUCT_ABS)

	scp -r /Users/jerry/iPhone/iPhoneHome/build/Release/iPhoneHome.app/iPhoneHome root@192.168.1.103:/Applications/iPhoneHome.app

clean:
	echo rm -f $(OBJECTS_ABS)
	echo rm -rf $(APP_ABS)

