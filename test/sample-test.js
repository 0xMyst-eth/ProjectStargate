const { expect } = require("chai");
const { starknet } = require("hardhat");

describe("First test", function () {
  this.timeout(800_000);
  
  let dummyCoin, DummyCoin, arcane, Arcane;
  let account1, account2;

  beforeEach("Should Deploy", async function(){

    account1 = await starknet.deployAccount("OpenZeppelin");
    account2 =await starknet.deployAccount("OpenZeppelin");

    Arcane = await starknet.getContractFactory("Arcane");
    arcane = await Arcane.deploy({ name: starknet.shortStringToBigInt("Arcane"), symbol: starknet.shortStringToBigInt("ARC") });
    DummyCoin = await starknet.getContractFactory("DummyCoin");
    dummyCoin = await DummyCoin.deploy( { name: starknet.shortStringToBigInt("DUMMY"), symbol : starknet.shortStringToBigInt("DUM"), decimals: BigInt(18), initial_supply: { low: 5000000000000000, high: 0 }, recipient: BigInt(account1.starknetContract.address)});
    

    console.log("Deployed!");
    // console.log("Account Address is ",BigInt(account1.starknetContract.address));
    let balance1  =await dummyCoin.call("balanceOf", { account: BigInt(account1.starknetContract.address)});
    console.log("balance is: ", balance1);
    await arcane.invoke("set_eth", { address: dummyCoin.address });


  });

  it("Should mint a wizard", async function() {
    let approved = await account1.invoke(dummyCoin,"approve",{ spender : arcane.address, amount : { low:50000000000000000, high:0 }});
    let accountBalance = await arcane.call("balanceOf", { owner: BigInt(account1.starknetContract.address) });
    console.log("balance is ", accountBalance);
    await account1.invoke(arcane, "mint_star_mage", { wiz_name: starknet.shortStringToBigInt("hello")});
    accountBalance = await arcane.call("balanceOf", { owner: BigInt(account1.starknetContract.address) });
    let balance1  =await dummyCoin.call("balanceOf", { account: BigInt(account1.starknetContract.address)});
    let balance3  =await dummyCoin.call("balanceOf", { account: BigInt(account2.starknetContract.address)});
    let balance2  =await dummyCoin.call("balanceOf", { account: BigInt(arcane.address)});
    console.log("ETH balnce of acc1: ", balance1);
    console.log("ETH balnce of acc2: ", balance3);
    console.log("ETH balnce of Arcane: ", balance2);

    // transfer owner
    await arcane.invoke("transfer_ownership", { new_owner : account2.starknetContract.address });
    await account2.invoke(arcane, "allowance_withdraw", { amount : 500000000000000000000 })
    await account2.invoke(arcane, "withdraw");
    balance1  =await dummyCoin.call("balanceOf", { account: BigInt(account1.starknetContract.address)});
    balance2  =await dummyCoin.call("balanceOf", { account: BigInt(account1.starknetContract.address)});

    console.log("ETH balnce of acc1: ", balance1);
    console.log("ETH balnce of acc2: ", balance2);


    let wizInfos = await arcane.call("get_wiz_infos", { wiz_id: BigInt(0)});
    console.log("wiz infos: ",wizInfos);
  
  });
});
