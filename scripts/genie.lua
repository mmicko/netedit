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

MAME_DIR = (path.getabsolute("..") .. "/")
LIBTYPE = "StaticLib"

local BGFX_BUILD_DIR = path.join("../", "build")
local BGFX_THIRD_PARTY_DIR = path.join(BGFX_DIR, "3rdparty")

defines {
	"BX_CONFIG_ENABLE_MSVC_LEVEL4_WARNINGS=1"
}

dofile (path.join(MAME_DIR, "scripts/toolchain.lua"))
if not toolchain(BGFX_BUILD_DIR, BGFX_THIRD_PARTY_DIR) then
	return -- no action specified
end

function copyLib()
end

function addprojectflags()
	if _ACTION == "gmake" then
		buildoptions {
			"-Wno-unused-parameter",
			"-Wno-shadow",
			"-Wno-array-bounds",
		}	
	end
	configuration { "vs*" }
		buildoptions {
			"/wd4244", -- warning C4244: 'argument' : conversion from 'xxx' to 'xxx', possible loss of data
			"/wd4334", -- warning C4334: '<<': result of 32-bit shift implicitly converted to 64 bits (was 64-bit shift intended?)
			"/wd4800", -- warning C4800: 'type' : forcing value to bool 'true' or 'false' (performance warning)
			"/wd4723", -- warning C4723: 'potential divide by 0
		}			
end

dofile (path.join(BGFX_DIR, "scripts", "bgfx.lua"))

group "common"
dofile (path.join(BGFX_DIR, "scripts", "example-common.lua"))

group "libs"
bgfxProject("", "StaticLib", {})
dofile("netlist.lua")

group "main"

-- MAIN Project
project ("netedit")
	uuid (os.uuid("netedit"))
	kind "WindowedApp"

targetdir(MODULE_DIR)
targetsuffix ""

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
	"netlist",
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

