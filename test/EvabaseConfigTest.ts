'use strict';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';

chai.use(solidity);
const help = require('./initEvebase.ts');
describe('EvabaseConfig', function () {
  let app: any;
  before(async function () {
    app = await help.initEvebase();
  });

  it('Should return the new evabaseConfig once changed', async function () {
    // const EvabaseConfig = await ethers.getContractFactory("EvabaseConfig");
    // const evabaseConfig = await EvabaseConfig.deploy();
    // await evabaseConfig.deployed();
    const evabaseConfig = app.evabaseConfig;
    // expect(await evabaseConfig.greet()).to.equal("Hello, world!");

    const setBatchFlowNumTx = await evabaseConfig.setBatchFlowNum(4);

    // wait until the transaction is mined
    await setBatchFlowNumTx.wait();

    expect(await evabaseConfig.batchFlowNum()).to.equal(4);

    const keeper = '0x707cc7727Ca057056516b48864F0BA52B8A03A2b';
    const addKeepTx = await evabaseConfig.addKeeper(keeper);
    // wait until the transaction is mined
    await addKeepTx.wait();

    expect(await evabaseConfig.isKeeper(keeper));
  });

  it('Should return the new evabaseConfig once  changed', async function () {
    // const EvabaseConfig = await ethers.getContractFactory("EvabaseConfig");
    // const evabaseConfig = await EvabaseConfig.deploy();
    // await evabaseConfig.deployed();
    const evabaseConfig = app.evabaseConfig;
    const owner = await evabaseConfig.owner();
    const ownerO = await ethers.getSigners();
    console.log(owner);
    console.log(ownerO[0].address);
    expect(owner === ownerO[0].address);

    // evabaseConfig.owner().then((owner: any) => {
    //   expect(owner.to.eq(ownerO[0].address));
    // });
  });
});
