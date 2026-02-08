DEVICE_ID = 00008020-001224981411002E
TEAM_ID = 49NSXZJZ54
SCHEME = NovelReaderApp
PROJECT = NovelReaderApp.xcodeproj
DERIVED_DATA = $(HOME)/Library/Developer/Xcode/DerivedData/NovelReaderApp-dgpxpeizblwacqfuezvplbaupayy

.PHONY: install clean build

install: build
	ideviceinstaller install $(DERIVED_DATA)/Build/Products/Release-iphoneos/NovelReaderApp.app

build:
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS,id=$(DEVICE_ID)' \
		-configuration Release \
		DEVELOPMENT_TEAM=$(TEAM_ID) \
		CODE_SIGN_STYLE=Automatic \
		build

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
