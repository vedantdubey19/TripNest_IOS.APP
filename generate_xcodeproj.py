import os
import hashlib

def get_uuid(path, prefix):
    # Generates a deterministic 24-character hexadecimal string suitable for Xcode UUIDs
    m = hashlib.md5((prefix + path).encode('utf-8')).hexdigest()
    return m[:24].upper()

def main():
    print("Scanning directories for Swift source files...")
    subdirs = ["App", "Core", "Models", "Repositories", "ViewModels", "Views"]
    
    # Recursively find all swift files inside our project directories
    all_files = []
    for sd in subdirs:
        if not os.path.exists(sd):
            continue
        for root, dirs, files in os.walk(sd):
            for file in files:
                if file.endswith(".swift"):
                    file_path = os.path.join(root, file)
                    all_files.append(file_path)
                    
    # Sort for deterministic output
    all_files.sort()
    
    if not all_files:
        print("Error: No Swift files found. Make sure you are in the project root directory.")
        return
        
    print(f"Found {len(all_files)} Swift source files.")
    
    # Establish directory group representations
    groups = {} # path -> list of (child_name, child_is_dir, child_path)
    for f in all_files:
        parts = f.split(os.sep)
        for i in range(len(parts)):
            parent_path = os.sep.join(parts[:i]) if i > 0 else ""
            if i < len(parts) - 1:
                child_name = parts[i]
                child_path = os.sep.join(parts[:i+1])
                is_dir = True
            else:
                child_name = parts[i]
                child_path = f
                is_dir = False
            
            if parent_path not in groups:
                groups[parent_path] = []
            
            item = (child_name, is_dir, child_path)
            if item not in groups[parent_path]:
                groups[parent_path].append(item)
                
    # Insert Assets.xcassets group representation under App group
    if "App" not in groups:
        groups["App"] = []
    groups["App"].append(("Assets.xcassets", False, "App/Assets.xcassets"))
    
    # Define UUID Constants
    PROJECT_UUID = "DF798B752C8D40578AFEB040"
    TARGET_UUID = "DF798B762C8D40578AFEB040"
    SOURCES_BUILD_PHASE_UUID = "DF798B772C8D40578AFEB040"
    FRAMEWORKS_BUILD_PHASE_UUID = "DF798B782C8D40578AFEB040"
    RESOURCES_BUILD_PHASE_UUID = "DF798B792C8D40578AFEB040"
    MAIN_GROUP_UUID = "DF798B7A2C8D40578AFEB040"
    PRODUCTS_GROUP_UUID = "DF798B7B2C8D40578AFEB040"
    PRODUCT_FILE_REF_UUID = "DF798B7C2C8D40578AFEB040"
    PROJECT_CONFIG_LIST_UUID = "DF798B7D2C8D40578AFEB040"
    TARGET_CONFIG_LIST_UUID = "DF798B7E2C8D40578AFEB040"
    PROJECT_DEBUG_CONFIG_UUID = "DF798B7F2C8D40578AFEB040"
    PROJECT_RELEASE_CONFIG_UUID = "DF798B802C8D40578AFEB040"
    TARGET_DEBUG_CONFIG_UUID = "DF798B812C8D40578AFEB040"
    TARGET_RELEASE_CONFIG_UUID = "DF798B822C8D40578AFEB040"
    
    # Asset catalog UUIDs
    ASSETS_REF_UUID = "DF798B8D2C8D40578AFEB040"
    ASSETS_BLD_UUID = "DF798B8E2C8D40578AFEB040"
    
    build_files_section = []
    file_refs_section = []
    groups_section = []
    
    file_uuids = {} # path -> (file_ref_uuid, build_file_uuid)
    for f in all_files:
        file_ref = get_uuid(f, "REF")
        build_file = get_uuid(f, "BLD")
        file_uuids[f] = (file_ref, build_file)
        
        file_name = os.path.basename(f)
        build_files_section.append(f"\t\t{build_file} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {file_name} */; }};")
        file_refs_section.append(f"\t\t{file_ref} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = \"{file_name}\"; path = \"{f}\"; sourceTree = \"SOURCE_ROOT\"; }};")
        
    # Append Assets.xcassets reference and build file
    file_uuids["App/Assets.xcassets"] = (ASSETS_REF_UUID, ASSETS_BLD_UUID)
    build_files_section.append(f"\t\t{ASSETS_BLD_UUID} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ASSETS_REF_UUID} /* Assets.xcassets */; }};")
    file_refs_section.append(f"\t\t{ASSETS_REF_UUID} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; name = \"Assets.xcassets\"; path = \"App/Assets.xcassets\"; sourceTree = \"SOURCE_ROOT\"; }};")
    
    # Append application product bundle ref
    file_refs_section.append(f"\t\t{PRODUCT_FILE_REF_UUID} /* TripNest.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = TripNest.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    
    # Generate UUIDs for all directories
    group_uuids = {} # path -> uuid
    for path in groups:
        if path == "":
            group_uuids[path] = MAIN_GROUP_UUID
        else:
            group_uuids[path] = get_uuid(path, "GRP")
            
    # Compile PBXGroup nodes
    for path, children in groups.items():
        group_uuid = group_uuids[path]
        children_lines = []
        
        # Sort children for clean Xcode display (subfolders first, then files)
        sorted_children = sorted(children, key=lambda x: (not x[1], x[0]))
        
        for name, is_dir, child_path in sorted_children:
            if is_dir:
                child_uuid = group_uuids[child_path]
                children_lines.append(f"\t\t\t\t{child_uuid} /* {name} */,")
            else:
                child_uuid = file_uuids[child_path][0]
                children_lines.append(f"\t\t\t\t{child_uuid} /* {name} */,")
                
        # Main group contains products too
        if path == "":
            children_lines.append(f"\t\t\t\t{PRODUCTS_GROUP_UUID} /* Products */,")
            
        group_name_comment = os.path.basename(path) if path != "" else "TripNest"
        
        path_prop = f"path = \"{os.path.basename(path)}\";" if path != "" else ""
        name_prop = f"name = \"{group_name_comment}\";" if path != "" else ""
        
        group_content = f"""\t\t{group_uuid} /* {group_name_comment} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{"\n".join(children_lines)}
\t\t\t);
\t\t\t{name_prop}
\t\t\t{path_prop}
\t\t\tsourceTree = "<group>";
\t\t}};"""
        groups_section.append(group_content)
        
    # Append Products Group
    products_group = f"""\t\t{PRODUCTS_GROUP_UUID} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{PRODUCT_FILE_REF_UUID} /* TripNest.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};"""
    groups_section.append(products_group)
    
    # Sources compiler list
    sources_lines = []
    for f in all_files:
        build_file = file_uuids[f][1]
        file_name = os.path.basename(f)
        sources_lines.append(f"\t\t\t\t{build_file} /* {file_name} in Sources */,")
        
    sources_build_phase = f"""\t\t{SOURCES_BUILD_PHASE_UUID} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{"\n".join(sources_lines)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""
    
    pbxproj_content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_files_section)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(file_refs_section)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{FRAMEWORKS_BUILD_PHASE_UUID} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{chr(10).join(groups_section)}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{TARGET_UUID} /* TripNest */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {TARGET_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget "TripNest" */;
			buildPhases = (
				{SOURCES_BUILD_PHASE_UUID} /* Sources */,
				{FRAMEWORKS_BUILD_PHASE_UUID} /* Frameworks */,
				{RESOURCES_BUILD_PHASE_UUID} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = TripNest;
			productName = TripNest;
			productReference = {PRODUCT_FILE_REF_UUID} /* TripNest.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{PROJECT_UUID} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{TARGET_UUID} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {PROJECT_CONFIG_LIST_UUID} /* Build configuration list for PBXProject "TripNest" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {MAIN_GROUP_UUID} /* TripNest */;
			productRefGroup = {PRODUCTS_GROUP_UUID} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{TARGET_UUID} /* TripNest */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{RESOURCES_BUILD_PHASE_UUID} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{ASSETS_BLD_UUID} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

{sources_build_phase}

/* Begin XCBuildConfiguration section */
		{PROJECT_DEBUG_CONFIG_UUID} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_CXX_LIBRARY = "libc++";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_PREPROCESSOR_DEFINITIONS = YES;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_ACTUAL = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{PROJECT_RELEASE_CONFIG_UUID} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_CXX_LIBRARY = "libc++";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_PREPROCESSOR_DEFINITIONS = YES;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_ACTUAL = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
			}};
			name = Release;
		}};
		{TARGET_DEBUG_CONFIG_UUID} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_DEBUG_DYLIB = YES;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tripnest.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{TARGET_RELEASE_CONFIG_UUID} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tripnest.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{PROJECT_CONFIG_LIST_UUID} /* Build configuration list for PBXProject "TripNest" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{PROJECT_DEBUG_CONFIG_UUID} /* Debug */,
				{PROJECT_RELEASE_CONFIG_UUID} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{TARGET_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget "TripNest" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{TARGET_DEBUG_CONFIG_UUID} /* Debug */,
				{TARGET_RELEASE_CONFIG_UUID} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {PROJECT_UUID} /* Project object */;
}}
"""
    
    # Create directories if they do not exist
    os.makedirs("TripNest.xcodeproj", exist_ok=True)
    os.makedirs("TripNest.xcodeproj/project.xcworkspace", exist_ok=True)
    
    # Write files
    with open("TripNest.xcodeproj/project.pbxproj", "w") as f:
        f.write(pbxproj_content)
        
    workspace_content = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:TripNest.xcodeproj">
   </FileRef>
</Workspace>
"""
    with open("TripNest.xcodeproj/project.xcworkspace/contents.xcworkspacedata", "w") as f:
        f.write(workspace_content)
        
    print("Successfully generated TripNest.xcodeproj with native iOS application targets!")

if __name__ == "__main__":
    main()
