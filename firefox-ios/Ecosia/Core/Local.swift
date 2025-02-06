// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Local: String, Codable, CaseIterable {
    case
    es_ar = "es-ar",
    en_au = "en-au",
    de_at = "de-at",
    fr_be = "fr-be",
    nl_be = "nl-be",
    pt_br = "pt-br",
    bg_bg = "bg-bg",
    en_ca = "en-ca",
    fr_ca = "fr-ca",
    es_cl = "es-cl",
    zh_cn = "zh-cn",
    es_co = "es-co",
    hr_hr = "hr-hr",
    da_dk = "da-dk",
    fi_fi = "fi-fi",
    fr_fr = "fr-fr",
    de_de = "de-de",
    zh_hk = "zh-hk",
    en_in = "en-in",
    en_id = "en-id",
    en_ie = "en-ie",
    it_it = "it-it",
    ja_jp = "ja-jp",
    lv_lv = "lv-lv",
    lt_lt = "lt-lt",
    en_my = "en-my",
    es_mx = "es-mx",
    nl_nl = "nl-nl",
    en_nz = "en-nz",
    nb_no = "nb-no",
    es_pe = "es-pe",
    en_ph = "en-ph",
    pl_pl = "pl-pl",
    pt_pt = "pt-pt",
    ru_ru = "ru-ru",
    ar_sa = "ar-sa",
    en_sa = "en-sa",
    en_sg = "en-sg",
    sk_sk = "sk-sk",
    en_za = "en-za",
    ko_kr = "ko-kr",
    es_es = "es-es",
    sv_se = "sv-se",
    de_ch = "de-ch",
    fr_ch = "fr-ch",
    zh_tw = "zh-tw",
    en_th = "en-th",
    th_th = "th-th",
    tr_tr = "tr-tr",
    uk_ua = "uk-ua",
    en_gb = "en-gb",
    en_us = "en-us",
    es_us = "es-us",
    es_ve = "es-ve",
    en_vn = "en-vn",
    vi_vn = "vi-vn",
    cz_cz = "cz-cz",
    ee_ee = "ee-ee",
    gr_gr = "gr-gr",
    ro_ro = "ro-ro",
    en_ww = "en-ww"

    static func make(for locale: Locale) -> Self {
        locale.local ?? locale.withCountry ?? locale.withRegion ?? .en_us
    }
}

private extension Locale {
    var local: Local? {
        Local(rawValue: identifier.lowercased())
    }

    var withCountry: Local? {
        (self as NSLocale).countryCode.flatMap { code in
            Local.allCases.first { $0.rawValue.hasSuffix(code.lowercased()) }
        }
    }

    var withRegion: Local? {
        regionCode.flatMap { code in
            Local.allCases.first { $0.rawValue.hasSuffix(code.lowercased()) }
        }
    }
}
