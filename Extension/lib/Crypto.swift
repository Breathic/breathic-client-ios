import Foundation
import SwiftJWT

struct MyClaims: Claims {
    let validationKey: String
}

func sign(validationKey: String) -> String {
    do {
        let key: Data = try Data(
            contentsOf: URL(fileURLWithPath: PRIVATE_KEY_PATH),
            options: .alwaysMapped
        )
        let jwtSigner = JWTSigner.hs256(key: key)
        let myClaims = MyClaims(validationKey: validationKey)
        var myJWT = JWT(claims: myClaims)
        let signedJWT = try myJWT.sign(using: jwtSigner)
        return signedJWT
    }
    catch {
        print("sign()", error)
    }

    return ""
}
