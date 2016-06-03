#import "NBMetadataCoreMapper.h"

@implementation NBMetadataCoreMapper

static NSMutableDictionary *kMapCCode2CN;

+ (NSArray *)ISOCodeFromCallingNumber:(NSString *)key
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kMapCCode2CN = [[NSMutableDictionary alloc] init];

        NSMutableArray *countryCode356Array = [[NSMutableArray alloc] init];
        [countryCode356Array addObject:@"MT"];
        [kMapCCode2CN setObject:countryCode356Array forKey:@"356"];

        NSMutableArray *countryCode53Array = [[NSMutableArray alloc] init];
        [countryCode53Array addObject:@"CU"];
        [kMapCCode2CN setObject:countryCode53Array forKey:@"53"];

        NSMutableArray *countryCode381Array = [[NSMutableArray alloc] init];
        [countryCode381Array addObject:@"RS"];
        [kMapCCode2CN setObject:countryCode381Array forKey:@"381"];

        NSMutableArray *countryCode373Array = [[NSMutableArray alloc] init];
        [countryCode373Array addObject:@"MD"];
        [kMapCCode2CN setObject:countryCode373Array forKey:@"373"];

        NSMutableArray *countryCode508Array = [[NSMutableArray alloc] init];
        [countryCode508Array addObject:@"PM"];
        [kMapCCode2CN setObject:countryCode508Array forKey:@"508"];

        NSMutableArray *countryCode509Array = [[NSMutableArray alloc] init];
        [countryCode509Array addObject:@"HT"];
        [kMapCCode2CN setObject:countryCode509Array forKey:@"509"];

        NSMutableArray *countryCode54Array = [[NSMutableArray alloc] init];
        [countryCode54Array addObject:@"AR"];
        [kMapCCode2CN setObject:countryCode54Array forKey:@"54"];

        NSMutableArray *countryCode800Array = [[NSMutableArray alloc] init];
        [countryCode800Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode800Array forKey:@"800"];

        NSMutableArray *countryCode268Array = [[NSMutableArray alloc] init];
        [countryCode268Array addObject:@"SZ"];
        [kMapCCode2CN setObject:countryCode268Array forKey:@"268"];

        NSMutableArray *countryCode357Array = [[NSMutableArray alloc] init];
        [countryCode357Array addObject:@"CY"];
        [kMapCCode2CN setObject:countryCode357Array forKey:@"357"];

        NSMutableArray *countryCode382Array = [[NSMutableArray alloc] init];
        [countryCode382Array addObject:@"ME"];
        [kMapCCode2CN setObject:countryCode382Array forKey:@"382"];

        NSMutableArray *countryCode55Array = [[NSMutableArray alloc] init];
        [countryCode55Array addObject:@"BR"];
        [kMapCCode2CN setObject:countryCode55Array forKey:@"55"];

        NSMutableArray *countryCode374Array = [[NSMutableArray alloc] init];
        [countryCode374Array addObject:@"AM"];
        [kMapCCode2CN setObject:countryCode374Array forKey:@"374"];

        NSMutableArray *countryCode56Array = [[NSMutableArray alloc] init];
        [countryCode56Array addObject:@"CL"];
        [kMapCCode2CN setObject:countryCode56Array forKey:@"56"];

        NSMutableArray *countryCode81Array = [[NSMutableArray alloc] init];
        [countryCode81Array addObject:@"JP"];
        [kMapCCode2CN setObject:countryCode81Array forKey:@"81"];

        NSMutableArray *countryCode269Array = [[NSMutableArray alloc] init];
        [countryCode269Array addObject:@"KM"];
        [kMapCCode2CN setObject:countryCode269Array forKey:@"269"];

        NSMutableArray *countryCode358Array = [[NSMutableArray alloc] init];
        [countryCode358Array addObject:@"FI"];
        [countryCode358Array addObject:@"AX"];
        [kMapCCode2CN setObject:countryCode358Array forKey:@"358"];

        NSMutableArray *countryCode57Array = [[NSMutableArray alloc] init];
        [countryCode57Array addObject:@"CO"];
        [kMapCCode2CN setObject:countryCode57Array forKey:@"57"];

        NSMutableArray *countryCode82Array = [[NSMutableArray alloc] init];
        [countryCode82Array addObject:@"KR"];
        [kMapCCode2CN setObject:countryCode82Array forKey:@"82"];

        NSMutableArray *countryCode375Array = [[NSMutableArray alloc] init];
        [countryCode375Array addObject:@"BY"];
        [kMapCCode2CN setObject:countryCode375Array forKey:@"375"];

        NSMutableArray *countryCode58Array = [[NSMutableArray alloc] init];
        [countryCode58Array addObject:@"VE"];
        [kMapCCode2CN setObject:countryCode58Array forKey:@"58"];

        NSMutableArray *countryCode359Array = [[NSMutableArray alloc] init];
        [countryCode359Array addObject:@"BG"];
        [kMapCCode2CN setObject:countryCode359Array forKey:@"359"];

        NSMutableArray *countryCode376Array = [[NSMutableArray alloc] init];
        [countryCode376Array addObject:@"AD"];
        [kMapCCode2CN setObject:countryCode376Array forKey:@"376"];

        NSMutableArray *countryCode84Array = [[NSMutableArray alloc] init];
        [countryCode84Array addObject:@"VN"];
        [kMapCCode2CN setObject:countryCode84Array forKey:@"84"];

        NSMutableArray *countryCode385Array = [[NSMutableArray alloc] init];
        [countryCode385Array addObject:@"HR"];
        [kMapCCode2CN setObject:countryCode385Array forKey:@"385"];

        NSMutableArray *countryCode377Array = [[NSMutableArray alloc] init];
        [countryCode377Array addObject:@"MC"];
        [kMapCCode2CN setObject:countryCode377Array forKey:@"377"];

        NSMutableArray *countryCode86Array = [[NSMutableArray alloc] init];
        [countryCode86Array addObject:@"CN"];
        [kMapCCode2CN setObject:countryCode86Array forKey:@"86"];

        NSMutableArray *countryCode297Array = [[NSMutableArray alloc] init];
        [countryCode297Array addObject:@"AW"];
        [kMapCCode2CN setObject:countryCode297Array forKey:@"297"];

        NSMutableArray *countryCode386Array = [[NSMutableArray alloc] init];
        [countryCode386Array addObject:@"SI"];
        [kMapCCode2CN setObject:countryCode386Array forKey:@"386"];

        NSMutableArray *countryCode378Array = [[NSMutableArray alloc] init];
        [countryCode378Array addObject:@"SM"];
        [kMapCCode2CN setObject:countryCode378Array forKey:@"378"];

        NSMutableArray *countryCode670Array = [[NSMutableArray alloc] init];
        [countryCode670Array addObject:@"TL"];
        [kMapCCode2CN setObject:countryCode670Array forKey:@"670"];

        NSMutableArray *countryCode298Array = [[NSMutableArray alloc] init];
        [countryCode298Array addObject:@"FO"];
        [kMapCCode2CN setObject:countryCode298Array forKey:@"298"];

        NSMutableArray *countryCode387Array = [[NSMutableArray alloc] init];
        [countryCode387Array addObject:@"BA"];
        [kMapCCode2CN setObject:countryCode387Array forKey:@"387"];

        NSMutableArray *countryCode590Array = [[NSMutableArray alloc] init];
        [countryCode590Array addObject:@"GP"];
        [countryCode590Array addObject:@"BL"];
        [countryCode590Array addObject:@"MF"];
        [kMapCCode2CN setObject:countryCode590Array forKey:@"590"];

        NSMutableArray *countryCode299Array = [[NSMutableArray alloc] init];
        [countryCode299Array addObject:@"GL"];
        [kMapCCode2CN setObject:countryCode299Array forKey:@"299"];

        NSMutableArray *countryCode591Array = [[NSMutableArray alloc] init];
        [countryCode591Array addObject:@"BO"];
        [kMapCCode2CN setObject:countryCode591Array forKey:@"591"];

        NSMutableArray *countryCode680Array = [[NSMutableArray alloc] init];
        [countryCode680Array addObject:@"PW"];
        [kMapCCode2CN setObject:countryCode680Array forKey:@"680"];

        NSMutableArray *countryCode808Array = [[NSMutableArray alloc] init];
        [countryCode808Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode808Array forKey:@"808"];

        NSMutableArray *countryCode672Array = [[NSMutableArray alloc] init];
        [countryCode672Array addObject:@"NF"];
        [kMapCCode2CN setObject:countryCode672Array forKey:@"672"];

        NSMutableArray *countryCode850Array = [[NSMutableArray alloc] init];
        [countryCode850Array addObject:@"KP"];
        [kMapCCode2CN setObject:countryCode850Array forKey:@"850"];

        NSMutableArray *countryCode389Array = [[NSMutableArray alloc] init];
        [countryCode389Array addObject:@"MK"];
        [kMapCCode2CN setObject:countryCode389Array forKey:@"389"];

        NSMutableArray *countryCode592Array = [[NSMutableArray alloc] init];
        [countryCode592Array addObject:@"GY"];
        [kMapCCode2CN setObject:countryCode592Array forKey:@"592"];

        NSMutableArray *countryCode681Array = [[NSMutableArray alloc] init];
        [countryCode681Array addObject:@"WF"];
        [kMapCCode2CN setObject:countryCode681Array forKey:@"681"];

        NSMutableArray *countryCode673Array = [[NSMutableArray alloc] init];
        [countryCode673Array addObject:@"BN"];
        [kMapCCode2CN setObject:countryCode673Array forKey:@"673"];

        NSMutableArray *countryCode690Array = [[NSMutableArray alloc] init];
        [countryCode690Array addObject:@"TK"];
        [kMapCCode2CN setObject:countryCode690Array forKey:@"690"];

        NSMutableArray *countryCode593Array = [[NSMutableArray alloc] init];
        [countryCode593Array addObject:@"EC"];
        [kMapCCode2CN setObject:countryCode593Array forKey:@"593"];

        NSMutableArray *countryCode682Array = [[NSMutableArray alloc] init];
        [countryCode682Array addObject:@"CK"];
        [kMapCCode2CN setObject:countryCode682Array forKey:@"682"];

        NSMutableArray *countryCode674Array = [[NSMutableArray alloc] init];
        [countryCode674Array addObject:@"NR"];
        [kMapCCode2CN setObject:countryCode674Array forKey:@"674"];

        NSMutableArray *countryCode852Array = [[NSMutableArray alloc] init];
        [countryCode852Array addObject:@"HK"];
        [kMapCCode2CN setObject:countryCode852Array forKey:@"852"];

        NSMutableArray *countryCode691Array = [[NSMutableArray alloc] init];
        [countryCode691Array addObject:@"FM"];
        [kMapCCode2CN setObject:countryCode691Array forKey:@"691"];

        NSMutableArray *countryCode594Array = [[NSMutableArray alloc] init];
        [countryCode594Array addObject:@"GF"];
        [kMapCCode2CN setObject:countryCode594Array forKey:@"594"];

        NSMutableArray *countryCode683Array = [[NSMutableArray alloc] init];
        [countryCode683Array addObject:@"NU"];
        [kMapCCode2CN setObject:countryCode683Array forKey:@"683"];

        NSMutableArray *countryCode675Array = [[NSMutableArray alloc] init];
        [countryCode675Array addObject:@"PG"];
        [kMapCCode2CN setObject:countryCode675Array forKey:@"675"];

        NSMutableArray *countryCode30Array = [[NSMutableArray alloc] init];
        [countryCode30Array addObject:@"GR"];
        [kMapCCode2CN setObject:countryCode30Array forKey:@"30"];

        NSMutableArray *countryCode853Array = [[NSMutableArray alloc] init];
        [countryCode853Array addObject:@"MO"];
        [kMapCCode2CN setObject:countryCode853Array forKey:@"853"];

        NSMutableArray *countryCode692Array = [[NSMutableArray alloc] init];
        [countryCode692Array addObject:@"MH"];
        [kMapCCode2CN setObject:countryCode692Array forKey:@"692"];

        NSMutableArray *countryCode595Array = [[NSMutableArray alloc] init];
        [countryCode595Array addObject:@"PY"];
        [kMapCCode2CN setObject:countryCode595Array forKey:@"595"];

        NSMutableArray *countryCode31Array = [[NSMutableArray alloc] init];
        [countryCode31Array addObject:@"NL"];
        [kMapCCode2CN setObject:countryCode31Array forKey:@"31"];

        NSMutableArray *countryCode870Array = [[NSMutableArray alloc] init];
        [countryCode870Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode870Array forKey:@"870"];

        NSMutableArray *countryCode676Array = [[NSMutableArray alloc] init];
        [countryCode676Array addObject:@"TO"];
        [kMapCCode2CN setObject:countryCode676Array forKey:@"676"];

        NSMutableArray *countryCode32Array = [[NSMutableArray alloc] init];
        [countryCode32Array addObject:@"BE"];
        [kMapCCode2CN setObject:countryCode32Array forKey:@"32"];

        NSMutableArray *countryCode596Array = [[NSMutableArray alloc] init];
        [countryCode596Array addObject:@"MQ"];
        [kMapCCode2CN setObject:countryCode596Array forKey:@"596"];

        NSMutableArray *countryCode685Array = [[NSMutableArray alloc] init];
        [countryCode685Array addObject:@"WS"];
        [kMapCCode2CN setObject:countryCode685Array forKey:@"685"];

        NSMutableArray *countryCode33Array = [[NSMutableArray alloc] init];
        [countryCode33Array addObject:@"FR"];
        [kMapCCode2CN setObject:countryCode33Array forKey:@"33"];

        NSMutableArray *countryCode960Array = [[NSMutableArray alloc] init];
        [countryCode960Array addObject:@"MV"];
        [kMapCCode2CN setObject:countryCode960Array forKey:@"960"];

        NSMutableArray *countryCode677Array = [[NSMutableArray alloc] init];
        [countryCode677Array addObject:@"SB"];
        [kMapCCode2CN setObject:countryCode677Array forKey:@"677"];

        NSMutableArray *countryCode855Array = [[NSMutableArray alloc] init];
        [countryCode855Array addObject:@"KH"];
        [kMapCCode2CN setObject:countryCode855Array forKey:@"855"];

        NSMutableArray *countryCode34Array = [[NSMutableArray alloc] init];
        [countryCode34Array addObject:@"ES"];
        [kMapCCode2CN setObject:countryCode34Array forKey:@"34"];

        NSMutableArray *countryCode880Array = [[NSMutableArray alloc] init];
        [countryCode880Array addObject:@"BD"];
        [kMapCCode2CN setObject:countryCode880Array forKey:@"880"];

        NSMutableArray *countryCode597Array = [[NSMutableArray alloc] init];
        [countryCode597Array addObject:@"SR"];
        [kMapCCode2CN setObject:countryCode597Array forKey:@"597"];

        NSMutableArray *countryCode686Array = [[NSMutableArray alloc] init];
        [countryCode686Array addObject:@"KI"];
        [kMapCCode2CN setObject:countryCode686Array forKey:@"686"];

        NSMutableArray *countryCode961Array = [[NSMutableArray alloc] init];
        [countryCode961Array addObject:@"LB"];
        [kMapCCode2CN setObject:countryCode961Array forKey:@"961"];

        NSMutableArray *countryCode60Array = [[NSMutableArray alloc] init];
        [countryCode60Array addObject:@"MY"];
        [kMapCCode2CN setObject:countryCode60Array forKey:@"60"];

        NSMutableArray *countryCode678Array = [[NSMutableArray alloc] init];
        [countryCode678Array addObject:@"VU"];
        [kMapCCode2CN setObject:countryCode678Array forKey:@"678"];

        NSMutableArray *countryCode856Array = [[NSMutableArray alloc] init];
        [countryCode856Array addObject:@"LA"];
        [kMapCCode2CN setObject:countryCode856Array forKey:@"856"];

        NSMutableArray *countryCode881Array = [[NSMutableArray alloc] init];
        [countryCode881Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode881Array forKey:@"881"];

        NSMutableArray *countryCode36Array = [[NSMutableArray alloc] init];
        [countryCode36Array addObject:@"HU"];
        [kMapCCode2CN setObject:countryCode36Array forKey:@"36"];

        NSMutableArray *countryCode61Array = [[NSMutableArray alloc] init];
        [countryCode61Array addObject:@"AU"];
        [countryCode61Array addObject:@"CC"];
        [countryCode61Array addObject:@"CX"];
        [kMapCCode2CN setObject:countryCode61Array forKey:@"61"];

        NSMutableArray *countryCode598Array = [[NSMutableArray alloc] init];
        [countryCode598Array addObject:@"UY"];
        [kMapCCode2CN setObject:countryCode598Array forKey:@"598"];

        NSMutableArray *countryCode687Array = [[NSMutableArray alloc] init];
        [countryCode687Array addObject:@"NC"];
        [kMapCCode2CN setObject:countryCode687Array forKey:@"687"];

        NSMutableArray *countryCode962Array = [[NSMutableArray alloc] init];
        [countryCode962Array addObject:@"JO"];
        [kMapCCode2CN setObject:countryCode962Array forKey:@"962"];

        NSMutableArray *countryCode62Array = [[NSMutableArray alloc] init];
        [countryCode62Array addObject:@"ID"];
        [kMapCCode2CN setObject:countryCode62Array forKey:@"62"];

        NSMutableArray *countryCode679Array = [[NSMutableArray alloc] init];
        [countryCode679Array addObject:@"FJ"];
        [kMapCCode2CN setObject:countryCode679Array forKey:@"679"];

        NSMutableArray *countryCode882Array = [[NSMutableArray alloc] init];
        [countryCode882Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode882Array forKey:@"882"];

        NSMutableArray *countryCode970Array = [[NSMutableArray alloc] init];
        [countryCode970Array addObject:@"PS"];
        [kMapCCode2CN setObject:countryCode970Array forKey:@"970"];

        NSMutableArray *countryCode971Array = [[NSMutableArray alloc] init];
        [countryCode971Array addObject:@"AE"];
        [kMapCCode2CN setObject:countryCode971Array forKey:@"971"];

        NSMutableArray *countryCode63Array = [[NSMutableArray alloc] init];
        [countryCode63Array addObject:@"PH"];
        [kMapCCode2CN setObject:countryCode63Array forKey:@"63"];

        NSMutableArray *countryCode599Array = [[NSMutableArray alloc] init];
        [countryCode599Array addObject:@"CW"];
        [countryCode599Array addObject:@"BQ"];
        [kMapCCode2CN setObject:countryCode599Array forKey:@"599"];

        NSMutableArray *countryCode688Array = [[NSMutableArray alloc] init];
        [countryCode688Array addObject:@"TV"];
        [kMapCCode2CN setObject:countryCode688Array forKey:@"688"];

        NSMutableArray *countryCode963Array = [[NSMutableArray alloc] init];
        [countryCode963Array addObject:@"SY"];
        [kMapCCode2CN setObject:countryCode963Array forKey:@"963"];

        NSMutableArray *countryCode39Array = [[NSMutableArray alloc] init];
        [countryCode39Array addObject:@"IT"];
        [countryCode39Array addObject:@"VA"];
        [kMapCCode2CN setObject:countryCode39Array forKey:@"39"];

        NSMutableArray *countryCode64Array = [[NSMutableArray alloc] init];
        [countryCode64Array addObject:@"NZ"];
        [kMapCCode2CN setObject:countryCode64Array forKey:@"64"];

        NSMutableArray *countryCode883Array = [[NSMutableArray alloc] init];
        [countryCode883Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode883Array forKey:@"883"];

        NSMutableArray *countryCode972Array = [[NSMutableArray alloc] init];
        [countryCode972Array addObject:@"IL"];
        [kMapCCode2CN setObject:countryCode972Array forKey:@"972"];

        NSMutableArray *countryCode65Array = [[NSMutableArray alloc] init];
        [countryCode65Array addObject:@"SG"];
        [kMapCCode2CN setObject:countryCode65Array forKey:@"65"];

        NSMutableArray *countryCode90Array = [[NSMutableArray alloc] init];
        [countryCode90Array addObject:@"TR"];
        [kMapCCode2CN setObject:countryCode90Array forKey:@"90"];

        NSMutableArray *countryCode689Array = [[NSMutableArray alloc] init];
        [countryCode689Array addObject:@"PF"];
        [kMapCCode2CN setObject:countryCode689Array forKey:@"689"];

        NSMutableArray *countryCode964Array = [[NSMutableArray alloc] init];
        [countryCode964Array addObject:@"IQ"];
        [kMapCCode2CN setObject:countryCode964Array forKey:@"964"];

        NSMutableArray *countryCode1Array = [[NSMutableArray alloc] init];
        [countryCode1Array addObject:@"US"];
        [countryCode1Array addObject:@"AG"];
        [countryCode1Array addObject:@"AI"];
        [countryCode1Array addObject:@"AS"];
        [countryCode1Array addObject:@"BB"];
        [countryCode1Array addObject:@"BM"];
        [countryCode1Array addObject:@"BS"];
        [countryCode1Array addObject:@"CA"];
        [countryCode1Array addObject:@"DM"];
        [countryCode1Array addObject:@"DO"];
        [countryCode1Array addObject:@"GD"];
        [countryCode1Array addObject:@"GU"];
        [countryCode1Array addObject:@"JM"];
        [countryCode1Array addObject:@"KN"];
        [countryCode1Array addObject:@"KY"];
        [countryCode1Array addObject:@"LC"];
        [countryCode1Array addObject:@"MP"];
        [countryCode1Array addObject:@"MS"];
        [countryCode1Array addObject:@"PR"];
        [countryCode1Array addObject:@"SX"];
        [countryCode1Array addObject:@"TC"];
        [countryCode1Array addObject:@"TT"];
        [countryCode1Array addObject:@"VC"];
        [countryCode1Array addObject:@"VG"];
        [countryCode1Array addObject:@"VI"];
        [kMapCCode2CN setObject:countryCode1Array forKey:@"1"];

        NSMutableArray *countryCode66Array = [[NSMutableArray alloc] init];
        [countryCode66Array addObject:@"TH"];
        [kMapCCode2CN setObject:countryCode66Array forKey:@"66"];

        NSMutableArray *countryCode91Array = [[NSMutableArray alloc] init];
        [countryCode91Array addObject:@"IN"];
        [kMapCCode2CN setObject:countryCode91Array forKey:@"91"];

        NSMutableArray *countryCode973Array = [[NSMutableArray alloc] init];
        [countryCode973Array addObject:@"BH"];
        [kMapCCode2CN setObject:countryCode973Array forKey:@"973"];

        NSMutableArray *countryCode965Array = [[NSMutableArray alloc] init];
        [countryCode965Array addObject:@"KW"];
        [kMapCCode2CN setObject:countryCode965Array forKey:@"965"];

        NSMutableArray *countryCode92Array = [[NSMutableArray alloc] init];
        [countryCode92Array addObject:@"PK"];
        [kMapCCode2CN setObject:countryCode92Array forKey:@"92"];

        NSMutableArray *countryCode93Array = [[NSMutableArray alloc] init];
        [countryCode93Array addObject:@"AF"];
        [kMapCCode2CN setObject:countryCode93Array forKey:@"93"];

        NSMutableArray *countryCode974Array = [[NSMutableArray alloc] init];
        [countryCode974Array addObject:@"QA"];
        [kMapCCode2CN setObject:countryCode974Array forKey:@"974"];

        NSMutableArray *countryCode966Array = [[NSMutableArray alloc] init];
        [countryCode966Array addObject:@"SA"];
        [kMapCCode2CN setObject:countryCode966Array forKey:@"966"];

        NSMutableArray *countryCode94Array = [[NSMutableArray alloc] init];
        [countryCode94Array addObject:@"LK"];
        [kMapCCode2CN setObject:countryCode94Array forKey:@"94"];

        NSMutableArray *countryCode7Array = [[NSMutableArray alloc] init];
        [countryCode7Array addObject:@"RU"];
        [countryCode7Array addObject:@"KZ"];
        [kMapCCode2CN setObject:countryCode7Array forKey:@"7"];

        NSMutableArray *countryCode886Array = [[NSMutableArray alloc] init];
        [countryCode886Array addObject:@"TW"];
        [kMapCCode2CN setObject:countryCode886Array forKey:@"886"];

        NSMutableArray *countryCode95Array = [[NSMutableArray alloc] init];
        [countryCode95Array addObject:@"MM"];
        [kMapCCode2CN setObject:countryCode95Array forKey:@"95"];

        NSMutableArray *countryCode878Array = [[NSMutableArray alloc] init];
        [countryCode878Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode878Array forKey:@"878"];

        NSMutableArray *countryCode967Array = [[NSMutableArray alloc] init];
        [countryCode967Array addObject:@"YE"];
        [kMapCCode2CN setObject:countryCode967Array forKey:@"967"];

        NSMutableArray *countryCode975Array = [[NSMutableArray alloc] init];
        [countryCode975Array addObject:@"BT"];
        [kMapCCode2CN setObject:countryCode975Array forKey:@"975"];

        NSMutableArray *countryCode992Array = [[NSMutableArray alloc] init];
        [countryCode992Array addObject:@"TJ"];
        [kMapCCode2CN setObject:countryCode992Array forKey:@"992"];

        NSMutableArray *countryCode976Array = [[NSMutableArray alloc] init];
        [countryCode976Array addObject:@"MN"];
        [kMapCCode2CN setObject:countryCode976Array forKey:@"976"];

        NSMutableArray *countryCode968Array = [[NSMutableArray alloc] init];
        [countryCode968Array addObject:@"OM"];
        [kMapCCode2CN setObject:countryCode968Array forKey:@"968"];

        NSMutableArray *countryCode993Array = [[NSMutableArray alloc] init];
        [countryCode993Array addObject:@"TM"];
        [kMapCCode2CN setObject:countryCode993Array forKey:@"993"];

        NSMutableArray *countryCode98Array = [[NSMutableArray alloc] init];
        [countryCode98Array addObject:@"IR"];
        [kMapCCode2CN setObject:countryCode98Array forKey:@"98"];

        NSMutableArray *countryCode888Array = [[NSMutableArray alloc] init];
        [countryCode888Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode888Array forKey:@"888"];

        NSMutableArray *countryCode977Array = [[NSMutableArray alloc] init];
        [countryCode977Array addObject:@"NP"];
        [kMapCCode2CN setObject:countryCode977Array forKey:@"977"];

        NSMutableArray *countryCode994Array = [[NSMutableArray alloc] init];
        [countryCode994Array addObject:@"AZ"];
        [kMapCCode2CN setObject:countryCode994Array forKey:@"994"];

        NSMutableArray *countryCode995Array = [[NSMutableArray alloc] init];
        [countryCode995Array addObject:@"GE"];
        [kMapCCode2CN setObject:countryCode995Array forKey:@"995"];

        NSMutableArray *countryCode979Array = [[NSMutableArray alloc] init];
        [countryCode979Array addObject:@"001"];
        [kMapCCode2CN setObject:countryCode979Array forKey:@"979"];

        NSMutableArray *countryCode996Array = [[NSMutableArray alloc] init];
        [countryCode996Array addObject:@"KG"];
        [kMapCCode2CN setObject:countryCode996Array forKey:@"996"];

        NSMutableArray *countryCode998Array = [[NSMutableArray alloc] init];
        [countryCode998Array addObject:@"UZ"];
        [kMapCCode2CN setObject:countryCode998Array forKey:@"998"];

        NSMutableArray *countryCode40Array = [[NSMutableArray alloc] init];
        [countryCode40Array addObject:@"RO"];
        [kMapCCode2CN setObject:countryCode40Array forKey:@"40"];

        NSMutableArray *countryCode41Array = [[NSMutableArray alloc] init];
        [countryCode41Array addObject:@"CH"];
        [kMapCCode2CN setObject:countryCode41Array forKey:@"41"];

        NSMutableArray *countryCode43Array = [[NSMutableArray alloc] init];
        [countryCode43Array addObject:@"AT"];
        [kMapCCode2CN setObject:countryCode43Array forKey:@"43"];

        NSMutableArray *countryCode44Array = [[NSMutableArray alloc] init];
        [countryCode44Array addObject:@"GB"];
        [countryCode44Array addObject:@"GG"];
        [countryCode44Array addObject:@"IM"];
        [countryCode44Array addObject:@"JE"];
        [kMapCCode2CN setObject:countryCode44Array forKey:@"44"];

        NSMutableArray *countryCode211Array = [[NSMutableArray alloc] init];
        [countryCode211Array addObject:@"SS"];
        [kMapCCode2CN setObject:countryCode211Array forKey:@"211"];

        NSMutableArray *countryCode45Array = [[NSMutableArray alloc] init];
        [countryCode45Array addObject:@"DK"];
        [kMapCCode2CN setObject:countryCode45Array forKey:@"45"];

        NSMutableArray *countryCode220Array = [[NSMutableArray alloc] init];
        [countryCode220Array addObject:@"GM"];
        [kMapCCode2CN setObject:countryCode220Array forKey:@"220"];

        NSMutableArray *countryCode212Array = [[NSMutableArray alloc] init];
        [countryCode212Array addObject:@"MA"];
        [countryCode212Array addObject:@"EH"];
        [kMapCCode2CN setObject:countryCode212Array forKey:@"212"];

        NSMutableArray *countryCode46Array = [[NSMutableArray alloc] init];
        [countryCode46Array addObject:@"SE"];
        [kMapCCode2CN setObject:countryCode46Array forKey:@"46"];

        NSMutableArray *countryCode47Array = [[NSMutableArray alloc] init];
        [countryCode47Array addObject:@"NO"];
        [countryCode47Array addObject:@"SJ"];
        [kMapCCode2CN setObject:countryCode47Array forKey:@"47"];

        NSMutableArray *countryCode221Array = [[NSMutableArray alloc] init];
        [countryCode221Array addObject:@"SN"];
        [kMapCCode2CN setObject:countryCode221Array forKey:@"221"];

        NSMutableArray *countryCode213Array = [[NSMutableArray alloc] init];
        [countryCode213Array addObject:@"DZ"];
        [kMapCCode2CN setObject:countryCode213Array forKey:@"213"];

        NSMutableArray *countryCode48Array = [[NSMutableArray alloc] init];
        [countryCode48Array addObject:@"PL"];
        [kMapCCode2CN setObject:countryCode48Array forKey:@"48"];

        NSMutableArray *countryCode230Array = [[NSMutableArray alloc] init];
        [countryCode230Array addObject:@"MU"];
        [kMapCCode2CN setObject:countryCode230Array forKey:@"230"];

        NSMutableArray *countryCode222Array = [[NSMutableArray alloc] init];
        [countryCode222Array addObject:@"MR"];
        [kMapCCode2CN setObject:countryCode222Array forKey:@"222"];

        NSMutableArray *countryCode49Array = [[NSMutableArray alloc] init];
        [countryCode49Array addObject:@"DE"];
        [kMapCCode2CN setObject:countryCode49Array forKey:@"49"];

        NSMutableArray *countryCode231Array = [[NSMutableArray alloc] init];
        [countryCode231Array addObject:@"LR"];
        [kMapCCode2CN setObject:countryCode231Array forKey:@"231"];

        NSMutableArray *countryCode223Array = [[NSMutableArray alloc] init];
        [countryCode223Array addObject:@"ML"];
        [kMapCCode2CN setObject:countryCode223Array forKey:@"223"];

        NSMutableArray *countryCode240Array = [[NSMutableArray alloc] init];
        [countryCode240Array addObject:@"GQ"];
        [kMapCCode2CN setObject:countryCode240Array forKey:@"240"];

        NSMutableArray *countryCode232Array = [[NSMutableArray alloc] init];
        [countryCode232Array addObject:@"SL"];
        [kMapCCode2CN setObject:countryCode232Array forKey:@"232"];

        NSMutableArray *countryCode224Array = [[NSMutableArray alloc] init];
        [countryCode224Array addObject:@"GN"];
        [kMapCCode2CN setObject:countryCode224Array forKey:@"224"];

        NSMutableArray *countryCode216Array = [[NSMutableArray alloc] init];
        [countryCode216Array addObject:@"TN"];
        [kMapCCode2CN setObject:countryCode216Array forKey:@"216"];

        NSMutableArray *countryCode241Array = [[NSMutableArray alloc] init];
        [countryCode241Array addObject:@"GA"];
        [kMapCCode2CN setObject:countryCode241Array forKey:@"241"];

        NSMutableArray *countryCode233Array = [[NSMutableArray alloc] init];
        [countryCode233Array addObject:@"GH"];
        [kMapCCode2CN setObject:countryCode233Array forKey:@"233"];

        NSMutableArray *countryCode225Array = [[NSMutableArray alloc] init];
        [countryCode225Array addObject:@"CI"];
        [kMapCCode2CN setObject:countryCode225Array forKey:@"225"];

        NSMutableArray *countryCode250Array = [[NSMutableArray alloc] init];
        [countryCode250Array addObject:@"RW"];
        [kMapCCode2CN setObject:countryCode250Array forKey:@"250"];

        NSMutableArray *countryCode500Array = [[NSMutableArray alloc] init];
        [countryCode500Array addObject:@"FK"];
        [kMapCCode2CN setObject:countryCode500Array forKey:@"500"];

        NSMutableArray *countryCode242Array = [[NSMutableArray alloc] init];
        [countryCode242Array addObject:@"CG"];
        [kMapCCode2CN setObject:countryCode242Array forKey:@"242"];

        NSMutableArray *countryCode420Array = [[NSMutableArray alloc] init];
        [countryCode420Array addObject:@"CZ"];
        [kMapCCode2CN setObject:countryCode420Array forKey:@"420"];

        NSMutableArray *countryCode234Array = [[NSMutableArray alloc] init];
        [countryCode234Array addObject:@"NG"];
        [kMapCCode2CN setObject:countryCode234Array forKey:@"234"];

        NSMutableArray *countryCode226Array = [[NSMutableArray alloc] init];
        [countryCode226Array addObject:@"BF"];
        [kMapCCode2CN setObject:countryCode226Array forKey:@"226"];

        NSMutableArray *countryCode251Array = [[NSMutableArray alloc] init];
        [countryCode251Array addObject:@"ET"];
        [kMapCCode2CN setObject:countryCode251Array forKey:@"251"];

        NSMutableArray *countryCode501Array = [[NSMutableArray alloc] init];
        [countryCode501Array addObject:@"BZ"];
        [kMapCCode2CN setObject:countryCode501Array forKey:@"501"];

        NSMutableArray *countryCode218Array = [[NSMutableArray alloc] init];
        [countryCode218Array addObject:@"LY"];
        [kMapCCode2CN setObject:countryCode218Array forKey:@"218"];

        NSMutableArray *countryCode243Array = [[NSMutableArray alloc] init];
        [countryCode243Array addObject:@"CD"];
        [kMapCCode2CN setObject:countryCode243Array forKey:@"243"];

        NSMutableArray *countryCode421Array = [[NSMutableArray alloc] init];
        [countryCode421Array addObject:@"SK"];
        [kMapCCode2CN setObject:countryCode421Array forKey:@"421"];

        NSMutableArray *countryCode235Array = [[NSMutableArray alloc] init];
        [countryCode235Array addObject:@"TD"];
        [kMapCCode2CN setObject:countryCode235Array forKey:@"235"];

        NSMutableArray *countryCode260Array = [[NSMutableArray alloc] init];
        [countryCode260Array addObject:@"ZM"];
        [kMapCCode2CN setObject:countryCode260Array forKey:@"260"];

        NSMutableArray *countryCode227Array = [[NSMutableArray alloc] init];
        [countryCode227Array addObject:@"NE"];
        [kMapCCode2CN setObject:countryCode227Array forKey:@"227"];

        NSMutableArray *countryCode252Array = [[NSMutableArray alloc] init];
        [countryCode252Array addObject:@"SO"];
        [kMapCCode2CN setObject:countryCode252Array forKey:@"252"];

        NSMutableArray *countryCode502Array = [[NSMutableArray alloc] init];
        [countryCode502Array addObject:@"GT"];
        [kMapCCode2CN setObject:countryCode502Array forKey:@"502"];

        NSMutableArray *countryCode244Array = [[NSMutableArray alloc] init];
        [countryCode244Array addObject:@"AO"];
        [kMapCCode2CN setObject:countryCode244Array forKey:@"244"];

        NSMutableArray *countryCode236Array = [[NSMutableArray alloc] init];
        [countryCode236Array addObject:@"CF"];
        [kMapCCode2CN setObject:countryCode236Array forKey:@"236"];

        NSMutableArray *countryCode261Array = [[NSMutableArray alloc] init];
        [countryCode261Array addObject:@"MG"];
        [kMapCCode2CN setObject:countryCode261Array forKey:@"261"];

        NSMutableArray *countryCode350Array = [[NSMutableArray alloc] init];
        [countryCode350Array addObject:@"GI"];
        [kMapCCode2CN setObject:countryCode350Array forKey:@"350"];

        NSMutableArray *countryCode228Array = [[NSMutableArray alloc] init];
        [countryCode228Array addObject:@"TG"];
        [kMapCCode2CN setObject:countryCode228Array forKey:@"228"];

        NSMutableArray *countryCode253Array = [[NSMutableArray alloc] init];
        [countryCode253Array addObject:@"DJ"];
        [kMapCCode2CN setObject:countryCode253Array forKey:@"253"];

        NSMutableArray *countryCode503Array = [[NSMutableArray alloc] init];
        [countryCode503Array addObject:@"SV"];
        [kMapCCode2CN setObject:countryCode503Array forKey:@"503"];

        NSMutableArray *countryCode245Array = [[NSMutableArray alloc] init];
        [countryCode245Array addObject:@"GW"];
        [kMapCCode2CN setObject:countryCode245Array forKey:@"245"];

        NSMutableArray *countryCode423Array = [[NSMutableArray alloc] init];
        [countryCode423Array addObject:@"LI"];
        [kMapCCode2CN setObject:countryCode423Array forKey:@"423"];

        NSMutableArray *countryCode237Array = [[NSMutableArray alloc] init];
        [countryCode237Array addObject:@"CM"];
        [kMapCCode2CN setObject:countryCode237Array forKey:@"237"];

        NSMutableArray *countryCode262Array = [[NSMutableArray alloc] init];
        [countryCode262Array addObject:@"RE"];
        [countryCode262Array addObject:@"YT"];
        [kMapCCode2CN setObject:countryCode262Array forKey:@"262"];

        NSMutableArray *countryCode351Array = [[NSMutableArray alloc] init];
        [countryCode351Array addObject:@"PT"];
        [kMapCCode2CN setObject:countryCode351Array forKey:@"351"];

        NSMutableArray *countryCode229Array = [[NSMutableArray alloc] init];
        [countryCode229Array addObject:@"BJ"];
        [kMapCCode2CN setObject:countryCode229Array forKey:@"229"];

        NSMutableArray *countryCode254Array = [[NSMutableArray alloc] init];
        [countryCode254Array addObject:@"KE"];
        [kMapCCode2CN setObject:countryCode254Array forKey:@"254"];

        NSMutableArray *countryCode504Array = [[NSMutableArray alloc] init];
        [countryCode504Array addObject:@"HN"];
        [kMapCCode2CN setObject:countryCode504Array forKey:@"504"];

        NSMutableArray *countryCode246Array = [[NSMutableArray alloc] init];
        [countryCode246Array addObject:@"IO"];
        [kMapCCode2CN setObject:countryCode246Array forKey:@"246"];

        NSMutableArray *countryCode20Array = [[NSMutableArray alloc] init];
        [countryCode20Array addObject:@"EG"];
        [kMapCCode2CN setObject:countryCode20Array forKey:@"20"];

        NSMutableArray *countryCode238Array = [[NSMutableArray alloc] init];
        [countryCode238Array addObject:@"CV"];
        [kMapCCode2CN setObject:countryCode238Array forKey:@"238"];

        NSMutableArray *countryCode263Array = [[NSMutableArray alloc] init];
        [countryCode263Array addObject:@"ZW"];
        [kMapCCode2CN setObject:countryCode263Array forKey:@"263"];

        NSMutableArray *countryCode352Array = [[NSMutableArray alloc] init];
        [countryCode352Array addObject:@"LU"];
        [kMapCCode2CN setObject:countryCode352Array forKey:@"352"];

        NSMutableArray *countryCode255Array = [[NSMutableArray alloc] init];
        [countryCode255Array addObject:@"TZ"];
        [kMapCCode2CN setObject:countryCode255Array forKey:@"255"];

        NSMutableArray *countryCode505Array = [[NSMutableArray alloc] init];
        [countryCode505Array addObject:@"NI"];
        [kMapCCode2CN setObject:countryCode505Array forKey:@"505"];

        NSMutableArray *countryCode247Array = [[NSMutableArray alloc] init];
        [countryCode247Array addObject:@"AC"];
        [kMapCCode2CN setObject:countryCode247Array forKey:@"247"];

        NSMutableArray *countryCode239Array = [[NSMutableArray alloc] init];
        [countryCode239Array addObject:@"ST"];
        [kMapCCode2CN setObject:countryCode239Array forKey:@"239"];

        NSMutableArray *countryCode264Array = [[NSMutableArray alloc] init];
        [countryCode264Array addObject:@"NA"];
        [kMapCCode2CN setObject:countryCode264Array forKey:@"264"];

        NSMutableArray *countryCode353Array = [[NSMutableArray alloc] init];
        [countryCode353Array addObject:@"IE"];
        [kMapCCode2CN setObject:countryCode353Array forKey:@"353"];

        NSMutableArray *countryCode256Array = [[NSMutableArray alloc] init];
        [countryCode256Array addObject:@"UG"];
        [kMapCCode2CN setObject:countryCode256Array forKey:@"256"];

        NSMutableArray *countryCode370Array = [[NSMutableArray alloc] init];
        [countryCode370Array addObject:@"LT"];
        [kMapCCode2CN setObject:countryCode370Array forKey:@"370"];

        NSMutableArray *countryCode506Array = [[NSMutableArray alloc] init];
        [countryCode506Array addObject:@"CR"];
        [kMapCCode2CN setObject:countryCode506Array forKey:@"506"];

        NSMutableArray *countryCode248Array = [[NSMutableArray alloc] init];
        [countryCode248Array addObject:@"SC"];
        [kMapCCode2CN setObject:countryCode248Array forKey:@"248"];

        NSMutableArray *countryCode265Array = [[NSMutableArray alloc] init];
        [countryCode265Array addObject:@"MW"];
        [kMapCCode2CN setObject:countryCode265Array forKey:@"265"];

        NSMutableArray *countryCode290Array = [[NSMutableArray alloc] init];
        [countryCode290Array addObject:@"SH"];
        [countryCode290Array addObject:@"TA"];
        [kMapCCode2CN setObject:countryCode290Array forKey:@"290"];

        NSMutableArray *countryCode354Array = [[NSMutableArray alloc] init];
        [countryCode354Array addObject:@"IS"];
        [kMapCCode2CN setObject:countryCode354Array forKey:@"354"];

        NSMutableArray *countryCode257Array = [[NSMutableArray alloc] init];
        [countryCode257Array addObject:@"BI"];
        [kMapCCode2CN setObject:countryCode257Array forKey:@"257"];

        NSMutableArray *countryCode371Array = [[NSMutableArray alloc] init];
        [countryCode371Array addObject:@"LV"];
        [kMapCCode2CN setObject:countryCode371Array forKey:@"371"];

        NSMutableArray *countryCode507Array = [[NSMutableArray alloc] init];
        [countryCode507Array addObject:@"PA"];
        [kMapCCode2CN setObject:countryCode507Array forKey:@"507"];

        NSMutableArray *countryCode249Array = [[NSMutableArray alloc] init];
        [countryCode249Array addObject:@"SD"];
        [kMapCCode2CN setObject:countryCode249Array forKey:@"249"];

        NSMutableArray *countryCode266Array = [[NSMutableArray alloc] init];
        [countryCode266Array addObject:@"LS"];
        [kMapCCode2CN setObject:countryCode266Array forKey:@"266"];

        NSMutableArray *countryCode51Array = [[NSMutableArray alloc] init];
        [countryCode51Array addObject:@"PE"];
        [kMapCCode2CN setObject:countryCode51Array forKey:@"51"];

        NSMutableArray *countryCode291Array = [[NSMutableArray alloc] init];
        [countryCode291Array addObject:@"ER"];
        [kMapCCode2CN setObject:countryCode291Array forKey:@"291"];

        NSMutableArray *countryCode258Array = [[NSMutableArray alloc] init];
        [countryCode258Array addObject:@"MZ"];
        [kMapCCode2CN setObject:countryCode258Array forKey:@"258"];

        NSMutableArray *countryCode355Array = [[NSMutableArray alloc] init];
        [countryCode355Array addObject:@"AL"];
        [kMapCCode2CN setObject:countryCode355Array forKey:@"355"];

        NSMutableArray *countryCode372Array = [[NSMutableArray alloc] init];
        [countryCode372Array addObject:@"EE"];
        [kMapCCode2CN setObject:countryCode372Array forKey:@"372"];

        NSMutableArray *countryCode27Array = [[NSMutableArray alloc] init];
        [countryCode27Array addObject:@"ZA"];
        [kMapCCode2CN setObject:countryCode27Array forKey:@"27"];

        NSMutableArray *countryCode52Array = [[NSMutableArray alloc] init];
        [countryCode52Array addObject:@"MX"];
        [kMapCCode2CN setObject:countryCode52Array forKey:@"52"];

        NSMutableArray *countryCode380Array = [[NSMutableArray alloc] init];
        [countryCode380Array addObject:@"UA"];
        [kMapCCode2CN setObject:countryCode380Array forKey:@"380"];

        NSMutableArray *countryCode267Array = [[NSMutableArray alloc] init];
        [countryCode267Array addObject:@"BW"];
        [kMapCCode2CN setObject:countryCode267Array forKey:@"267"];
    });
    return [kMapCCode2CN objectForKey:key];
}

@end

