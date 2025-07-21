// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

protocol MerinoStoriesProviding: Sendable {
    typealias StoryResult = Swift.Result<[RecommendationDataItem], Error>

    func fetchStories(items: Int32) async throws -> [RecommendationDataItem]
}

extension MerinoStoriesProviding {
    func fetchStories(items: Int32) async throws -> [RecommendationDataItem] {
        return try await fetchStories(items: items)
    }
}

final class MerinoProvider: MerinoStoriesProviding, FeatureFlaggable, @unchecked Sendable {
    private static let SupportedLocales = [
        "en_CA",
        "en_US",
        "en_GB",
        "en_ZA",
        "de_DE",
        "de_AT",
        "de_CH"
    ]

    private let prefs: Prefs
    private var logger: Logger

    let MerinoServicesBaseURL = "https://merino.services.mozilla.com"

    enum Error: Swift.Error {
        case failure
    }

    init(
        prefs: Prefs,
        logger: Logger = DefaultLogger.shared
    ) {
        self.prefs = prefs
        self.logger = logger
    }

    func fetchStories(items: Int32) async throws -> [RecommendationDataItem] {
        let isFeatureEnabled = prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        let isCurrentLocaleSupported = MerinoProvider.islocaleSupported(Locale.current.identifier)

        if shouldUseMockData {
            return try await getMockDataFeed(count: items)
        }

        // Ensure the feature is enabled and current locale is supported
        guard isFeatureEnabled, isCurrentLocaleSupported else {
            throw Error.failure
        }

        return try await getFeedItems(items: items)
    }

    func getFeedItems(items: Int32) async throws -> [RecommendationDataItem] {
        do {
            let client = try CuratedRecommendationsClient(
                config: CuratedRecommendationsConfig(
                    baseHost: MerinoServicesBaseURL,
                    userAgentHeader: UserAgent.getUserAgent()
                )
            )

            guard let currentLocale = iOSToMerinoLocale(from: Locale.current.identifier) else {
                return []
            }

            let merinoRequest = CuratedRecommendationsRequest(
                locale: currentLocale,
                count: items
            )

            let response = try client.getCuratedRecommendations(request: merinoRequest)
            return response.data
        } catch let error as CuratedRecommendationsApiError {
            switch error {
            case .Network(let reason):
                logger.log("Network error when fetching Curated Recommendations: \(reason)",
                        level: .debug,
                        category: .merino
                    )

            case .Other(let code?, let reason) where code == 400:
                logger.log("Bad Request: \(reason)",
                        level: .debug,
                        category: .merino
                    )

            case .Other(let code?, let reason) where code == 422:
                logger.log("Validation Error: \(reason)",
                        level: .debug,
                        category: .merino
                    )

            case .Other(let code?, let reason) where (500...599).contains(code):
                logger.log("Server Error: \(reason)",
                        level: .debug,
                        category: .merino
                    )

            case .Other(nil, let reason):
                logger.log("Missing status code: \(reason)",
                        level: .debug,
                        category: .merino
                    )

            case .Other(_, let reason):
                logger.log("Unexpected Error: \(reason)",
                        level: .debug,
                        category: .merino
                    )
            }
            return []
        } catch {
            logger.log("Unhandled error: \(error)",
                    level: .debug,
                    category: .merino
                )
            return []
        }
    }

    // Returns nil if the locale is not supported
    static func islocaleSupported(_ locale: String) -> Bool {
        return MerinoProvider.SupportedLocales.contains(locale)
    }

    private var shouldUseMockData: Bool {
        return featureFlags.isCoreFeatureEnabled(.useMockData)
    }

    private func iOSToMerinoLocale(from locale: String) -> CuratedRecommendationLocale? {
        switch locale {
        case "en": return .en
        case "en_CA": return .enCa
        case "en_GB": return .enGb
        case "en_US": return .enUs
        case "de": return .de
        case "de_DE": return .deDe
        case "de_AT": return .deAt
        case "de_CH": return .deCh
            // Not sure if we're supporting these yet
            //        case "fr": return .fr
            //        case "fr_FR": return .frFr
            //        case "es": return .es
            //        case "es_ES": return .esEs
            //        case "it": return .it
            //        case "it_IT": return .itIt
        default: return nil
        }
    }

    /// Because we're not testing the Merino API/AS module, we're simply providing some
    /// dummy data here.
    private func getMockDataFeed(count: Int32 = 2) async throws -> [RecommendationDataItem] {
        // swiftlint:disable line_length
        return [
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "3533e87e-4997-40d9-b9fb-d1cb0251f7a2",
                scheduledCorpusItemId: "e2acfa3e-5796-4dfd-97e0-789534b255fc",
                url: "https://getpocket.com/explore/item/the-key-to-tender-meat-baking-soda?utm_source=firefox-newtab-en-us",
                title: "Test stories",
                excerpt: "A little goes a long way with especially tough cuts—like this juicy London broil.",
                topic: Optional("food"),
                publisher: "Bon Appétit",
                isTimeSensitive: false,
                imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/488b9813-362a-4f2f-8913-c6809bb13b13.jpeg",
                iconUrl: nil,
                tileId: 5001967569054564,
                receivedRank: 0
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "0d050453-5e55-449f-b3db-ef8ad8718565",
                scheduledCorpusItemId: "d0a8f781-0f4d-45bb-8b67-0374ab15eddb",
                url: "https://www.theatlantic.com/ideas/archive/2025/07/colbert-ouster-cbc-trump/683593/?utm_source=firefox-newtab-en-us",
                title: "Is Colbert’s Ouster Really Just a ‘Financial Decision’?",
                excerpt: "CBS no longer deserves the benefit of the doubt.",
                topic: Optional("government"),
                publisher: "The Atlantic",
                isTimeSensitive: false,
                imageUrl: "https://cdn.theatlantic.com/thumbor/TbnhCECNqQFY0aj_PspubT7ktHg=/0x0:4992x2600/1200x625/media/img/mt/2025/07/GettyImages_2221626038/original.jpg",
                iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/be51ae18a8eef2024d43939444d387d010b94cb958609dfe265de46cee3fbaa3_2172.png"),
                tileId: 2985020605016951,
                receivedRank: 1
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "20744137-b078-4ce9-b767-ba37689749c0",
                scheduledCorpusItemId: "55f52f66-1003-4855-85a7-96b572e6a738",
                url: "https://www.popularmechanics.com/space/a65420751/sunspots-duration/?utm_source=firefox-newtab-en-us",
                title: "Scientists Just Solved a Solar Mystery That Baffled Humanity for Centuries",
                excerpt: "We’ve never known why sunspots can last on our star’s surface for as long as they do, but we finally cracked the case.",
                topic: Optional("education-science"),
                publisher: "Popular Mechanics",
                isTimeSensitive: false,
                imageUrl: "https://hips.hearstapps.com/hmg-prod/images/view-of-the-sun-through-a-solar-telescope-showing-solar-news-photo-1752786212.pjpeg?crop=1xw:0.75926xh;center,top&resize=1200:*",
                iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/fe1cb0b8726e04628d485fbea02af35769e1e55d8c1b2dae8b421d624d567727_4738.png"),
                tileId: 7721968922229774,
                receivedRank: 2
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "f706b881-6ab1-4cf6-add7-00444d59a91a",
                scheduledCorpusItemId: "b335ab06-519a-4464-8429-f98a58292194",
                url: "https://www.axios.com/2025/07/17/trump-china-retreat-soft-power?utm_source=firefox-newtab-en-us",
                title: "Trump’s Soft-Power Retreat Scrambles U.S.-China Race",
                excerpt: "The administration has stepped back from key arenas in which the U.S. has sought to blunt China’s rise.",
                topic: Optional("government"),
                publisher: "Axios",
                isTimeSensitive: false,
                imageUrl: "https://images.axios.com/yoaacJizsxRj4AHkOgylKUKfAcU=/0x0:1920x1080/1366x768/2025/07/16/1752699524830.jpg",
                iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/8df439915f8fd081a2945d6847262222da8a720833d7e12a545c56ecfa89f744_387.svg"),
                tileId: 6020234825850118,
                receivedRank: 3
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "f2f9185a-c690-4ac1-acd3-f225f927417c",
                scheduledCorpusItemId: "a239fa95-36f8-42f7-a4ca-d3878766dcdd",
                url: "https://getpocket.com/explore/item/the-best-time-to-eat-dinner-according-to-the-experts?utm_source=firefox-newtab-en-us",
                title: "The Best Time to Eat Dinner, According to the Experts",
                excerpt: "Is it better to stick to a strict meal schedule or eat when you’re hungry? Health experts share advice.",
                topic: Optional("health"),
                publisher: "Vogue",
                isTimeSensitive: false,
                imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/ada64205-796a-4b4f-9e67-6250d4d4e86e.jpeg",
                iconUrl: nil,
                tileId: 3011629647813898,
                receivedRank: 4
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "e128cf2e-9045-4ade-aed9-9175a466a955",
                scheduledCorpusItemId: "550ac795-4748-4487-b4fa-15ded5b06133",
                url: "https://www.realsimple.com/the-worst-thing-you-can-do-to-your-lawn-in-summer-11774576?utm_source=firefox-newtab-en-us",
                title: "Landscapers Agree: This Is the Worst Thing You Can Do to Your Lawn in Summer",
                excerpt: "Learn the biggest lawn care mistake to avoid in summer, plus expert-backed tips on watering, mowing, and fertilizing to keep your grass green and healthy.",
                topic: Optional("home"),
                publisher: "Real Simple",
                isTimeSensitive: false,
                imageUrl: "https://www.realsimple.com/thmb/NEOMglkzJmZ8O2lASU-fyV3X4Lc=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/worst-mistakes-for-summer-lawn-GettyImages-186668074-572f7f80be884e54857d132e99ce324f.jpg",
                iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/349614dd7779a80fded606c4efee36347a796242a29b697ec8581119f37e929a_1961.oct"),
                tileId: 6679041012221866,
                receivedRank: 5
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "bc395532-b2ad-4771-8b81-53bcbf0641cc",
                scheduledCorpusItemId: "1c4d7391-90bd-487c-9c27-902d1eec3e4a",
                url: "https://www.openculture.com/2025/07/the-first-photograph-ever-taken.html?utm_source=firefox-newtab-en-us",
                title: "The First Photograph Ever Taken (1826)",
                excerpt: "In histories of early photography, Louis Daguerre faithfully appears as one of the fathers of the medium.",
                topic: Optional(
                    "education"
                ),
                publisher: "Open Culture",
                isTimeSensitive: false,
                imageUrl: "https://cdn8.openculture.com/2025/07/16200403/Niepce-Reproduction-1.jpg",
                iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/4c25757d2c34d98d4ab8276c71b45937d8a74845affb14b5ef6221b401e4cd97_15828.png"),
                tileId: 5546176030426704,
                receivedRank: 6
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "23fc633e-371e-4e0b-8d47-a7dcf18c1607",
                scheduledCorpusItemId: "6be7cf34-1401-49d1-9084-38be81f5a224",
                url: "https://www.popsci.com/health/dark-age-medicine-tik-tok/?utm_source=firefox-newtab-en-us",
                title: "Dark Age Detoxes Sometimes Resembled TikTok Health Trends",
                excerpt: "A few remedies hold up. Most don’t—and that’s why good research matters.",
                topic: Optional("health"),
                publisher: "Popular Science",
                isTimeSensitive: false,
                imageUrl: "https://www.popsci.com/wp-content/uploads/2025/07/Medieval-Medical-Manuscript.png?w=2000",
                iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/1150b8d47148a907b3d87b3d603617bc37aa6fc42e8c36b5bbcf2520e4eb0811_8786.webp"),
                tileId: 6504696185440382,
                receivedRank: 7
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "3a4cf682-0d7e-4732-9cfe-f6febb54c06f",
                scheduledCorpusItemId: "2bcddf89-5e2d-41a4-8c5f-ccdd1960b496",
                url: "https://www.polygon.com/dc/613031/does-superman-kill-2025-movie-james-gunn?utm_source=firefox-newtab-en-us",
                title: "Superman Commits the Sin That Set Off Endless Fights Over Zack Snyder’s Man of Steel",
                excerpt: "Guardians of the Galaxy director James Gunn has strong opinions about whether it’s okay for Superman to kill",
                topic: Optional("arts"),
                publisher: "Polygon",
                isTimeSensitive: false,
                imageUrl: "https://platform.polygon.com/wp-content/uploads/sites/2/2025/07/rev-1-SPMN-TRL1-011_High_Res_JPEG.jpeg?quality=90&strip=all&crop=0%2C0.38911471028896%2C100%2C99.221770579422&w=1200",
                iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/625a5459f1a0378ec8a6a9078bd7d8e2123b3b280c5fb3737c3743a78d149f25_3122.png"),
                tileId: 1470620396767604,
                receivedRank: 8
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "4670787e-2c28-4ce9-ba29-7243454e8145",
                scheduledCorpusItemId: "19775920-c087-47f1-bfd6-448105b1f614",
                url: "https://theweek.com/personal-finance/maximum-social-security-benefit?utm_source=firefox-newtab-en-us",
                title: "How Can You Get the Maximum Social Security Retirement Benefit?",
                excerpt: "For many, Social Security benefits are a key part of their retirement plan. So it makes sense that you would want to get the most possible from this monthly source of income.",
                topic: Optional("finance"),
                publisher: "The Week",
                isTimeSensitive: false,
                imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/d8ac2a42-0f8e-4564-99ec-0fccd70ce366.jpeg",
                iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/d82545b2950d2fb4b17af30ec1fadc004109a7d99013ae2e4e2c50ce27688b24_953.svg"),
                tileId: 3926404236008861,
                receivedRank: 9
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "d4719254-25e7-4e1c-8f6f-9e5b437204bd",
                scheduledCorpusItemId: "c7b1e6e3-bde2-4539-8799-d0901e87f317",
                url: "https://www.marthastewart.com/how-to-get-rid-of-fleas-in-yard-11770641?utm_source=firefox-newtab-en-us",
                title: "How to Get Rid of Fleas in Your Yard—and Keep Them From Coming Indoors",
                excerpt: "Learn how to effectively get rid of fleas in your yard with these safe, expert-recommended methods—and stop them from invading your home.",
                topic: Optional("home"),
                publisher: "Martha Stewart",
                isTimeSensitive: false,
                imageUrl: "https://www.marthastewart.com/thmb/zJ_EUZ8fRSOkDr1rDs2WVbXR0m0=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/ms-dog-in-yard-b729532e128640e8872b85664427f42b.jpg",
                iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/8ca59983bd90b386dcb3cfeec7a800851297279b217c5a753d5ec63cb5809d89_10526.oct"),
                tileId: 6249784105520104,
                receivedRank: 10
            ),
            MozillaAppServices.RecommendationDataItem(
                corpusItemId: "eb49b11b-91cd-4619-af92-1d9dd05ede28",
                scheduledCorpusItemId: "a8e11e16-3443-4472-a298-441e26c6eb6f",
                url: "https://getpocket.com/explore/item/an-ancient-era-of-global-warming-could-hint-at-our-scorching-future?utm_source=firefox-newtab-en-us",
                title: "An Ancient Era of Global Warming Could Hint at Our Scorching Future",
                excerpt: "Looking back at the strange and sweaty days of the PETM.",
                topic: Optional("education-science"),
                publisher: "Popular Science",
                isTimeSensitive: false,
                imageUrl: "https://s3.amazonaws.com/pocket-curatedcorpusapi-prod-images/f12454f0-29ca-417e-9585-11349b9899e0.jpeg",
                iconUrl: nil,
                tileId: 6586934795928967,
                receivedRank: 11
            )
        ]
        // swiftlint:enable line_length
    }
}
