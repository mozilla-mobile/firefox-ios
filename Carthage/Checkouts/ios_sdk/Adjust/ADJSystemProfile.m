/*
 * Copyright 2008-2014, Torsten Curdt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// original at https://github.com/tcurdt/feedbackreporter/blob/master/Sources/Main/FRSystemProfile.m

#import "ADJSystemProfile.h"
#import <sys/sysctl.h>
#import <sys/types.h>
#import <mach/machine.h>
#import "ADJAdjustFactory.h"
#import "ADJLogger.h"

@implementation ADJSystemProfile

+ (BOOL) is64bit
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);

    error = sysctlbyname("hw.cpu64bit_capable", &value, &length, NULL, 0);
    
    if(error != 0) {
        error = sysctlbyname("hw.optional.x86_64", &value, &length, NULL, 0); //x86 specific
    }
    
    if(error != 0) {
        error = sysctlbyname("hw.optional.64bitops", &value, &length, NULL, 0); //PPC specific
    }

    if (error != 0) {
        return NO;
    }

    return value == 1;
}

+ (NSString*) cpuFamily
{
    int cpufamily = -1;
    size_t length = sizeof(cpufamily);
    int error = sysctlbyname("hw.cpufamily", &cpufamily, &length, NULL, 0);

    if (error != 0) {
        [ADJAdjustFactory.logger error:@"Failed to obtain CPU family (%d)", error];
        return nil;
    }
    switch (cpufamily)
    {
#ifdef CPUFAMILY_UNKNOWN
        case CPUFAMILY_UNKNOWN:
            return @"CPUFAMILY_UNKNOWN";
#endif
#ifdef CPUFAMILY_POWERPC_G3
        case CPUFAMILY_POWERPC_G3:
            return @"CPUFAMILY_POWERPC_G3";
#endif
#ifdef CPUFAMILY_POWERPC_G4
        case CPUFAMILY_POWERPC_G4:
            return @"CPUFAMILY_POWERPC_G4";
#endif
#ifdef CPUFAMILY_POWERPC_G5
        case CPUFAMILY_POWERPC_G5:
            return @"CPUFAMILY_POWERPC_G5";
#endif
#ifdef CPUFAMILY_INTEL_6_13
        case CPUFAMILY_INTEL_6_13:
            return @"CPUFAMILY_INTEL_6_13";
#endif
#ifdef CPUFAMILY_INTEL_YONAH
        case CPUFAMILY_INTEL_YONAH:
            return @"CPUFAMILY_INTEL_YONAH";
#endif
#ifdef CPUFAMILY_INTEL_MEROM
        case CPUFAMILY_INTEL_MEROM:
            return @"CPUFAMILY_INTEL_MEROM";
#endif
#ifdef CPUFAMILY_INTEL_PENRYN
        case CPUFAMILY_INTEL_PENRYN:
            return @"CPUFAMILY_INTEL_PENRYN";
#endif
#ifdef CPUFAMILY_INTEL_NEHALEM
        case CPUFAMILY_INTEL_NEHALEM:
            return @"CPUFAMILY_INTEL_NEHALEM";
#endif
#ifdef CPUFAMILY_INTEL_WESTMERE
        case CPUFAMILY_INTEL_WESTMERE:
            return @"CPUFAMILY_INTEL_WESTMERE";
#endif
#ifdef CPUFAMILY_INTEL_SANDYBRIDGE
        case CPUFAMILY_INTEL_SANDYBRIDGE:
            return @"CPUFAMILY_INTEL_SANDYBRIDGE";
#endif
#ifdef CPUFAMILY_INTEL_IVYBRIDGE
        case CPUFAMILY_INTEL_IVYBRIDGE:
            return @"CPUFAMILY_INTEL_IVYBRIDGE";
#endif
#ifdef CPUFAMILY_INTEL_HASWELL
        case CPUFAMILY_INTEL_HASWELL:
            return @"CPUFAMILY_INTEL_HASWELL";
#endif
#ifdef CPUFAMILY_INTEL_BROADWELL
        case CPUFAMILY_INTEL_BROADWELL:
            return @"CPUFAMILY_INTEL_BROADWELL";
#endif
#ifdef CPUFAMILY_INTEL_SKYLAKE
        case CPUFAMILY_INTEL_SKYLAKE:
            return @"CPUFAMILY_INTEL_SKYLAKE";
#endif
#ifdef CPUFAMILY_ARM_9
        case CPUFAMILY_ARM_9:
            return @"CPUFAMILY_ARM_9";
#endif
#ifdef CPUFAMILY_ARM_11
        case CPUFAMILY_ARM_11:
            return @"CPUFAMILY_ARM_11";
#endif
#ifdef CPUFAMILY_ARM_XSCALE
        case CPUFAMILY_ARM_XSCALE:
            return @"CPUFAMILY_ARM_XSCALE";
#endif
#ifdef CPUFAMILY_ARM_12
        case CPUFAMILY_ARM_12:
            return @"CPUFAMILY_ARM_12";
#endif
#ifdef CPUFAMILY_ARM_13
        case CPUFAMILY_ARM_13:
            return @"CPUFAMILY_ARM_13";
#endif
#ifdef CPUFAMILY_ARM_14
        case CPUFAMILY_ARM_14:
            return @"CPUFAMILY_ARM_14";
#endif
#ifdef CPUFAMILY_ARM_15
        case CPUFAMILY_ARM_15:
            return @"CPUFAMILY_ARM_15";
#endif
#ifdef CPUFAMILY_ARM_SWIFT
        case CPUFAMILY_ARM_SWIFT:
            return @"CPUFAMILY_ARM_SWIFT";
#endif
#ifdef CPUFAMILY_ARM_CYCLONE
        case CPUFAMILY_ARM_CYCLONE:
            return @"CPUFAMILY_ARM_CYCLONE";
#endif
#ifdef CPUFAMILY_ARM_TYPHOON
        case CPUFAMILY_ARM_TYPHOON:
            return @"CPUFAMILY_ARM_TYPHOON";
#endif
#ifdef CPUFAMILY_ARM_TWISTER
        case CPUFAMILY_ARM_TWISTER:
            return @"CPUFAMILY_ARM_TWISTER";
#endif
#ifdef CPUFAMILY_ARM_HURRICANE
        case CPUFAMILY_ARM_HURRICANE:
            return @"CPUFAMILY_ARM_HURRICANE";
#endif
    }
    NSString * unknowCpuFamily = [NSString stringWithFormat:@"Unknown CPU family %d", cpufamily];
    [ADJAdjustFactory.logger warn:@"%@", unknowCpuFamily];
    return unknowCpuFamily;
}
/*
 original function
 operatingSystemVersionString should not be parsed
  https://developer.apple.com/reference/foundation/nsprocessinfo/1408730-operatingsystemversionstring?language=objc
+ (NSString*) osVersion
{
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if (info == nil) {
        return nil;
    }
    NSString *version = [info operatingSystemVersionString];
    
    if ([version hasPrefix:@"Version "]) {
        version = [version substringFromIndex:8];
    }

    return version;
}
*/
+ (int) cpuCount
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);
    error = sysctlbyname("hw.ncpu", &value, &length, NULL, 0);
    
    if (error != 0) {
        [ADJAdjustFactory.logger error:@"Failed to obtain CPU count (%d)", error];
        return 1;
    }
    
    return value;
}

+ (NSString*) machineArch
{
    return [ADJSystemProfile readSysctlbByNameString:"hw.machinearch" errorLog:@"Failed to obtain machine arch"];
}

+ (NSString*) machineModel
{
    return [ADJSystemProfile readSysctlbByNameString:"hw.model" errorLog:@"Failed to obtain machine model"];
}

+ (NSString*) cpuBrand
{
    return [ADJSystemProfile readSysctlbByNameString:"machdep.cpu.brand_string" errorLog:@"Failed to obtain CPU brand"];
}

+ (NSString*) cpuFeatures
{
    return [ADJSystemProfile readSysctlbByNameString:"machdep.cpu.features" errorLog:@"Failed to obtain CPU features"];
}

+ (NSString*) cpuVendor
{
    return [ADJSystemProfile readSysctlbByNameString:"machdep.cpu.vendor" errorLog:@"Failed to obtain CPU vendor"];
}

+ (NSString*) osVersion
{
    return [ADJSystemProfile readSysctlbByNameString:"kern.osversion" errorLog:@"Failed to obtain OS version"];
}

+ (NSString*) readSysctlbByNameString:(const char *)name
                             errorLog:(NSString*)errorLog
{
    int error = 0;
    size_t length = 0;
    error = sysctlbyname(name, NULL, &length, NULL, 0);

    if (error != 0) {
        [ADJAdjustFactory.logger error:@"%@ (%d)", errorLog, error];
        return nil;
    }

    char *p = malloc(sizeof(char) * length);
    if (p) {
        error = sysctlbyname(name, p, &length, NULL, 0);
    }

    if (error != 0) {
        [ADJAdjustFactory.logger error:@"%@ (%d)", errorLog, error];
        free(p);
        return nil;
    }

    NSString * result = [NSString stringWithUTF8String:p];

    free(p);

    return result;

}

+ (NSString*) appleLanguage
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defs objectForKey:@"AppleLanguages"];

    if ([languages count] == 0) {
        [ADJAdjustFactory.logger error:@"Failed to obtain preferred language"];
        return nil;
    }
    
    return [languages objectAtIndex:0];
}

+ (long long) cpuSpeed
{
    long long result = 0;

	int error = 0;

    int64_t hertz = 0;
	size_t size = sizeof(hertz);
	int mib[2] = {CTL_HW, HW_CPU_FREQ};
	
	error = sysctl(mib, 2, &hertz, &size, NULL, 0);
	
    if (error) {
        [ADJAdjustFactory.logger error:@"Failed to obtain CPU speed (%d)", error];
        return -1;
    }
	
	result = (long long)(hertz/1000000); // Convert to MHz
    
    return result;
}

+ (long long) ramsize
{
    long long result = 0;

	int error = 0;
    int64_t value = 0;
    size_t length = sizeof(value);
	
    error = sysctlbyname("hw.memsize", &value, &length, NULL, 0);
	if (error) {
        [ADJAdjustFactory.logger error:@"Failed to obtain RAM size (%d)", error];
        return -1;
	}
	const int64_t kBytesPerMebibyte = 1024*1024;
	result = (long long)(value/kBytesPerMebibyte);
    
    return result;
}


+ (NSString*) cpuType
{
    int error = 0;

    int cputype = -1;
    size_t length = sizeof(cputype);
    error = sysctlbyname("hw.cputype", &cputype, &length, NULL, 0);

    if (error != 0) {
        [ADJAdjustFactory.logger error:@"Failed to obtain CPU type (%d)", error];
        return nil;
    }

    NSString * cpuTypeString = [ADJSystemProfile readCpuTypeSubtype:cputype readSubType:NO cpusubtype:0];

    if (cpuTypeString != nil) {
        return cpuTypeString;
    }

    NSString * unknowCpuType = [NSString stringWithFormat:@"Unknown CPU type %d", cputype];
    [ADJAdjustFactory.logger warn:@"%@", unknowCpuType];
    return unknowCpuType;
}

+ (NSString*) cpuSubtype
{
    int error = 0;

    int cputype = -1;
    size_t length = sizeof(cputype);
    error = sysctlbyname("hw.cputype", &cputype, &length, NULL, 0);

    if (error != 0) {
        [ADJAdjustFactory.logger error:@"Failed to obtain CPU type (%d)", error];
        return nil;
    }

    int cpuSubtype = -1;
    length = sizeof(cpuSubtype);
    error = sysctlbyname("hw.cpusubtype", &cpuSubtype, &length, NULL, 0);

    if (error != 0) {
        [ADJAdjustFactory.logger error:@"Failed to obtain CPU subtype (%d)", error];
        return nil;
    }


    NSString * cpuSubtypeString = [ADJSystemProfile readCpuTypeSubtype:cputype readSubType:YES cpusubtype:cpuSubtype];

    if (cpuSubtypeString != nil) {
        return cpuSubtypeString;
    }

    NSString * unknowCpuSubtype = [NSString stringWithFormat:@"Unknown CPU subtype %d", cpuSubtype];
    [ADJAdjustFactory.logger warn:@"%@", unknowCpuSubtype];
    return unknowCpuSubtype;
}

+ (NSString*) readCpuTypeSubtype:(int)cputype
                     readSubType:(BOOL)readSubType
                      cpusubtype:(int)cpusubtype
{
    switch (cputype)
    {
#ifdef CPU_TYPE_ANY
        case CPU_TYPE_ANY:
            if (!readSubType) return @"CPU_TYPE_ANY";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_MULTIPLE
            case CPU_SUBTYPE_MULTIPLE:
                return @"CPU_SUBTYPE_MULTIPLE";
#endif
#ifdef CPU_SUBTYPE_LITTLE_ENDIAN
            case CPU_SUBTYPE_LITTLE_ENDIAN:
                return @"CPU_SUBTYPE_LITTLE_ENDIAN";
#endif
#ifdef CPU_SUBTYPE_BIG_ENDIAN
            case CPU_SUBTYPE_BIG_ENDIAN:
                return @"CPU_SUBTYPE_BIG_ENDIAN";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_VAX
        case CPU_TYPE_VAX:
            if (!readSubType) return @"CPU_TYPE_VAX";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_VAX_ALL
            case CPU_SUBTYPE_VAX_ALL:
                return @"CPU_SUBTYPE_VAX_ALL";
#endif
#ifdef CPU_SUBTYPE_VAX780
            case CPU_SUBTYPE_VAX780:
                return @"CPU_SUBTYPE_VAX780";
#endif
#ifdef CPU_SUBTYPE_VAX785
            case CPU_SUBTYPE_VAX785:
                return @"CPU_SUBTYPE_VAX785";
#endif
#ifdef CPU_SUBTYPE_VAX750
            case CPU_SUBTYPE_VAX750:
                return @"CPU_SUBTYPE_VAX750";
#endif
#ifdef CPU_SUBTYPE_VAX730
            case CPU_SUBTYPE_VAX730:
                return @"CPU_SUBTYPE_VAX730";
#endif
#ifdef CPU_SUBTYPE_UVAXI
            case CPU_SUBTYPE_UVAXI:
                return @"CPU_SUBTYPE_UVAXI";
#endif
#ifdef CPU_SUBTYPE_UVAXII
            case CPU_SUBTYPE_UVAXII:
                return @"CPU_SUBTYPE_UVAXII";
#endif
#ifdef CPU_SUBTYPE_VAX8200
            case CPU_SUBTYPE_VAX8200:
                return @"CPU_SUBTYPE_VAX8200";
#endif
#ifdef CPU_SUBTYPE_VAX8500
            case CPU_SUBTYPE_VAX8500:
                return @"CPU_SUBTYPE_VAX8500";
#endif
#ifdef CPU_SUBTYPE_VAX8600
            case CPU_SUBTYPE_VAX8600:
                return @"CPU_SUBTYPE_VAX8600";
#endif
#ifdef CPU_SUBTYPE_VAX8650
            case CPU_SUBTYPE_VAX8650:
                return @"CPU_SUBTYPE_VAX8650";
#endif
#ifdef CPU_SUBTYPE_VAX8800
            case CPU_SUBTYPE_VAX8800:
                return @"CPU_SUBTYPE_VAX8800";
#endif
#ifdef CPU_SUBTYPE_UVAXIII
            case CPU_SUBTYPE_UVAXIII:
                return @"CPU_SUBTYPE_UVAXIII";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_MC680x0
        case CPU_TYPE_MC680x0:
            if (!readSubType) return @"CPU_TYPE_MC680x0";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_MC680x0_ALL
            case CPU_SUBTYPE_MC680x0_ALL:
                return @"CPU_SUBTYPE_MC680x0_ALL";
#endif
#ifdef CPU_SUBTYPE_MC68040
            case CPU_SUBTYPE_MC68040:
                return @"CPU_SUBTYPE_MC68040";
#endif
#ifdef CPU_SUBTYPE_MC68030_ONLY
            case CPU_SUBTYPE_MC68030_ONLY:
                return @"CPU_SUBTYPE_MC68030_ONLY";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_X86_64
        case CPU_TYPE_X86_64:
            if (!readSubType) return @"CPU_TYPE_X86_64";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_X86_64_ALL
            case CPU_SUBTYPE_X86_64_ALL:
                return @"CPU_SUBTYPE_X86_64_ALL";
#endif
#ifdef CPU_SUBTYPE_X86_ARCH1
            case CPU_SUBTYPE_X86_ARCH1:
                return @"CPU_SUBTYPE_X86_ARCH1";
#endif
#ifdef CPU_SUBTYPE_X86_64_H
            case CPU_SUBTYPE_X86_64_H:
                return @"CPU_SUBTYPE_X86_64_H";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_X86
        case CPU_TYPE_X86:
            if (!readSubType) return @"CPU_TYPE_X86";
            switch (cpusubtype) {
#ifdef CPU_SUBTYPE_386
                case CPU_SUBTYPE_386:
                    return @"CPU_SUBTYPE_386";
#endif
#ifdef CPU_SUBTYPE_486
                case CPU_SUBTYPE_486:
                    return @"CPU_SUBTYPE_486";
#endif
#ifdef CPU_SUBTYPE_486SX
                case CPU_SUBTYPE_486SX:
                    return @"CPU_SUBTYPE_486SX";
#endif
#ifdef CPU_SUBTYPE_586
                case CPU_SUBTYPE_586:
                    return @"CPU_SUBTYPE_586";
#endif
#ifdef CPU_SUBTYPE_PENTPRO
                case CPU_SUBTYPE_PENTPRO:
                    return @"CPU_SUBTYPE_PENTPRO";
#endif
#ifdef CPU_SUBTYPE_PENTII_M3
                case CPU_SUBTYPE_PENTII_M3:
                    return @"CPU_SUBTYPE_PENTII_M3";
#endif
#ifdef CPU_SUBTYPE_PENTII_M5
                case CPU_SUBTYPE_PENTII_M5:
                    return @"CPU_SUBTYPE_PENTII_M5";
#endif
#ifdef CPU_SUBTYPE_CELERON
                case CPU_SUBTYPE_CELERON:
                    return @"CPU_SUBTYPE_CELERON";
#endif
#ifdef CPU_SUBTYPE_CELERON_MOBILE
                case CPU_SUBTYPE_CELERON_MOBILE:
                    return @"CPU_SUBTYPE_CELERON_MOBILE";
#endif
#ifdef CPU_SUBTYPE_PENTIUM_3
                case CPU_SUBTYPE_PENTIUM_3:
                    return @"CPU_SUBTYPE_PENTIUM_3";
#endif
#ifdef CPU_SUBTYPE_PENTIUM_3_M
                case CPU_SUBTYPE_PENTIUM_3_M:
                    return @"CPU_SUBTYPE_PENTIUM_3_M";
#endif
#ifdef CPU_SUBTYPE_PENTIUM_3_XEON
                case CPU_SUBTYPE_PENTIUM_3_XEON:
                    return @"CPU_SUBTYPE_PENTIUM_3_XEON";
#endif
#ifdef CPU_SUBTYPE_PENTIUM_M
                case CPU_SUBTYPE_PENTIUM_M:
                    return @"CPU_SUBTYPE_PENTIUM_M";
#endif
#ifdef CPU_SUBTYPE_PENTIUM_4
                case CPU_SUBTYPE_PENTIUM_4:
                    return @"CPU_SUBTYPE_PENTIUM_4";
#endif
#ifdef CPU_SUBTYPE_PENTIUM_4_M
                case CPU_SUBTYPE_PENTIUM_4_M:
                    return @"CPU_SUBTYPE_PENTIUM_4_M";
#endif
#ifdef CPU_SUBTYPE_ITANIUM
                case CPU_SUBTYPE_ITANIUM:
                    return @"CPU_SUBTYPE_ITANIUM";
#endif
#ifdef CPU_SUBTYPE_ITANIUM_2
                case CPU_SUBTYPE_ITANIUM_2:
                    return @"CPU_SUBTYPE_ITANIUM_2";
#endif
#ifdef CPU_SUBTYPE_XEON
                case CPU_SUBTYPE_XEON:
                    return @"CPU_SUBTYPE_XEON";
#endif
#ifdef CPU_SUBTYPE_XEON_MP
                case CPU_SUBTYPE_XEON_MP:
                    return @"CPU_SUBTYPE_XEON_MP";
#endif
            }
            break;
#endif
#ifdef CPU_TYPE_MC98000
        case CPU_TYPE_MC98000:
            if (!readSubType) return @"CPU_TYPE_MC98000";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_MC98000_ALL
            case CPU_SUBTYPE_MC98000_ALL:
                return @"CPU_SUBTYPE_MC98000_ALL";
#endif
#ifdef CPU_SUBTYPE_MC98601
            case CPU_SUBTYPE_MC98601:
                return @"CPU_SUBTYPE_MC98601";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_HPPA
        case CPU_TYPE_HPPA:
            if (!readSubType) return @"CPU_TYPE_HPPA";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_HPPA_7100
            case CPU_SUBTYPE_HPPA_7100:
                return @"CPU_SUBTYPE_HPPA_7100";
#endif
#ifdef CPU_SUBTYPE_HPPA_7100LC
            case CPU_SUBTYPE_HPPA_7100LC:
                return @"CPU_SUBTYPE_HPPA_7100LC";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_ARM64
        case CPU_TYPE_ARM64:
            if (!readSubType) return @"CPU_TYPE_ARM64";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_ARM64_ALL
            case CPU_SUBTYPE_ARM64_ALL:
                return @"CPU_SUBTYPE_ARM64_ALL";
#endif
#ifdef CPU_SUBTYPE_ARM64_V8
            case CPU_SUBTYPE_ARM64_V8:
                return @"CPU_SUBTYPE_ARM64_V8";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_ARM
        case CPU_TYPE_ARM:
            if (!readSubType) return @"CPU_TYPE_ARM";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_ARM_ALL
            case CPU_SUBTYPE_ARM_ALL:
                return @"CPU_SUBTYPE_ARM_ALL";
#endif
#ifdef CPU_SUBTYPE_ARM_V4T
            case CPU_SUBTYPE_ARM_V4T:
                return @"CPU_SUBTYPE_ARM_V4T";
#endif
#ifdef CPU_SUBTYPE_ARM_V6
            case CPU_SUBTYPE_ARM_V6:
                return @"CPU_SUBTYPE_ARM_V6";
#endif
#ifdef CPU_SUBTYPE_ARM_V5TEJ
            case CPU_SUBTYPE_ARM_V5TEJ:
                return @"CPU_SUBTYPE_ARM_V5TEJ";
#endif
#ifdef CPU_SUBTYPE_ARM_XSCALE
            case CPU_SUBTYPE_ARM_XSCALE:
                return @"CPU_SUBTYPE_ARM_XSCALE";
#endif
#ifdef CPU_SUBTYPE_ARM_V7
            case CPU_SUBTYPE_ARM_V7:
                return @"CPU_SUBTYPE_ARM_V7";
#endif
#ifdef CPU_SUBTYPE_ARM_V7F
            case CPU_SUBTYPE_ARM_V7F:
                return @"CPU_SUBTYPE_ARM_V7F";
#endif
#ifdef CPU_SUBTYPE_ARM_V7S
            case CPU_SUBTYPE_ARM_V7S:
                return @"CPU_SUBTYPE_ARM_V7S";
#endif
#ifdef CPU_SUBTYPE_ARM_V7K
            case CPU_SUBTYPE_ARM_V7K:
                return @"CPU_SUBTYPE_ARM_V7K";
#endif
#ifdef CPU_SUBTYPE_ARM_V6M
            case CPU_SUBTYPE_ARM_V6M:
                return @"CPU_SUBTYPE_ARM_V6M";
#endif
#ifdef CPU_SUBTYPE_ARM_V7M
            case CPU_SUBTYPE_ARM_V7M:
                return @"CPU_SUBTYPE_ARM_V7M";
#endif
#ifdef CPU_SUBTYPE_ARM_V7EM
            case CPU_SUBTYPE_ARM_V7EM:
                return @"CPU_SUBTYPE_ARM_V7EM";
#endif
#ifdef CPU_SUBTYPE_ARM_V8
            case CPU_SUBTYPE_ARM_V8:
                return @"CPU_SUBTYPE_ARM_V8";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_MC88000
        case CPU_TYPE_MC88000:
            if (!readSubType) return @"CPU_TYPE_MC88000";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_MC88000_ALL
            case CPU_SUBTYPE_MC88000_ALL:
                return @"CPU_SUBTYPE_MC88000_ALL";
#endif
#ifdef CPU_SUBTYPE_MC88100
            case CPU_SUBTYPE_MC88100:
                return @"CPU_SUBTYPE_MC88100";
#endif
#ifdef CPU_SUBTYPE_MC88110
            case CPU_SUBTYPE_MC88110:
                return @"CPU_SUBTYPE_MC88110";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_SPARC
        case CPU_TYPE_SPARC:
            if (!readSubType) return @"CPU_TYPE_SPARC";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_SPARC_ALL
            case CPU_SUBTYPE_SPARC_ALL:
                return @"CPU_SUBTYPE_SPARC_ALL";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_I860
        case CPU_TYPE_I860:
            if (!readSubType) return @"CPU_TYPE_I860";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_I860_ALL
            case CPU_SUBTYPE_I860_ALL:
                return @"CPU_SUBTYPE_I860_ALL";
#endif
#ifdef CPU_SUBTYPE_I860_860
            case CPU_SUBTYPE_I860_860:
                return @"CPU_SUBTYPE_I860_860";
#endif
        }
            break;
#endif
#ifdef CPU_TYPE_POWERPC64
        case CPU_TYPE_POWERPC64:
            if (!readSubType) return @"CPU_TYPE_POWERPC64";
            break;
#endif
#ifdef CPU_TYPE_POWERPC
        case CPU_TYPE_POWERPC:
            if (!readSubType) return @"CPU_TYPE_POWERPC";
            switch (cpusubtype)
        {
#ifdef CPU_SUBTYPE_POWERPC_ALL
            case CPU_SUBTYPE_POWERPC_ALL:
                return @"CPU_SUBTYPE_POWERPC_ALL";
#endif
#ifdef CPU_SUBTYPE_POWERPC_601
            case CPU_SUBTYPE_POWERPC_601:
                return @"CPU_SUBTYPE_POWERPC_601";
#endif
#ifdef CPU_SUBTYPE_POWERPC_602
            case CPU_SUBTYPE_POWERPC_602:
                return @"CPU_SUBTYPE_POWERPC_602";
#endif
#ifdef CPU_SUBTYPE_POWERPC_603
            case CPU_SUBTYPE_POWERPC_603:
                return @"CPU_SUBTYPE_POWERPC_603";
#endif
#ifdef CPU_SUBTYPE_POWERPC_603e
            case CPU_SUBTYPE_POWERPC_603e:
                return @"CPU_SUBTYPE_POWERPC_603e";
#endif
#ifdef CPU_SUBTYPE_POWERPC_603ev
            case CPU_SUBTYPE_POWERPC_603ev:
                return @"CPU_SUBTYPE_POWERPC_603ev";
#endif
#ifdef CPU_SUBTYPE_POWERPC_604
            case CPU_SUBTYPE_POWERPC_604:
                return @"CPU_SUBTYPE_POWERPC_604";
#endif
#ifdef CPU_SUBTYPE_POWERPC_604e
            case CPU_SUBTYPE_POWERPC_604e:
                return @"CPU_SUBTYPE_POWERPC_604e";
#endif
#ifdef CPU_SUBTYPE_POWERPC_620
            case CPU_SUBTYPE_POWERPC_620:
                return @"CPU_SUBTYPE_POWERPC_620";
#endif
#ifdef CPU_SUBTYPE_POWERPC_750
            case CPU_SUBTYPE_POWERPC_750:
                return @"CPU_SUBTYPE_POWERPC_750";
#endif
#ifdef CPU_SUBTYPE_POWERPC_7400
            case CPU_SUBTYPE_POWERPC_7400:
                return @"CPU_SUBTYPE_POWERPC_7400";
#endif
#ifdef CPU_SUBTYPE_POWERPC_7450
            case CPU_SUBTYPE_POWERPC_7450:
                return @"CPU_SUBTYPE_POWERPC_7450";
#endif
#ifdef CPU_SUBTYPE_POWERPC_970
            case CPU_SUBTYPE_POWERPC_970:
                return @"CPU_SUBTYPE_POWERPC_970";
#endif
        }
            break;
#endif
    }

    return nil;
}

@end
