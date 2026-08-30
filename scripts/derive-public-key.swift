import CryptoKit
import Foundation

// Sparkle's exported private key is a base64 Ed25519 seed. Printing the public
// key it derives lets a release check that it will be accepted by installed
// copies before it ships something they would silently reject.
guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write(Data("usage: derive-public-key.swift <private-key-file>\n".utf8))
    exit(2)
}

let text = (try? String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8))?
    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

guard let seed = Data(base64Encoded: text),
      let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: seed) else {
    FileHandle.standardError.write(Data("could not read an Ed25519 private key from that file\n".utf8))
    exit(2)
}

print(key.publicKey.rawRepresentation.base64EncodedString())
