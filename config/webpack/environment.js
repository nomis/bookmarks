const { environment } = require('@rails/webpacker')
const erb = require('./loaders/erb')

environment.loaders.prepend('erb', erb)

// The default MD4 hash function isn't supported by the latest OpenSSL
// https://stackoverflow.com/a/73465262
environment.config.output.hashFunction = "sha512"

// There's another hard-coded use of MD4 in compression-webpack-plugin
// https://stackoverflow.com/a/69691525
const crypto = require("crypto");
const crypto_orig_createHash = crypto.createHash;
crypto.createHash = algorithm => crypto_orig_createHash(algorithm == "md4" ? "sha512" : algorithm);

module.exports = environment
