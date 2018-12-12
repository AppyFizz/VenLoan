/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a 
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() { 
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>') 
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
};

// var DefaultBuilder = require("truffle-default-builder");

// module.exports = {
//   build: new DefaultBuilder({
//     "index.html": "index.html",
//     "app.js": [
//       "javascripts/app.js"
//     ],
//     "app.css": [
//       "stylesheets/app.css"
//     ],
//     "images/": "images/"
//   }),
//   networks: {
//     development: {
//       host: "localhost",
//       port: 8545,
//       network_id: "*" // Match any network id
//     }
//   }
// };

// module.exports = {
//   // See <http://truffleframework.com/docs/advanced/configuration>
//   // to customize your Truffle configuration!
//   networks: {
//     "development": {
//       network_id: 2,
//       host: "localhost",
//       port: 9545
//     },
//   }
// };