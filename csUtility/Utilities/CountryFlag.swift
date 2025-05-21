// Utilities/CountryFlags.swift (Yeni dosya)
import Foundation

// Basit bir ülke kodu -> bayrak emoji dönüştürücü
// Daha kapsamlı bir kütüphane veya SFSymbols da kullanılabilir.
func flag(country: String) -> String {
    let base: UInt32 = 127397 // Bölgesel Gösterge Sembol Harfi A için Unicode skaler değeri - 1
    var s = ""
    for v in country.uppercased().unicodeScalars {
        if let scalar = UnicodeScalar(base + v.value) {
            s.unicodeScalars.append(scalar)
        }
    }
    return String(s)
}

// Örnek Kullanım:
// let trFlag = flag(country: "TR") // 🇹🇷
// let dkFlag = flag(country: "DK") // 🇩🇰
