// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

// swiftlint:disable function_body_length line_length
struct MerinoTestData {
    /// Because we're not testing the Merino API/AS module, we're simply providing some
    /// dummy data here.
    func getMockDataFeed(_ numberOfStories: Int) -> [RecommendationDataItem] {
        var mockData = mockFeedData(startingRank: 0)
        while mockData.count < numberOfStories {
            mockData.append(contentsOf: mockFeedData(startingRank: Int64(mockData.count)))
        }

        return mockData
    }

    private func mockFeedData(startingRank: Int64) -> [RecommendationDataItem] {
        let item1 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "3533e87e-4997-40d9-b9fb-d1cb0251f7a2",
            scheduledCorpusItemId: "e2acfa3e-5796-4dfd-97e0-789534b255fc",
            url: "https://www.istockphoto.com/photos/funny-dog-teeth",
            title: "iOS Team's Favourite Dog with Funny Toofs",
            excerpt: "A little goes a long way with especially tough cuts—like this juicy London broil.",
            topic: Optional("food"),
            publisher: "Merino Mock Stories",
            isTimeSensitive: false,
            imageUrl: "https://img-getpocket.cdn.mozilla.net/direct?url=https://pocket-image-cache.com/1200x/filters:format(jpg):extract_focal()/https%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F1923%252F1571076802_GettyImages-626006674.jpg&resize=w450",
            iconUrl: nil,
            tileId: 5001967569054564,
            receivedRank: startingRank
        )

        let item2 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "84bf104c-0505-4231-89d5-3d743830ecf8",
            scheduledCorpusItemId: "7b413f5d-a77a-484f-bbb9-0c000ca3a5cc",
            url: "https://www.cbsnews.com/news/cracker-barrel-cbrl-stock-down-200-million-loss-new-logo-change/?utm_source=firefox-newtab-en-us",
            title: "Cracker Barrel Loses Almost $200 Million in Value As Stock Plunges After New Logo Release",
            excerpt: "Cracker Barrel stock plunged almost 15% on Thursday after the company released a new logo that removes its long-time image of a man leaning against a barrel.",
            topic: Optional("business"),
            publisher: "CBS News",
            isTimeSensitive: true,
            imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/24f8f255-d514-4721-aead-d63057df94f5.jpeg",
            iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/8b0ecb290ba9c0d8b86b5fbdea1b8eba2f52fd30b07d3307d99d39384fb81c05_12061.png"),
            tileId: 1952229662688373,
            receivedRank: startingRank + 1
        )
        let item3 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "95670c69-3082-4f8c-8543-555293f68649",
            scheduledCorpusItemId: "fa688491-4572-4588-8548-f8a83d98d12c",
            url: "https://www.hollywoodreporter.com/lifestyle/lifestyle-news/millie-bobby-brown-husband-jake-bongiovi-adoption-baby-girl-1236350219/?utm_source=firefox-newtab-en-us",
            title: "Millie Bobby Brown and Husband Jake Bongiovi Welcome First Child Through Adoption",
            excerpt: "The ‘Stranger Things’ star shared the surprise news on Instagram on Thursday morning: “We are beyond excited to embark on this beautiful next chapter of parenthood in both peace and privacy.”",
            topic: Optional("arts"),
            publisher: "The Hollywood Reporter",
            isTimeSensitive: true,
            imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/27c26788-cf23-44b8-8b40-d76993690b23.jpeg",
            iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/162eb56a3019c04beb5831f93a82c58769dc75f905eb8221849a21fa6618ee22_1533.png"),
            tileId: 6770537480335588,
            receivedRank: startingRank + 2
        )
        let item4 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "78ed1c7c-53f6-48ef-b31c-3f1651111f9f",
            scheduledCorpusItemId: "afaa1153-9868-4539-bb7f-9a4abbfba084",
            url: "https://www.nbcnews.com/politics/donald-trump/ny-appeals-court-throws-trumps-500-million-fraud-judgment-rcna217340?utm_source=firefox-newtab-en-us",
            title: "New York Appeals Court Throws Out Trump’s More Than $500 Million Fraud Judgment",
            excerpt: "The ruling by the state Appellate Division spares the president and his companies from having to pay an award they had warned would severely damage his company.",
            topic: Optional("government"),
            publisher: "NBC News",
            isTimeSensitive: true,
            imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/a41a8610-a32e-476c-ac76-ca70a04512f0.jpeg",
            iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/f72a169d901fe296f4cc35642ffc42d1c946bd56e81f9fa2fdbe0cf5ecdf1fc9_5052.png"),
            tileId: 8987118048804803,
            receivedRank: startingRank + 3
        )
        let item5 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "9d61603e-514f-404c-a6b7-a1cece33d7ba",
            scheduledCorpusItemId: "dbecb6c0-944c-44bd-acbd-49ddaa3e6951",
            url: "https://apnews.com/article/trump-visas-deportations-068ad6cd5724e7248577f17592327ca4?utm_source=firefox-newtab-en-us",
            title: "Trump Administration Reviewing All 55M People With US Visas for Potential Deportable Violations",
            excerpt: "The Trump administration says it’s reviewing all the more than 55 million people with U.S. visas for potential deportable violations.",
            topic: Optional("government"),
            publisher: "The Associated Press",
            isTimeSensitive: true,
            imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/67d52e4c-8a13-439a-8eeb-8310fdda2b7e.jpeg",
            iconUrl: nil,
            tileId: 6659490465553266,
            receivedRank: startingRank + 4
        )
        let item6 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "0843c943-6ae3-485f-8c89-05349ff8ec4e",
            scheduledCorpusItemId: "ff8b8868-08d2-442c-a9dc-5faea05d97a1",
            url: "https://www.rollingstone.com/music/music-news/brent-hinds-mastodon-dead-obituary-1235413200/?utm_source=firefox-newtab-en-us",
            title: "Brent Hinds, Mastodon Co-Founder and Former Lead Guitarist, Dead at 51",
            excerpt: "Musician appeared on eight albums as part of Grammy-winning heavy metal band.",
            topic: Optional("arts"),
            publisher: "Rolling Stone",
            isTimeSensitive: true,
            imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/dd5bc1f9-dadf-40f6-96a6-10061c7e33de.jpeg",
            iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/f8a09a712c2b2b7a087e406038cb7f008706993d336c4b2568a331c3ac04de8e_10498.webp"),
            tileId: 1640985575611217,
            receivedRank: startingRank + 5
        )
        let item7 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "be8f7702-bf82-4f33-a8f2-f50d3f1816d2",
            scheduledCorpusItemId: "58a54df3-e308-415f-8159-9af0c537da6d",
            url: "https://www.marthastewart.com/risks-of-tossing-banana-peels-outside-11792455?utm_source=firefox-newtab-en-us",
            title: "Never Toss a Banana Peel Outside—Here’s Why It’s Such a Big Mistake",
            excerpt: "Think tossing a banana peel outside is harmless? Experts explain why littering organic waste like banana peels can harm wildlife, disrupt ecosystems, and damage the environment.",
            topic: Optional("food"),
            publisher: "Martha Stewart",
            isTimeSensitive: false,
            imageUrl: "https://www.marthastewart.com/thmb/wSCEairFrWeEyJkylAq83H0FKWM=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/GettyImages-1327738996-512b8dbc53134de69c06563080d63816.jpg",
            iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/8ca59983bd90b386dcb3cfeec7a800851297279b217c5a753d5ec63cb5809d89_10526.oct"),
            tileId: 7932148395325558,
            receivedRank: startingRank + 6
        )
        let item8 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "0264e4c7-0399-4db7-a0b5-3abc281b2149",
            scheduledCorpusItemId: "54356144-e2cf-4b7e-935b-9c38c5321c79",
            url: "https://www.nbcnews.com/world/asia/cloudbursts-killed-400-people-south-asia-are-rcna225997?utm_source=firefox-newtab-en-us",
            title: "Cloudbursts Have Killed Over 400 People in South Asia. What Are They?",
            excerpt: "More than 430 people have been killed after intense deluges swallowed entire villages in mountainous India and Pakistan as climate change intensifies what experts say are called “rain bombs” or cloudbursts.",
            topic: Optional("education-science"),
            publisher: "NBC News",
            isTimeSensitive: true,
            imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/caa6baf4-85ab-443c-b650-96856fb4818d.jpeg",
            iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/f72a169d901fe296f4cc35642ffc42d1c946bd56e81f9fa2fdbe0cf5ecdf1fc9_5052.png"),
            tileId: 4748605489636694,
            receivedRank: startingRank + 7
        )
        let item9 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "09999dc6-d7c8-47ac-8652-38d8f96fb113",
            scheduledCorpusItemId: "93c2c9d5-a593-4124-9183-2a8f47982815",
            url: "https://variety.com/2025/tv/news/emily-in-paris-season-5-release-date-first-look-1236493943/?utm_source=firefox-newtab-en-us",
            title: "‘Emily in Paris’ Sets Season 5 Release Date, Drops First Look As Emily Heads to Venice",
            excerpt: "“Emily in Paris” is back and heading to Venice, with Netflix setting the season 5 premiere date",
            topic: Optional("arts"),
            publisher: "Variety",
            isTimeSensitive: true,
            imageUrl: "https://s3.us-east-1.amazonaws.com/pocket-curatedcorpusapi-prod-images/bd4f6371-6482-4eea-b396-fed08a10b6ec.jpeg",
            iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/0a8875435837f783fbf1022a78eafca4288ab0cd7efc6b8a7933d8e875f5b87d_2886.png"),
            tileId: 2594876311576705,
            receivedRank: startingRank + 8
        )
        let item10 = MozillaAppServices.RecommendationDataItem(
            corpusItemId: "ee304902-5a8c-4eb5-b2bd-a7db8427a5f6",
            scheduledCorpusItemId: "77b1de51-54af-460a-a025-c3080f3cc76b",
            url: "https://www.popularmechanics.com/science/health/a65821818/breath-hold-record/?utm_source=firefox-newtab-en-us",
            title: "A Freediver Held His Breath for Almost Half an Hour—and Obliterated a World Record",
            excerpt: "The attempt was only possible thanks to some pre-gaming with pure oxygen, but still eye-popping.",
            topic: Optional("sports"),
            publisher: "Popular Mechanics",
            isTimeSensitive: false,
            imageUrl: "https://hips.hearstapps.com/hmg-prod/images/man-meditating-in-swimming-pool-royalty-free-image-1755637009.pjpeg?crop=1.00xw:0.754xh;0,0.111xh&resize=1200:*",
            iconUrl: Optional("https://merino-images.services.mozilla.com/favicons/fe1cb0b8726e04628d485fbea02af35769e1e55d8c1b2dae8b421d624d567727_4738.png"),
            tileId: 2930260002745765,
            receivedRank: startingRank + 9
        )

        return [
            item1,
            item2,
            item3,
            item4,
            item5,
            item6,
            item7,
            item8,
            item9,
            item10,
        ]
    }
}
// swiftlint:enable function_body_length line_length
