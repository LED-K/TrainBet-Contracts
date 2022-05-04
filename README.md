

# Train Journey Pronostic app

This project demonstrates an advanced Oracle use case, integrating tools commonly used alongside Hardhat in the ecosystem.

The project comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts. It also comes with a variety of other tools, preconfigured to work with the project code.


Try running some of the following tasks:

```shell
npm install
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

# Smart Contracts deployments

So After you get your account whitelisted to deploy on iExec Sidechain you have to modify the .env.template file to a file named .env, and then edit it to fill in the details. Enter your the private key of the account which will send the deployment transaction.
Same goes for contract verification, you'll need to provide your Etherscan Api key in the .env file
 With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network iExecSidechain scripts/deploy.js
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network iExecSidechain DEPLOYED_CONTRACT_ADDRESS 
```
