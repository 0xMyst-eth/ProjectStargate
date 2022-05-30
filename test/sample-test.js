const { expect } = require("chai");
const { starknet } = require("hardhat");

describe("First test", function () {
  this.timeout(300_000);
  
  let contract, Contract, arcane, Arcane;
  let account1;

  beforeEach("Should Deploy", async function(){

    // Contract = await starknet.getContractFactory("Hello2");
    // contract = await Contract.deploy();
    Arcane = await starknet.getContractFactory("Arcane");
    arcane = await Arcane.deploy({ name: starknet.shortStringToBigInt("Arcane"), symbol: starknet.shortStringToBigInt("ARC") });

    console.log("Deployed!");

    account1 = await starknet.deployAccount("OpenZeppelin");
    // console.log("Account Address is ",BigInt(account1.starknetContract.address));

  });
  
  xit("Test", async function () {
    await contract.invoke("set_authority", { authority_address: BigInt(account1.starknetContract.address)});
 
    await account1.invoke(contract, "set_player_age", { player_id: 0, age: 27 });
    await account1.invoke(contract, "set_player_age", { player_id: 1, age: 56 });
    await account1.invoke(contract, "set_player_age", { player_id: 2, age: 11 });
    await account1.invoke(contract, "set_player_age", { player_id: 3, age: 35 });
    await account1.invoke(contract, "set_player_age", { player_id: 4, age: 8 });


    let playerAge = await contract.call("get_player_age", { player_id: 10 })

    let ageArray = await contract.call("get_player_ages", { start_id : 0, end_id : 5 });
    console.log("yoo : ", ageArray);
    
    console.log("Playe Age: ", playerAge);
  });

  it("Should mint a wizard", async function() {
    let accountBalance = await arcane.call("balanceOf", { owner: BigInt(account1.starknetContract.address) });
    console.log("balance is ", accountBalance);
    await account1.invoke(arcane, "mint_star_mage", { wiz_name: starknet.shortStringToBigInt("hello")});
    accountBalance = await arcane.call("balanceOf", { owner: BigInt(account1.starknetContract.address) });

    let wizInfos = await arcane.call("get_wiz_infos", { wiz_id: BigInt(0)});
    console.log("wiz infos: ",wizInfos);
    // accountBalance = await wizard.call("balanceOf", { owner: BigInt(account1.starknetContract.address) });
    // console.log("balance is ", accountBalance);
    // await account1.invoke(wizard, "mintWiz", { wizName: starknet.shortStringToBigInt("gropd2")});
    // accountBalance = await wizard.call("balanceOf", { owner: BigInt(account1.starknetContract.address) });
    // console.log("balance is ", accountBalance);
    // let wizStat = await account1.call(wizard, "get_stats", { wiz_id: 1});
  });
});
