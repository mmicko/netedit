solution "netedit"
	configurations {
		"Debug",
		"Release",
	}
	platforms {
		"x32",
		"x64",
	}

language "C++"
startproject "netedit"

-- BEGIN GENie configuration
premake.make.makefile_ignore = true
--premake._checkgenerate = false
premake.check_paths = true
msgcompile ("Compiling $(subst ../,,$<)...")
msgcompile_objc ("Objective-C compiling $(subst ../,,$<)...")
msgresource ("Compiling resources $(subst ../,,$<)...")
msglinking ("Linking $(notdir $@)...")
msgarchiving ("Archiving $(notdir $@)...")
msgprecompile ("Precompiling $(subst ../,,$<)...")
messageskip { "SkipCreatingMessage", "SkipBuildingMessage", "SkipCleaningMessage" }
-- END GENie configuration

MODULE_DIR = path.getabsolute("../")
SRC_DIR = path.getabsolute("../src")
BGFX_DIR   = path.getabsolute("../3rdparty/bgfx")
BX_DIR     = path.getabsolute("../3rdparty/bx")

local BGFX_BUILD_DIR = path.join("../", "build")
local BGFX_THIRD_PARTY_DIR = path.join(BGFX_DIR, "3rdparty")

defines {
	"BX_CONFIG_ENABLE_MSVC_LEVEL4_WARNINGS=1"
}

dofile (path.join(BX_DIR, "scripts/toolchain.lua"))
if not toolchain(BGFX_BUILD_DIR, BGFX_THIRD_PARTY_DIR) then
	return -- no action specified
end

function copyLib()
end

dofile (path.join(BGFX_DIR, "scripts", "bgfx.lua"))

group "common"
dofile (path.join(BGFX_DIR, "scripts", "example-common.lua"))

group "libs"
bgfxProject("", "StaticLib", {})

group "main"

-- MAIN Project
project ("netedit")
	uuid (os.uuid("netedit"))
	kind "WindowedApp"

targetdir(MODULE_DIR)
targetsuffix ""

removeflags {
	"NoExceptions",
} 
configuration {}

includedirs {
	path.join(BX_DIR,   "include"),
	path.join(BGFX_DIR, "include"),
	path.join(BGFX_DIR, "3rdparty"),
	path.join(BGFX_DIR, "examples/common"),
	path.join(SRC_DIR,  ""),
}

files {
	path.join(SRC_DIR, "main.cpp"),
}
if _ACTION == "gmake" then
	removebuildoptions_cpp {
		"-std=c++11",
	}
	buildoptions_cpp {
		"-x c++",
		"-std=c++14",
	}
end

links {
	"bgfx",
	"example-common",
}
configuration { "mingw*" }
	targetextension ".exe"
	links {
		"gdi32",
		"psapi",
	}

configuration { "vs20*", "x32 or x64" }
	links {
		"gdi32",
		"psapi",
	}

configuration { "mingw-clang" }
	kind "ConsoleApp"

configuration { "linux-*" }
	links {
		"X11",
		"GL",
		"pthread",
	}

configuration { "osx" }
	linkoptions {
		"-framework Cocoa",
		"-framework QuartzCore",
		"-framework OpenGL",
		"-weak_framework Metal",
	}

configuration {}

strip()

