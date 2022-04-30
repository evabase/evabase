/* eslint-disable strict */
import chai, { expect } from 'chai';
// import { ethers } from "hardhat";
import { solidity } from 'ethereum-waffle';

chai.use(solidity);
const help = require('./initEvebase.ts');
describe('EvaSafesFactory', function () {
  let app: any;
  before(async function () {
    app = await help.initEvebase();
  });
  const testaddress = '0x707cc7727Ca057056516b48864F0BA52B8A03A2b';

  it('Should return the new EvaSafesFactory create safes', async function () {
    const evaSafesFactory = app.evaSafesFactory;
    const evaFlowController = app.evaFlowController;
    const evabaseConfig = app.evabaseConfig;
    await evabaseConfig.setControl(evaFlowController.address);
    // console.log(tx);

    await evaSafesFactory.calcSafes(testaddress);

    await evaSafesFactory.create(testaddress);

    const real = await evaSafesFactory.get(testaddress);
    // console.log('before', before);
    // console.log(after);
    // console.log('real', real);

    expect(before === real);
  });

  it('Should return the new evaFlowController address same', async function () {
    // const evaSafesFactory = app.evaSafesFactory;
    const evaFlowController = app.evaFlowController;
    const evabaseConfig = app.evabaseConfig;
    await evabaseConfig.setControl(evaFlowController.address);
    // console.log(tx);

    // await evaSafesFactory.calcSafes(testaddress);

    // await evaFlowController.createEvaSafes(testaddress);

    // const real = await evaSafesFactory.get(testaddress);
    // console.log(before);
    // // console.log(after);
    // console.log(real);

    // expect(before === real);
  });
});
