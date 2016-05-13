#import "NBMetadataCoreTestMapper.h"

@implementation NBMetadataCoreTestMapper

static NSMutableDictionary *kMapCCode2CN;

+ (NSArray *)ISOCodeFromCallingNumber:(NSString *)key
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kMapCCode2CN = [[NSMutableDictionary alloc] init];

        NSMutableArray *countryCode971Array = [[NSMutableArray alloc] init];
        [countryCode971Array addObject:@"AE"];
        [kMapCCode2CN setObject:countryCode971Array forKey:@"971"];

        NSMutableArray *countryCode55Array = [[NSMutableArray alloc] init];
        [countryCode55Array addObject:@"BR"];
        [kMapCCode2CN setObject:countryCode55Array forKey:@"55"];

        NSMutableArray *countryCode48Array = [[NSMutableArray alloc] init];
        [countryCode48Array addObject:@"PL"];
        [kMapCCode2CN setObject:countryCode48Array forKey:@"48"];

        NSMutableArray *countryCode33Array = [[NSMutableArray alloc] init];
        [countryCode33Array addObject:@"FR"];
        [kMapCCode2CN setObject:countryCode33Array forKey:@"33"];

        NSMutableArray *countryCode49Array = [[NSMutableArray alloc] init];
        [countryCode49Array addObject:@"DE"];
        [kMapCCode2CN setObject:countryCode49Array forKey:@"49"];

        NSMutableArray *countryCode86Array = [[NSMutableArray alloc] init];
        [countryCode86Array addObject:@"CN"];
        [kMapCCode2CN setObject:countryCode86Array forKey:@"86"];

        NSMutableArray *countryCode64Array = [[NSMutableArray alloc] init];
        [countryCode64Array addObject:@"NZ"];
        [kMapCCode2CN setObject:countryCode64Array forKey:@"64"];

        NSMutableArray *countryCode800Array = [[NSMutableArray alloc] init];
        [countryCode800Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode800Array forKey:@"800"];

        NSMutableArray *countryCode1Array = [[NSMutableArray alloc] init];
        [countryCode1Array addObject:@"US"];
        [countryCode1Array addObject:@"BB"];
        [countryCode1Array addObject:@"BS"];
        [countryCode1Array addObject:@"CA"];
        [kMapCCode2CN setObject:countryCode1Array forKey:@"1"];

        NSMutableArray *countryCode65Array = [[NSMutableArray alloc] init];
        [countryCode65Array addObject:@"SG"];
        [kMapCCode2CN setObject:countryCode65Array forKey:@"65"];

        NSMutableArray *countryCode36Array = [[NSMutableArray alloc] init];
        [countryCode36Array addObject:@"HU"];
        [kMapCCode2CN setObject:countryCode36Array forKey:@"36"];

        NSMutableArray *countryCode244Array = [[NSMutableArray alloc] init];
        [countryCode244Array addObject:@"AO"];
        [kMapCCode2CN setObject:countryCode244Array forKey:@"244"];

        NSMutableArray *countryCode375Array = [[NSMutableArray alloc] init];
        [countryCode375Array addObject:@"BY"];
        [kMapCCode2CN setObject:countryCode375Array forKey:@"375"];

        NSMutableArray *countryCode44Array = [[NSMutableArray alloc] init];
        [countryCode44Array addObject:@"GB"];
        [countryCode44Array addObject:@"GG"];
        [kMapCCode2CN setObject:countryCode44Array forKey:@"44"];

        NSMutableArray *countryCode81Array = [[NSMutableArray alloc] init];
        [countryCode81Array addObject:@"JP"];
        [kMapCCode2CN setObject:countryCode81Array forKey:@"81"];

        NSMutableArray *countryCode52Array = [[NSMutableArray alloc] init];
        [countryCode52Array addObject:@"MX"];
        [kMapCCode2CN setObject:countryCode52Array forKey:@"52"];

        NSMutableArray *countryCode82Array = [[NSMutableArray alloc] init];
        [countryCode82Array addObject:@"KR"];
        [kMapCCode2CN setObject:countryCode82Array forKey:@"82"];

        NSMutableArray *countryCode376Array = [[NSMutableArray alloc] init];
        [countryCode376Array addObject:@"AD"];
        [kMapCCode2CN setObject:countryCode376Array forKey:@"376"];

        NSMutableArray *countryCode979Array = [[NSMutableArray alloc] init];
        [countryCode979Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode979Array forKey:@"979"];

        NSMutableArray *countryCode46Array = [[NSMutableArray alloc] init];
        [countryCode46Array addObject:@"SE"];
        [kMapCCode2CN setObject:countryCode46Array forKey:@"46"];

        NSMutableArray *countryCode39Array = [[NSMutableArray alloc] init];
        [countryCode39Array addObject:@"IT"];
        [kMapCCode2CN setObject:countryCode39Array forKey:@"39"];

        NSMutableArray *countryCode61Array = [[NSMutableArray alloc] init];
        [countryCode61Array addObject:@"AU"];
        [countryCode61Array addObject:@"CC"];
        [countryCode61Array addObject:@"CX"];
        [kMapCCode2CN setObject:countryCode61Array forKey:@"61"];

        NSMutableArray *countryCode54Array = [[NSMutableArray alloc] init];
        [countryCode54Array addObject:@"AR"];
        [kMapCCode2CN setObject:countryCode54Array forKey:@"54"];

        NSMutableArray *countryCode262Array = [[NSMutableArray alloc] init];
        [countryCode262Array addObject:@"RE"];
        [countryCode262Array addObject:@"YT"];
        [kMapCCode2CN setObject:countryCode262Array forKey:@"262"];
    });
    return [kMapCCode2CN objectForKey:key];
}

@end

