import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    tomoHubEntryPointProxy,
    mockTomo,
    subject1,
    TOMO_NAME,
    currentTimestamp,
} from '../__setup.spec';;
import {buildBuySeparator} from '../helpers/utils'
import { ERRORS } from '../helpers/errors';

makeSuiteCleanRoom('Buy Whole Vote Pass With Timestamp', function () {
    context('Generic', function () {

        context('Negatives', function () {
            it('User should fail to buy vote pass with timestamp if msg.value less than price.',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 1);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 1);
                const ethValue = price1.sub(10000000);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    1,
                    100000,
                    currentTimestamp,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: ethValue}
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.FUNDS_NOT_ENOUGH);
            });

            it('User should fail to buy vote pass with timestamp if the price large than max accept price.',   async function () {
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 1);
                const price1 = await mockTomo.connect(user).getBuyPriceAfterFee(subject1, 1);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassAndFragment(
                    subject1,
                    1,
                    price1.sub(100000),
                    currentTimestamp,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: price1}
                )).to.be.revertedWithCustomError(tomoHubEntryPointProxy, ERRORS.LARGE_THAN_MAX_ACCEPTPRICE);
            });
        })

        context('Scenarios', function () {
            it('Should get correct variable if buy vote pass with timestamp success.',   async function () {
                expect((await tomoHubEntryPointProxy._globalLockIndex())).to.equal(0);
                const sig = await buildBuySeparator(mockTomo.address, TOMO_NAME, subject1, tomoHubEntryPointProxy.address, 1);
                const price1 = await mockTomo.getBuyPriceAfterFee(subject1, 1);
                await expect(tomoHubEntryPointProxy.connect(user).buyVotePassWithLockTimeStamp(
                    subject1,
                    1,
                    price1,
                    currentTimestamp,
                    [sig.v],
                    [sig.r],
                    [sig.s],
                    {value: price1}
                )).to.not.be.reverted;
                expect((await tomoHubEntryPointProxy._globalLockIndex())).to.equal(1);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).subject)).to.equal(subject1);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).amount)).to.equal(1);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).lockUntil)).to.equal(currentTimestamp);
                expect(((await tomoHubEntryPointProxy._indexToVotePassLockInfo(0)).owner)).to.equal(userAddress);
            });
        })
    })
})