/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class TrackingAdsTests: XCTestCase {

    let ath = AdsTelemetryHelper()
    
    func testGetProviderNil() {
        let mockData: [String: String] = ["url": "saasj"]
        let result = ath.getProviderForMessage(message: mockData)
        XCTAssertEqual(result?.name, nil)
    }
    
    func testGetProviderGoogle() {
        let mockData: [String: String] = ["url": "https://www.google.com/search?q=iphone&rlz=1C5CHFA_enRO979RO979&oq=iphone&aqs=chrome..69i57j0i512l9.2034j0j7&sourceid=chrome&ie=UTF-8"]
        let result = ath.getProviderForMessage(message: mockData)
        XCTAssertEqual(result?.name, BasicSearchProvider.google.rawValue)
    }
    
    func testGetProviderDuckDuckGo() {
        let mockData: [String: String] = ["url": "https://duckduckgo.com/?q=iphone&t=ha&va=j&ia=web"]
        let result = ath.getProviderForMessage(message: mockData)
        XCTAssertEqual(result?.name, BasicSearchProvider.duckduckgo.rawValue)
    }
    
    func testGetProviderBing() {
        let mockData: [String: String] = ["url": "https://www.bing.com/search?q=iphone&form=QBLH&sp=-1&pq=ipho&sc=10-4&qs=n&sk=&cvid=3AE803700EA346D0A67F5E6FE8E661A9&ghsh=0&ghacc=0&ghpl="]
        let result = ath.getProviderForMessage(message: mockData)
        XCTAssertEqual(result?.name, BasicSearchProvider.bing.rawValue)
    }
    
    func testGetProviderYahoo() {
        let mockData: [String: String] = ["url": "https://ro.search.yahoo.com/search?p=iphone&fr=yfp-t&fr2=p%3Afp%2Cm%3Asb&ei=UTF-8&fp=1"]
        let result = ath.getProviderForMessage(message: mockData)
        XCTAssertEqual(result?.name, BasicSearchProvider.yahoo.rawValue)
    }
    
    func testListAdUrlsNil() {
        let provider = SearchProviderModel.searchProviderList[0]
        let urls: [String] = []
        XCTAssertEqual(provider.listAdUrls(urls: urls), [])
    }
    
    func testListAdUrlsWrongURL() {
        let provider = SearchProviderModel.searchProviderList[0]
        let urls: [String] = ["https://eune.op.gg"]
        XCTAssertEqual(provider.listAdUrls(urls: urls), [])
    }
    
    func testListAdUrlsGoogle() {
        let provider = SearchProviderModel.searchProviderList[0]
        let urls: [String] = ["https://www.googleadservices.com/pagead/aclk?sa=L&ai=DChcSEwih-5P99c35AhUGkGgJHXg8DEoYABAMGgJ3Zg&ohost=www.google.com&cid=CAASJeRoYucil5gTx1Dra7a5t4AxPQJZ8Lm70ggAP3L_VOoLiZZzUuw&sig=AOD64_1dSBtVL11huUaOUS4NYZZgwPM9Cg&ctype=5&q=&ved=2ahUKEwiM8Iz99c35AhXwh_0HHacsALkQwg8oAHoECAEQCw&adurl="]
        XCTAssertEqual(provider.listAdUrls(urls: urls), urls)
    }
    
    func testListAdUrlsGoogleFromMoreUrls() {
        let provider = SearchProviderModel.searchProviderList[0]
        let urls: [String] = ["https://www.googleadservices.com/pagead/aclk?sa=L&ai=DChcSEwih-5P99c35AhUGkGgJHXg8DEoYABAMGgJ3Zg&ohost=www.google.com&cid=CAASJeRoYucil5gTx1Dra7a5t4AxPQJZ8Lm70ggAP3L_VOoLiZZzUuw&sig=AOD64_1dSBtVL11huUaOUS4NYZZgwPM9Cg&ctype=5&q=&ved=2ahUKEwiM8Iz99c35AhXwh_0HHacsALkQwg8oAHoECAEQCw&adurl=","https://eune.op.gg"]
        XCTAssertEqual(provider.listAdUrls(urls: urls), [urls[0]])
    }
    
    func testListAdUrlsDuckDuckGo() {
        XCTSkip("#3693 - Test failed on XCode 14.1 and MacOS 13 on Bitrise")
        let provider = SearchProviderModel.searchProviderList[1]
        let urls: [String] = ["https://www.googleadservices.com/pagead/aclk?sa=L&ai=DChcSEwih-5P99c35AhUGkGgJHXg8DEoYABAMGgJ3Zg&ohost=www.google.com&cid=CAASJeRoYucil5gTx1Dra7a5t4AxPQJZ8Lm70ggAP3L_VOoLiZZzUuw&sig=AOD64_1dSBtVL11huUaOUS4NYZZgwPM9Cg&ctype=5&q=&ved=2ahUKEwiM8Iz99c35AhXwh_0HHacsALkQwg8oAHoECAEQCw&adurl="]
        XCTAssertEqual(provider.listAdUrls(urls: urls), [])
    }
    
    func testListAdUrlsDuckDuckGoFromMoreUrls() {
        let provider = SearchProviderModel.searchProviderList[1]
        let urls: [String] = ["https://www.googleadservices.com/pagead/aclk?sa=L&ai=DChcSEwih-5P99c35AhUGkGgJHXg8DEoYABAMGgJ3Zg&ohost=www.google.com&cid=CAASJeRoYucil5gTx1Dra7a5t4AxPQJZ8Lm70ggAP3L_VOoLiZZzUuw&sig=AOD64_1dSBtVL11huUaOUS4NYZZgwPM9Cg&ctype=5&q=&ved=2ahUKEwiM8Iz99c35AhXwh_0HHacsALkQwg8oAHoECAEQCw&adurl=","https://eune.op.gg"]
        XCTAssertEqual(provider.listAdUrls(urls: urls), [])
    }
    
    func testListAdUrlsBing() {
        let provider = SearchProviderModel.searchProviderList[3]
        let urls: [String] = ["https://www.bing.com/aclick?ld=e8ksZMewU3OvVXAtm0bMf8MjVUCUyvjlOgnO69Tj5FxmIJ0M5G4_lITqu8IiD1X1070BKQbmbUI33LDAsI1jdWkfwWMr_ZCNj5Ny0DImwo_8P2AiaRuWLOGZRJQadBG0wBHhHQPLwmt1pg39evkjEPnjbk9ETgXsyc6t1WdSAQZ_i3K2O3V_OrxXtGbDqMxGBkJkHHDQ&u=aHR0cHMlM2ElMmYlMmZjbGlja3NlcnZlLmRhcnRzZWFyY2gubmV0JTJmbGluayUyZmNsaWNrJTNmbGlkJTNkNDM3MDAwNjE3MjkyNzg3OTglMjZkc19zX2t3Z2lkJTNkNTg3MDAwMDY4NDU2NTk2NTYlMjZkc19hX2NpZCUzZDY2NzI1NjU5NyUyNmRzX2FfY2FpZCUzZDEyNDg0OTc5NzQyJTI2ZHNfYV9hZ2lkJTNkMTE4MjU4MDcyOTg5JTI2ZHNfYV9saWQlM2Rrd2QtMzAzMzk3MzQ4NTU1JTI2JTI2ZHNfZV9hZGlkJTNkNzQ5MDQyODE2MzMzNTIlMjZkc19lX3RhcmdldF9pZCUzZGt3ZC03NDkwNDM1MDc3NzE5MyUyNiUyNmRzX3VybF92JTNkMiUyNmRzX2Rlc3RfdXJsJTNkaHR0cHMlM2ElMmYlMmZ3d3cud2FsbWFydC5jb20lMmZzZWFyY2glMmYlM2ZxdWVyeSUzZElwaG9uZSUyNTIwQ2VsbCtQaG9uZSUyNmNhdF9pZCUzZDAlMjZhZGlkJTNkMjIyMjIyMjIyMjU0MjI0OTA1NjMlMjZ3bWxzcGFydG5lciUzZHdtdGxhYnMlMjZ3bDAlM2RlJTI2d2wxJTNkbyUyNndsMiUzZG0lMjZ3bDMlM2Q3NDkwNDI4MTYzMzM1MiUyNndsNCUzZGt3ZC03NDkwNDM1MDc3NzE5MyUyNndsNSUzZDE0MDkwOCUyNndsNiUzZCUyNndsNyUzZCUyNndsMTQlM2RpUGhvbmUlMjZ2ZWglM2RzZW0lMjZnY2xpZCUzZGQ2YTAwMWViNmEyMzExZjM3ZDU3NjMxNzk4N2E5NzM3JTI2Z2Nsc3JjJTNkM3AuZHMlMjYlMjZtc2Nsa2lkJTNkZDZhMDAxZWI2YTIzMTFmMzdkNTc2MzE3OTg3YTk3Mzc&rlid=d6a001eb6a2311f37d576317987a9737"]
        XCTAssertEqual(provider.listAdUrls(urls: urls), urls)
    }
    
    func testListAdUrlsBingFromMoreUrls() {
        let provider = SearchProviderModel.searchProviderList[3]
        let urls: [String] = ["https://www.bing.com/aclick?ld=e8ksZMewU3OvVXAtm0bMf8MjVUCUyvjlOgnO69Tj5FxmIJ0M5G4_lITqu8IiD1X1070BKQbmbUI33LDAsI1jdWkfwWMr_ZCNj5Ny0DImwo_8P2AiaRuWLOGZRJQadBG0wBHhHQPLwmt1pg39evkjEPnjbk9ETgXsyc6t1WdSAQZ_i3K2O3V_OrxXtGbDqMxGBkJkHHDQ&u=aHR0cHMlM2ElMmYlMmZjbGlja3NlcnZlLmRhcnRzZWFyY2gubmV0JTJmbGluayUyZmNsaWNrJTNmbGlkJTNkNDM3MDAwNjE3MjkyNzg3OTglMjZkc19zX2t3Z2lkJTNkNTg3MDAwMDY4NDU2NTk2NTYlMjZkc19hX2NpZCUzZDY2NzI1NjU5NyUyNmRzX2FfY2FpZCUzZDEyNDg0OTc5NzQyJTI2ZHNfYV9hZ2lkJTNkMTE4MjU4MDcyOTg5JTI2ZHNfYV9saWQlM2Rrd2QtMzAzMzk3MzQ4NTU1JTI2JTI2ZHNfZV9hZGlkJTNkNzQ5MDQyODE2MzMzNTIlMjZkc19lX3RhcmdldF9pZCUzZGt3ZC03NDkwNDM1MDc3NzE5MyUyNiUyNmRzX3VybF92JTNkMiUyNmRzX2Rlc3RfdXJsJTNkaHR0cHMlM2ElMmYlMmZ3d3cud2FsbWFydC5jb20lMmZzZWFyY2glMmYlM2ZxdWVyeSUzZElwaG9uZSUyNTIwQ2VsbCtQaG9uZSUyNmNhdF9pZCUzZDAlMjZhZGlkJTNkMjIyMjIyMjIyMjU0MjI0OTA1NjMlMjZ3bWxzcGFydG5lciUzZHdtdGxhYnMlMjZ3bDAlM2RlJTI2d2wxJTNkbyUyNndsMiUzZG0lMjZ3bDMlM2Q3NDkwNDI4MTYzMzM1MiUyNndsNCUzZGt3ZC03NDkwNDM1MDc3NzE5MyUyNndsNSUzZDE0MDkwOCUyNndsNiUzZCUyNndsNyUzZCUyNndsMTQlM2RpUGhvbmUlMjZ2ZWglM2RzZW0lMjZnY2xpZCUzZGQ2YTAwMWViNmEyMzExZjM3ZDU3NjMxNzk4N2E5NzM3JTI2Z2Nsc3JjJTNkM3AuZHMlMjYlMjZtc2Nsa2lkJTNkZDZhMDAxZWI2YTIzMTFmMzdkNTc2MzE3OTg3YTk3Mzc&rlid=d6a001eb6a2311f37d576317987a9737","https://eune.op.gg"]
        XCTAssertEqual(provider.listAdUrls(urls: urls), [urls[0]])
    }
    
    func testListAdUrlsYahoo() {
        let provider = SearchProviderModel.searchProviderList[2]
        let urls: [String] = ["https://www.googleadservices.com/pagead/aclk?sa=L&ai=DChcSEwih-5P99c35AhUGkGgJHXg8DEoYABAMGgJ3Zg&ohost=www.google.com&cid=CAASJeRoYucil5gTx1Dra7a5t4AxPQJZ8Lm70ggAP3L_VOoLiZZzUuw&sig=AOD64_1dSBtVL11huUaOUS4NYZZgwPM9Cg&ctype=5&q=&ved=2ahUKEwiM8Iz99c35AhXwh_0HHacsALkQwg8oAHoECAEQCw&adurl="]
        XCTAssertEqual(provider.listAdUrls(urls: urls), [])
    }
    
    func testListAdUrlsYahooFromMoreUrls() {
        let provider = SearchProviderModel.searchProviderList[2]
        let urls: [String] = ["https://www.googleadservices.com/pagead/aclk?sa=L&ai=DChcSEwih-5P99c35AhUGkGgJHXg8DEoYABAMGgJ3Zg&ohost=www.google.com&cid=CAASJeRoYucil5gTx1Dra7a5t4AxPQJZ8Lm70ggAP3L_VOoLiZZzUuw&sig=AOD64_1dSBtVL11huUaOUS4NYZZgwPM9Cg&ctype=5&q=&ved=2ahUKEwiM8Iz99c35AhXwh_0HHacsALkQwg8oAHoECAEQCw&adurl=","https://eune.op.gg"]
        XCTAssertEqual(provider.listAdUrls(urls: urls), [])
    }
}
